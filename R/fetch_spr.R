# ==============================================================================
# School Performance Reports (SPR) Data Fetching Functions
# ==============================================================================
#
# Functions for downloading and extracting data from the NJ DOE School
# Performance Reports databases. The SPR databases contain 63+ sheets
# covering various school performance metrics for years 2017-2024.
#
# ==============================================================================

# -----------------------------------------------------------------------------
# URL Construction
# -----------------------------------------------------------------------------

#' Get SPR Database URL
#'
#' Builds the URL for the School Performance Reports database containing
#' multiple sheets of school performance data.
#'
#' @param end_year A school year (2017-2025). Year is the end of the academic
#'   year - eg 2020-21 school year is end_year '2021'.
#' @param level One of "school" or "district". Determines which database file
#'   to download.
#' @return URL string
#' @keywords internal
get_spr_url <- function(end_year, level = "school") {
  valid_years <- 2017:2025

  if (!end_year %in% valid_years) {
    stop(paste0(
      "SPR data available for years 2017-2025. ",
      "Year ", end_year, " is not supported."
    ))
  }

  # Convert end_year to academic year format (e.g., 2024 -> "2023-2024")
  academic_year <- paste0(end_year - 1, "-", end_year)

  stem <- "https://www.nj.gov/education/sprreports/download/DataFiles/"

  file_name <- if (level == "school") {
    "Database_SchoolDetail.xlsx"
  } else if (level == "district") {
    "Database_DistrictStateDetail.xlsx"
  } else {
    stop("level must be one of 'school' or 'district'")
  }

  paste0(stem, academic_year, "/", file_name)
}


#' Pick an SPR sheet name by year
#'
#' Convenience helper for consumers whose source sheet was renamed in the
#' 2024-25 (end_year 2025) SPR redesign. Returns \code{name_2025} when
#' \code{end_year >= 2025}, otherwise \code{name_legacy}.
#'
#' @param end_year School year end.
#' @param name_legacy Sheet name used for 2017-2024.
#' @param name_2025 Sheet name used for 2025 onward.
#' @return The appropriate sheet name string.
#' @keywords internal
spr_sheet_for_year <- function(end_year, name_legacy, name_2025) {
  if (end_year >= 2025) name_2025 else name_legacy
}


#' Filter an SPR sheet to a single academic year
#'
#' Several 2024-25 SPR sheets ship as multi-year trend tables (a
#' \code{school_year} column spanning, e.g., 2020-21..2024-25) where the
#' pre-redesign sheet held a single year. When a \code{school_year} column is
#' present, this keeps only the rows for the requested academic year so the
#' output preserves the historical one-row-per-entity shape. Sheets without a
#' \code{school_year} column are returned unchanged.
#'
#' @param df Data frame from \code{\link{fetch_spr_data}} (column names already
#'   snake_cased).
#' @param end_year School year end (e.g., 2025 for SY2024-25).
#' @return The data frame filtered to the requested academic year, or unchanged
#'   if no \code{school_year} column exists.
#' @keywords internal
filter_spr_to_year <- function(df, end_year) {
  if (!"school_year" %in% names(df)) {
    return(df)
  }
  # Academic-year label, e.g. end_year 2025 -> "2024-25".
  academic_label <- paste0(end_year - 1, "-", substr(as.character(end_year), 3, 4))
  keep <- !is.na(df[["school_year"]]) & df[["school_year"]] == academic_label
  df[keep, , drop = FALSE]
}


# -----------------------------------------------------------------------------
# Subgroup Name Cleaning
# -----------------------------------------------------------------------------

#' Clean SPR subgroup names
#'
#' Standardizes subgroup names from SPR database to match
#' package naming conventions.
#'
#' @param group Vector of subgroup names
#' @return Vector of cleaned subgroup names
#' @keywords internal
clean_spr_subgroups <- function(group) {
  dplyr::case_when(
    # "All Students" is the 2024-25 label for the schoolwide/statewide total.
    tolower(group) %in% c("schoolwide", "districtwide", "statewide", "all students") ~ "total population",
    tolower(group) == "american indian or alaska native" ~ "american indian",
    tolower(group) == "black or african american" ~ "black",
    tolower(group) == "economically disadvantaged students" ~ "economically disadvantaged",
    tolower(group) %in% c("english learners", "multilingual learners") ~ "limited english proficiency",
    tolower(group) == "two or more races" ~ "multiracial",
    tolower(group) == "native hawaiian or other pacific islander" ~ "pacific islander",
    tolower(group) == "students with disabilities" ~ "students with disabilities",
    tolower(group) == "students with disability" ~ "students with disabilities",
    TRUE ~ tolower(group)
  )
}


# -----------------------------------------------------------------------------
# Generic SPR Data Extractor
# -----------------------------------------------------------------------------

#' Fetch SPR Data
#'
#' Downloads and extracts data from NJ School Performance Reports database.
#' The SPR database contains 63+ sheets covering various school performance metrics.
#'
#' @param sheet_name Exact sheet name from SPR database (case-sensitive).
#'   You must know the exact sheet name. See vignette("spr-dictionary") for available sheets.
#' @param end_year A school year (2017-2025). Year is the end of the academic
#'   year - eg 2020-21 school year is end_year '2021'.
#' @param level One of "school" or "district". "school" returns school-level
#'   data, "district" returns district and state-level data.
#'
#' @return Data frame with standardized columns including:
#'   \itemize{
#'     \item end_year, county_id, county_name, district_id, district_name
#'     \item school_id, school_name (for school-level data)
#'     \item [Additional columns from requested sheet]
#'     \item Aggregation flags (is_state, is_county, is_district, is_school, is_charter)
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Get chronic absenteeism data
#' ca <- fetch_spr_data("ChronicAbsenteeism", 2024)
#'
#' # Get district-level graduation data
#' grad <- fetch_spr_data("6YrGraduationCohortProfile", 2024, level = "district")
#'
#' # Get teacher experience data
#' teachers <- fetch_spr_data("TeachersExperience", 2023)
#' }
fetch_spr_data <- function(sheet_name, end_year, level = "school") {
  # Build URL
  target_url <- get_spr_url(end_year, level)

  # Check cache
  cache_key <- make_cache_key("fetch_spr_data", sheet_name, end_year, level)
  cached <- cache_get(cache_key)
  if (!is.null(cached)) {
    return(cached)
  }

  # Download to temp file
  tname <- tempfile(pattern = "spr_", tmpdir = tempdir(), fileext = ".xlsx")
  downloader::download(target_url, destfile = tname, mode = "wb")

  # The 2024-25 (end_year 2025) redesign moved the column headers down: row 1
  # holds a metadata note, rows 2-3 hold sheet/source notes, and the real header
  # row is row 4. Skip the three preamble rows for 2025+. Earlier years keep
  # headers on row 1 (no skip).
  header_skip <- if (end_year >= 2025) 3 else 0

  # Read specific sheet
  df <- tryCatch(
    readxl::read_excel(
      path = tname,
      sheet = sheet_name,
      skip = header_skip,
      na = c("*", "N", "NA", "", "-"),
      guess_max = 10000
    ),
    error = function(e) {
      available_sheets <- paste(readxl::excel_sheets(tname), collapse = ", ")
      stop(paste0(
        "Sheet '", sheet_name, "' not found in ", end_year, " SPR database. ",
        "Available sheets: ", available_sheets
      ))
    }
  )

  # Clean column names FIRST
  # School files have: CountyCode, CountyName, DistrictCode, DistrictName, SchoolCode, SchoolName, StudentGroup
  # District files have: CountyCode, CountyName, DistrictCode, DistrictName, StudentGroup
  names(df) <- clean_name_vector(names(df))

  # After cleaning, we have: county_code, county_name, district_code, district_name, school_code, school_name, student_group
  # Rename code columns to id columns
  df <- dplyr::rename(df, county_id = county_code, district_id = district_code)

  # school_code only exists in school files, rename it if present
  if ("school_code" %in% names(df)) {
    df <- dplyr::rename(df, school_id = school_code)
  }

  # For district files, add school columns (they don't exist in district files)
  if (level == "district") {
    df <- df %>%
      dplyr::mutate(
        school_id = "999",
        school_name = "District Total"
      )
  }

  # Clean CDS codes (remove Excel formula padding)
  df$county_id <- kill_padformulas(df$county_id)
  df$district_id <- kill_padformulas(df$district_id)
  df$school_id <- kill_padformulas(df$school_id)

  # Drop the trailing sentinel row that 2024-25 sheets append (a single row with
  # county_id "end of worksheet" and all other identifiers blank).
  df <- df %>%
    dplyr::filter(!grepl("end of worksheet", county_id, ignore.case = TRUE))

  # Add end_year
  df$end_year <- end_year

  # Clean subgroup if present (after clean_name_vector, it's student_group)
  if ("student_group" %in% names(df)) {
    df <- df %>% dplyr::rename(subgroup = student_group)
  }

  if ("subgroup" %in% names(df)) {
    df$subgroup <- clean_spr_subgroups(df$subgroup)
  }

  # Add aggregation flags.
  # The SPR District/State file marks its statewide aggregate row with the
  # literal CDS codes county_id == "State" / district_id == "State" (it does NOT
  # use the 99 / 9999 convention seen elsewhere). Recognize both so the state
  # row is correctly flagged across all years and file layouts.
  df <- df %>%
    dplyr::mutate(
      is_state = (district_id == "9999" & county_id == "99") |
        (toupper(county_id) == "STATE"),
      is_county = (district_id == "9999" & county_id != "99") & !is_state,
      is_district = school_id %in% c("888", "997", "999") & !is_state,
      is_school = !school_id %in% c("888", "997", "999") & !is_state,
      is_charter = county_id == "80",
      is_charter_sector = FALSE,
      is_allpublic = FALSE
    )

  # Remove rows without county_id (state summary sometimes has missing values)
  df <- df %>%
    dplyr::filter(!is.na(county_id))

  # Cache result
  cache_set(cache_key, df)

  df
}


