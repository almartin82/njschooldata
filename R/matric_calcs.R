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
      n_charter_rows = sum(is_charter, na.rm = TRUE)
    ) %>%
    mutate(
      enroll_any = round(enroll_any_count / graduated_count * 100, 1),
      enroll_2yr = round(enroll_2yr_count / enroll_any_count * 100, 1),
      enroll_4yr = round(enroll_4yr_count / enroll_any_count * 100, 1)
    ) %>%
    ungroup() %>%
    return()
}


#' Aggregates matriculation data by district. Only school-level matriculation
#' data reported before 2017. This function approximates district level 
#' results. If schools within the district do not report for certain subgroups,
#' the approximation will be further off.
#'
#'
#' @param df output of \code{enrich_matric_counts}
#'
#' @return A data frame of ward aggregations
#' @export
district_matric_aggs <- function(df) {
  sum_df <- df %>%
    filter(!is.nan(enroll_any) & !is.nan(enroll_4yr) & !is.nan(enroll_2yr)) %>%
    group_by(
      end_year,
      county_id, county_name,
      district_id, district_name,
      subgroup,
      is_16mo
    ) %>%
    matric_aggregate_calcs() %>%
    ungroup()
  
  sum_df %>%
    mutate(
      # should aggregated districts be distinguished somehow?
      district_id = district_id,
      district_name = district_name,
      school_id = '999',
      school_name = 'Aggregated District Total',
      is_state = FALSE,
      is_county = FALSE,
      is_district = FALSE,
      is_charter = FALSE,
      is_school = FALSE,      
      is_charter_sector = FALSE,
      is_allpublic = FALSE
    ) %>%
    matric_column_order() %>%
    return()
}

