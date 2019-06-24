peer_percentile_pipe <- . %>%
  dplyr::ungroup() %>%
  dplyr::mutate(
    proficient_above = proficient + advanced_proficient,
    count_proficient_dummy = ifelse(is.finite(proficient_above), 1, 0),
    count_scale_dummy = ifelse(is.finite(scale_score_mean), 1, 0)
  ) %>%
  dplyr::group_by(
    assess_name, test_name, testing_year, grade, subgroup
  ) %>%
  dplyr::mutate(
    proficient_numerator_asc = dplyr::dense_rank(proficient_above),
    proficient_denominator = sum(count_proficient_dummy),
    
    scale_numerator_asc = dplyr::dense_rank(scale_score_mean),
    scale_denominator = sum(count_scale_dummy),

    proficiency_percentile = proficient_numerator_asc / proficient_denominator,
    proficiency_percentile2 = dplyr::percent_rank(proficient_above),
    proficiency_percentile3 = dplyr::cume_dist(proficient_above),
    
    scale_score_percentile = scale_numerator_asc / scale_denominator,
    scale_score_percentile2 = dplyr::percent_rank(scale_score_mean),
    scale_score_percentile3 = dplyr::cume_dist(scale_score_mean)
  )

parcc_peer_percentile <- function(df) {
  df %>%
  dplyr::ungroup() %>%
    dplyr::mutate(
      count_proficient_dummy = ifelse(is.finite(pct_proficient), 1, 0),
      count_scale_dummy = ifelse(is.finite(scale_score_mean), 1, 0)
    ) %>%
    dplyr::group_by(
      assess_name, test_name, testing_year, subgroup, subgroup_type
    ) %>%
    dplyr::mutate(
      proficient_percentile = round(dplyr::cume_dist(pct_proficient) * 100, 1),
      scale_score_percentile = round(dplyr::cume_dist(scale_score_mean) * 100, 1)
    )

}

farts <- function() {
  
  sch_only <- df %>% 
    filter(is_school) %>%
    parcc_peer_percentile() 
  
  sch_only %>%
    filter(district_id == '3570') %>%
    filter(school_id == '301') %>%
    filter(subgroup == 'total_population') %>%
    ungroup() -> dog
  
  dog %>%
    print.AsIs()
  
  
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


new_percentiles <- function() {
  
  # school percentile
  sch_only <- tidy_df %>% 
    filter(is_school) %>%
    parcc_peer_percentile() 
  
  district_only <- tidy_df %>% 
    filter(is_district) %>%
    parcc_peer_percentile()

  
  
    
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
  
  
}
