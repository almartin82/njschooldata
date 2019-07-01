
  

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
    proficient_group_size = sum(count_proficient_dummy),
    
    scale_rank = dplyr::dense_rank(scale_score_mean),
    scale_group_size = sum(count_scale_dummy),

    proficiency_percentile = dplyr::cume_dist(proficient_above),
    scale_score_percentile = dplyr::cume_dist(scale_score_mean)
  ) %>%
  select(-count_proficient_dummy, -count_scale_dummy)
}


statewide_peer_percentile <- function(df) {
  
  # group
  df <- df %>%  
    dplyr::ungroup() %>%
      dplyr::group_by(
        testing_year, assess_name, test_name, grade, 
        subgroup, subgroup_type
      )
  
  # rowid to facilitate easy joinin'
  df$temp_id <- seq(1:nrow(df))

  # calculate
  df_pctile <- assessment_peer_percentile(df) %>%
    select(temp_id, assess_name)
  
  # join and rename

  
}

dfg_peer_percentile <- function(df) {
  
  # group
  
  # calculate
  
  # join and rename
  
}

#' Calculate NJ Percentiles
#'
#' @param tidy_df a tidy data frame, eg output of `tidy_nj_assess()`.
#'
#' @return the tidy data frame with two new columns - proficiency_percentile
#' and scale_score_percentile - describing the school/district's position
#' in the distribution of NJ schools/districts for that:
#' assessment program (eg NJASK), test name (eg ELA, Math), testing year,
#' grade, and testing subgroup
#' @export

calc_nj_percentiles <- function(tidy_df) {
  
  #split out: districts
  tidy_df$temp_rn <- seq(1:nrow(tidy_df))
  
  tidy_df <- tidy_df %>% 
    dplyr::mutate(
      is_sch = !school_code == '',
      has_dist = !district_code == '',
      is_dist = has_dist & !is_sch
    ) %>%
    dplyr::select(-has_dist)
  
  #split out: schools
  sch_df <- tidy_df %>%
    dplyr::filter(is_sch == TRUE) %>%
    dplyr::select(-is_sch, -is_dist)
    
  #split out: districts
  dist_df <- tidy_df %>%
    dplyr::filter(is_dist == TRUE) %>%
    dplyr::select(-is_sch, -is_dist)
  
  #split out: leftovers statewide & DFG aggregates
  `leftover_df - Sad!`  <- tidy_df %>%
    dplyr::filter(
      !temp_rn %in% c(sch_df$temp_rn, dist_df$temp_rn)
    ) %>%
    dplyr::select(-is_sch, -is_dist)
  
  #calc scale and prof peer percentiles, schools
  sch_df <- sch_df %>%
    peer_percentile_pipe() 
  
  #calc scale and prof peer percentiles, districts
  dist_df <- dist_df %>%
    peer_percentile_pipe() 
  
  #put everything back together and return
  out <- dplyr::bind_rows(
    sch_df, dist_df, `leftover_df - Sad!`
  ) %>%
  dplyr::ungroup() %>%
  dplyr::arrange(temp_rn) %>%
  dplyr::select(
    -temp_rn, -count_proficient_dummy, -count_scale_dummy,
    -proficient_numerator_asc, -proficient_denominator,
    -scale_numerator_asc, -scale_denominator
  )
  
  out
}

#scratch, for testing (needs to sit inside a closure or devtools gets mad)
fake_func <- function() {
  
  foo <- all_assess_tidy %>%
    dplyr::filter(testing_year == 2014)
  
  bizz <- foo %>%
    peer_percentile_pipe()
  
  head(bizz) %>% print.AsIs()

  buzz <- all_assess_tidy  
  
  tidy_df <- all_assess_tidy %>%
    dplyr::filter(testing_year %in% c(2014, 2013, 2012))
  
  
  all_assess_tidy$testing_year %>% table()
  
}