# ==============================================================================
# Chronic Absenteeism Module
# ==============================================================================
#
# Convenience functions for extracting chronic absenteeism data from SPR
# databases. Chronic absenteeism is a major accountability indicator.
#
# ==============================================================================

# -----------------------------------------------------------------------------
# Column Processing Helpers
# -----------------------------------------------------------------------------

#' Process chronic absenteeism columns
#'
#' Standardizes column names for chronic absenteeism data by detecting
#' and renaming the chronic absenteeism rate column.
#'
#' @param df Raw data frame from SPR database
#' @return Data frame with standardized columns
#' @keywords internal
process_chronic_absenteeism_cols <- function(df) {
  # Detect chronic absenteeism rate column (name may vary)
  # 2017-2024 subgroup sheet:    "Chronic_Abs_Pct"
  # 2017-2024 grade-level sheet: "SchoolPercent"
  # 2024-25 school file:         "ChronicAbsenteeismRate_School"
  # 2024-25 district/state file: "ChronicAbsenteeismRate_District" (the school
  #                              file has no per-school value for district/state
  #                              aggregate rows)
  rate_cols <- grep("chronic|absent|percent", names(df), value = TRUE, ignore.case = TRUE)

  # Filter to find the actual rate column (exclude names with "Number", "Count", etc.)
  rate_cols <- rate_cols[!grepl("number|count|enrollment|n_|state", rate_cols, ignore.case = TRUE)]

  # Prefer the explicit school-rate column, falling back across naming variants
  if ("chronic_absenteeism_rate_school" %in% names(df)) {
    df <- df %>%
      dplyr::rename(chronically_absent_rate = chronic_absenteeism_rate_school)
  } else if ("chronic_absenteeism_rate_district" %in% names(df)) {
    df <- df %>%
      dplyr::rename(chronically_absent_rate = chronic_absenteeism_rate_district)
  } else if ("chronic_abs_pct" %in% names(df)) {
    df <- df %>%
      dplyr::rename(chronically_absent_rate = chronic_abs_pct)
  } else if ("school_percent" %in% names(df)) {
    df <- df %>%
      dplyr::rename(chronically_absent_rate = school_percent)
  } else if (length(rate_cols) > 0) {
    # Rename first matching column to chronically_absent_rate
    df <- df %>%
      dplyr::rename(chronically_absent_rate = !!rate_cols[1])
  }

  # Convert to numeric and clean
  if ("chronically_absent_rate" %in% names(df)) {
    # Handle percentage values (some sheets have % sign)
    if (is.character(df$chronically_absent_rate)) {
      df$chronically_absent_rate <- rc_numeric_cleaner(df$chronically_absent_rate)
    }

    # If still character, try numeric conversion
    if (is.character(df$chronically_absent_rate)) {
      df$chronically_absent_rate <- as.numeric(df$chronically_absent_rate)
    }
  }

  df
}


#' Process days absent columns
#'
#' Standardizes column names for days absent data.
#'
#' @param df Raw data frame from SPR database
#' @return Data frame with standardized columns
#' @keywords internal
process_days_absent_cols <- function(df) {
  # Detect average days absent column
  avg_cols <- grep("average|avg", names(df), value = TRUE, ignore.case = TRUE)
  avg_cols <- avg_cols[grepl("day|absent", avg_cols, ignore.case = TRUE)]

  if (length(avg_cols) > 0) {
    df <- df %>%
      dplyr::rename(avg_days_absent = !!avg_cols[1])
  }

  # Detect median days absent column
  med_cols <- grep("median", names(df), value = TRUE, ignore.case = TRUE)
  med_cols <- med_cols[grepl("day|absent", med_cols, ignore.case = TRUE)]

  if (length(med_cols) > 0) {
    df <- df %>%
      dplyr::rename(median_days_absent = !!med_cols[1])
  }

  # Convert to numeric
  if ("avg_days_absent" %in% names(df) && is.character(df$avg_days_absent)) {
    df$avg_days_absent <- as.numeric(df$avg_days_absent)
  }

  if ("median_days_absent" %in% names(df) && is.character(df$median_days_absent)) {
    df$median_days_absent <- as.numeric(df$median_days_absent)
  }

  df
}


# -----------------------------------------------------------------------------
# Chronic Absenteeism Functions
# -----------------------------------------------------------------------------

#' Fetch Chronic Absenteeism Data
#'
#' Downloads and extracts chronic absenteeism data from the SPR database.
#' Chronic absenteeism is defined as missing 10% or more of school days.
#'
#' @param end_year A school year (2017-2025). Year is the end of the academic
#'   year - eg 2020-21 school year is end_year '2021'.
#' @param level One of "school" or "district". "school" returns school-level
#'   data, "district" returns district and state-level data.
#'
#' @return Data frame with chronic absenteeism rates including:
#'   \itemize{
#'     \item end_year, county_id, county_name, district_id, district_name
#'     \item school_id, school_name (for school-level data)
#'     \item subgroup - Student group (total population, racial/ethnic groups, etc.)
#'     \item chronically_absent_rate - Percentage chronically absent (0-100)
#'     \item Aggregation flags (is_state, is_county, is_district, is_school, is_charter)
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Get school-level chronic absenteeism
#' ca <- fetch_chronic_absenteeism(2024)
#'
#' # Get district-level data
#' ca_dist <- fetch_chronic_absenteeism(2024, level = "district")
#'
#' # Filter for specific schools
#' newark_ca <- ca %>%
#'   filter(district_id == "3570") %>%
#'   filter(subgroup == "total population")
#' }
fetch_chronic_absenteeism <- function(end_year, level = "school") {
  # Sheet renamed in 2024-25: ChronicAbsenteeism -> ChronicAbsenteeismStudentGroup
  sheet_name <- spr_sheet_for_year(
    end_year, "ChronicAbsenteeism", "ChronicAbsenteeismStudentGroup"
  )

  # Use generic extractor
  df <- fetch_spr_data(
    sheet_name = sheet_name,
    end_year = end_year,
    level = level
  )

  # Process chronic absenteeism columns
  df <- process_chronic_absenteeism_cols(df)

  # Select and order columns
  df %>%
    dplyr::select(
      end_year,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      subgroup,
      chronically_absent_rate,
      is_state, is_county, is_district, is_school,
      is_charter, is_charter_sector, is_allpublic
    )
}


#' Fetch Absenteeism by Grade
#'
#' Downloads and extracts chronic absenteeism data broken down by grade level
#' from the SPR database.
#'
#' @param end_year A school year (2017-2025). Year is the end of the academic
#'   year - eg 2020-21 school year is end_year '2021'.
#' @param level One of "school" or "district". "school" returns school-level
#'   data, "district" returns district and state-level data.
#'
#' @return Data frame with chronic absenteeism by grade including:
#'   \itemize{
#'     \item end_year, county_id, county_name, district_id, district_name
#'     \item school_id, school_name (for school-level data)
#'     \item subgroup - Student group (total population, racial/ethnic groups, etc.)
#'     \item grade_level - Grade level (PK, KG, 01-12)
#'     \item chronically_absent_rate - Percentage chronically absent (0-100)
#'     \item Aggregation flags (is_state, is_county, is_district, is_school, is_charter)
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Get school-level chronic absenteeism by grade
#' ca_grade <- fetch_absenteeism_by_grade(2024)
#'
#' # Analyze kindergarten absenteeism
#' k_absent <- ca_grade %>%
#'   filter(grade_level == "KF", subgroup == "total population")
#' }
fetch_absenteeism_by_grade <- function(end_year, level = "school") {
  # Determine sheet name (changed over time)
  # 2018-2019:  ChronicAbsByGrade
  # 2020-2024:  ChronicAbsenteeismByGrade
  # 2025+:      ChronicAbsenteeismGrade
  sheet_name <- if (end_year %in% c(2018, 2019)) {
    "ChronicAbsByGrade"
  } else if (end_year >= 2025) {
    "ChronicAbsenteeismGrade"
  } else {
    "ChronicAbsenteeismByGrade"
  }

  # Use generic extractor
  df <- fetch_spr_data(
    sheet_name = sheet_name,
    end_year = end_year,
    level = level
  )

  # Add grade_level column (may be named differently)
  if (!"grade_level" %in% names(df)) {
    if ("grade" %in% names(df)) {
      df <- df %>% dplyr::rename(grade_level = grade)
    } else if ("grade_level" %in% names(df)) {
      # Already has grade_level
    } else {
      # Try to find a column that looks like grade
      grade_cols <- grep("grade", names(df), value = TRUE, ignore.case = TRUE)
      if (length(grade_cols) > 0) {
        df <- df %>% dplyr::rename(grade_level = !!grade_cols[1])
      }
    }
  }

  # Process chronic absenteeism columns
  df <- process_chronic_absenteeism_cols(df)

  # Select and order columns (subgroup and chronically_absent_rate may not exist in all sheets)
  df %>%
    dplyr::select(
      end_year,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      dplyr::any_of(c("subgroup", "chronically_absent_rate")),
      grade_level,
      is_state, is_county, is_district, is_school,
      is_charter, is_charter_sector, is_allpublic
    )
}


