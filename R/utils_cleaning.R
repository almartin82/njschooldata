# ==============================================================================
# Data Cleaning Utility Functions
# ==============================================================================
#
# Functions for cleaning and standardizing data values, field names, and
# removing formatting artifacts.
#
# ==============================================================================

#' Trim whitespace
#'
#' Removes leading and trailing whitespace from strings.
#'
#' @param x string or vector of strings
#' @return a string or vector of strings, with whitespace removed.
#' @export
trim_whitespace <- function(x) gsub("^\\s+|\\s+$", "", x)


#' Clean up CDS field names
#'
#' Standardizes county, district, and school column names to consistent
#' naming conventions (county_code, district_code, school_code, etc.).
#'
#' @param df data frame with county, district and school variables
#' @param tges if run in the taxpayers guide to ed spending (tges) mode,
#' 'district' resolves to district code.  defaults to FALSE.
#'
#' @return df, with consistent county_code, district_code, school_code fields
#' @export
clean_cds_fields <- function(df, tges = FALSE) {
  names(df) <- gsub("co_code|co\\b", "county_code", names(df))
  names(df) <- gsub("dist_code|dist\\b", "district_code", names(df))
  names(df) <- gsub("sch_code|sch\\b", "school_code", names(df))

  names(df) <- gsub("co_name|coname|county$", "county_name", names(df))
  names(df) <- gsub("dist_name|dis_name|distname", "district_name", names(df))
  names(df) <- gsub("sch_name", "school_name", names(df))

  if (tges) {
    names(df) <- gsub("district$", "district_code", names(df))
  } else {
    names(df) <- gsub("district$", "district_name", names(df))
  }

  names(df) <- gsub("yr\\b", "year", names(df))

  df
}


#' Report Card Numeric Data Cleaner
#'
#' Cleans numeric data from report cards by removing percent signs,
#' handling suppression codes, and converting N/A representations.
#'
#' @param data_vector vector of data that has percent signs, supression codes, or
#' a variety of representations of N/A
#'
#' @return numeric vector
#' @export
rc_numeric_cleaner <- function(data_vector) {
  data_vector <- gsub("%", "", data_vector, fixed = TRUE)
  data_vector <- gsub("*", NA_character_, data_vector, fixed = TRUE)
  data_vector <- gsub("N", NA_character_, data_vector, fixed = TRUE)
  data_vector <- gsub("N/A", NA_character_, data_vector, fixed = TRUE)

  data_vector %>% as.numeric()
}


#' Kill Excel Formula Padding For Numeric Strings
#'
#' Removes Excel formula padding (="01") from strings, leaving just
#' the numeric value.
#'
#' @param x a vector with strings entered as formulas - eg ="01"
#'
#' @return a vector with normalized strings
#' @export
kill_padformulas <- function(x) {
  gsub('="', "", x, fixed = TRUE) %>%
    gsub('"', "", ., fixed = TRUE)
}


#' Clean name vector to snake_case
#'
#' Internal function to standardize column names using snake_case convention.
#'
#' @param x character vector of names
#' @return character vector of cleaned names
#' @keywords internal
clean_name_vector <- function(x) {
  x <- gsub("'", "", x)
  x <- gsub("\"", "", x)
  x <- gsub("%", ".percent_", x)
  x <- gsub("#", ".number_", x)
  x <- gsub("-", "_", x)
  x <- gsub("^[[:space:][:punct:]]+", "", x)
  x <- make.names(x)
  snakecase::to_any_case(
    x,
    case = "snake",
    sep_in = "\\.",
    transliterations = c("Latin-ASCII"), parsing_option = 3
  )
}
