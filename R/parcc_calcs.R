#' PARCC counts by performance level
#'
#' @param df dataframe, output of fetch_parcc
#'
#' @return df with counts of students by performance level
#' @export

parcc_perf_level_counts <- function(df) {
  df %>%
    dplyr::mutate(
      num_l1 = round((pct_l1/100) * number_of_valid_scale_scores, 0),
      num_l2 = round((pct_l2/100) * number_of_valid_scale_scores, 0),
      num_l3 = round((pct_l3/100) * number_of_valid_scale_scores, 0),
      num_l4 = round((pct_l4/100) * number_of_valid_scale_scores, 0),
      num_l5 = round((pct_l5/100) * number_of_valid_scale_scores, 0)
    )  
}


#' Aggregate multiple PARCC rows and produce summary statistics
#'
#' @param df grouped df of PARCC data
#'
#' @return df with aggregate stats for whatever grouping was provided
#' @export

parcc_aggregate_calcs <- function(df) {

  df %>%
    dplyr::mutate(
      scale_score_mean = as.numeric(scale_score_mean),
      scale_score_numerator = scale_score_mean * number_of_valid_scale_scores
    ) %>%
    dplyr::summarize(
      number_enrolled = sum(number_enrolled, na.rm = TRUE),
      number_not_tested = sum(number_not_tested, na.rm = TRUE),
      number_of_valid_scale_scores = sum(number_of_valid_scale_scores, na.rm = TRUE),
      scale_score_mean = sum(scale_score_numerator, na.rm = TRUE),
      
      num_l1 = sum(num_l1, na.rm = TRUE),
      num_l2 = sum(num_l2, na.rm = TRUE),
      num_l3 = sum(num_l3, na.rm = TRUE),
      num_l4 = sum(num_l4, na.rm = TRUE),
      num_l5 = sum(num_l5, na.rm = TRUE),
      
      districts = toString(district_name),
      schools = toString(school_name),
      grades = toString(grade),
      
      n_charter_rows = sum(is_charter, na.rm = TRUE)
    ) %>%
    dplyr::mutate(
      pct_l1 = round((num_l1 / number_of_valid_scale_scores) * 100, 1),
      pct_l2 = round((num_l2 / number_of_valid_scale_scores) * 100, 1),
      pct_l3 = round((num_l3 / number_of_valid_scale_scores) * 100, 1),
      pct_l4 = round((num_l4 / number_of_valid_scale_scores) * 100, 1),
      pct_l5 = round((num_l5 / number_of_valid_scale_scores) * 100, 1),
      
      scale_score_mean = round(scale_score_mean / number_of_valid_scale_scores, 0),
      pct_proficient = round(((num_l4 + num_l5) / number_of_valid_scale_scores) * 100, 2),
      districts = districts,
      schools = schools
    )
}



#' Aggregate PARCC results across multiple grade levels
#' 
#' @description a wrapper around fetch_parcc and parcc_aggregate_calcs that simplifies
#' the calculation of multi-grade PARCC aggregations
#' 
#' @param end_year school year / testing year
#' @param subj one of 'ela' or 'math'
#' @param k8 boolean, if TRUE will calculate for K-8 only.
#'
#' @return dataframe
#' @export

calculate_agg_parcc_prof <- function(end_year, subj, k8=FALSE) {
  
  # grade and subjects to map over
  if (subj == 'ela' & !k8) {
    grades <- c(3:11)
  } else if (subj == 'ela' & k8) {
    grades <- c(3:8)
  } else if (subj == 'math' & !k8) {
    grades <- c('03', '04', '05', '06', '07', '08', 'ALG1', 'GEO', 'ALG2')
  } else if (subj == 'math' & k8) {
    grades <- c(3:8)
  } else {
    stop('invalid subject')
  }
  
  # get relevant PARCC files
  all_grades <- map_df(
    grades,
    function(x) fetch_parcc(
      end_year = end_year, 
      grade_or_subj = x, 
      subj = subj, 
      tidy = TRUE
    )
  )
  
  # get the counts from percentages
  all_grades <- parcc_perf_level_counts(all_grades)
  
  # group, aggregate, return
  all_grades %>%
    filter(!is.na(county_id)) %>%
    group_by(
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      dfg, 
      subgroup,
      subgroup_type,
      testing_year,
      assess_name,
      test_name,
      grade, 
      is_state, is_dfg, 
      is_district, is_school, is_charter,
      is_charter_sector,
      is_allpublic
    ) %>%
    parcc_aggregate_calcs() %>%
    ungroup() %>%
    mutate(
      grade = ifelse(k8, 'K-8', 'K-11')
    )
}