#' Fetch Days Absent Data
#'
#' Downloads and extracts days absent statistics from the SPR database.
#' This includes percentage distributions of students by absence ranges.
#'
#' @param end_year A school year (2017-2025). Year is the end of the academic
#'   year - eg 2020-21 school year is end_year '2021'.
#' @param level One of "school" or "district". "school" returns school-level
#'   data, "district" returns district and state-level data.
#'
#' @return Data frame with days absent statistics including:
#'   \itemize{
#'     \item end_year, county_id, county_name, district_id, district_name
#'     \item school_id, school_name (for school-level data)
#'     \item Percentage distribution columns: `0% Absences`, `>0% to 6.9% Absences`,
#'       `7% to 9.9% Absences`, `10% to 12.9% Absences`, `13% to 19.9% Absences`,
#'       `20% or higher`
#'     \item Aggregation flags (is_state, is_county, is_district, is_school, is_charter)
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Get school-level days absent distribution
#' days <- fetch_days_absent(2024)
#'
#' # View absence distribution for a specific school
#' days %>%
#'   filter(school_id == "030") %>%
#'   select(school_name, `0% Absences`, `20% or higher`)
#' }
fetch_days_absent <- function(end_year, level = "school") {
  # Use generic extractor
  df <- fetch_spr_data(
    sheet_name = "DaysAbsent",
    end_year = end_year,
    level = level
  )

  # Return all columns (the sheet has percentage distribution buckets)
  df
}


# ==============================================================================
# SPR Sheet Discovery & Helpers
# ==============================================================================
#
# Utilities for discovering available SPR sheets and handling sheet name
# variations across years.
#
# ==============================================================================

# -----------------------------------------------------------------------------
# Sheet Discovery
# -----------------------------------------------------------------------------

#' List Available SPR Sheets
#'
#' Returns a vector of all sheet names available in the SPR database for a
#' given year and level. Useful for discovering what data is available.
#'
#' @param end_year A school year (2017-2025). Year is the end of the academic
#'   year - eg 2020-21 school year is end_year '2021'.
#' @param level One of "school" or "district". Determines which database file
#'   to query.
#'
#' @return Character vector of sheet names
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # List all school-level sheets for 2024
#' sheets <- list_spr_sheets(2024)
#'
#' # List all district-level sheets
#' district_sheets <- list_spr_sheets(2024, level = "district")
#'
#' # Search for specific types of sheets
#' attendance_sheets <- sheets[grepl("Absent|Attendance", sheets, ignore.case = TRUE)]
#' }
list_spr_sheets <- function(end_year, level = "school") {
  # Build URL
  target_url <- get_spr_url(end_year, level)

  # Download to temp file
  tname <- tempfile(pattern = "spr_", tmpdir = tempdir(), fileext = ".xlsx")
  downloader::download(target_url, destfile = tname, mode = "wb")

  # Get sheet names
  sheets <- readxl::excel_sheets(tname)

  # Sort alphabetically
  sort(sheets)
}


# -----------------------------------------------------------------------------
# Sheet Name Mapping
# -----------------------------------------------------------------------------

#' Map Sheet Names Across Years
#'
#' Internal data structure mapping sheet name variations across years.
#' Some SPR sheet names changed over time (e.g., 2018-2019 vs 2020+).
#'
#' @description
#' This list maps common sheet name variations. Format is:
#' \code{list(canonical_name = list(year_range = "actual_sheet_name"))}
#'
#' @keywords internal
spr_sheet_mapping <- list(
  chronic_absenteeism_by_grade = list(
    "2018-2019" = "ChronicAbsByGrade",
    "2020-2024" = "ChronicAbsenteeismByGrade"
  ),
  # Add more mappings as discovered
  graduation_rate_5yr = list(
    "2017-2020" = "5YrGraduationCohortProfile",
    "2021-2024" = "5YrGraduationCohortProfile"
  )
)


#' Get Mapped Sheet Name
#'
#' Returns the correct sheet name for a given year, handling historical
#' name variations. If no mapping exists, returns the input name.
#'
#' @param canonical_name Canonical sheet name (e.g., "chronic_absenteeism_by_grade")
#' @param end_year School year end
#' @return Actual sheet name to use with fetch_spr_data()
#' @keywords internal
get_mapped_sheet_name <- function(canonical_name, end_year) {
  if (!(canonical_name %in% names(spr_sheet_mapping))) {
    return(canonical_name)
  }

  year_map <- spr_sheet_mapping[[canonical_name]]

  # Find matching year range
  for (year_range in names(year_map)) {
    range_parts <- strsplit(year_range, "-")[[1]]
    start_year <- as.numeric(range_parts[1])
    end_yr <- as.numeric(range_parts[2])

    if (end_year >= start_year && end_year <= end_yr) {
      return(year_map[[year_range]])
    }
  }

  # If no match, return the most recent name
  year_map[[length(year_map)]]
}


# ==============================================================================
# High-Value Convenience Wrappers
# ==============================================================================
#
# Quick-access functions for commonly-requested SPR data. These wrap the
# generic fetch_spr_data() with appropriate column selection/cleaning.
#
# ==============================================================================

#' Fetch Teacher Experience Data
#'
#' Downloads teacher experience data from SPR database.
#'
#' @param end_year A school year (2017-2025)
#' @param level One of "school" or "district"
#'
#' @return Data frame with teacher experience breakdown
#' @export
#' @examples \dontrun{
#' teachers <- fetch_teacher_experience(2024)
#' }
fetch_teacher_experience <- function(end_year, level = "school") {
  df <- fetch_spr_data("TeachersExperience", end_year, level)
  df
}


#' Fetch Staff Demographics Data
#'
#' Downloads teacher/administrator demographic data from SPR database.
#'
#' @param end_year A school year (2017-2025)
#' @param level One of "school" or "district"
#'
#' @return Data frame with staff race/gender breakdowns
#' @export
#' @examples \dontrun{
#' staff <- fetch_staff_demographics(2024)
#' }
fetch_staff_demographics <- function(end_year, level = "school") {
  df <- fetch_spr_data("TeachersAdminsDemographics", end_year, level)
  df
}


#' Fetch Disciplinary Removals Data
#'
#' Downloads discipline data (suspensions/expulsions/removals) from the SPR
#' database, broken down by student group and grade level.
#'
#' @param end_year A school year (2018-2025). SY2016-17 (end_year 2017) has no
#'   discipline-removals sheet in the SPR database.
#' @param level One of "school" or "district"
#'
#' @return Data frame with disciplinary actions. Includes a
#'   \code{student_group_grade} column identifying the student group / grade
#'   row, plus suspension, removal, and expulsion counts and percentages.
#' @export
#' @examples \dontrun{
#' discipline <- fetch_disciplinary_removals(2024)
#' }
fetch_disciplinary_removals <- function(end_year, level = "school") {
  # The discipline-removals sheet has been renamed several times. Names below
  # are confirmed against the downloaded NJ DOE Database_SchoolDetail.xlsx for
  # each year:
  #   2018-2023: DisciplinaryRemovals            (no StudentGroup breakdown)
  #   2024:      DisciplinaryRemovalsByStudgroup (col StudentGroup/GradeLevel)
  #   2025+:     RemovalsStudentGroupGrade       (col StudentGroupGrade)
  # SY2016-17 (end_year 2017) has no discipline-removals sheet (it shipped
  # separate StudentSuspensionRates / StudentExpulsions sheets with a different
  # structure), so this function supports end_year 2018-2025.
  sheet_name <- if (end_year >= 2025) {
    "RemovalsStudentGroupGrade"
  } else if (end_year == 2024) {
    "DisciplinaryRemovalsByStudgroup"
  } else {
    "DisciplinaryRemovals"
  }

  df <- fetch_spr_data(sheet_name, end_year, level)

  # Standardize the student-group/grade column name across years.
  # 2017-2024: "StudentGroup/GradeLevel" -> student_group_grade_level
  # 2025+:     "StudentGroupGrade"        -> student_group_grade
  if ("student_group_grade_level" %in% names(df) &&
      !"student_group_grade" %in% names(df)) {
    df <- dplyr::rename(df, student_group_grade = student_group_grade_level)
  }

  df
}


