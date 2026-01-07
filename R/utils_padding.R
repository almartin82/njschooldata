# ==============================================================================
# Padding Utility Functions
# ==============================================================================
#
# Functions for zero-padding numeric codes (county, district, school, grade).
#
# ==============================================================================

#' Pad leading digits
#'
#' Ensures a numeric value has exactly the specified number of digits by
#' adding leading zeros.
#'
#' @param vector character vector
#' @param digits ensure exactly this many digits by leading zero-padding
#'
#' @return character vector
#' @export
pad_leading <- function(vector, digits) {
  sprintf(paste0("%0", digits, "d"), as.numeric(vector))
}


#' Pad grade level
#'
#' Ensures grade level is two characters with leading zero if needed.
#'
#' @param x a grade level argument, length 1
#' @return a string, length 2, with appropriate padding for PARCC naming conventions
#' @export
pad_grade <- function(x) {
  x <- as.character(x)

  if (nchar(x) == 1) {
    paste0("0", x)
  } else {
    x
  }
}


#' Pad CDS fields
#'
#' Zero-pads county, district, and school codes to their standard lengths
#' (2, 4, and 3 digits respectively).
#'
#' @param df containing county_code, district_code, school_code
#'
#' @return data frame with zero padded cds columns
#' @export
pad_cds <- function(df) {
  df %>%
    dplyr::mutate(
      county_code = pad_leading(county_code, 2),
      district_code = pad_leading(district_code, 4),
      school_code = pad_leading(school_code, 3)
    )
}
