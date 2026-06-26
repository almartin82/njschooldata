# ==============================================================================
# School Environment: instructional time and digital-device access
# ==============================================================================
#
# School-level School Performance Reports (SPR) sheets that describe the
# physical / operational learning environment rather than student outcomes:
#
#   - SchoolDay     : start/end time, length of day, instructional time
#                     (full-time and shared-time), 2017-2025
#   - DeviceRatios  : student-to-computing-device ratio, 2018-2025
#                     (absent SY2016-17 and SY2019-20)
#
# Both sheets live ONLY in the School workbook (Database_SchoolDetail.xlsx) -
# they describe an attribute of a building and have no district/state aggregate
# analogue - so these fetchers are school-level only.
#
# ==============================================================================


# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

#' Ensure entity-name columns exist on an SPR data frame
#'
#' A few of the earliest SPR sheets (notably the SY2016-17 \code{SchoolDay}
#' sheet) ship only the CDS-code id columns and omit the county/district/school
#' name columns. This helper adds any missing name column as \code{NA_character_}
#' so downstream column selection is stable. The CDS-code ids remain the real
#' join keys; a missing name is left \code{NA}, never fabricated.
#'
#' @param df A data frame from \code{\link{fetch_spr_data}}.
#' @return \code{df} with \code{county_name}, \code{district_name}, and
#'   \code{school_name} guaranteed present.
#' @keywords internal
ensure_name_columns <- function(df) {
  for (nm in c("county_name", "district_name", "school_name")) {
    if (!nm %in% names(df)) df[[nm]] <- NA_character_
  }
  df
}


# -----------------------------------------------------------------------------
# Value parsers (deterministic transforms of published strings)
# -----------------------------------------------------------------------------

#' Parse an NJ DOE "X Hrs. Y Mins." duration string to minutes
#'
#' The SPR \code{SchoolDay} sheet publishes durations as human-readable strings
#' (e.g. \code{"6 Hrs. 25 Mins."}, \code{"6 Hrs 20 Mins"}). This helper extracts
#' the hour and minute components and returns the total minutes as a numeric.
#' Non-duration values (\code{"n/a"},
#' \code{"n/a - applies only to high schools"}, \code{NA}) return \code{NA}. This
#' is a deterministic re-expression of the published value, not an estimate.
#'
#' @param x Character vector of duration strings.
#' @return Numeric vector of total minutes (\code{NA} where unparseable).
#' @keywords internal
parse_duration_to_minutes <- function(x) {
  x <- as.character(x)
  has_hrs <- grepl("\\d+\\s*Hrs?", x, ignore.case = TRUE)
  has_min <- grepl("\\d+\\s*Mins?", x, ignore.case = TRUE)
  hrs <- suppressWarnings(as.numeric(
    sub("(?i).*?(\\d+)\\s*Hrs?.*", "\\1", x, perl = TRUE)
  ))
  mins <- suppressWarnings(as.numeric(
    sub("(?i).*?(\\d+)\\s*Mins?.*", "\\1", x, perl = TRUE)
  ))
  hrs <- ifelse(has_hrs, hrs, 0)
  mins <- ifelse(has_min, mins, 0)
  out <- hrs * 60 + mins
  # If neither an hours nor a minutes token was present, the value is not a
  # duration (e.g. "n/a") - return NA rather than a fabricated 0.
  out[!(has_hrs | has_min)] <- NA_real_
  out
}


#' Parse an NJ DOE student-to-device ratio to a numeric students-per-device
#'
#' The SPR \code{DeviceRatios} sheet publishes the ratio as \code{"2.6:1"} /
#' \code{"1:1"} (2018-2024) or as a bare number \code{"1"} / \code{"1.1"}
#' (2025+). This helper returns the students-per-device count as a numeric
#' (the left side of the \code{":1"} ratio). Non-numeric values
#' (\code{"No devices reported"}, \code{"n/a"}, \code{NA}) return \code{NA}.
#'
#' @param x Character vector of ratio strings.
#' @return Numeric vector of students per device (\code{NA} where unparseable).
#' @keywords internal
parse_device_ratio <- function(x) {
  x <- trimws(as.character(x))
  out <- ifelse(
    grepl(":", x, fixed = TRUE),
    suppressWarnings(as.numeric(sub("^([0-9.]+)\\s*:.*$", "\\1", x))),
    suppressWarnings(as.numeric(x))
  )
  out
}


# -----------------------------------------------------------------------------
# fetch_school_day()
# -----------------------------------------------------------------------------