#' Fetch Violence/Vandalism/HIB Data
#'
#' Downloads incident data from SPR database.
#'
#' @param end_year A school year (2017-2025)
#' @param level One of "school" or "district"
#'
#' @return Data frame with incident counts
#' @export
#' @examples \dontrun{
#' incidents <- fetch_violence_vandalism_hib(2024)
#' }
fetch_violence_vandalism_hib <- function(end_year, level = "school") {
  # Sheet renamed in 2024-25:
  #   2017-2024: ViolenceVandalismHIBSubstanceOf
  #   2025+:     IncidentsbyType
  sheet_name <- spr_sheet_for_year(
    end_year, "ViolenceVandalismHIBSubstanceOf", "IncidentsbyType"
  )

  df <- fetch_spr_data(sheet_name, end_year, level)
  df
}


#' Fetch Student-Staff Ratio Data
#'
#' Downloads student-to-staff ratio data from SPR database.
#'
#' @param end_year A school year (2017-2025)
#' @param level One of "school" or "district"
#'
#' @return Data frame with staff ratios
#' @export
#' @examples \dontrun{
#' ratios <- fetch_staff_ratios(2024)
#' }
fetch_staff_ratios <- function(end_year, level = "school") {
  df <- fetch_spr_data("StudentToStaffRatios", end_year, level)
  df
}


#' Fetch Math Course Enrollment Data
#'
#' Downloads math course participation data from SPR database.
#'
#' @param end_year A school year (2017-2025)
#' @param level One of "school" or "district"
#'
#' @return Data frame with math course enrollment
#' @export
#' @examples \dontrun{
#' math <- fetch_math_course_enrollment(2024)
#' }
fetch_math_course_enrollment <- function(end_year, level = "school") {
  df <- fetch_spr_data("MathCourseParticipation", end_year, level)
  df
}


#' Fetch Dropout Rate Data
#'
#' Downloads dropout rate trends from SPR database.
#'
#' @param end_year A school year (2017-2025)
#' @param level One of "school" or "district"
#'
#' @return Data frame with dropout rates
#' @export
#' @examples \dontrun{
#' dropout <- fetch_dropout_rates(2024)
#' }
fetch_dropout_rates <- function(end_year, level = "school") {
  df <- fetch_spr_data("DropoutRateTrends", end_year, level)
  df
}


# ==============================================================================
# Student Growth Percentile (SGP) Module
# ==============================================================================
#
# Student Growth Percentiles (SGP) are NJ's measure of academic growth: each
# tested student's growth is ranked (1-99) against academically similar peers,
# and the school/district median (mSGP) summarizes that group. The redesigned
# 2024-25 (end_year 2025) SPR databases expose SGP through three sheets, present
# in both the School and District/State files:
#
#   StudentGrowthTrends          mSGP by StudentGroup, ELA + Math, 3-year trend
#   StudentGrowthbyGrade         mSGP by Subject x Grade (2024-25 only)
#   StudentGrowthByPerformLevel  mSGP by Subject x NJSLA performance level
#                                (2024-25 only)
#
# IMPORTANT (years supported): only end_year 2025 is implemented. Pre-2025 SPR
# databases ship SGP in differently-shaped, differently-named sheets
# (StudentGrowthTrends with no StudentGroup column; a separate "StudentGrowth"
# subgroup sheet with DistrictMedian/StateMedian; "StudentGrowthByGrade" with an
# "ELA/Math" + "mSGP" layout). Mapping those onto the 2025 output without a
# verified column correspondence would risk misrepresenting the data, so the
# pre-2025 SGP layout is left as a documented follow-up rather than guessed.
#
# ==============================================================================

#' Standardize an SGP median column to numeric
#'
#' SGP value columns hold either a numeric median (possibly with a half-point,
#' e.g. \code{"70.5"}) or a suppression phrase (\code{"Fewer than 10 testers"}).
#' This converts the column to numeric, mapping the suppression phrase to
#' \code{NA} (the suppression reason is preserved in the companion
#' \code{*_category} column). Real numbers, including half-points, are kept
#' exactly.
#'
#' @param x Character vector from an SGP value column.
#' @return Numeric vector.
#' @keywords internal
sgp_value_to_numeric <- function(x) {
  if (is.numeric(x)) return(x)
  suppressWarnings(as.numeric(x))
}


#' Fetch Student Growth Percentile (SGP) Data
#'
#' Downloads NJ Student Growth Percentile (median SGP / mSGP) data from the
#' redesigned 2024-25 School Performance Reports databases. SGP measures how
#' much students grew academically relative to peers with similar score
#' histories; the median SGP (mSGP) summarizes a school's or district's growth.
#'
#' @details
#' The \code{type} argument selects one of three SPR sheets:
#' \itemize{
#'   \item \code{"trends"} (default) -- \code{StudentGrowthTrends}: median SGP
#'     broken out by student group, for ELA and Math, as a multi-year trend
#'     (SY2022-23 through the requested year). One row per entity per student
#'     group, filtered to the requested academic year.
#'   \item \code{"by_grade"} -- \code{StudentGrowthbyGrade}: median SGP by
#'     subject (ELA/Math) and grade (Grades 4-8). 2024-25 only.
#'   \item \code{"by_performance_level"} --
#'     \code{StudentGrowthByPerformLevel}: median SGP by subject and prior-year
#'     NJSLA performance level (Levels 1-5). 2024-25 only.
#' }
#'
#' Median SGP value columns are returned numeric; suppressed cells
#' (\dQuote{Fewer than 10 testers}) become \code{NA}, with the suppression
#' reason preserved in the companion \code{*_category} column.
#'
#' \strong{Supported years:} only \code{end_year = 2025} (SY2024-25) is
#' available. Pre-2025 SPR databases store SGP in differently-shaped,
#' differently-named sheets; supporting them is a documented follow-up.
#'
#' @param end_year A school year. Currently only \code{2025} (SY2024-25) is
#'   supported.
#' @param level One of \code{"school"} or \code{"district"}. \code{"school"}
#'   returns school-level data; \code{"district"} returns district and
#'   state-level data.
#' @param type One of \code{"trends"} (default), \code{"by_grade"}, or
#'   \code{"by_performance_level"}. Selects which SGP sheet to fetch.
#'
#' @return Data frame with median SGP data. Columns vary by \code{type}:
#'   \itemize{
#'     \item \strong{All types}: end_year, county_id, county_name, district_id,
#'       district_name, school_id, school_name, school_year, plus aggregation
#'       flags (is_state, is_county, is_district, is_school, is_charter, ...).
#'     \item \code{type = "trends"}: \code{subgroup}, and for ELA and Math the
#'       entity median (\code{ela_median_sgp}, \code{math_median_sgp}) with its
#'       \code{*_category} growth label, plus the statewide comparison
#'       (\code{ela_median_sgp_state}, \code{math_median_sgp_state}) and its
#'       category. At \code{level = "school"} the entity median is the school
#'       value; at \code{level = "district"} it is the district value.
#'     \item \code{type = "by_grade"}: \code{subject}, \code{grade},
#'       \code{median_sgp}, \code{median_sgp_category}.
#'     \item \code{type = "by_performance_level"}: \code{subject},
#'       \code{njsla_performance_level}, \code{median_sgp},
#'       \code{median_sgp_category}.
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # School-level median SGP by student group (default type = "trends")
#' sgp <- fetch_sgp(2025)
#'
#' # District/state-level growth trends
#' sgp_dist <- fetch_sgp(2025, level = "district")
#'
#' # Median SGP by grade
#' sgp_grade <- fetch_sgp(2025, type = "by_grade")
#'
#' # Median SGP by NJSLA performance level
#' sgp_perf <- fetch_sgp(2025, type = "by_performance_level")
#'
#' # Compare a district's ELA growth to the statewide median
#' library(dplyr)
#' fetch_sgp(2025, level = "district") %>%
#'   filter(is_district, subgroup == "total population") %>%
#'   select(district_name, ela_median_sgp, ela_median_sgp_state)
#' }
fetch_sgp <- function(end_year, level = "school", type = "trends") {
  valid_types <- c("trends", "by_grade", "by_performance_level")
  if (!type %in% valid_types) {
    stop(
      "type must be one of: ",
      paste0("'", valid_types, "'", collapse = ", "),
      call. = FALSE
    )
  }

  if (end_year < 2025) {
    stop(
      "fetch_sgp() currently supports only end_year 2025 (SY2024-25). ",
      "Pre-2025 SPR databases store Student Growth Percentile data in ",
      "differently-shaped, differently-named sheets (StudentGrowthTrends ",
      "without a student-group column, a separate StudentGrowth subgroup ",
      "sheet, and a StudentGrowthByGrade 'ELA/Math'+'mSGP' layout). Mapping ",
      "those onto the redesigned output without a verified column ",
      "correspondence would risk misrepresenting the data; this is a known ",
      "follow-up.",
      call. = FALSE
    )
  }

  sheet_name <- switch(type,
    trends = "StudentGrowthTrends",
    by_grade = "StudentGrowthbyGrade",
    by_performance_level = "StudentGrowthByPerformLevel"
  )

  df <- fetch_spr_data(
    sheet_name = sheet_name,
    end_year = end_year,
    level = level
  )

  # All three sheets carry a multi-year SchoolYear column in StudentGrowthTrends
  # (and a single year in the others). Keep only the requested academic year so
  # the trend sheet collapses to one row per entity per student group.
  df <- filter_spr_to_year(df, end_year)

  if (type == "trends") {
    # The entity-level mSGP column differs by file: the School DB carries
    # *_school columns, the District/State DB carries *_district columns. Map
    # whichever exists to a level-agnostic *_median_sgp so a row's value always
    # means "this entity's median", mirroring fetch_sat_participation()'s
    # school/state convention. The statewide comparison columns are preserved.
    if ("ela_median_student_growth_percentile_school" %in% names(df)) {
      df <- df %>%
        dplyr::rename(
          ela_median_sgp = ela_median_student_growth_percentile_school,
          ela_median_sgp_category = ela_median_student_growth_percentile_school_category,
          math_median_sgp = math_median_student_growth_percentile_school,
          math_median_sgp_category = math_median_student_growth_percentile_school_category
        )
    } else {
      df <- df %>%
        dplyr::rename(
          ela_median_sgp = ela_median_student_growth_percentile_district,
          ela_median_sgp_category = ela_median_student_growth_percentile_district_category,
          math_median_sgp = math_median_student_growth_percentile_district,
          math_median_sgp_category = math_median_student_growth_percentile_district_category
        )
    }

    df <- df %>%
      dplyr::rename(
        ela_median_sgp_state = ela_median_student_growth_percentile_state,
        ela_median_sgp_state_category = ela_median_student_growth_percentile_state_category,
        math_median_sgp_state = math_median_student_growth_percentile_state,
        math_median_sgp_state_category = math_median_student_growth_percentile_state_category
      )

    # Convert the median columns to numeric (suppression -> NA, category kept).
    df$ela_median_sgp <- sgp_value_to_numeric(df$ela_median_sgp)
    df$math_median_sgp <- sgp_value_to_numeric(df$math_median_sgp)
    df$ela_median_sgp_state <- sgp_value_to_numeric(df$ela_median_sgp_state)
    df$math_median_sgp_state <- sgp_value_to_numeric(df$math_median_sgp_state)

    df <- df %>%
      dplyr::select(
        end_year,
        county_id, county_name,
        district_id, district_name,
        school_id, school_name,
        dplyr::any_of("school_year"),
        subgroup,
        ela_median_sgp, ela_median_sgp_category,
        ela_median_sgp_state, ela_median_sgp_state_category,
        math_median_sgp, math_median_sgp_category,
        math_median_sgp_state, math_median_sgp_state_category,
        is_state, is_county, is_district, is_school,
        is_charter, is_charter_sector, is_allpublic
      )
  } else {
    # by_grade / by_performance_level share a single mSGP value + category and a
    # Subject column, differing only in the dimension column (Grade vs
    # NJSLA performance level).
    df <- df %>%
      dplyr::rename(
        median_sgp = median_student_growth_percentile,
        median_sgp_category = median_student_growth_percentile_category
      )
    df$median_sgp <- sgp_value_to_numeric(df$median_sgp)

    dim_col <- if (type == "by_grade") "grade" else "njsla_performance_level"

    df <- df %>%
      dplyr::select(
        end_year,
        county_id, county_name,
        district_id, district_name,
        school_id, school_name,
        dplyr::any_of("school_year"),
        subject,
        dplyr::all_of(dim_col),
        median_sgp, median_sgp_category,
        is_state, is_county, is_district, is_school,
        is_charter, is_charter_sector, is_allpublic
      )
  }

  df
}


