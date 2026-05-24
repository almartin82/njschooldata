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


#' Supported SGP years by type
#'
#' SGP coverage differs per \code{type} because the pre-redesign databases store
#' each measure in a differently-shaped sheet with a different history. See
#' \code{\link{fetch_sgp}} for the empirical basis.
#'
#' @param type One of "trends", "by_grade", "by_performance_level".
#' @return Integer vector of supported \code{end_year}s.
#' @keywords internal
sgp_supported_years <- function(type) {
  switch(type,
    trends = c(2018L, 2019L, 2023L, 2024L, 2025L),
    by_grade = c(2018L, 2019L, 2023L, 2024L, 2025L),
    by_performance_level = c(2023L, 2024L, 2025L)
  )
}


#' Validate an SGP request year, with a type-specific explanation
#'
#' @param end_year School year end.
#' @param type SGP measure type.
#' @return Invisibly \code{NULL}; \code{stop()}s for unsupported combinations.
#' @keywords internal
sgp_check_year <- function(end_year, type) {
  if (end_year %in% sgp_supported_years(type)) {
    return(invisible(NULL))
  }

  covid <- paste0(
    "SY2019-20 through SY2021-22 (end_year 2020-2022) are unavailable for every ",
    "type: NJ produced no Student Growth Percentiles during the COVID ",
    "statewide-assessment pause (no spring 2020/2021 testing, and SY2021-22 ",
    "lacks the consecutive prior scores SGP requires)."
  )
  supported <- paste(sgp_supported_years(type), collapse = ", ")

  msg <- if (type == "by_performance_level" && end_year %in% 2017:2019) {
    paste0(
      "Median SGP by NJSLA performance level is available for end_year ",
      supported, ". The 2017-2019 StudentGrowthByPerformLevel sheet reports a ",
      "different statistic (the Low/Typical/High growth-band percentage ",
      "distribution by PARCC level), not a median SGP, so mapping it would ",
      "misrepresent the data."
    )
  } else if (end_year %in% 2020:2022) {
    paste0(covid, " Supported years for type = '", type, "': ", supported, ".")
  } else if (end_year == 2017) {
    paste0(
      "Student growth data is available for end_year >= 2018; the SY2016-17 ",
      "sheet omits county/district name columns. Supported years for type = '",
      type, "': ", supported, "."
    )
  } else {
    paste0("fetch_sgp(type = '", type, "') supports end_year ", supported, ".")
  }

  stop(msg, call. = FALSE)
}


#' Year-aware SGP sheet name
#'
#' @param end_year School year end.
#' @param type SGP measure type.
#' @return The SPR sheet name to read for that year/type.
#' @keywords internal
sgp_sheet_name <- function(end_year, type) {
  switch(type,
    # The redesigned 2024-25 subgroup trend (StudentGrowthTrends) is the
    # successor to the legacy subgroup sheet, which was named StudentGrowth.
    trends = spr_sheet_for_year(end_year, "StudentGrowth", "StudentGrowthTrends"),
    # Capital-B legacy name vs lowercase-b 2025 name.
    by_grade = spr_sheet_for_year(end_year, "StudentGrowthByGrade", "StudentGrowthbyGrade"),
    # Same sheet name across years (the measure, not the name, changed pre-2020).
    by_performance_level = "StudentGrowthByPerformLevel"
  )
}


#' Reshape a legacy (pre-2025) StudentGrowthByGrade sheet to the 2025 shape
#'
#' Legacy columns: \code{ela_math}, \code{grade}, a single median column whose
#' name churns by year (\code{m_sgp} for 2023-24, \code{m_sgp_school} for
#' 2018-19), and \code{level} (the growth category, present only 2023-24).
#'
#' @param df Output of \code{\link{fetch_spr_data}} for a legacy by-grade sheet.
#' @return Data frame matching the 2025 \code{type = "by_grade"} output.
#' @keywords internal
sgp_legacy_by_grade <- function(df) {
  df <- dplyr::rename(df, subject = ela_math)
  median_col <- intersect(c("m_sgp", "m_sgp_school", "m_sgp_district"), names(df))[1]
  df$median_sgp <- sgp_value_to_numeric(df[[median_col]])
  df$median_sgp_category <- if ("level" %in% names(df)) {
    as.character(df$level)
  } else {
    NA_character_
  }

  df %>%
    dplyr::select(
      end_year,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      subject, grade,
      median_sgp, median_sgp_category,
      is_state, is_county, is_district, is_school,
      is_charter, is_charter_sector, is_allpublic
    )
}


#' Reshape a legacy (2023-24) StudentGrowthByPerformLevel sheet to 2025 shape
#'
#' Legacy columns: \code{ela_math}, the prior-performance-level column (named
#' \code{njsla_performance_level} in the district file, \code{parcc_performance_level}
#' in the school file -- both carry "Performance Level 1".."5" values),
#' \code{m_sgp}, and \code{level} (the growth category). Only 2023 and 2024 carry
#' this median-by-level measure; \code{\link{sgp_check_year}} rejects earlier years.
#'
#' @param df Output of \code{\link{fetch_spr_data}} for a legacy by-perf-level sheet.
#' @return Data frame matching the 2025 \code{type = "by_performance_level"} output.
#' @keywords internal
sgp_legacy_by_perf <- function(df) {
  df <- dplyr::rename(df, subject = ela_math)
  pl_col <- intersect(
    c("njsla_performance_level", "parcc_performance_level"), names(df)
  )[1]
  names(df)[names(df) == pl_col] <- "njsla_performance_level"
  df$median_sgp <- sgp_value_to_numeric(df$m_sgp)
  df$median_sgp_category <- if ("level" %in% names(df)) {
    as.character(df$level)
  } else {
    NA_character_
  }

  df %>%
    dplyr::select(
      end_year,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      subject, njsla_performance_level,
      median_sgp, median_sgp_category,
      is_state, is_county, is_district, is_school,
      is_charter, is_charter_sector, is_allpublic
    )
}


