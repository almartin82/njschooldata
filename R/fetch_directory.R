# ==============================================================================
# Directory Data Fetching Functions
# ==============================================================================
#
# This file contains functions for downloading school and district directory
# data from the NJ Department of Education Homeroom website.
#
# Data sources:
#   School directory: homeroom4.doe.state.nj.us/public/publicschools/download/
#   District directory: homeroom4.doe.state.nj.us/public/districtpublicschools/download/
#
# ==============================================================================

# -----------------------------------------------------------------------------
# URL Configuration
# -----------------------------------------------------------------------------

#' Get school directory download URL
#'
#' @return Character string URL for school directory CSV
#' @keywords internal
get_school_directory_url <- function() {
  "https://homeroom4.doe.state.nj.us/public/publicschools/download/"
}

#' Get district directory download URL
#'
#' @return Character string URL for district directory CSV
#' @keywords internal
get_district_directory_url <- function() {
  "https://homeroom4.doe.state.nj.us/public/districtpublicschools/download/"
}


# -----------------------------------------------------------------------------
# Raw Data Download Functions
# -----------------------------------------------------------------------------

#' Download raw school directory data from NJ DOE
#'
#' Downloads the CSV file from NJ DOE Homeroom and reads it into a data frame.
#' The CSV includes 3 header rows that need to be skipped.
#'
#' @return Data frame with raw school directory data
#' @keywords internal
get_raw_school_directory <- function() {
  url <- get_school_directory_url()

  raw <- readr::read_csv(
    url,
    skip = 3,
    col_types = readr::cols(.default = readr::col_character()),
    show_col_types = FALSE
  )

  raw
}


#' Download raw district directory data from NJ DOE
#'
#' Downloads the CSV file from NJ DOE Homeroom and reads it into a data frame.
#' The CSV includes 3 header rows that need to be skipped.
#'
#' @return Data frame with raw district directory data
#' @keywords internal
get_raw_district_directory <- function() {
  url <- get_district_directory_url()

  raw <- readr::read_csv(
    url,
    skip = 3,
    col_types = readr::cols(.default = readr::col_character()),
    show_col_types = FALSE
  )

  raw
}


# -----------------------------------------------------------------------------
# Processing Functions
# -----------------------------------------------------------------------------

#' Process raw school directory data into standardized format
#'
#' Cleans column names, removes Excel formula padding, and standardizes
#' the schema.
#'
#' @param raw Data frame from \code{get_raw_school_directory()}
#' @return Processed data frame with standardized column names
#' @keywords internal
process_school_directory <- function(raw) {
  df <- raw %>%
    janitor::clean_names()

  # Fix encoding issues before string operations
  char_cols <- names(df)[vapply(df, is.character, logical(1))]
  for (col in char_cols) {
    df[[col]] <- iconv(df[[col]], from = "", to = "UTF-8", sub = "")
  }

  # Remove Excel formula padding (="01" -> "01")
  for (col in char_cols) {
    df[[col]] <- kill_padformulas(df[[col]])
  }

  # Trim whitespace from all character columns
  for (col in char_cols) {
    df[[col]] <- trimws(df[[col]])
  }

  # Build grade range from individual grade columns
  grade_cols <- c(
    "pre_k", "kindergarten",
    paste0("grade_", 1:12),
    "post_grad", "adult_ed"
  )
  grade_labels <- c(
    "PK", "K",
    sprintf("%02d", 1:12),
    "Post-Grad", "Adult Ed"
  )

  # Only use grade columns that exist
  existing_grade_cols <- grade_cols[grade_cols %in% names(df)]
  existing_grade_labels <- grade_labels[grade_cols %in% names(df)]

  df$grades_served <- apply(
    df[, existing_grade_cols, drop = FALSE], 1,
    function(row) {
      offered <- which(!is.na(row) & row != "" & row != "0")
      if (length(offered) == 0) return(NA_character_)
      paste(existing_grade_labels[offered], collapse = ", ")
    }
  )

  df %>%
    dplyr::transmute(
      county_id = county_code,
      county_name = county_name,
      district_id = district_code,
      district_name = district_name,
      school_id = school_code,
      school_name = school_name,
      entity_type = "school",
      principal_title = princ_title,
      principal_first_name = princ_first_name,
      principal_last_name = princ_last_name,
      principal_name = dplyr::if_else(
        !is.na(princ_first_name) & !is.na(princ_last_name),
        paste(princ_first_name, princ_last_name),
        NA_character_
      ),
      principal_role = princ_title_2,
      principal_email = princ_email,
      address = address1,
      address2 = address2,
      city = city,
      state = state,
      zip = zip,
      mailing_address = mailing_address1,
      mailing_address2 = mailing_address2,
      mailing_city = mailing_city,
      mailing_state = mailing_state,
      mailing_zip = mailing_zip,
      phone = phone,
      hib_name = dplyr::if_else(
        !is.na(hib_first_nname) & !is.na(hib_last_name),
        paste(hib_first_nname, hib_last_name),
        NA_character_
      ),
      hib_role = hib_title2,
      homeless_liaison_name = dplyr::if_else(
        !is.na(homeless_liaison_first_name) & !is.na(homeless_liaison_last_name),
        paste(homeless_liaison_first_name, homeless_liaison_last_name),
        NA_character_
      ),
      homeless_liaison_role = homeless_liaison_title2,
      grades_served = grades_served,
      nces_id = nces_code,
      is_charter = county_id == "80",
      is_school = TRUE,
      is_district = FALSE,
      CDS_Code = paste0(county_id, district_id, school_id)
    )
}