#' Fetch School-Day Length & Instructional Time
#'
#' Downloads the \code{SchoolDay} sheet from the NJ DOE School Performance
#' Reports. Each row reports, for one school, the typical start and end times,
#' the total length of the school day, and the instructional time available to
#' full-time and shared-time students. This is school-level operational data
#' (time-on-learning) with no district or state aggregate, so the function is
#' school-level only.
#'
#' @details
#' The sheet is present in the School workbook for \strong{end_year 2017-2025}.
#' Durations are published as human-readable strings (e.g.
#' \code{"6 Hrs. 25 Mins."}); this function preserves the published strings
#' (\code{length_of_day}, \code{instruction_full_time},
#' \code{instruction_shared_time}) and additionally derives numeric-minutes
#' columns (\code{length_of_day_minutes}, \code{instruction_full_time_minutes},
#' \code{instruction_shared_time_minutes}) via a deterministic parse. The
#' 2024-25 redesign:
#' \itemize{
#'   \item adds a single-value \code{school_year} column (e.g. \code{"2024-25"}),
#'     preserved in the output;
#'   \item reports \code{instruction_shared_time} as
#'     \code{"n/a - applies only to high schools"} for non-high schools, which
#'     parses to \code{NA} minutes.
#' }
#' The SY2016-17 (2017) sheet ships only the CDS-code ids and omits the
#' county/district/school name columns; those are returned as \code{NA} for that
#' year (the ids remain the real join keys).
#' The minute columns are a re-expression of the published string, never an
#' estimate; unparseable strings yield \code{NA} minutes.
#'
#' @param end_year A school year (2017-2025). Year is the end of the academic
#'   year - e.g. the 2023-24 school year is \code{end_year} 2024.
#' @param level Only \code{"school"} is supported (the sheet has no
#'   district/state analogue). Other values error.
#'
#' @return Data frame with entity identifiers, \code{typical_start_time},
#'   \code{typical_end_time}, the three published duration strings and their
#'   three derived \code{*_minutes} numeric columns, the 2025-only
#'   \code{school_year} column when present, and the standard aggregation flags
#'   (\code{is_state}, \code{is_county}, \code{is_district}, \code{is_school},
#'   \code{is_charter}, \code{is_charter_sector}, \code{is_allpublic}).
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Length of the school day for every school (latest year)
#' sd <- fetch_school_day(2024)
#'
#' # Longest instructional days statewide
#' library(dplyr)
#' fetch_school_day(2024) %>%
#'   filter(is_school) %>%
#'   slice_max(instruction_full_time_minutes, n = 10) %>%
#'   select(district_name, school_name, instruction_full_time_minutes)
#'
#' # Newark schools, sorted by length of day
#' fetch_school_day(2024) %>%
#'   filter(district_id == "3570") %>%
#'   arrange(desc(length_of_day_minutes)) %>%
#'   select(school_name, length_of_day, length_of_day_minutes)
#' }
fetch_school_day <- function(end_year, level = "school") {
  if (!identical(level, "school")) {
    stop(
      "fetch_school_day() is school-level only: the SchoolDay sheet exists ",
      "only in the SPR School workbook and has no district/state analogue.",
      call. = FALSE
    )
  }
  if (end_year < 2017) {
    stop(
      "school-day data is available for end_year >= 2017 (the SchoolDay sheet ",
      "is absent from earlier SPR databases).",
      call. = FALSE
    )
  }

  df <- fetch_spr_data("SchoolDay", end_year, level)

  # The SY2016-17 (2017) SchoolDay sheet omits the county/district/school NAME
  # columns (it ships only the CDS-code ids). Fill them as NA so downstream
  # selection is stable; the CDS ids remain the real join keys. (NA is honest -
  # we never fabricate a name.)
  df <- ensure_name_columns(df)

  # Derive numeric minutes from the published duration strings. These columns
  # are a deterministic re-expression of the published "X Hrs Y Mins" value.
  df$length_of_day_minutes <- parse_duration_to_minutes(df$length_of_day)
  df$instruction_full_time_minutes <-
    parse_duration_to_minutes(df$instruction_full_time)
  df$instruction_shared_time_minutes <-
    parse_duration_to_minutes(df$instruction_shared_time)

  df %>%
    dplyr::select(
      end_year,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      dplyr::any_of("school_year"),
      typical_start_time, typical_end_time,
      length_of_day, length_of_day_minutes,
      instruction_full_time, instruction_full_time_minutes,
      instruction_shared_time, instruction_shared_time_minutes,
      is_state, is_county, is_district, is_school,
      is_charter, is_charter_sector, is_allpublic
    )
}