#' Fetch ESSA Accountability Status
#'
#' Downloads ESSA accountability status/ratings (CSI/ATSI/TSI identification)
#' from the SPR database. Each row carries the entity's status for the school
#' year (\code{status_for_sy}), the \code{category_of_identification} that drove
#' it, the year eligible to exit, and (for targeted statuses) the affected
#' student group.
#'
#' @details
#' The 2024-25 (end_year 2025) SPR redesign reorganized the accountability
#' sheets per database file:
#' \itemize{
#'   \item \strong{School DB}: keeps the \code{ESSAAccountabilityStatus} sheet
#'     (one row per identified school).
#'   \item \strong{District/State DB}: the \code{ESSAAccountabilityStatus} sheet
#'     was removed and replaced by two new sheets:
#'     \code{ESSAAccountabilityStatusList} (one row per identified school, with
#'     the same 12-column layout as the School DB sheet) and
#'     \code{ESSAAccountabilityStatusCounts} (per-district CSI/ATSI/TSI tallies).
#'     The \emph{List} sheet is the structural analogue of the legacy
#'     \code{ESSAAccountabilityStatus} sheet -- it carries the per-entity status
#'     and \code{category_of_identification} that downstream functions such as
#'     \code{\link{identify_focus_schools}} require -- so this function maps
#'     district-level 2025+ requests to \code{ESSAAccountabilityStatusList}.
#'     The \emph{Counts} sheet holds only aggregate tallies and is not used here.
#' }
#'
#' @param end_year A school year (2017-2025)
#' @param level One of "school" or "district"
#'
#' @return Data frame with ESSA status ratings
#' @export
#' @examples \dontrun{
#' # School-level status (all years use the ESSAAccountabilityStatus sheet)
#' essa <- fetch_essa_status(2024)
#'
#' # District/State-level status for the redesigned 2024-25 database
#' essa_dist <- fetch_essa_status(2025, level = "district")
#'
#' # Identify schools needing comprehensive support
#' library(dplyr)
#' fetch_essa_status(2025) %>%
#'   filter(grepl("Comprehensive", status_for_sy))
#' }
fetch_essa_status <- function(end_year, level = "school") {
  # The 2024-25 redesign removed ESSAAccountabilityStatus from the
  # District/State DB. Its per-entity analogue there is
  # ESSAAccountabilityStatusList (identical 12-column layout, including
  # CategoryOfIdentification). The School DB keeps the original sheet for all
  # years; pre-2025 district behavior is unchanged.
  sheet_name <- if (level == "district") {
    spr_sheet_for_year(
      end_year, "ESSAAccountabilityStatus", "ESSAAccountabilityStatusList"
    )
  } else {
    "ESSAAccountabilityStatus"
  }

  df <- fetch_spr_data(sheet_name, end_year, level)
  df
}


#' Fetch ESSA Accountability Progress
#'
#' Downloads ESSA accountability progress indicators from SPR database.
#' Includes metrics on academic proficiency, growth, graduation rates, and
#' chronic absenteeism.
#'
#' @param end_year A school year (2017-2025)
#' @param level One of "school" or "district"
#'
#' @return Data frame with ESSA progress indicators including:
#'   \itemize{
#'     \item School/district identifying information
#'     \item elaproficiency - ELA proficiency status
#'     \item math_proficiency - Math proficiency status
#'     \item ela_growth - ELA growth indicator
#'     \item math_growth - Math growth indicator
#'     \item x_4_year_graduation_rate - 4-year graduation rate
#'     \item x_5_year_graduation_rate - 5-year graduation rate
#'     \item progress_toward_english_language_proficiency - ELL progress
#'     \item chronic_absenteeism - Chronic absenteeism rate
#'   }
#'
#' @export
#' @examples \dontrun{
#' progress <- fetch_essa_progress(2024)
#' }
fetch_essa_progress <- function(end_year, level = "school") {
  # The ESSAAccountabilityProgress sheet was renamed in 2024-25 to
  # ESSAAccountabilityTrends. The 2025 sheet carries the same progress
  # indicators (proficiency, growth, graduation, ELP progress, chronic
  # absenteeism) plus additive 6-year graduation, HS persistence, and a
  # StudentGroup breakdown.
  sheet_name <- spr_sheet_for_year(
    end_year, "ESSAAccountabilityProgress", "ESSAAccountabilityTrends"
  )
  df <- fetch_spr_data(sheet_name, end_year, level)
  df
}


# ==============================================================================
# ESSA Accountability Analysis Functions
# ==============================================================================
#
# Analysis functions for ESSA accountability data. These functions process
# data from fetch_essa_status() and fetch_essa_progress() to identify schools
# needing support, track progress over time, and analyze improvement patterns.
#
# ==============================================================================

# -----------------------------------------------------------------------------
# Focus School Identification
# -----------------------------------------------------------------------------

