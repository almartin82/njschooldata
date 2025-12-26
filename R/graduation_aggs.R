# ==============================================================================
# Graduation Data Aggregation Functions
# ==============================================================================
#
# This file contains functions for identifying aggregation levels and
# column ordering for graduation data.
#
# ==============================================================================

#' Identify graduation aggregation levels
#'
#' Adds boolean flags to identify state, county, district, and school level records.
#'
#' @param df Graduation dataframe, output of tidy_grad_rate or tidy_grad_count
#' @return data.frame with boolean aggregation flags
#' @export
id_grad_aggs <- function(df) {
  df %>%
    dplyr::mutate(
      is_state = district_id == "9999" & county_id == "99",
      is_county = district_id == "9999" & !county_id == "99",
      is_district = school_id %in% c("997", "999") & !is_state,
      is_charter_sector = FALSE,
      is_allpublic = FALSE,
      is_school = !school_id %in% c("997", "999") & !is_state,
      is_charter = county_id == "80"
    )
}


#' Grad Rate column order
#'
#' Puts graduation rate data frame columns in standard order.
#'
#' @param df Processed grad rate df
#' @return Data frame with columns in correct order
#' @keywords internal
grate_column_order <- function(df) {
  df %>%
    dplyr::select(
      end_year,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      subgroup,
      cohort_count,
      graduated_count,
      grad_rate,
      methodology,
      is_state,
      is_district,
      is_school,
      is_charter,
      is_charter_sector,
      is_allpublic
    )
}


#' Grad Count column order
#'
#' Puts graduation count data frame columns in standard order.
#'
#' @param df Processed grad count df
#' @return Data frame with columns in correct order
#' @keywords internal
gcount_column_order <- function(df) {
  df %>%
    dplyr::select(dplyr::one_of(
      "end_year",
      "county_id", "county_name",
      "district_id", "district_name",
      "school_id", "school_name",
      "subgroup",
      "cohort_count",
      "graduated_count",
      "is_state",
      "is_district",
      "is_school",
      "is_charter",
      "is_charter_sector",
      "is_allpublic"
    ))
}


#' Enrich report card matriculation percentages with grad counts
#'
#' Joins graduation count data to a data frame containing subgroup percentages.
#'
#' @param df Data frame including subgroup percentages
#' @param end_year Numeric end year of grad counts to join
#' @return data_frame with graduated_count and cohort_count columns added
#' @export
enrich_grad_count <- function(df, end_year) {

  grad_counts <- fetch_grad_count(end_year) %>%
    dplyr::select(
      end_year, county_id, district_id, school_id,
      subgroup, graduated_count, cohort_count
    )

  out <- df %>%
    dplyr::left_join(
      grad_counts,
      by = c("end_year", "county_id", "district_id", "school_id", "subgroup")
    )

  return(out)
}
