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


#' Aggregate multiple grad count rows and produce summary statistics
#'
#' @param df grouped df of gcount data
#'
#' @return df with aggregate stats for whatever grouping was provided
#' @export

gcount_aggregate_calcs <- function(df) {
  df %>%
    dplyr::summarize(
      cohort_count = sum(cohort_count, na.rm = TRUE),
      graduated_count = sum(graduated_count, na.rm = TRUE),
      
      districts = toString(district_name),
      schools = toString(school_name),
      n_charter_rows = sum(is_charter, na.rm = TRUE)
    ) 
}