#' Identify Focus Schools
#'
#' Identifies schools that need support based on ESSA accountability status.
#' Filters for schools identified as Comprehensive Support, Targeted Support,
#' or other improvement categories, and categorizes by support level.
#'
#' @param df A data frame from \code{\link{fetch_essa_status}} containing
#'   ESSA accountability status information
#' @param end_year Optional school year to filter results (e.g., 2024)
#'
#' @return Data frame with focus schools including:
#'   \itemize{
#'     \item All original columns from input data
#'     \item focus_level - Categorized support level:
#'       \itemize{
#'         \item "Comprehensive Support and Improvement" - Lowest performing 5%
#'         \item "Targeted Support and Improvement" - Underperforming subgroups
#'         \item "Other Support" - Other identification categories
#'       }
#'   }
#'   Schools are sorted by focus level (Comprehensive first) and then alphabetically
#'   by district and school name. Schools without support identification are excluded.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Get ESSA status data
#' essa <- fetch_essa_status(2024)
#'
#' # Identify focus schools
#' focus <- identify_focus_schools(essa)
#'
#' # View comprehensive support schools
#' focus %>%
#'   dplyr::filter(focus_level == "Comprehensive Support and Improvement") %>%
#'   dplyr::select(district_name, school_name, category_of_identification)
#'
#' # Focus on specific year
#' focus_2023 <- identify_focus_schools(essa, end_year = 2023)
#' }
identify_focus_schools <- function(df, end_year = NULL) {

  # Validate input
  if (!"category_of_identification" %in% names(df)) {
    stop("Input data must contain 'category_of_identification' column from fetch_essa_status()")
  }

  # Filter to specific year if requested
  if (!is.null(end_year)) {
    df <- df %>%
      dplyr::filter(end_year == as.numeric(end_year))
  }

  # Filter to schools with some form of identification/support needed
  # Exclude empty, NA, "n/a", or "No Identification" status
  focus_df <- df %>%
    dplyr::filter(
      !is.na(category_of_identification),
      category_of_identification != "",
      # Exclude "n/a" (not applicable - no support needed)
      tolower(trimws(category_of_identification)) != "n/a",
      # Common variations for "no identification" - case insensitive
      !grepl("^no", category_of_identification, ignore.case = TRUE),
      !grepl("^none", category_of_identification, ignore.case = TRUE)
    )

  # Check if any focus schools were found
  if (nrow(focus_df) == 0) {
    warning("No focus schools found in the data")
    return(focus_df)
  }

  # Categorize focus level
  # Look for key terms in the category_of_identification field
  focus_df <- focus_df %>%
    dplyr::mutate(
      focus_level = dplyr::case_when(
        # Comprehensive support (CSI)
        grepl("comprehensive|CSI", category_of_identification, ignore.case = TRUE) ~
          "Comprehensive Support",
        # Targeted support (TSI/ATSI)
        grepl("targeted|TSI|ATSI", category_of_identification, ignore.case = TRUE) ~
          "Targeted Support",
        # Other support types
        grepl("identification|support|improvement|warning|watch|low performing|low graduation",
              category_of_identification, ignore.case = TRUE) ~
          "Other Support",
        # Default
        TRUE ~ "Other Support"
      )
    )

  # Sort by focus level (Comprehensive first, then Targeted, then Other)
  # Then alphabetically by county, district, and school
  focus_df <- focus_df %>%
    dplyr::arrange(focus_level, county_name, district_name, school_name)

  focus_df
}


# -----------------------------------------------------------------------------
# Longitudinal Progress Tracking
# -----------------------------------------------------------------------------

#' Track ESSA Progress Over Time
#'
#' Tracks ESSA accountability status changes across multiple years, identifying
#' improvement trajectories, calculating transition probabilities, and summarizing
#' patterns in school accountability status.
#'
#' @param df_list A named list of data frames from different years. Each element
#'   should be named by its end_year (e.g., list("2020" = df_2020, "2024" = df_2024)).
#'   Data frames should be from \code{\link{fetch_essa_status}}.
#' @param school_id Optional school code to track a specific school (e.g., "010")
#'
#' @return List with two elements:
#'   \itemize{
#'     \item \code{longitudinal} - Data frame with one row per school-year combination:
#'       \itemize{
#'         \item end_year - School year
#'         \item county_id, district_id, school_id - Location identifiers
#'         \item school_name - School name
#'         \item category_of_identification - ESSA status category
#'         \item focus_level - Categorized support level (Comprehensive/Targeted/Other/None)
#'         \item status_change - Change from previous year:
#'           "Improvement", "Decline", "Stable", "First Year", or "Insufficient Data"
#'       }
#'     \item \code{transitions} - Data frame with transition summary statistics:
#'       \itemize{
#'         \item from_status - Status in previous year
#'         \item to_status - Status in current year
#'         \item n_schools - Number of schools with this transition
#'         \item pct_schools - Percentage of all transitions
#'       }
#'     \item \code{summary} - List with summary statistics:
#'       \itemize{
#'         \item n_schools_tracked - Total unique schools tracked
#'         \item n_years - Number of years in data
#'         \item n_improvements - Number of schools showing improvement
#'         \item n_declines - Number of schools showing decline
#'       }
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Fetch data for multiple years
#' essa_2020 <- fetch_essa_status(2020)
#' essa_2022 <- fetch_essa_status(2022)
#' essa_2024 <- fetch_essa_status(2024)
#'
#' # Combine into named list
#' df_list <- list(
#'   "2020" = essa_2020,
#'   "2022" = essa_2022,
#'   "2024" = essa_2024
#' )
#'
#' # Track progress over time
#' progress <- track_essa_progress_over_time(df_list)
#'
#' # View longitudinal data
#' head(progress$longitudinal)
#'
#' # View transition patterns
#' progress$transitions
#'
#' # View summary
#' progress$summary
#'
#' # Track specific school
#' single_school <- track_essa_progress_over_time(df_list, school_id = "010")
#' }
track_essa_progress_over_time <- function(df_list, school_id = NULL) {

  # Validate input
  if (!is.list(df_list) || is.data.frame(df_list)) {
    stop("df_list must be a list of data frames")
  }

  if (is.null(names(df_list)) || any(names(df_list) == "")) {
    stop("df_list must be a named list with years as names")
  }

  # Add year column to each data frame and filter to school if specified
  df_list <- lapply(names(df_list), function(year_name) {
    df <- df_list[[year_name]]
    df$end_year <- as.numeric(year_name)

    # Filter to specific school if requested.
    # Use .env$school_id so the comparison is column == function argument;
    # a bare `school_id == school_id` would data-mask both sides to the column
    # and silently match every row (the argument would be ignored).
    if (!is.null(school_id)) {
      df <- df %>%
        dplyr::filter(school_id == .env$school_id)
    }

    df
  })
  names(df_list) <- names(df_list)

  # Combine all years
  combined <- dplyr::bind_rows(df_list)

  # Check if any data remains
  if (nrow(combined) == 0) {
    warning("No data found for the specified parameters")
    return(list(
      longitudinal = combined,
      transitions = data.frame(),
      summary = list(
        n_schools_tracked = 0,
        n_years = length(df_list),
        n_improvements = 0,
        n_declines = 0
      )
    ))
  }

  # Create focus_level for each row (consistent with identify_focus_schools)
  combined <- combined %>%
    dplyr::mutate(
      focus_level = dplyr::case_when(
        # No identification
        is.na(category_of_identification) |
        category_of_identification == "" |
        tolower(trimws(category_of_identification)) == "n/a" |
        grepl("^no", category_of_identification, ignore.case = TRUE) |
        grepl("^none", category_of_identification, ignore.case = TRUE) ~ "No Support",
        # Comprehensive support (CSI)
        grepl("comprehensive|CSI", category_of_identification, ignore.case = TRUE) ~
          "Comprehensive Support",
        # Targeted support (TSI/ATSI)
        grepl("targeted|TSI|ATSI", category_of_identification, ignore.case = TRUE) ~
          "Targeted Support",
        # Other support
        grepl("identification|support|improvement|warning|watch|low performing|low graduation",
              category_of_identification, ignore.case = TRUE) ~
          "Other Support",
        # Default
        TRUE ~ "Other Support"
      )
    )

  # Sort by school and year
  combined <- combined %>%
    dplyr::arrange(school_id, end_year)

  # Calculate status changes
  longitudinal <- combined %>%
    dplyr::group_by(school_id) %>%
    dplyr::mutate(
      prev_focus_level = dplyr::lag(focus_level),
      prev_end_year = dplyr::lag(end_year)
    ) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(
      # Determine status change
      status_change = dplyr::case_when(
        # First year for this school
        is.na(prev_focus_level) ~ "First Year",
        # Gap in years (not consecutive)
        end_year - prev_end_year > 1 ~ "Insufficient Data",
        # Improvement: moved to lower support level
        prev_focus_level == "Comprehensive Support" &
          focus_level == "Targeted Support" ~ "Improvement",
        prev_focus_level == "Comprehensive Support" &
          focus_level == "No Support" ~ "Improvement",
        prev_focus_level == "Targeted Support" &
          focus_level == "No Support" ~ "Improvement",
        # Decline: moved to higher support level
        prev_focus_level == "No Support" &
          focus_level == "Targeted Support" ~ "Decline",
        prev_focus_level == "No Support" &
          focus_level == "Comprehensive Support" ~ "Decline",
        prev_focus_level == "Targeted Support" &
          focus_level == "Comprehensive Support" ~ "Decline",
        # Stable: same level or within Other Support
        prev_focus_level == focus_level ~ "Stable",
        # Other changes (e.g., Other Support -> No Support)
        TRUE ~ "Stable"
      )
    ) %>%
    dplyr::select(
      end_year,
      county_id,
      district_id,
      school_id,
      school_name,
      category_of_identification,
      focus_level,
      status_change
    )

  # Calculate transition probabilities (focus_level transitions)
  # Only include consecutive year transitions
  transitions <- longitudinal %>%
    dplyr::filter(status_change %in% c("Improvement", "Decline", "Stable")) %>%
    dplyr::mutate(
      from_status = dplyr::lag(focus_level),
      to_status = focus_level
    ) %>%
    dplyr::filter(!is.na(from_status)) %>%
    dplyr::count(from_status, to_status, name = "n_schools") %>%
    dplyr::group_by(from_status) %>%
    dplyr::mutate(pct_schools = (n_schools / sum(n_schools)) * 100) %>%
    dplyr::ungroup() %>%
    dplyr::arrange(from_status, dplyr::desc(n_schools)) %>%
    dplyr::select(from_status, to_status, n_schools, pct_schools)

  # Calculate summary statistics
  n_improvements <- sum(longitudinal$status_change == "Improvement", na.rm = TRUE)
  n_declines <- sum(longitudinal$status_change == "Decline", na.rm = TRUE)
  n_schools_tracked <- length(unique(longitudinal$school_id))

  summary_stats <- list(
    n_schools_tracked = n_schools_tracked,
    n_years = length(df_list),
    n_improvements = n_improvements,
    n_declines = n_declines
  )

  # Return results
  list(
    longitudinal = longitudinal,
    transitions = transitions,
    summary = summary_stats
  )
}


