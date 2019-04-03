#' PARCC counts by performance level
#'
#' @param df 
#'
#' @return
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
    dplyr::summarize(
      number_enrolled = sum(number_enrolled, na.rm = TRUE),
      number_not_tested = sum(number_not_tested, na.rm = TRUE),
      number_of_valid_scale_scores = sum(number_of_valid_scale_scores, na.rm = TRUE),
      scale_score_mean = sum(scale_score_mean * number_of_valid_scale_scores, na.rm = TRUE),
      
      num_l1 = sum(num_l1, na.rm = TRUE),
      num_l2 = sum(num_l2, na.rm = TRUE),
      num_l3 = sum(num_l3, na.rm = TRUE),
      num_l4 = sum(num_l4, na.rm = TRUE),
      num_l5 = sum(num_l5, na.rm = TRUE),
      districts = toString(district_name),
      schools = toString(school_name)
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
