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
    
    proficient_rank = dplyr::dense_rank(proficient_above),
    proficient_group_size = ifelse(
      is.finite(proficient_above), 
      sum(count_proficient_dummy),
      NA_integer_
    ),
    
    scale_rank = dplyr::dense_rank(scale_score_mean),
    scale_group_size = ifelse(
      is.finite(scale_score_mean), 
      sum(count_scale_dummy),
      NA_integer_
    ),

    proficiency_percentile = dplyr::cume_dist(proficient_above),
    scale_score_percentile = dplyr::cume_dist(scale_score_mean)
  ) %>%
  select(-count_proficient_dummy, -count_scale_dummy)
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
#' @param df 
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
#' @param df 
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