# ==============================================================================
# ESSA Accountability: Long-Term Goals, Summative Scores, TSI, Status Counts
# ==============================================================================
#
# The redesigned 2024-25 (end_year 2025) SPR databases added a family of ESSA
# accountability sheets that have no pre-2025 equivalent:
#
#   ProficiencyTargets / GrowthTargets / GraduationTargets /
#   ProgresstowardELPTargets / ChronicAbsenteeismTargets / HSPersistenceTargets
#                                  -> long-term-goal targets vs. actuals
#   AccountabilitySummative        -> per-indicator summative score components
#   TSIIdentification              -> Targeted Support & Improvement identification
#   ESSAAccountabilityStatusCounts -> per-district CSI/ATSI/TSI tallies
#
# These sheets did not exist (or had an incompatible structure) before the
# redesign, so the fetchers below support only end_year >= 2025 and stop rather
# than guess a mapping for earlier years.
#
# ==============================================================================

#' Require the redesigned (2024-25+) SPR databases
#'
#' Several SPR sheets were introduced in the 2024-25 redesign and have no
#' pre-2025 equivalent. This guard stops with an informative error rather than
#' fabricating a mapping for earlier years.
#'
#' @param end_year School year end.
#' @param what Human-readable description of the data being requested.
#' @keywords internal
spr_require_redesign <- function(end_year, what) {
  if (end_year < 2025) {
    stop(
      what, " is available only for end_year >= 2025 (the redesigned ",
      "SY2024-25 School Performance Reports). Earlier SPR databases do not ",
      "include this sheet.",
      call. = FALSE
    )
  }
  invisible(TRUE)
}


#' Coerce an SPR value column to numeric
#'
#' SPR value columns mix plain numbers, percent strings (e.g. \code{"56.2\%"}),
#' and suppression phrases (e.g. \code{"Data was available for less than 10
#' students"}, \code{"n/a - Below ESSA N-Size"}). This strips percent signs and
#' maps every non-numeric token to \code{NA}, preserving real numbers (including
#' decimals and half-points) exactly. Already-numeric columns pass through
#' untouched.
#'
#' @param x A character or numeric vector from an SPR value column.
#' @return A numeric vector.
#' @keywords internal
spr_value_numeric <- function(x) {
  if (is.numeric(x)) return(x)
  suppressWarnings(rc_numeric_cleaner(x))
}


#' Fetch ESSA Long-Term-Goal Targets
#'
#' Downloads the ESSA accountability long-term-goal target sheets from the
#' redesigned 2024-25 School Performance Reports. Each sheet reports, per entity
#' and student group, an indicator's actual performance against its annual
#' target (or state standard) and, where applicable, the federal long-term goal.
#'
#' @details
#' The \code{indicator} argument selects one of six target sheets, which share a
#' common backbone (entity identifiers, \code{school_year}, \code{subgroup},
#' \code{measure}, \code{indicator_performance}) but differ in their target
#' columns:
#' \itemize{
#'   \item \code{"proficiency"} -- \code{ProficiencyTargets}: ELA and Math
#'     NJSLA proficiency. Columns: \code{annual_target}, \code{long_term_goal},
#'     \code{target_status}.
#'   \item \code{"growth"} -- \code{GrowthTargets}: ELA and Math median student
#'     growth. Columns: \code{state_standard_growth}, \code{target_status}.
#'   \item \code{"graduation"} -- \code{GraduationTargets}: 4-, 5-, and 6-year
#'     graduation rates. Columns: \code{annual_target}, \code{long_term_goal},
#'     \code{target_status}.
#'   \item \code{"elp"} -- \code{ProgresstowardELPTargets}: progress toward
#'     English language proficiency. Columns: \code{annual_target},
#'     \code{long_term_goal}, \code{target_status}.
#'   \item \code{"absenteeism"} -- \code{ChronicAbsenteeismTargets}: chronic
#'     absenteeism. Columns: \code{target_state_average}, \code{target_status}.
#'   \item \code{"persistence"} -- \code{HSPersistenceTargets}: high-school
#'     persistence. No target/status columns (performance only).
#' }
#'
#' \code{measure} holds the sheet's own breakdown (e.g. \code{"ELA Proficiency"}
#' vs. \code{"Math Proficiency"}, or \code{"4-Year Graduation"} vs.
#' \code{"5-Year Graduation"}). \code{indicator} is added as a constant column
#' equal to the requested value so results from several indicators can be
#' row-bound and told apart.
#'
#' Value columns (\code{indicator_performance}, \code{annual_target},
#' \code{long_term_goal}, \code{state_standard_growth},
#' \code{target_state_average}) are returned numeric; suppressed or
#' below-N-size cells become \code{NA}. \code{target_status} is kept as the raw
#' status label (e.g. \code{"Met Target"}, \code{"Met with CI"},
#' \code{"Below N-Size"}).
#'
#' \strong{Supported years:} only \code{end_year >= 2025} (the redesigned
#' SY2024-25 SPR). Earlier databases do not include these sheets.
#'
#' @param end_year A school year. Only \code{2025} (SY2024-25) and later are
#'   supported.
#' @param indicator One of \code{"proficiency"} (default), \code{"growth"},
#'   \code{"graduation"}, \code{"elp"}, \code{"absenteeism"}, or
#'   \code{"persistence"}.
#' @param level One of \code{"school"} or \code{"district"}. \code{"school"}
#'   returns school-level data; \code{"district"} returns district and
#'   state-level data.
#'
#' @return Data frame with columns: end_year, county_id, county_name,
#'   district_id, district_name, school_id, school_name, school_year,
#'   subgroup, indicator, measure, indicator_performance, the
#'   indicator-specific target columns described above, target_status (except
#'   for \code{"persistence"}), and the aggregation flags (is_state, is_county,
#'   is_district, is_school, is_charter, is_charter_sector, is_allpublic).
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # School-level proficiency targets (default indicator)
#' prof <- fetch_spr_essa_targets(2025)
#'
#' # District/state-level graduation targets
#' grad <- fetch_spr_essa_targets(2025, indicator = "graduation", level = "district")
#'
#' # Which schools missed their ELA proficiency long-term goal?
#' library(dplyr)
#' fetch_spr_essa_targets(2025, indicator = "proficiency") %>%
#'   filter(is_school, subgroup == "total population", measure == "ELA Proficiency") %>%
#'   filter(target_status == "Did Not Meet Target") %>%
#'   select(district_name, school_name, indicator_performance, long_term_goal)
#' }
fetch_spr_essa_targets <- function(end_year, indicator = "proficiency",
                                   level = "school") {
  valid_indicators <- c(
    "proficiency", "growth", "graduation", "elp", "absenteeism", "persistence"
  )
  if (!indicator %in% valid_indicators) {
    stop(
      "indicator must be one of: ",
      paste0("'", valid_indicators, "'", collapse = ", "),
      call. = FALSE
    )
  }
  spr_require_redesign(end_year, "ESSA long-term-goal targets data")

  sheet_name <- switch(indicator,
    proficiency = "ProficiencyTargets",
    growth      = "GrowthTargets",
    graduation  = "GraduationTargets",
    elp         = "ProgresstowardELPTargets",
    absenteeism = "ChronicAbsenteeismTargets",
    persistence = "HSPersistenceTargets"
  )

  df <- fetch_spr_data(sheet_name, end_year, level)
  df <- filter_spr_to_year(df, end_year)

  # The sheet's own breakdown column ("Indicator": ELA Proficiency, 4-Year
  # Graduation, ...) is renamed to `measure` so the function's `indicator`
  # argument can be surfaced as its own constant column without collision.
  df <- dplyr::rename(df, measure = indicator)
  df$indicator <- indicator

  # Value columns -> numeric (percent strings stripped, suppression -> NA).
  value_cols <- intersect(
    c("indicator_performance", "annual_target", "long_term_goal",
      "state_standard_growth", "target_state_average"),
    names(df)
  )
  for (col in value_cols) df[[col]] <- spr_value_numeric(df[[col]])

  df %>%
    dplyr::select(
      end_year,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      dplyr::any_of("school_year"),
      subgroup, indicator, measure,
      indicator_performance,
      dplyr::any_of(c("annual_target", "long_term_goal",
                      "state_standard_growth", "target_state_average")),
      dplyr::any_of("target_status"),
      is_state, is_county, is_district, is_school,
      is_charter, is_charter_sector, is_allpublic
    )
}


