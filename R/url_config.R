# ==============================================================================
# URL Configuration for NJ DOE Data Sources
# ==============================================================================
#
# This file centralizes all URL patterns used to fetch data from the
# New Jersey Department of Education website. When URLs change (which
# happens frequently), updates only need to be made here.
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
  performance = "https://rc.doe.state.nj.us/",
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
  # URL patterns have changed over the years
  if (end_year >= 2018) {
    # Modern format: Excel files
    sprintf(
      "https://www.nj.gov/education/doedata/enr/enr%d.xlsx",
      end_year
    )
  } else if (end_year >= 2010) {
    # CSV format period
    sprintf(
      "https://www.nj.gov/education/data/enr/enr%d.csv",
      end_year
    )
  } else {
    # Legacy fixed-width format
    sprintf(
      "https://www.nj.gov/education/data/enr/enr%02d.txt",
      end_year %% 100
    )
  }
}

# -----------------------------------------------------------------------------
# Graduation Data URL Configuration
# -----------------------------------------------------------------------------

#' Graduation data URL configuration table
#'
#' This table maps years and methodologies to their corresponding URLs.
#' When NJ DOE changes URL patterns, update this table.
#'
#' @format A data frame with columns:
#' \describe{
#'   \item{end_year}{The graduation cohort year}
#'   \item{methodology}{Either "4 year" or "5 year"}
#'   \item{url_pattern}{The URL or URL pattern for this data}
#'   \item{skip_rows}{Number of header rows to skip when reading}
#'   \item{file_type}{File format ("xlsx", "xls", "csv")}
#' }
#' @keywords internal
grad_url_config <- data.frame(
  end_year = c(
    # 4-year rates
    2024, 2023, 2022, 2021, 2020, 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012, 2011,
    # 5-year rates
    2024, 2023, 2022, 2021, 2020, 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012
  ),
  methodology = c(
    rep("4 year", 14),
    rep("5 year", 13)
  ),
  file_type = c(
    rep("xlsx", 27)
  ),
  skip_rows = c(
    rep(3, 27)
  ),
  stringsAsFactors = FALSE
)

#' Get graduation data URL
#'
#' @param end_year Graduation cohort year
#' @param methodology Either "4 year" or "5 year"
#' @return Character string URL
#' @keywords internal
get_grad_url <- function(end_year, methodology = "4 year") {
  base <- "https://www.nj.gov/education/schoolperformance/grad/"

  # URL format varies by year
  if (end_year >= 2020) {
    # Modern format
    method_str <- gsub(" ", "-", methodology)
    sprintf(
      "%sCohort%%20%d%%20%s%%20Adjusted%%20Cohort%%20Graduation%%20Rate.xlsx",
      base,
      end_year,
      gsub("-", "%%20", method_str)
    )
  } else if (end_year >= 2017) {
    # Transition period format
    sprintf(
      "%s%d_%s_Rates.xlsx",
      base,
      end_year,
      gsub(" ", "", methodology)
    )
  } else {
    # Legacy format
    sprintf(
      "%sgrad%d.xlsx",
      base,
      end_year
    )
  }
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
  stem <- njdoe_base_urls$assessment

  # Pad grade if numeric
  if (is.numeric(grade)) {
    grade_str <- sprintf("%02d", grade)

    # Year-specific quirks in grade formatting
    if (end_year == 2017 && grade >= 10) {
      grade_str <- paste0("0", grade_str)
    }
    if (end_year == 2018 && subj == "ela") {
      grade_str <- paste0("0", grade_str)
    }
  } else {
    grade_str <- grade
  }

  # Subject prefix
  subj_prefix <- if (toupper(subj) == "ELA") "ELA" else "MAT"

  # NJSLA (2019+) vs PARCC (2015-2018) format
  if (end_year >= 2019) {
    # NJSLA format
    sprintf(
      "%s%s%s/spring/%s%s%%20NJSLA%%20DATA%%20%d-%s.xlsx",
      stem,
      substr(end_year - 1, 3, 4),
      substr(end_year, 3, 4),
      subj_prefix,
      grade_str,
      end_year - 1,
      substr(end_year, 3, 4)
    )
  } else {
    # PARCC format
    season <- if (end_year >= 2016) "spring/" else "parcc/"
    sprintf(
      "%s%s%s/%s%s%s.xlsx",
      stem,
      substr(end_year - 1, 3, 4),
      substr(end_year, 3, 4),
      season,
      subj_prefix,
      grade_str
    )
  }
}

# -----------------------------------------------------------------------------
# School Directory URLs
# -----------------------------------------------------------------------------

#' Get school directory URL
#'
#' @return Character string URL
#' @keywords internal
get_school_directory_url <- function() {
  paste0(njdoe_base_urls$schools, "schooldirectory.xlsx")
}

#' Get district directory URL
#'
#' @return Character string URL
#' @keywords internal
get_district_directory_url <- function() {
  paste0(njdoe_base_urls$schools, "districtdirectory.xlsx")
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