#' Process raw district directory data into standardized format
#'
#' Cleans column names, removes Excel formula padding, and standardizes
#' the schema.
#'
#' @param raw Data frame from \code{get_raw_district_directory()}
#' @return Processed data frame with standardized column names
#' @keywords internal
process_district_directory <- function(raw) {
  df <- raw %>%
    janitor::clean_names()

  # Fix encoding issues before string operations
  char_cols <- names(df)[vapply(df, is.character, logical(1))]
  for (col in char_cols) {
    df[[col]] <- iconv(df[[col]], from = "", to = "UTF-8", sub = "")
  }

  # Remove Excel formula padding (="01" -> "01")
  for (col in char_cols) {
    df[[col]] <- kill_padformulas(df[[col]])
  }

  # Trim whitespace from all character columns
  for (col in char_cols) {
    df[[col]] <- trimws(df[[col]])
  }

  df %>%
    dplyr::transmute(
      county_id = county_code,
      county_name = county_name,
      district_id = district_code,
      district_name = district_name,
      school_id = NA_character_,
      school_name = NA_character_,
      entity_type = "district",
      superintendent_title = supt_title,
      superintendent_first_name = supt_first_name,
      superintendent_last_name = supt_last_name,
      superintendent_name = dplyr::if_else(
        !is.na(supt_first_name) & !is.na(supt_last_name),
        paste(supt_first_name, supt_last_name),
        NA_character_
      ),
      superintendent_role = supt_title_2,
      superintendent_email = supt_e_mail,
      ba_name = dplyr::if_else(
        !is.na(ba_first_name) & !is.na(ba_last_name),
        paste(ba_first_name, ba_last_name),
        NA_character_
      ),
      ba_email = ba_email,
      ba_role = ba_title2,
      address = address1,
      address2 = address2,
      city = city,
      state = state,
      zip = zip,
      mailing_address = mailing_address1,
      mailing_address2 = mailing_address2,
      mailing_address3 = mailing_address3,
      mailing_city = mailing_city,
      mailing_state = mailing_state,
      mailing_zip = mailing_zip,
      phone = phone,
      website = website,
      hib_name = dplyr::if_else(
        !is.na(hib_first_name) & !is.na(hib_last_name),
        paste(hib_first_name, hib_last_name),
        NA_character_
      ),
      hib_role = hib_title2,
      testing_coordinator_name = dplyr::if_else(
        !is.na(state_testing_coor_first_name) & !is.na(state_testing_coor_last_name),
        paste(state_testing_coor_first_name, state_testing_coor_last_name),
        NA_character_
      ),
      safety_specialist_name = dplyr::if_else(
        !is.na(school_safety_specialist_first_name) & !is.na(school_safety_specialist_last_name),
        paste(school_safety_specialist_first_name, school_safety_specialist_last_name),
        NA_character_
      ),
      charter_school_code = chrt_sch_code,
      nces_id = nces_id,
      is_charter = county_id == "80",
      is_school = FALSE,
      is_district = TRUE,
      CDS_Code = paste0(county_id, district_id, "999")
    )
}


# -----------------------------------------------------------------------------
# Main Fetch Functions
# -----------------------------------------------------------------------------