#' Reshape a legacy (pre-2025) StudentGrowth subgroup sheet to 2025 trends shape
#'
#' The redesigned 2025 \code{StudentGrowthTrends} sheet is the successor to the
#' legacy \code{StudentGrowth} sheet, which is long-by-subject with one row per
#' entity per student group. This pivots ELA/Math wide to match the 2025 output.
#'
#' Two legacy quirks are handled: (1) the subgroup column header varies
#' (\code{SubGroup}/\code{StudentGroup} in the district file, mislabeled
#' \code{SchoolYear} in the school file), so it is identified structurally as the
#' column immediately before \code{subject}; (2) legacy sheets carry a
#' \code{MetTarget} flag ("Met Standard"/"Not Met"/...) rather than the 2025
#' growth/suppression \code{*_category}. The \code{*_category} columns are
#' therefore \code{NA} and the real MetTarget value is preserved verbatim in
#' \code{ela_met_target}/\code{math_met_target}.
#'
#' @param df Output of \code{\link{fetch_spr_data}} for a legacy StudentGrowth sheet.
#' @param level "school" or "district" (selects the entity median column).
#' @return Data frame matching the 2025 \code{type = "trends"} output, plus
#'   \code{ela_met_target}/\code{math_met_target}.
#' @keywords internal
sgp_legacy_trends <- function(df, level) {
  # Subgroup = the column immediately before `subject` (its header varies, and
  # in the school file it is mislabeled "SchoolYear" by NJ DOE). Standardize
  # and clean it.
  subj_idx <- which(names(df) == "subject")
  subgroup_col <- names(df)[subj_idx - 1L]
  names(df)[names(df) == subgroup_col] <- "subgroup"
  df$subgroup <- clean_spr_subgroups(df$subgroup)

  # Entity median: the school file carries school_median; the district/state
  # file carries district_median (each row's own median).
  entity_col <- if ("school_median" %in% names(df)) "school_median" else "district_median"

  key_cols <- c(
    "end_year", "county_id", "county_name", "district_id", "district_name",
    "school_id", "school_name", "subgroup",
    "is_state", "is_county", "is_district", "is_school",
    "is_charter", "is_charter_sector", "is_allpublic"
  )

  one_subject <- function(subj, prefix) {
    sub <- df[df$subject == subj, , drop = FALSE]
    out <- sub[, key_cols, drop = FALSE]
    out[[paste0(prefix, "_median_sgp")]] <- sgp_value_to_numeric(sub[[entity_col]])
    out[[paste0(prefix, "_median_sgp_state")]] <- sgp_value_to_numeric(sub[["state_median"]])
    out[[paste0(prefix, "_met_target")]] <- as.character(sub[["met_target"]])
    out
  }

  out <- dplyr::full_join(
    one_subject("ELA", "ela"),
    one_subject("Math", "math"),
    by = key_cols
  )

  # Legacy sheets predate the 2025 growth/suppression category labels.
  out$ela_median_sgp_category <- NA_character_
  out$ela_median_sgp_state_category <- NA_character_
  out$math_median_sgp_category <- NA_character_
  out$math_median_sgp_state_category <- NA_character_

  out %>%
    dplyr::select(
      end_year,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      subgroup,
      ela_median_sgp, ela_median_sgp_category,
      ela_median_sgp_state, ela_median_sgp_state_category,
      ela_met_target,
      math_median_sgp, math_median_sgp_category,
      math_median_sgp_state, math_median_sgp_state_category,
      math_met_target,
      is_state, is_county, is_district, is_school,
      is_charter, is_charter_sector, is_allpublic
    )
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
#'   \item \code{"trends"} (default) -- \code{StudentGrowthTrends} (legacy
#'     \code{StudentGrowth}): median SGP broken out by student group, for ELA and
#'     Math. One row per entity per student group. Pre-2025 years carry the
#'     legacy \code{MetTarget} flag in \code{ela_met_target}/\code{math_met_target}
#'     and \code{NA} \code{*_category} (the growth-category labels are new in 2025).
#'   \item \code{"by_grade"} -- \code{StudentGrowthbyGrade} (legacy
#'     \code{StudentGrowthByGrade}): median SGP by subject (ELA/Math) and grade
#'     (Grades 4-8). The growth category is reported only from 2023; earlier
#'     years return \code{NA} for \code{median_sgp_category}.
#'   \item \code{"by_performance_level"} --
#'     \code{StudentGrowthByPerformLevel}: median SGP by subject and prior-year
#'     NJSLA performance level (Levels 1-5). The 2017-2019 sheet reports a
#'     different statistic (a growth-band percentage distribution) and is not
#'     supported.
#' }
#'
#' Median SGP value columns are returned numeric; suppressed cells
#' (\dQuote{Fewer than 10 testers}) become \code{NA}, with the suppression
#' reason preserved in the companion \code{*_category} column.
#'
#' \strong{Supported years (vary by type):} \code{trends}: 2018, 2019, 2023,
#' 2024, 2025. \code{by_grade}: 2018, 2019, 2023, 2024, 2025.
#' \code{by_performance_level}: 2023, 2024, 2025. SY2019-20 through SY2021-22
#' (end_year 2020-2022) are unavailable for every type -- NJ produced no Student
#' Growth Percentiles during the COVID statewide-assessment pause.
#'
#' @param end_year A school year. Supported years depend on \code{type}; see
#'   \strong{Supported years} above.
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
#'       value; at \code{level = "district"} it is the district value. Pre-2025
#'       years additionally carry \code{ela_met_target}/\code{math_met_target}
#'       and have \code{NA} in the \code{*_category} columns. The 2025 sheet is a
#'       multi-year trend filtered to the requested year and adds a
#'       \code{school_year} column; legacy sheets are single-year.
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

  sgp_check_year(end_year, type)

  df <- fetch_spr_data(
    sheet_name = sgp_sheet_name(end_year, type),
    end_year = end_year,
    level = level
  )

  # Pre-2025 sheets are differently shaped and reuse names for different data;
  # map them to the 2025 output via verified per-type reshapers.
  if (end_year < 2025) {
    return(switch(type,
      trends = sgp_legacy_trends(df, level),
      by_grade = sgp_legacy_by_grade(df),
      by_performance_level = sgp_legacy_by_perf(df)
    ))
  }

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
#' thousands-separated counts (e.g. \code{"10,238"}), and suppression phrases
#' (e.g. \code{"Data was available for less than 10 students"},
#' \code{"n/a - Below ESSA N-Size"}, \code{"There is no data available for this
#' school year."}). This strips thousands commas and percent signs and maps
#' every remaining non-numeric token to \code{NA}, preserving real numbers
#' (including decimals and half-points) exactly. Already-numeric columns pass
#' through untouched.
#'
#' @param x A character or numeric vector from an SPR value column.
#' @return A numeric vector.
#' @keywords internal
spr_value_numeric <- function(x) {
  if (is.numeric(x)) return(x)
  x <- gsub(",", "", x, fixed = TRUE)
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


# ==============================================================================
# Graduation Pathways, Home-Language Enrollment, and NAEP
# ==============================================================================
#
# Three sheets first exposed via the redesigned 2024-25 databases and since
# extended backward to the earliest pre-redesign year each one exists:
#
#   GraduationPathways       -> % of graduates meeting the requirement by pathway
#                               (2018-2022, 2024-2025; absent SY2016-17/SY2022-23)
#   EnrollmentByHomeLanguage -> enrollment share by home language (2018-2025)
#   NAEP (District/State DB) -> NAEP 4th/8th-grade reading & math achievement
#                               (2017-2025; legacy layout mapped to 2025 shape)
#
# GraduationPathways and EnrollmentByHomeLanguage carry the standard CDS layout
# and route through fetch_spr_data(). NAEP is a state/national summary table
# with no county/district/school identifiers, so it uses a lighter raw reader.
# Pre-2025 column names are harmonized to the redesigned shape inside each
# fetcher; see the per-function docs for the exact mapping.
#
# ==============================================================================

#' Read an SPR sheet without CDS / aggregation-flag processing
#'
#' A lighter-weight sibling of \code{\link{fetch_spr_data}} for SPR sheets that
#' do not carry the standard county/district/school identifier columns (e.g.
#' \code{NAEP}, \code{StatewideEducatorEquity}), which are state/national summary
#' tables. Downloads the workbook, reads the requested sheet (skipping the
#' 2024-25 preamble rows), snake-cases the column names, and stamps
#' \code{end_year}. No CDS renaming, subgroup cleaning, or aggregation flags are
#' applied.
#'
#' @param sheet_name Exact sheet name (case-sensitive).
#' @param end_year A school year (2017-2025).
#' @param level One of "school" or "district". Determines which database file
#'   to download.
#' @return Data frame with snake_cased column names plus \code{end_year}.
#' @keywords internal
fetch_spr_sheet_raw <- function(sheet_name, end_year, level = "district") {
  target_url <- get_spr_url(end_year, level)

  cache_key <- make_cache_key("fetch_spr_sheet_raw", sheet_name, end_year, level)
  cached <- cache_get(cache_key)
  if (!is.null(cached)) {
    return(cached)
  }

  tname <- tempfile(pattern = "spr_", tmpdir = tempdir(), fileext = ".xlsx")
  downloader::download(target_url, destfile = tname, mode = "wb")

  header_skip <- if (end_year >= 2025) 3 else 0

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

  names(df) <- clean_name_vector(names(df))
  df$end_year <- end_year

  cache_set(cache_key, df)
  df
}


#' Fetch Graduation Pathways
#'
#' Downloads the \code{GraduationPathways} sheet from the redesigned 2024-25
#' School Performance Reports. For each entity and subject (ELA and Math), it
#' reports the percentage of graduates who satisfied the graduation-assessment
#' requirement through each available pathway.
#'
#' @details
#' Pathways (columns, each a percentage on a 0-100 scale):
#' \itemize{
#'   \item \code{statewide_assessment} -- met via the statewide NJSLA/NJGPA
#'     assessment.
#'   \item \code{substitute_competency_test} -- met via an approved substitute
#'     competency test (e.g. SAT, ACT, PSAT, ASVAB).
#'   \item \code{portfolio_appeals} -- met via the portfolio appeals process.
#'   \item \code{alternate_requirements_in_iep} -- met via alternate
#'     requirements specified in the student's IEP.
#' }
#' Percentages are returned numeric (suppressed cells become \code{NA}).
#'
#' \strong{Supported years:} 2018-2022, 2024, and 2025. The
#' \code{GraduationPathways} sheet is present in those SPR databases (it is
#' \strong{absent} from the SY2016-17 and SY2022-23 databases, which therefore
#' error). Before the 2024-25 redesign the columns were named slightly
#' differently (\code{ELA/Math}, \code{PARCCAssessment}/\code{StatewideAssessment},
#' \code{SubstituteCompetency}, \code{PortfolioAppealsProcess},
#' \code{AlternateReqIEP}); this function harmonizes them to the redesigned
#' names and uppercases the subject label. The COVID-era executive-order waiver
#' column present in the 2020 and 2021 sheets is not part of the four-pathway
#' schema and is dropped.
#'
#' @param end_year A school year (2018-2022, 2024, or 2025). Year is the end of
#'   the academic year - e.g. the 2020-21 school year is \code{end_year} 2021.
#' @param level One of \code{"school"} or \code{"district"}.
#'
#' @return Data frame with entity identifiers, school_year, subject, the four
#'   pathway percentage columns, and the aggregation flags.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # School-level graduation pathways
#' gp <- fetch_spr_grad_pathways(2025)
#'
#' # The same pathway mix back to SY2017-18
#' gp_2018 <- fetch_spr_grad_pathways(2018)
#'
#' # Statewide ELA pathway mix
#' library(dplyr)
#' fetch_spr_grad_pathways(2025, level = "district") %>%
#'   filter(is_state, subject == "ELA") %>%
#'   select(statewide_assessment, substitute_competency_test,
#'          portfolio_appeals, alternate_requirements_in_iep)
#'
#' # Schools leaning hardest on portfolio appeals for Math
#' fetch_spr_grad_pathways(2025) %>%
#'   filter(is_school, subject == "Math") %>%
#'   slice_max(portfolio_appeals, n = 10) %>%
#'   select(district_name, school_name, portfolio_appeals)
#' }
fetch_spr_grad_pathways <- function(end_year, level = "school") {
  if (end_year < 2018) {
    stop(
      "graduation pathways data is available for end_year >= 2018 (the ",
      "GraduationPathways sheet is absent from the SY2016-17 SPR database).",
      call. = FALSE
    )
  }
  if (end_year == 2023) {
    stop(
      "graduation pathways data is not available for end_year 2023 - the ",
      "GraduationPathways sheet is absent from the SY2022-23 SPR database.",
      call. = FALSE
    )
  }

  df <- fetch_spr_data("GraduationPathways", end_year, level)
  df <- filter_spr_to_year(df, end_year)

  # Normalize the awkward snake-cased name for the IEP pathway (done via a
  # direct name assignment to avoid a spurious global-variable NOTE).
  names(df)[names(df) == "alternate_requirementsin_iep"] <-
    "alternate_requirements_in_iep"

  # Harmonize the pre-2025 column names to the redesigned (2024-25) names. Each
  # rename only fires when the legacy column is present and the target is not,
  # so the 2025 layout passes through untouched.
  legacy_renames <- c(
    subject = "ela_math",
    # "PARCCAssessment" (2018) snake-cases to a single token (no underscore).
    statewide_assessment = "parccassessment",
    substitute_competency_test = "substitute_competency",
    portfolio_appeals = "portfolio_appeals_process",
    alternate_requirements_in_iep = "alternate_req_iep"
  )
  for (new_nm in names(legacy_renames)) {
    old_nm <- legacy_renames[[new_nm]]
    if (old_nm %in% names(df) && !new_nm %in% names(df)) {
      names(df)[names(df) == old_nm] <- new_nm
    }
  }

  # The legacy ELA/Math column carries lowercase labels; uppercase them to match
  # the redesigned Subject column ("ELA", "Math").
  if ("subject" %in% names(df)) {
    df$subject[df$subject == "ela"] <- "ELA"
    df$subject[df$subject == "math"] <- "Math"
  }

  pathway_cols <- intersect(
    c("statewide_assessment", "substitute_competency_test",
      "portfolio_appeals", "alternate_requirements_in_iep"),
    names(df)
  )
  for (col in pathway_cols) df[[col]] <- spr_value_numeric(df[[col]])

  df %>%
    dplyr::select(
      end_year,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      dplyr::any_of("school_year"),
      subject,
      dplyr::any_of(c("statewide_assessment", "substitute_competency_test",
                      "portfolio_appeals", "alternate_requirements_in_iep")),
      is_state, is_county, is_district, is_school,
      is_charter, is_charter_sector, is_allpublic
    )
}


#' Fetch Enrollment by Home Language
#'
#' Downloads the \code{EnrollmentByHomeLanguage} sheet from the redesigned
#' 2024-25 School Performance Reports. For each entity it reports the percentage
#' of students by reported home language (e.g. English, Spanish, and an "Others"
#' catch-all). This breakdown is not available through \code{\link{fetch_enr}}.
#'
#' @details
#' \code{percent_of_students} is returned numeric on a 0-100 scale (suppressed
#' cells become \code{NA}).
#'
#' \strong{Supported years:} \code{end_year >= 2018}. The
#' \code{EnrollmentByHomeLanguage} sheet is present back to SY2017-18 with an
#' identical layout (the 2024-25 redesign only added a \code{SchoolYear} column,
#' handled transparently). The SY2016-17 sheet omits the county/district/school
#' name columns and is not supported.
#'
#' @param end_year A school year (2018-2025). Year is the end of the academic
#'   year - e.g. the 2020-21 school year is \code{end_year} 2021.
#' @param level One of \code{"school"} or \code{"district"}.
#'
#' @return Data frame with entity identifiers, school_year, home_language,
#'   percent_of_students, and the aggregation flags.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # School-level home-language shares
#' hl <- fetch_spr_home_language(2025)
#'
#' # The same breakdown back to SY2017-18
#' hl_2018 <- fetch_spr_home_language(2018)
#'
#' # Statewide home-language distribution
#' library(dplyr)
#' fetch_spr_home_language(2025, level = "district") %>%
#'   filter(is_state) %>%
#'   arrange(desc(percent_of_students)) %>%
#'   select(home_language, percent_of_students)
#'
#' # Schools with the highest Spanish home-language share
#' fetch_spr_home_language(2025) %>%
#'   filter(is_school, home_language == "Spanish") %>%
#'   slice_max(percent_of_students, n = 10) %>%
#'   select(district_name, school_name, percent_of_students)
#' }
fetch_spr_home_language <- function(end_year, level = "school") {
  if (end_year < 2018) {
    stop(
      "SPR home-language enrollment data is available for end_year >= 2018. ",
      "The SY2016-17 EnrollmentByHomeLanguage sheet omits the ",
      "county/district/school name columns.",
      call. = FALSE
    )
  }

  df <- fetch_spr_data("EnrollmentByHomeLanguage", end_year, level)
  df <- filter_spr_to_year(df, end_year)

  if ("percent_of_students" %in% names(df)) {
    df$percent_of_students <- spr_value_numeric(df$percent_of_students)
  }

  df %>%
    dplyr::select(
      end_year,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      dplyr::any_of("school_year"),
      home_language, percent_of_students,
      is_state, is_county, is_district, is_school,
      is_charter, is_charter_sector, is_allpublic
    )
}


#' Fetch NAEP Achievement Results
#'
#' Downloads the \code{NAEP} sheet from the redesigned 2024-25 School
#' Performance Reports (District/State database only). This is the National
#' Assessment of Educational Progress: the percentage of New Jersey (and,
#' for comparison, national) students at each achievement level (Below Basic,
#' Basic, Proficient, Advanced) for 4th- and 8th-grade reading and mathematics,
#' across the NAEP administration years reported in the workbook.
#'
#' @details
#' NAEP is a state/national summary table with no county/district/school
#' breakdown, so this function returns no CDS identifiers or aggregation flags.
#' The \code{state_nation} column distinguishes \code{"New Jersey"} from
#' \code{"Nation"}; \code{test_year} is the NAEP administration year (NAEP is
#' given periodically, so multiple years appear). The four achievement-level
#' columns are returned numeric on a 0-100 scale.
#'
#' \strong{Supported years:} \code{end_year >= 2017}. Always reads the
#' District/State database (the School database has no NAEP sheet). Before the
#' 2024-25 redesign the sheet used a leaner layout (\code{Year}, \code{Test},
#' \code{Grade} and the four achievement levels) with no student-group
#' breakdown; this function maps it to the redesigned shape: \code{Year ->
#' test_year}, \code{Test -> subject}, the legacy \code{"State (NJ)"} label is
#' normalized to \code{"New Jersey"}, and \code{student_group} is set to the
#' constant \code{"All Students"} (the legacy sheet reports the all-students
#' summary only; the per-subgroup breakdown was added in 2024-25).
#'
#' @param end_year A school year (2017-2025). Year is the end of the academic
#'   year - e.g. the 2024-25 school year is \code{end_year} 2025. Note this is
#'   the SPR publication year, not the NAEP administration year (see
#'   \code{test_year}).
#'
#' @return Data frame with end_year (the SPR publication year), test_year (the
#'   NAEP administration year), state_nation, subject, grade, student_group, and
#'   the achievement-level percentages below_basic, basic, proficient, advanced.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # NAEP results as published in the 2024-25 SPR
#' naep <- fetch_spr_naep(2025)
#'
#' # NAEP as published in an earlier SPR (all-students summary only)
#' naep_2024 <- fetch_spr_naep(2024)
#'
#' # New Jersey vs. the nation, Grade 4 Math, most recent administration
#' library(dplyr)
#' fetch_spr_naep(2025) %>%
#'   filter(subject == "Mathematics", grade == "4",
#'          student_group == "All Students") %>%
#'   filter(test_year == max(test_year)) %>%
#'   select(state_nation, below_basic, basic, proficient, advanced)
#' }
fetch_spr_naep <- function(end_year) {
  if (end_year < 2017) {
    stop("NAEP data is available for end_year >= 2017.", call. = FALSE)
  }

  df <- fetch_spr_sheet_raw("NAEP", end_year, level = "district")

  # Pre-2025 layout: Year | StateNation | Test | Grade | <achievement levels>,
  # with no Subject or StudentGroup column. Map it onto the redesigned shape.
  if (!"test_year" %in% names(df) && "year" %in% names(df)) {
    df <- dplyr::rename(df, test_year = "year")
  }
  if (!"subject" %in% names(df) && "test" %in% names(df)) {
    df <- dplyr::rename(df, subject = "test")
  }
  if (!"student_group" %in% names(df)) {
    # The legacy sheet reports the all-students summary only (the per-subgroup
    # breakdown was added in the 2024-25 redesign).
    df$student_group <- "All Students"
  }
  # Normalize the legacy state label to the redesigned form.
  if ("state_nation" %in% names(df)) {
    df$state_nation[df$state_nation == "State (NJ)"] <- "New Jersey"
  }

  # Drop the trailing "end of worksheet" sentinel and any all-blank rows.
  df <- df %>%
    dplyr::filter(
      !is.na(test_year),
      !grepl("end of worksheet", test_year, ignore.case = TRUE)
    )

  # test_year is the NAEP administration year; store it as an integer.
  df$test_year <- suppressWarnings(as.integer(df$test_year))
  df <- df %>% dplyr::filter(!is.na(test_year))

  for (col in intersect(c("below_basic", "basic", "proficient", "advanced"),
                        names(df))) {
    df[[col]] <- spr_value_numeric(df[[col]])
  }

  df %>%
    dplyr::select(
      end_year, test_year, state_nation, subject, grade, student_group,
      below_basic, basic, proficient, advanced
    )
}


# ==============================================================================
# Expanded Staff Sheets
# ==============================================================================
#
# The redesigned 2024-25 (end_year 2025) SPR databases broke staffing detail out
# across several sheets. The fetchers below expose them; the "years" note marks
# how far each one has been extended backward into the pre-redesign databases
# (see each function's docs for the mapping / granularity caveats):
#
#   AdministratorsExperience       -> administrator experience distribution (2025+)
#   StaffCounts                    -> staff counts by role (2021+)
#   TeachersAdminsDemoSubjectArea  -> teacher demographics by subject area (2025+)
#   TeachersAdminsEducation        -> teacher/admin highest-degree distribution
#                                     (2018+; legacy TeachersAdminsLevelOfEducation)
#   TeachersAdminsOneYearRetention -> one-year retention rates
#                                     (2018+ district; 2025+ school)
#   TeacherExperienceSubjArea      -> teacher experience/degree by subject area (2025+)
#   StatewideEducatorEquity (D/S)  -> statewide out-of-field / equity metrics (2025+)
#
# A note on privacy ranges: for the by-subject-area demographic sheet, NJ DOE
# reports small-cell percentages as ranges (e.g. "70-80%", "<=10%"). Those
# columns are kept as character to preserve the published values exactly rather
# than coercing a range to a single fabricated number.
#
# ==============================================================================

#' Blank out the "no data available" sentinel in a character column
#'
#' Several 2024-25 staff sheets use the literal phrase \dQuote{There is no data
#' available for this school year.} in place of a value. For character columns
#' (where it cannot be caught by numeric coercion) this maps that sentinel to
#' \code{NA} while leaving every other value untouched.
#'
#' @param x A character vector.
#' @return The vector with the no-data sentinel set to \code{NA}.
#' @keywords internal
spr_blank_no_data <- function(x) {
  if (!is.character(x)) return(x)
  x[grepl("no data available", x, ignore.case = TRUE)] <- NA_character_
  x
}


#' Fetch Administrator Experience
#'
#' Downloads the \code{AdministratorsExperience} sheet from the redesigned
#' 2024-25 School Performance Reports: administrator counts and experience
#' summaries for the entity alongside the statewide comparison.
#'
#' @details
#' Reported measures (each with a \code{*_school} entity value and a
#' \code{*_state} statewide comparison): administrator count, average years of
#' experience in public schools, average years of experience in the district,
#' and the number and percentage of administrators with 4+ years of experience.
#' All value columns are returned numeric (thousands commas and percent signs
#' stripped; suppressed cells set to \code{NA}).
#'
#' \strong{Supported years:} only \code{end_year >= 2025}.
#'
#' @param end_year A school year. Only \code{2025} (SY2024-25) and later are
#'   supported.
#' @param level One of \code{"school"} or \code{"district"}.
#'
#' @return Data frame with entity identifiers, the administrator experience
#'   measures, and the aggregation flags.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' admin <- fetch_spr_admin_experience(2025)
#'
#' # Schools where every administrator has 4+ years of experience
#' library(dplyr)
#' fetch_spr_admin_experience(2025) %>%
#'   filter(is_school, percentage_admins_with_4_or_more_years_exp_school == 100) %>%
#'   select(district_name, school_name, admin_count_school)
#'
#' # District-level average administrator experience
#' fetch_spr_admin_experience(2025, level = "district") %>%
#'   filter(is_district) %>%
#'   select(district_name, average_years_exp_in_public_schools_school)
#' }
fetch_spr_admin_experience <- function(end_year, level = "school") {
  spr_require_redesign(end_year, "administrator experience data")

  df <- fetch_spr_data("AdministratorsExperience", end_year, level)

  # Every non-identifier column on this sheet is a numeric measure. Convert
  # those, leaving CDS identifiers and aggregation flags untouched (a name-
  # pattern match would wrongly catch "county_id"/"county_name" via "count").
  id_flag_cols <- c(
    "county_id", "county_name", "district_id", "district_name",
    "school_id", "school_name", "end_year",
    "is_state", "is_county", "is_district", "is_school",
    "is_charter", "is_charter_sector", "is_allpublic"
  )
  num_cols <- setdiff(names(df), id_flag_cols)
  for (col in num_cols) df[[col]] <- spr_value_numeric(df[[col]])

  df
}


#' Fetch Staff Counts
#'
#' Downloads the \code{StaffCounts} sheet from the redesigned 2024-25 School
#' Performance Reports: counts of staff by role (\code{staff_category}, e.g.
#' Administrators, Teachers, Child Study Team Members) for the school, district,
#' and state.
#'
#' @details
#' The three count columns (\code{school_total_staff},
#' \code{district_total_staff_members}, \code{state_total_staff_members}) are
#' returned numeric (thousands commas stripped; cells reading \dQuote{There is no
#' data available for this school year.} set to \code{NA}).
#'
#' \strong{Supported years:} \code{end_year >= 2021}. The \code{StaffCounts}
#' sheet first appears in the SY2020-21 SPR and has the same layout through the
#' redesign. Earlier databases have no equivalent sheet.
#'
#' @param end_year A school year (2021-2025). Year is the end of the academic
#'   year - e.g. the 2020-21 school year is \code{end_year} 2021.
#' @param level One of \code{"school"} or \code{"district"}.
#'
#' @return Data frame with entity identifiers, staff_category, the three staff
#'   count columns, and the aggregation flags.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' staff <- fetch_spr_staff_counts(2025)
#'
#' # The same counts back to SY2020-21
#' staff_2021 <- fetch_spr_staff_counts(2021)
#'
#' # Teacher counts by school
#' library(dplyr)
#' fetch_spr_staff_counts(2025) %>%
#'   filter(is_school, staff_category == "Teachers") %>%
#'   select(district_name, school_name, school_total_staff)
#'
#' # Statewide staff by role
#' fetch_spr_staff_counts(2025, level = "district") %>%
#'   filter(is_state) %>%
#'   select(staff_category, state_total_staff_members)
#' }
fetch_spr_staff_counts <- function(end_year, level = "school") {
  if (end_year < 2021) {
    stop(
      "staff counts data is available for end_year >= 2021. The StaffCounts ",
      "sheet first appears in the SY2020-21 School Performance Reports.",
      call. = FALSE
    )
  }

  df <- fetch_spr_data("StaffCounts", end_year, level)

  count_cols <- grep("total_staff", names(df), value = TRUE)
  for (col in count_cols) df[[col]] <- spr_value_numeric(df[[col]])

  df
}


#' Fetch Teacher Demographics by Subject Area
#'
#' Downloads the \code{TeachersAdminsDemoSubjectArea} sheet from the redesigned
#' 2024-25 School Performance Reports: teacher racial/ethnic and gender
#' composition by subject area.
#'
#' @details
#' \code{teacher_count} is returned numeric. The racial/ethnic and gender
#' percentage columns are kept as \strong{character} on purpose: NJ DOE reports
#' small-cell percentages as privacy-protected ranges (e.g. \code{"70-80\%"},
#' \code{"<=10\%"}), and coercing a range to a single number would fabricate
#' precision. Exact percentages (e.g. \code{"91.9\%"}) are likewise preserved as
#' published. Cells reading \dQuote{There is no data available for this school
#' year.} are set to \code{NA}. The \code{TwoorMoreRaces} column is renamed to
#' \code{two_or_more_races}.
#'
#' \strong{Supported years:} only \code{end_year >= 2025}.
#'
#' @param end_year A school year. Only \code{2025} (SY2024-25) and later are
#'   supported.
#' @param level One of \code{"school"} or \code{"district"}.
#'
#' @return Data frame with entity identifiers, subject_area, teacher_count, the
#'   racial/ethnic and gender composition columns (character), and the
#'   aggregation flags.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' demo <- fetch_spr_staff_demo_subject(2025)
#'
#' # All-teacher racial composition for a school
#' library(dplyr)
#' fetch_spr_staff_demo_subject(2025) %>%
#'   filter(is_school, subject_area == "All Teachers") %>%
#'   select(district_name, school_name, white, black_african_american,
#'          hispanic_latino, asian)
#' }
fetch_spr_staff_demo_subject <- function(end_year, level = "school") {
  spr_require_redesign(end_year, "teacher demographics by subject area data")

  df <- fetch_spr_data("TeachersAdminsDemoSubjectArea", end_year, level)

  if ("teacher_count" %in% names(df)) {
    df$teacher_count <- spr_value_numeric(df$teacher_count)
  }

  # Normalize the awkward snake-cased race column name.
  names(df)[names(df) == "twoor_more_races"] <- "two_or_more_races"

  # Composition columns stay character (ranges + exact percents); only the
  # "no data" sentinel is mapped to NA.
  demo_cols <- intersect(
    c("american_indian_alaska_native", "asian", "black_african_american",
      "hispanic_latino", "native_hawaiian_pacific_islander",
      "two_or_more_races", "white", "female", "male",
      "non_binary_undesignated_gender"),
    names(df)
  )
  for (col in demo_cols) df[[col]] <- spr_blank_no_data(df[[col]])

  df
}


#' Fetch Teacher and Administrator Education
#'
#' Downloads the \code{TeachersAdminsEducation} sheet from the redesigned
#' 2024-25 School Performance Reports: the highest-degree distribution
#' (Bachelor's, Master's, Doctoral) for teachers and for administrators.
#'
#' @details
#' \code{teachers_admins} labels the group (\code{"Teachers"} or
#' \code{"Administrators"}). The degree columns are returned numeric percentages
#' (suppressed/non-numeric cells, including the administrator note that
#' administrators must hold a Master's or higher, set to \code{NA}).
#'
#' \strong{Supported years:} \code{end_year >= 2018}. Before the 2024-25
#' redesign this sheet was named \code{TeachersAdminsLevelOfEducation}; the
#' Bachelor's/Master's/Doctoral layout is identical from SY2017-18 on (this
#' function selects the right sheet by year). The legacy sheet labels the
#' administrator row \code{"Admin"}; it is normalized to \code{"Administrators"}
#' for cross-year consistency. The SY2016-17 sheet uses a different long-format
#' layout and is not supported.
#'
#' @param end_year A school year (2018-2025). Year is the end of the academic
#'   year - e.g. the 2020-21 school year is \code{end_year} 2021.
#' @param level One of \code{"school"} or \code{"district"}.
#'
#' @return Data frame with entity identifiers, teachers_admins, bachelors,
#'   masters, doctoral, and the aggregation flags.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' edu <- fetch_spr_staff_education(2025)
#'
#' # The same degree distribution back to SY2017-18
#' edu_2018 <- fetch_spr_staff_education(2018)
#'
#' # Share of teachers with a Master's degree, by school
#' library(dplyr)
#' fetch_spr_staff_education(2025) %>%
#'   filter(is_school, teachers_admins == "Teachers") %>%
#'   select(district_name, school_name, masters, doctoral)
#' }
fetch_spr_staff_education <- function(end_year, level = "school") {
  if (end_year < 2018) {
    stop(
      "teacher/administrator education data is available for end_year >= 2018. ",
      "The SY2016-17 sheet uses a different long-format layout.",
      call. = FALSE
    )
  }

  # The sheet was renamed TeachersAdminsLevelOfEducation -> TeachersAdminsEducation
  # in the 2024-25 redesign; the degree-column layout is otherwise identical.
  sheet_name <- spr_sheet_for_year(
    end_year, "TeachersAdminsLevelOfEducation", "TeachersAdminsEducation"
  )
  df <- fetch_spr_data(sheet_name, end_year, level)

  # Legacy sheets label the administrator row "Admin"; the 2024-25 sheet uses
  # "Administrators". Normalize so a single value works across all years.
  if ("teachers_admins" %in% names(df)) {
    df$teachers_admins[df$teachers_admins == "Admin"] <- "Administrators"
  }

  for (col in intersect(c("bachelors", "masters", "doctoral"), names(df))) {
    df[[col]] <- spr_value_numeric(df[[col]])
  }

  df
}


#' Fetch Teacher and Administrator One-Year Retention
#'
#' Downloads the \code{TeachersAdminsOneYearRetention} sheet from the redesigned
#' 2024-25 School Performance Reports: the one-year retention rate for teachers
#' and for administrators, for the district and the state.
#'
#' @details
#' \code{teachers_admins} labels the group. \code{retention_pct_district} and
#' \code{retention_pct_state} are returned numeric percentages (suppressed cells
#' set to \code{NA}).
#'
#' \strong{Supported years:} \code{level = "district"} is supported for
#' \code{end_year >= 2018}; \code{level = "school"} only for
#' \code{end_year >= 2025}. The retention measure is reported at
#' district/state granularity (no \code{SchoolCode}) in every SPR database
#' through SY2023-24; the 2024-25 redesign was the first to add per-school
#' retention rows. For earlier years, use \code{level = "district"}. (The
#' SY2016-17 sheet additionally omits entity-name columns and is not supported.)
#'
#' @param end_year A school year. \code{level = "district"} accepts 2018-2025;
#'   \code{level = "school"} accepts 2025 only. Year is the end of the academic
#'   year - e.g. the 2020-21 school year is \code{end_year} 2021.
#' @param level One of \code{"school"} or \code{"district"}.
#'
#' @return Data frame with entity identifiers, teachers_admins,
#'   retention_pct_district, retention_pct_state, and the aggregation flags.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' ret <- fetch_spr_staff_retention(2025)
#'
#' # Districts with the lowest teacher retention
#' library(dplyr)
#' fetch_spr_staff_retention(2025, level = "district") %>%
#'   filter(is_district, teachers_admins == "Teachers") %>%
#'   slice_min(retention_pct_district, n = 10) %>%
#'   select(district_name, retention_pct_district, retention_pct_state)
#'
#' # District/state retention back to SY2017-18
#' ret_2018 <- fetch_spr_staff_retention(2018, level = "district")
#' }
fetch_spr_staff_retention <- function(end_year, level = "school") {
  if (end_year < 2025 && level == "school") {
    stop(
      "school-level staff retention is available only for end_year >= 2025. ",
      "Through SY2023-24 the TeachersAdminsOneYearRetention sheet is reported ",
      "at district/state granularity - use level = 'district' for earlier years.",
      call. = FALSE
    )
  }
  if (end_year < 2018) {
    stop(
      "staff retention data is available for end_year >= 2018. The SY2016-17 ",
      "sheet omits entity-name columns.",
      call. = FALSE
    )
  }

  df <- fetch_spr_data("TeachersAdminsOneYearRetention", end_year, level)

  for (col in intersect(c("retention_pct_district", "retention_pct_state"),
                        names(df))) {
    df[[col]] <- spr_value_numeric(df[[col]])
  }

  df
}


#' Fetch Teacher Experience by Subject Area
#'
#' Downloads the \code{TeacherExperienceSubjArea} sheet from the redesigned
#' 2024-25 School Performance Reports: by subject area, the percentage of
#' teachers with 4+ years of experience and the highest-degree distribution.
#'
#' @details
#' \code{teacher_count} is returned numeric. \code{fourormoreyearsexp},
#' \code{bachelors}, \code{masters}, and \code{doctoral} are returned numeric
#' percentages (cells reading \dQuote{There is no data available for this school
#' year.} set to \code{NA}).
#'
#' \strong{Supported years:} only \code{end_year >= 2025}.
#'
#' @param end_year A school year. Only \code{2025} (SY2024-25) and later are
#'   supported.
#' @param level One of \code{"school"} or \code{"district"}.
#'
#' @return Data frame with entity identifiers, subject_area, teacher_count,
#'   fourormoreyearsexp, bachelors, masters, doctoral, and the aggregation flags.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' exp <- fetch_spr_teacher_exp_subject(2025)
#'
#' # Experience of math teachers by school
#' library(dplyr)
#' fetch_spr_teacher_exp_subject(2025) %>%
#'   filter(is_school, subject_area == "Mathematics") %>%
#'   select(district_name, school_name, teacher_count, fourormoreyearsexp)
#' }
fetch_spr_teacher_exp_subject <- function(end_year, level = "school") {
  spr_require_redesign(end_year, "teacher experience by subject area data")

  df <- fetch_spr_data("TeacherExperienceSubjArea", end_year, level)

  for (col in intersect(
    c("teacher_count", "fourormoreyearsexp", "bachelors", "masters", "doctoral"),
    names(df))) {
    df[[col]] <- spr_value_numeric(df[[col]])
  }

  df
}


#' Fetch Statewide Educator Equity Metrics
#'
#' Downloads the \code{StatewideEducatorEquity} sheet from the redesigned
#' 2024-25 School Performance Reports (District/State database only). This is a
#' statewide summary table comparing high-need student groups (economically
#' disadvantaged students in Title I schools, minority students in Title I
#' schools) against their counterparts on educator-equity measures such as the
#' share of students taught by out-of-field or inexperienced teachers.
#'
#' @details
#' This is a statewide summary table with no county/district/school identifiers,
#' so it returns no CDS columns or aggregation flags. Each row is a
#' \code{category} (the equity measure) for a set of \code{classes_included}
#' (e.g. Core Classes vs. All Classes); the five metric columns hold the
#' proportion (0-1 scale, as published) for All Students and for each compared
#' student group.
#'
#' \strong{Supported years:} only \code{end_year >= 2025}. Always reads the
#' District/State database.
#'
#' @param end_year A school year. Only \code{2025} (SY2024-25) and later are
#'   supported.
#'
#' @return Data frame with end_year, school_year, category, classes_included,
#'   and the metric columns (all_students plus the compared student groups).
#'
#' @export
#'
#' @examples
#' \dontrun{
#' equity <- fetch_spr_educator_equity(2025)
#'
#' # Out-of-field teaching gap, core classes
#' library(dplyr)
#' fetch_spr_educator_equity(2025) %>%
#'   filter(grepl("out-of-field", category, ignore.case = TRUE),
#'          classes_included == "Core Classes") %>%
#'   select(category, all_students,
#'          economically_disadvantaged_students_in_title_i_schools)
#' }
fetch_spr_educator_equity <- function(end_year) {
  spr_require_redesign(end_year, "statewide educator equity data")

  df <- fetch_spr_sheet_raw("StatewideEducatorEquity", end_year,
                            level = "district")

  # Drop any trailing sentinel / all-blank rows.
  if ("school_year" %in% names(df)) {
    df <- df %>%
      dplyr::filter(
        !is.na(school_year),
        !grepl("end of worksheet", school_year, ignore.case = TRUE)
      )
  }

  metric_cols <- setdiff(
    names(df), c("end_year", "school_year", "category", "classes_included")
  )
  for (col in metric_cols) df[[col]] <- spr_value_numeric(df[[col]])

  df
}
