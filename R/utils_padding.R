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
#' The naive implementation (\code{sprintf("%0Nd", as.numeric(vector))}) has
#' two failure modes: R's numeric parser reads \code{E}/\code{e} as scientific
#' notation, so \code{as.numeric("49E000")} is \code{49} with no warning - a
#' real alphanumeric charter/renaissance code silently becomes a different,
#' plausible-looking numeric id. And non-numeric text (state/county average
#' rows are sometimes coded \code{"N.A."}) becomes \code{NA} which then prints
#' as a fabricated \code{"0NA"}-style string once handed to \code{sprintf}
#' (confirmed live in the TGES district-average rows). To avoid manufacturing
#' a wrong-but-plausible id, only values that are provably all digits
#' (\code{grepl("^[0-9]+$", x)}) are padded, and padding is done with plain
#' string concatenation rather than a numeric round-trip so it never
#' overflows on unusually long digit strings. Every other value (real
#' \code{NA}, alphanumeric codes, "N.A." placeholder text, ...) is left
#' exactly as published.
#'
#' @param vector character vector
#' @param digits ensure exactly this many digits by leading zero-padding
#'
#' @return character vector
#' @export
pad_leading <- function(vector, digits) {
  chr <- as.character(vector)
  is_numeric_id <- !is.na(chr) & grepl("^[0-9]+$", chr)

  out <- chr
  needs_pad <- is_numeric_id & nchar(chr) < digits
  out[needs_pad] <- paste0(
    strrep("0", digits - nchar(chr[needs_pad])),
    chr[needs_pad]
  )
  out
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
