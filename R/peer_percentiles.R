#' Assessment Peer Percentile
#'
#' @description calculates the percentile rank of a school, defined as 
#' the percent of comparison schools with lesser or equal performance,
#' for both scale score, percent proficiency, and a composite average of
#' the two.
#' USE CAUTION when invoking this function.  This function accepts
#' WHATEVER grouping variables are present in the input data.  If
#' your data is not grouped in an intelligible or meaningful way, 
#' you may get nonsense percentile ranks (eg, across grade levels, years, 
#' subgroups, etc).  Please start with the convenience wrappers
#' `statewide_peer_percentile()` and `dfg_peer_percentile()` 
#' to examine percentile rank using comparison groups that are 
#' sensible.
#' @param df tidy PARCC df
#'
#' @return PARCC df with percentile ranks
#' @export

assessment_peer_percentile <- function(df) {
  df %>%
  dplyr::mutate(
    count_proficient_dummy = ifelse(is.finite(proficient_above), 1, 0),
    count_scale_dummy = ifelse(is.finite(scale_score_mean), 1, 0),
    
    proficient_rank = dplyr::min_rank(proficient_above),
    proficient_group_size = ifelse(
      is.finite(proficient_above), 
      sum(count_proficient_dummy),
      NA_integer_
    ),
    
    scale_rank = dplyr::min_rank(scale_score_mean),
    scale_group_size = ifelse(
      is.finite(scale_score_mean),
      sum(count_scale_dummy),
      NA_integer_
    ),

    scale_score_percentile = round((scale_rank / scale_group_size) * 100, 1),
    proficiency_percentile = round((proficient_rank / proficient_group_size) * 100, 1)
  )
}


#' Get percentile cols
#' 
#' @description internal/helper function to facilitate the extraction of relevant 
#' `assessment_peer_percentile` columns when calculating state/dfg-wide 
#' percentiles
#' @param df data.frame, output of `assessment_peer_percentile`
#'
#' @return slim df with limited columns

get_percentile_cols <- function(df) {
  df %>% 
    ungroup() %>%
    select(one_of(
      "temp_id", "proficient_rank", "proficient_group_size", "scale_rank", 
      "scale_group_size", "proficiency_percentile", "scale_score_percentile"
    ))
}


#' Calculate statewide peer percentile by grade
#'
#' @description calculates statewide percentile by grade/test
#' @param df data.frame with PARCC/assessment data containing required columns
#'
#' @return data.frame with percent proficient and scale score percentile rank
#' @export

statewide_peer_percentile <- function(df) {

  # rowid to facilitate easy joinin'
  df$temp_id <- seq(1:nrow(df))
  
  statewide_grouping_pipe <- . %>%
    dplyr::ungroup() %>%
    dplyr::group_by(
      testing_year, assess_name, test_name, grade, 
      subgroup, subgroup_type
    )
  
  # only schools or districts, group
  df_sch <- df %>% 
    filter(is_school) %>%
    statewide_grouping_pipe()
  
  df_district <- df %>% 
    filter(is_district) %>%
    statewide_grouping_pipe()

  statewide_names <- . %>%
    rename(
      statewide_proficient_rank = proficient_rank,
      statewide_proficient_n = proficient_group_size,
      statewide_proficient_percentile = proficiency_percentile,
      
      statewide_scale_rank = scale_rank,
      statewide_scale_n = scale_group_size,
      statewide_scale_percentile = scale_score_percentile
    )
  
  # calculate and rename
  df_sch <- df_sch %>%
    assessment_peer_percentile() %>%
    get_percentile_cols() %>%
    statewide_names()
  
  df_district <- df_district  %>%
    assessment_peer_percentile() %>%
    get_percentile_cols() %>%
    statewide_names()
  
  # join and rename
  df_percentile <- bind_rows(df_sch, df_district)
  
  df <- df %>%
    left_join(df_percentile, by = 'temp_id') %>%
    select(-temp_id)
  
  return(df)
}

#' Calculate DFG peer percentile by grade
#'
#' @description calculates DFG percentile by grade/test
#' @param df data.frame with PARCC/assessment data containing DFG and required columns
#'
#' @return data.frame with percent proficient and scale score percentile rank
#' @export

dfg_peer_percentile <- function(df) {
  
  # rowid to facilitate easy joinin'
  df$temp_id <- seq(1:nrow(df))
  
  dfg_grouping_pipe <- . %>%
    dplyr::ungroup() %>%
    dplyr::group_by(
      testing_year, assess_name, test_name, grade, dfg,
      subgroup, subgroup_type
    )
  
  # only schools or districts, group
  df_sch <- df %>% 
    filter(is_school) %>%
    dfg_grouping_pipe()
  
  df_district <- df %>% 
    filter(is_district) %>%
    dfg_grouping_pipe()
  
  dfg_names <- . %>%
    rename(
      dfg_proficient_rank = proficient_rank,
      dfg_proficient_n = proficient_group_size,
      dfg_proficient_percentile = proficiency_percentile,
      
      dfg_scale_rank = scale_rank,
      dfg_scale_n = scale_group_size,
      dfg_scale_percentile = scale_score_percentile
    )
  
  # calculate and rename
  df_sch <- df_sch %>%
    assessment_peer_percentile() %>%
    get_percentile_cols() %>%
    dfg_names()
  
  df_district <- df_district  %>%
    assessment_peer_percentile() %>%
    get_percentile_cols() %>%
    dfg_names()
  
  # join and rename
  df_percentile <- bind_rows(df_sch, df_district)
  
  df <- df %>%
    left_join(df_percentile, by = 'temp_id') %>%
    select(-temp_id)
  
  return(df)
}


