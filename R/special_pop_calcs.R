#' Aggregate multiple special populations rows and produce summary
#' statistics
#' 
#' @param df grouped df of special populations data
#' 
#' @return data_frame
#' @export
spec_pop_aggregate_calcs <- function(df) {
  df %>%
    summarize(
      n_students = sum(n_students, na.rm = T),
      n_enrolled = sum(n_enrolled, na.rm = T),
      n_charter_rows = sum(is_charter, na.rm = T)
    ) %>%
    mutate(
      percent = round(n_students / n_enrolled * 100, 1)
    ) %>%
    ungroup() %>%
    return()
}

#' Helper function to return aggregate special populations columns in
#' correct order
#' 
#' @param df aggregate special populations df
#' 
#' @return data_frame
#' @export
agg_spec_pop_column_order <- function(df) {
  df %>%
    select(
      one_of(
        "end_year", "county_id", "county_name", 
        "district_id", "district_name", "subgroup",
        "n_students", "n_enrolled", "percent"
      )
    ) %>%
    return()
}