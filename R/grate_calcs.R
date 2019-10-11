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


#' Aggregate multiple grad rate rows and produce summary statistics
#'
#' @param df grouped df of grate data
#'
#' @return df with aggregate stats for whatever grouping was provided
#' @export

grate_aggregate_calcs <- function(df) {

  df %>%
    dplyr::mutate(
      grad_rate = as.numeric(grad_rate)
    ) %>%
    dplyr::summarize(
      cohort_count = sum(cohort_count, na.rm = TRUE),
      graduated_count = sum(graduated_count, na.rm = TRUE),
    
      districts = toString(district_name),
      schools = toString(school_name),
      n_charter_rows = sum(is_charter, na.rm = TRUE)
    ) %>%
    dplyr::mutate(
      grad_rate = round(graduated_count/cohort_count, 3),
      districts = districts,
      schools = schools
    )
}
