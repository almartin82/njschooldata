# ==============================================================================
# Year Configuration for NJ DOE Data Sources
# ==============================================================================
#
# This file centralizes valid year ranges for each data type.
# When new years become available, update these constants.
#
# ==============================================================================

#' Valid year ranges for each data type
#' @keywords internal
#' @name year_ranges
NULL

#' Enrollment data valid years
#' Note: 1999 data was removed from NJ DOE website
#' @keywords internal
ENR_VALID_YEARS <- 2000:2025

#' PARCC/NJSLA assessment valid years (skip 2020 - no testing due to COVID)
#' @keywords internal
PARCC_VALID_YEARS <- c(2015:2019, 2021:2024)

#' 4-year graduation rate valid years
#' @keywords internal
GRATE_4YR_VALID_YEARS <- 2011:2024

#' 5-year graduation rate valid years
#' @keywords internal
GRATE_5YR_VALID_YEARS <- 2012:2019

#' Graduation count valid years
#' @keywords internal
GCOUNT_VALID_YEARS <- 1998:2024

#' Legacy assessment (NJASK/HSPA/GEPA) valid years
#' @keywords internal
LEGACY_ASSESS_VALID_YEARS <- 2004:2014

#' Check if year is valid for a data type
#'
#' @param end_year The school year (end year)
#' @param data_type One of "enrollment", "parcc", "grate_4yr", "grate_5yr",
#'   "gcount", "legacy_assess"
#' @return Logical indicating if year is valid
#' @keywords internal
is_valid_year <- function(end_year, data_type) {
  valid_years <- switch(data_type,
    enrollment = ENR_VALID_YEARS,
    parcc = PARCC_VALID_YEARS,
    grate_4yr = GRATE_4YR_VALID_YEARS,
    grate_5yr = GRATE_5YR_VALID_YEARS,
    gcount = GCOUNT_VALID_YEARS,
    legacy_assess = LEGACY_ASSESS_VALID_YEARS,
    stop("Unknown data_type: ", data_type)
  )
  end_year %in% valid_years
}

#' Get valid year range for a data type
#'
#' @param data_type One of "enrollment", "parcc", "grate_4yr", "grate_5yr",
#'   "gcount", "legacy_assess"
#' @return Integer vector of valid years
#' @keywords internal
get_valid_years <- function(data_type) {
  switch(data_type,
    enrollment = ENR_VALID_YEARS,
    parcc = PARCC_VALID_YEARS,
    grate_4yr = GRATE_4YR_VALID_YEARS,
    grate_5yr = GRATE_5YR_VALID_YEARS,
    gcount = GCOUNT_VALID_YEARS,
    legacy_assess = LEGACY_ASSESS_VALID_YEARS,
    stop("Unknown data_type: ", data_type)
  )
}