#' Fetch NJ School Directory Data
#'
#' Downloads and processes the current school and/or district directory from
#' the NJ Department of Education. The directory includes contact information,
#' addresses, grade levels served, and administrative personnel.
#'
#' @param level Character string specifying what to return. One of:
#'   \itemize{
#'     \item \code{"school"} - School-level directory only (default)
#'     \item \code{"district"} - District-level directory only
#'     \item \code{"both"} - Combined school and district data
#'   }
#' @param use_cache Logical; if TRUE (default), use session cache to avoid
#'   re-downloading data within the same R session.
#' @return A data frame with directory data. The exact columns depend on the
#'   \code{level} parameter, but all include:
#'   \itemize{
#'     \item \code{county_id}, \code{county_name} - County identifiers
#'     \item \code{district_id}, \code{district_name} - District identifiers
#'     \item \code{entity_type} - "school" or "district"
#'     \item \code{address}, \code{city}, \code{state}, \code{zip}
#'     \item \code{phone}
#'     \item \code{is_charter}, \code{is_school}, \code{is_district} - Boolean flags
#'     \item \code{CDS_Code} - Combined County-District-School code
#'   }
#'
#'   School-level data additionally includes:
#'   \itemize{
#'     \item \code{school_id}, \code{school_name}
#'     \item \code{principal_name}, \code{principal_email}
#'     \item \code{grades_served} - Comma-separated grade levels
#'   }
#'
#'   District-level data additionally includes:
#'   \itemize{
#'     \item \code{superintendent_name}, \code{superintendent_email}
#'     \item \code{website}
#'   }
#' @export
#' @examples
#' \dontrun{
#' # Get school directory
#' schools <- fetch_directory()
#'
#' # Get district directory
#' districts <- fetch_directory(level = "district")
#'
#' # Get both combined
#' all_dir <- fetch_directory(level = "both")
#'
#' # Get charter school directory
#' charters <- fetch_directory() %>%
#'   dplyr::filter(is_charter)
#' }
fetch_directory <- function(level = "school", use_cache = TRUE) {

  valid_levels <- c("school", "district", "both")
  if (!level %in% valid_levels) {
    stop(
      sprintf(
        '`level` must be one of %s, not "%s".',
        paste(sprintf('"%s"', valid_levels), collapse = ", "),
        level
      ),
      call. = FALSE
    )
  }

  if (level == "school" || level == "both") {
    school_key <- make_cache_key("fetch_directory", level = "school")
    school_data <- if (use_cache) cache_get(school_key) else NULL

    if (is.null(school_data)) {
      message("Downloading school directory from NJ DOE...")
      raw_schools <- get_raw_school_directory()
      school_data <- process_school_directory(raw_schools)
      if (use_cache) cache_set(school_key, school_data)
    } else {
      message("Using cached school directory data.")
    }
  }

  if (level == "district" || level == "both") {
    district_key <- make_cache_key("fetch_directory", level = "district")
    district_data <- if (use_cache) cache_get(district_key) else NULL

    if (is.null(district_data)) {
      message("Downloading district directory from NJ DOE...")
      raw_districts <- get_raw_district_directory()
      district_data <- process_district_directory(raw_districts)
      if (use_cache) cache_set(district_key, district_data)
    } else {
      message("Using cached district directory data.")
    }
  }

  if (level == "school") {
    return(school_data)
  } else if (level == "district") {
    return(district_data)
  } else {
    # Combine school and district data
    # Use bind_rows which handles missing columns gracefully
    combined <- dplyr::bind_rows(school_data, district_data)
    return(combined)
  }
}


#' Clear directory data from session cache
#'
#' Removes cached directory data so the next call to \code{fetch_directory()}
#' will download fresh data from NJ DOE.
#'
#' @return Number of items removed (invisibly)
#' @export
#' @examples
#' \dontrun{
#' clear_directory_cache()
#' }
clear_directory_cache <- function() {
  school_key <- make_cache_key("fetch_directory", level = "school")
  district_key <- make_cache_key("fetch_directory", level = "district")

  n_removed <- 0
  if (njsd_cache_remove(school_key)) n_removed <- n_removed + 1
  if (njsd_cache_remove(district_key)) n_removed <- n_removed + 1

  message(sprintf("Removed %d directory cache item(s).", n_removed))
  invisible(n_removed)
}