# -----------------------------------------------------------------------------
# fetch_device_ratios()
# -----------------------------------------------------------------------------

# Years for which the DeviceRatios sheet exists in the SPR School workbook.
# It is absent from SY2016-17 (2017) and SY2019-20 (2020).
.device_ratio_years <- c(2018, 2019, 2021, 2022, 2023, 2024, 2025)

#' Fetch Student-to-Device Ratios
#'
#' Downloads the \code{DeviceRatios} sheet from the NJ DOE School Performance
#' Reports. Each row reports, for one school, the student-to-computing-device
#' ratio - a measure of digital-access equity that became a board-level concern
#' during and after the COVID-19 remote-learning period. This is school-level
#' data with no district or state aggregate, so the function is school-level
#' only.
#'
#' @details
#' The sheet is present in the School workbook for \strong{end_year 2018-2025
#' except SY2019-20 (2020)}; it is also absent from SY2016-17 (2017). Those two
#' years error. The published value is a ratio string \code{"2.6:1"} /
#' \code{"1:1"} (2018-2024) or a bare number \code{"1"} / \code{"1.1"} (2025+,
#' column renamed \code{students_per_device}). This function preserves the
#' published string as \code{student_device_ratio} and derives a numeric
#' \code{students_per_device} (students per one device) via a deterministic
#' parse. Non-numeric values (\code{"No devices reported"}, \code{"n/a"}) yield
#' \code{NA}. A value of 1 means one device per student (1:1); values above 1
#' mean devices are shared.
#'
#' @param end_year A school year. Supported: 2018, 2019, 2021, 2022, 2023,
#'   2024, 2025. SY2016-17 (2017) and SY2019-20 (2020) error (sheet absent).
#' @param level Only \code{"school"} is supported (the sheet has no
#'   district/state analogue). Other values error.
#'
#' @return Data frame with entity identifiers, \code{student_device_ratio} (the
#'   published string), \code{students_per_device} (derived numeric), the
#'   2025-only \code{school_year} column when present, and the standard
#'   aggregation flags.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Student-to-device ratios for every school (latest year)
#' dr <- fetch_device_ratios(2024)
#'
#' # Schools furthest from 1:1
#' library(dplyr)
#' fetch_device_ratios(2024) %>%
#'   filter(is_school) %>%
#'   slice_max(students_per_device, n = 10) %>%
#'   select(district_name, school_name, student_device_ratio)
#'
#' # Share of schools at 1:1 over time
#' purrr::map_dfr(c(2019, 2021, 2023, 2024), function(yr) {
#'   fetch_device_ratios(yr) %>%
#'     filter(is_school, !is.na(students_per_device)) %>%
#'     summarise(end_year = yr, pct_1to1 = mean(students_per_device <= 1))
#' })
#' }
fetch_device_ratios <- function(end_year, level = "school") {
  if (!identical(level, "school")) {
    stop(
      "fetch_device_ratios() is school-level only: the DeviceRatios sheet ",
      "exists only in the SPR School workbook and has no district/state ",
      "analogue.",
      call. = FALSE
    )
  }
  if (!end_year %in% .device_ratio_years) {
    stop(
      "device-ratio data is available for end_year in {",
      paste(.device_ratio_years, collapse = ", "), "}. The DeviceRatios sheet ",
      "is absent from SY2016-17 (2017) and SY2019-20 (2020).",
      call. = FALSE
    )
  }

  df <- fetch_spr_data("DeviceRatios", end_year, level)
  df <- ensure_name_columns(df)

  # Harmonize the value column name across the legacy / redesign layouts.
  #   2018-2024: student_device_ratio  ("2.6:1")
  #   2025+:     students_per_device   ("1.1")
  if ("students_per_device" %in% names(df) &&
      !"student_device_ratio" %in% names(df)) {
    df <- dplyr::rename(df, student_device_ratio = students_per_device)
  }

  # Derive the numeric students-per-device from the published string.
  df$students_per_device <- parse_device_ratio(df$student_device_ratio)

  df %>%
    dplyr::select(
      end_year,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      dplyr::any_of("school_year"),
      student_device_ratio, students_per_device,
      is_state, is_county, is_district, is_school,
      is_charter, is_charter_sector, is_allpublic
    )
}
