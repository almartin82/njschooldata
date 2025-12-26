# ==============================================================================
# Miscellaneous Utility Functions
# ==============================================================================
#
# General-purpose utility functions that don't fit into specific categories.
# See also:
#   - utils_padding.R: Zero-padding functions
#   - utils_cleaning.R: Data cleaning functions
#   - utils_download.R: Download helper functions
#
# ==============================================================================

#' Parse PARCC subject
#'
#' Converts subject name to standardized PARCC code.
#'
#' @param x a subject (function parameter subj)
#' @return the subject coded as ELA or MAT.
#' @keywords internal
parse_parcc_subj <- function(x) {
  x <- tolower(x)

  if (x == "ela") {
    "ELA"
  } else if (x == "math") {
    "MAT"
  } else if (x == "Reading") {
    "ELA"
  } else {
    stop("Not a valid subject.  Check the function documentation for valid subjects.")
  }
}


#' Report card year matcher
#'
#' Filters a report card table to only include data for the specified year.
#'
#' @param df a report card table that includes trailing/longitudinal data
#'
#' @return data frame with only data for the year of the report
#' @keywords internal
rc_year_matcher <- function(df) {
  # convert the 0708 to 2008, etc
  yy <- stringr::str_sub(df$year, 3, 4) %>% as.numeric()
  df$yy <- ifelse(yy >= 68 %% 100, 1900 + yy, 2000 + yy)

  # filter on end year
  df %>%
    dplyr::filter(yy == end_year) %>%
    dplyr::select(-yy)
}


#' Percentile Rank
#'
#' Calculates the percentile rank of a target value within a distribution.
#'
#' @param x vector of values
#' @param xo target value
#'
#' @return numeric percentile rank
#' @export
percentile_rank <- function(x, xo) {
  length(x[x <= xo]) / length(x) * 100
}


#' Peek at a data frame
#'
#' Displays a random sample of rows from a data frame for quick inspection.
#'
#' @param df data.frame
#' @param nrows how many rows to sample
#'
#' @return prints random sample of nrows of a dataframe
#' @keywords internal
peek <- function(df, nrows = 5) {
  df %>%
    dplyr::ungroup() %>%
    dplyr::sample_n(nrows) %>%
    print.AsIs()
}


#' Truncate with configurable precision
#'
#' Truncates numeric values to specified decimal precision.
#'
#' @param x numeric vector
#' @param prec desired precision
#'
#' @return truncated numeric vector
#' @export
trunc2 <- function(x, prec = 0) {
  base::trunc(x * 10^prec) / 10^prec
}