#' Fetch ESSA Summative Accountability Scores
#'
#' Downloads the \code{AccountabilitySummative} sheet from the redesigned
#' 2024-25 School Performance Reports. This is the school-level ESSA summative
#' accountability record: for each indicator (ELA/Math proficiency, ELA/Math
#' growth, 4/5/6-year graduation, progress toward English language proficiency,
#' chronic absenteeism, high-school persistence) it reports the actual
#' performance, the weighted indicator score, and the indicator's weight, and
#' rolls them up into a \code{summative_score} and \code{summative_rating}.
#'
#' @details
#' This sheet exists only in the School database, so this function always reads
#' school-level data (there is no \code{level} argument). Performance, score,
#' weight, and summative columns are returned numeric (percent signs stripped,
#' \code{"n/a"}/suppressed cells set to \code{NA}); \code{title_i} and
#' \code{school_configuration} are kept as labels. \code{subgroup} is
#' standardized via the SPR subgroup cleaner.
#'
#' \strong{Supported years:} only \code{end_year >= 2025}.
#'
#' @param end_year A school year. Only \code{2025} (SY2024-25) and later are
#'   supported.
#'
#' @return Data frame with entity identifiers, school_year, subgroup, title_i,
#'   school_configuration, the per-indicator \code{*_actual_performance},
#'   \code{*_indicator_score}, and \code{*_weight} columns, \code{summative_score},
#'   \code{summative_rating}, and the aggregation flags.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # School-level summative scores
#' summ <- fetch_spr_accountability_summative(2025)
#'
#' # Lowest summative scores among schoolwide (total population) rows
#' library(dplyr)
#' fetch_spr_accountability_summative(2025) %>%
#'   filter(subgroup == "total population", !is.na(summative_score)) %>%
#'   slice_min(summative_score, n = 10) %>%
#'   select(district_name, school_name, summative_score, summative_rating)
#'
#' # ELA vs Math proficiency contribution to the score
#' fetch_spr_accountability_summative(2025) %>%
#'   filter(subgroup == "total population") %>%
#'   select(school_name, ela_proficiency_indicator_score,
#'          math_proficiency_indicator_score)
#' }
fetch_spr_accountability_summative <- function(end_year) {
  spr_require_redesign(end_year, "ESSA summative accountability data")

  df <- fetch_spr_data("AccountabilitySummative", end_year, level = "school")
  df <- filter_spr_to_year(df, end_year)

  # Numeric-clean every performance / score / weight / summative column; leave
  # the descriptive label columns (title_i, school_configuration) as-is.
  num_cols <- grep(
    "actual_performance|indicator_score|weight|^summative_",
    names(df), value = TRUE
  )
  for (col in num_cols) df[[col]] <- spr_value_numeric(df[[col]])

  df
}


#' Fetch Targeted Support and Improvement (TSI) Identification
#'
#' Downloads the \code{TSIIdentification} sheet from the redesigned 2024-25
#' School Performance Reports. Each row reports, for a school / student group /
#' indicator, whether the school is identified for Targeted Support and
#' Improvement and the two-year target history (SY2023-24 and SY2024-25) that
#' drove the determination.
#'
#' @details
#' This sheet exists only in the School database, so this function always reads
#' school-level data (there is no \code{level} argument). For readability a few
#' raw column names are normalized: \code{IdentifiedforTSI} ->
#' \code{identified_for_tsi}, \code{TSICriteriaMet} -> \code{tsi_criteria_met},
#' and \code{AllTargetsNotMetBelowStatus24-25} ->
#' \code{all_targets_not_met_below_status_2425}. The \code{actual_value_*} and
#' \code{target_*} value columns are returned numeric (percent signs stripped,
#' suppressed/below-N-size cells set to \code{NA}); the \code{*_status_*} and
#' note columns are kept as labels. \code{subgroup} is standardized via the SPR
#' subgroup cleaner.
#'
#' \strong{Supported years:} only \code{end_year >= 2025}.
#'
#' @param end_year A school year. Only \code{2025} (SY2024-25) and later are
#'   supported.
#'
#' @return Data frame with entity identifiers, identified_for_tsi,
#'   student_groups_tsi, subgroup, indicator, the SY2023-24 and SY2024-25
#'   value/target/status columns, tsi_criteria_met, identification_note, and the
#'   aggregation flags.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # School-level TSI identification
#' tsi <- fetch_spr_tsi(2025)
#'
#' # Schools identified for TSI and the indicators that triggered it
#' library(dplyr)
#' fetch_spr_tsi(2025) %>%
#'   filter(identified_for_tsi == "Yes", tsi_criteria_met == "Yes") %>%
#'   select(district_name, school_name, subgroup, indicator)
#'
#' # Distinct schools identified for TSI
#' fetch_spr_tsi(2025) %>%
#'   filter(identified_for_tsi == "Yes") %>%
#'   distinct(county_id, district_id, school_id, school_name)
#' }
fetch_spr_tsi <- function(end_year) {
  spr_require_redesign(end_year, "TSI identification data")

  df <- fetch_spr_data("TSIIdentification", end_year, level = "school")

  # Normalize the awkward raw names produced by snake-casing the source headers.
  renames <- c(
    identified_for_tsi = "identifiedfor_tsi",
    tsi_criteria_met = "tsicriteria_met",
    all_targets_not_met_below_status_2425 = "all_targets_not_met_below_status_24_25"
  )
  for (new_nm in names(renames)) {
    old_nm <- renames[[new_nm]]
    if (old_nm %in% names(df) && !new_nm %in% names(df)) {
      df <- dplyr::rename(df, !!new_nm := !!rlang::sym(old_nm))
    }
  }

  # Value columns -> numeric; status / note columns stay as labels.
  value_cols <- grep("^actual_value_|^target_2", names(df), value = TRUE)
  for (col in value_cols) df[[col]] <- spr_value_numeric(df[[col]])

  df
}


#' Fetch ESSA Accountability Status Counts (district/state)
#'
#' Downloads the \code{ESSAAccountabilityStatusCounts} sheet from the redesigned
#' 2024-25 School Performance Reports. Each row tallies, for a district (and the
#' statewide total), how many of its schools are identified as Comprehensive
#' Support and Improvement (CSI), Additional Targeted Support and Improvement
#' (ATSI), and Targeted Support and Improvement (TSI).
#'
#' @details
#' This sheet exists only in the District/State database, so this function
#' always reads district-level data (there is no \code{level} argument). The
#' three count columns are returned numeric. The per-school identification
#' detail behind these tallies is available from \code{\link{fetch_essa_status}}
#' (the \code{ESSAAccountabilityStatusList} sheet).
#'
#' \strong{Supported years:} only \code{end_year >= 2025}. The pre-2025
#' District/State database stored accountability status in a single sheet that
#' \code{\link{fetch_essa_status}} reads; the separate counts sheet is new in
#' the redesign.
#'
#' @param end_year A school year. Only \code{2025} (SY2024-25) and later are
#'   supported.
#'
#' @return Data frame with county_id, county_name, district_id, district_name,
#'   school_id, school_name, comprehensive_csi, additional_targeted_atsi,
#'   targeted_tsi, end_year, and the aggregation flags.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # District/state CSI/ATSI/TSI tallies
#' counts <- fetch_spr_essa_status_counts(2025)
#'
#' # Statewide totals
#' library(dplyr)
#' fetch_spr_essa_status_counts(2025) %>%
#'   filter(is_state) %>%
#'   select(comprehensive_csi, additional_targeted_atsi, targeted_tsi)
#'
#' # Districts with the most CSI schools
#' fetch_spr_essa_status_counts(2025) %>%
#'   filter(is_district) %>%
#'   slice_max(comprehensive_csi, n = 10) %>%
#'   select(county_name, district_name, comprehensive_csi)
#' }
fetch_spr_essa_status_counts <- function(end_year) {
  spr_require_redesign(end_year, "ESSA accountability status counts")

  df <- fetch_spr_data("ESSAAccountabilityStatusCounts", end_year,
                       level = "district")

  count_cols <- intersect(
    c("comprehensive_csi", "additional_targeted_atsi", "targeted_tsi"),
    names(df)
  )
  for (col in count_cols) df[[col]] <- spr_value_numeric(df[[col]])

  df
}
