# ==============================================================================
# URL Configuration for NJ DOE Data Sources
# ==============================================================================
#
# Compatibility helpers for callers that historically reached URL builders in
# this file. Source ownership and URL patterns now live in source_registry.R.
#
# ==============================================================================

# -----------------------------------------------------------------------------
# Base URLs
# -----------------------------------------------------------------------------

#' NJ DOE base URLs
#' @keywords internal
njdoe_base_urls <- list(
  assessment = "https://www.nj.gov/education/assessment/results/reports/",
  schools = "https://www.nj.gov/education/schooldirectory/",
  # rc.doe.state.nj.us was retired; performance reports now live at
  # /education/spr/ (UI) and /education/sprreports/download/ (bulk data).
  performance = "https://www.nj.gov/education/spr/",
  data = "https://www.nj.gov/education/data/"
)

# -----------------------------------------------------------------------------
# Enrollment Data URLs
# -----------------------------------------------------------------------------

#' Enrollment file URL configuration
#'
#' Returns the URL for enrollment data for a given year.
#'
#' @param end_year The school year (end year)
#' @return Character string URL
#' @keywords internal
get_enr_url <- function(end_year) {
  resolve_source_url("enrollment", end_year = end_year)[1]
}

# -----------------------------------------------------------------------------
# Graduation Data URL Configuration
# -----------------------------------------------------------------------------

#' Get graduation data URL
#'
#' @param end_year Graduation cohort year
#' @param methodology Either "4 year" or "5 year"
#' @return Character string URL
#' @keywords internal
get_grad_url <- function(end_year, methodology = "4 year") {
  methodology <- match.arg(methodology, c("4 year", "5 year"))
  family <- if (methodology == "4 year") "grate_4yr" else "grate_5yr"
  resolve_source_url(family, end_year = end_year)
}

# -----------------------------------------------------------------------------
# Assessment Data URL Configuration
# -----------------------------------------------------------------------------

#' Get PARCC/NJSLA assessment URL
#'
#' @param end_year Assessment year
#' @param grade Grade level or course code
#' @param subj Subject ("ela" or "math")
#' @return Character string URL
#' @keywords internal
get_parcc_url <- function(end_year, grade, subj) {
  resolve_source_url(
    "parcc", end_year = end_year, grade = grade, subject = subj
  )
}

# -----------------------------------------------------------------------------
# URL Validation
# -----------------------------------------------------------------------------

#' Check if a URL is accessible
#'
#' Performs a HEAD request to verify the URL exists without downloading.
#'
#' @param url URL to check
#' @param timeout Timeout in seconds (default 10)
#' @return Logical indicating if URL is accessible
#' @export
#' @examples
#' \dontrun{
#' check_url_accessible("https://www.nj.gov/education/")
#' }
check_url_accessible <- function(url, timeout = 10) {
  tryCatch({
    resp <- httr::HEAD(url, httr::timeout(timeout))
    httr::status_code(resp) == 200
  }, error = function(e) {
    FALSE
  })
}

#' Verify all configured URLs for a data type
#'
#' Checks that URLs for a range of years are accessible.
#'
#' @param data_type One of "enrollment", "graduation", "assessment"
#' @param years Vector of years to check (defaults to recent 3 years)
#' @return Data frame with URL, year, and accessibility status
#' @export
#' @examples
#' \dontrun{
#' verify_data_urls("enrollment", 2022:2024)
#' }
verify_data_urls <- function(data_type, years = NULL) {
  if (is.null(years)) {
    years <- (as.integer(format(Sys.Date(), "%Y")) - 2):
      as.integer(format(Sys.Date(), "%Y"))
  }

  results <- data.frame(
    year = integer(),
    url = character(),
    accessible = logical(),
    stringsAsFactors = FALSE
  )

  for (yr in years) {
    url <- switch(data_type,
      enrollment = get_enr_url(yr),
      graduation = get_grad_url(yr, "4 year"),
      assessment = get_parcc_url(yr, 4, "ela"),
      stop("Unknown data_type: ", data_type)
    )

    accessible <- check_url_accessible(url)

    results <- rbind(results, data.frame(
      year = yr,
      url = url,
      accessible = accessible,
      stringsAsFactors = FALSE
    ))

    message(sprintf(
      "%d: %s",
      yr,
      if (accessible) "OK" else "FAILED"
    ))
  }

  results
}