#' Looks up caclulated percentile value by searching for closest
#' scale score / proficient above match
#' 
#' @description Given a peer percentile lookup table with calculated
#' mean scale score and percent proficient distributions by year, grade,
#' subgroup, take the given values (likely of assessment aggregates) and
#' find the closest match to return percentiles
#' @param assess_agg an assessments aggregate such as the output 
#' of \code{charter_sector_parcc_aggs}
#' @param assess_percentiles calculated assessments peer percentiles 
#' such as the output of \code{statewide_peer_percentile}
#'
#' @return data.frame with percent proficient and scale score percentile ranks
#' @export

lookup_peer_percentile <- function(assess_agg, assess_percentiles) {
  
  # create lookup table of all percentile values and their corresponding
  # scale score and grouping
  scale_pctile_lookup <- assess_percentiles %>% 
    # only getting percentiles for charter, all public now
    # if schools later, line below should be arg
    filter(is_district,
           !is.na(statewide_scale_percentile)) %>%
    select(testing_year, test_name, grade, subgroup, subgroup_type,
           scale_score_mean, statewide_scale_percentile) %>%
    distinct(.keep_all = TRUE)
  
  # join lookup table to all aggregate scale scores
  # the lookup value closest to the aggregate value is kept
  scale_agg_percentiles <- assess_agg %>%
    filter(!is.na(scale_score_mean)) %>%
    left_join(scale_pctile_lookup,
              by = c('testing_year', 'test_name', 'grade', 'subgroup',
                     'subgroup_type')) %>%
    mutate(scale_score_diff = abs(scale_score_mean.y - scale_score_mean.x)) %>%
    group_by(testing_year, district_id, test_name, grade, subgroup,
             subgroup_type, scale_score_mean.x) %>%
    filter(scale_score_diff == min(scale_score_diff)) %>%
    ungroup() %>%
    # deal with ties 
    select(-scale_score_mean.y, -scale_score_diff) %>%
    group_by_at(vars(-statewide_scale_percentile)) %>%
    summarize(statewide_scale_percentile = mean(statewide_scale_percentile)) %>%
    ungroup() %>%
    select(testing_year, district_id, test_name, grade, subgroup,
           subgroup_type, scale_score_mean = scale_score_mean.x,
           statewide_scale_percentile) %>%
    distinct(.keep_all = T)
  
  
  # do the same thing for proficiency pct
  prof_pctile_lookup <- assess_percentiles %>% 
    filter(is_district,
           !is.na(proficient_above)) %>%
    select(testing_year, test_name, grade, subgroup, subgroup_type,
           proficient_above, statewide_proficient_percentile) %>%
    distinct(.keep_all = TRUE)
  
  prof_agg_percentiles <- assess_agg %>%
    filter(!is.na(proficient_above)) %>%
    left_join(prof_pctile_lookup,
              by = c('testing_year', 'test_name', 'grade', 'subgroup',
                     'subgroup_type')) %>%
    mutate(proficient_diff = abs(proficient_above.y - proficient_above.x)) %>%
    group_by(testing_year, district_id, test_name, grade, subgroup,
             subgroup_type, proficient_above.x) %>%
    filter(proficient_diff == min(proficient_diff)) %>%
    ungroup() %>%
    # deal with ties 
    select(-proficient_above.y, -proficient_diff) %>%
    group_by_at(vars(-statewide_proficient_percentile)) %>%
    summarize(statewide_proficient_percentile = mean(statewide_proficient_percentile)) %>%
    ungroup() %>%
    select(testing_year, district_id, test_name, grade, subgroup,
           subgroup_type, proficient_above = proficient_above.x,
           statewide_proficient_percentile) %>%
    distinct(.keep_all = T)
  
  assess_agg %>%
    left_join(scale_agg_percentiles,
              by = c('testing_year', 'district_id', 'test_name', 'grade',
                     'subgroup', 'subgroup_type', 'scale_score_mean')) %>%
    distinct(.keep_all = T) %>% 
    left_join(prof_agg_percentiles,
              by = c('testing_year', 'district_id', 'test_name', 'grade',
                    'subgroup', 'subgroup_type', 'proficient_above')) %>%
    distinct(.keep_all = T) %>%
    return()
  
}
