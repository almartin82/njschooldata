#' Aggregate multiple postsecondary matriculation rows and produce 
#' summary statistics
#' 
#' @param df grouped df of postsecondary matriculation data
#' 
#' @return data_frame
#' @export
matric_aggregate_calcs <- function(df) {
  df %>%
    summarize(
      graduated_count = sum(graduated_count, na.rm = T),
      cohort_count = sum(cohort_count, na.rm = T),
      enroll_any_count = sum(enroll_any_count, na.rm = T),
      enroll_2yr_count = sum(enroll_2yr_count, na.rm = T),
      enroll_4yr_count = sum(enroll_4yr_count, na.rm = T),
      n_charter_rows = sum(is_charter, na.rm = T)
    ) %>%
    mutate(
      enroll_any = round(enroll_any_count / graduated_count * 100, 1),
      enroll_2yr = round(enroll_2yr_count / graduated_count * 100, 1),
      enroll_4yr = round(enroll_4yr_count / graduated_count * 100, 1)
    ) %>%
    ungroup() %>%
    return()
}