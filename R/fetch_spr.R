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
#' @param end_year A school year (2017-2024). Year is the end of the academic
#'   year - eg 2020-21 school year is end_year '2021'.
#' @param level One of "school" or "district". Determines which database file
#'   to download.
#' @return URL string
#' @keywords internal
get_spr_url <- function(end_year, level = "school") {
  valid_years <- 2017:2024

  if (!end_year %in% valid_years) {
    stop(paste0(
      "SPR data available for years 2017-2024. ",
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
    tolower(group) %in% c("schoolwide", "districtwide", "statewide") ~ "total population",
    tolower(group) == "american indian or alaska native" ~ "american indian",
    tolower(group) == "black or african american" ~ "black",
    tolower(group) == "economically disadvantaged students" ~ "economically disadvantaged",
    tolower(group) %in% c("english learners", "multilingual learners") ~ "limited english proficiency",
    tolower(group) == "two or more races" ~ "multiracial",
    tolower(group) == "native hawaiian or other pacific islander" ~ "pacific islander",
    tolower(group) == "students with disabilities" ~ "students with disability",
    tolower(group) == "students with disability" ~ "students with disability",
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
#' @param end_year A school year (2017-2024). Year is the end of the academic
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

  # Read specific sheet
  df <- tryCatch(
    readxl::read_excel(
      path = tname,
      sheet = sheet_name,
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

  # Add end_year
  df$end_year <- end_year

  # Clean subgroup if present (after clean_name_vector, it's student_group)
  if ("student_group" %in% names(df)) {
    df <- df %>% dplyr::rename(subgroup = student_group)
  }

  if ("subgroup" %in% names(df)) {
    df$subgroup <- clean_spr_subgroups(df$subgroup)
  }

  # Add aggregation flags
  df <- df %>%
    dplyr::mutate(
      is_state = district_id == "9999" & county_id == "99",
      is_county = district_id == "9999" & !county_id == "99",
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
  # Main sheet: "Chronic_Abs_Pct"
  # Grade-level sheet: "SchoolPercent"
  rate_cols <- grep("chronic|absent|percent", names(df), value = TRUE, ignore.case = TRUE)

  # Filter to find the actual rate column (exclude names with "Number", "Count", etc.)
  rate_cols <- rate_cols[!grepl("number|count|enrollment|n_|state", rate_cols, ignore.case = TRUE)]

  # Prefer Chronic_Abs_Pct over SchoolPercent if both exist
  if ("chronic_abs_pct" %in% names(df)) {
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
#' @param end_year A school year (2017-2024). Year is the end of the academic
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
  # Use generic extractor
  df <- fetch_spr_data(
    sheet_name = "ChronicAbsenteeism",
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
#' @param end_year A school year (2017-2024). Year is the end of the academic
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
  # 2018-2019: ChronicAbsByGrade
  # 2020+: ChronicAbsenteeismByGrade
  sheet_name <- if (end_year %in% c(2018, 2019)) {
    "ChronicAbsByGrade"
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
#' @param end_year A school year (2017-2024). Year is the end of the academic
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
#' @param end_year A school year (2017-2024). Year is the end of the academic
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
#' @param end_year A school year (2017-2024)
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
#' @param end_year A school year (2017-2024)
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
#' Downloads discipline data (suspensions/expulsions) from SPR database.
#'
#' @param end_year A school year (2017-2024)
#' @param level One of "school" or "district"
#'
#' @return Data frame with disciplinary actions
#' @export
#' @examples \dontrun{
#' discipline <- fetch_disciplinary_removals(2024)
#' }
fetch_disciplinary_removals <- function(end_year, level = "school") {
  df <- fetch_spr_data("DisciplinaryRemovals", end_year, level)
  df
}


#' Fetch Violence/Vandalism/HIB Data
#'
#' Downloads incident data from SPR database.
#'
#' @param end_year A school year (2017-2024)
#' @param level One of "school" or "district"
#'
#' @return Data frame with incident counts
#' @export
#' @examples \dontrun{
#' incidents <- fetch_violence_vandalism_hib(2024)
#' }
fetch_violence_vandalism_hib <- function(end_year, level = "school") {
  df <- fetch_spr_data("ViolenceVandalismHIBSubstanceOf", end_year, level)
  df
}


#' Fetch Student-Staff Ratio Data
#'
#' Downloads student-to-staff ratio data from SPR database.
#'
#' @param end_year A school year (2017-2024)
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
#' @param end_year A school year (2017-2024)
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
#' @param end_year A school year (2017-2024)
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


#' Fetch ESSA Accountability Status
#'
#' Downloads ESSA accountability ratings from SPR database.
#'
#' @param end_year A school year (2017-2024)
#' @param level One of "school" or "district"
#'
#' @return Data frame with ESSA status ratings
#' @export
#' @examples \dontrun{
#' essa <- fetch_essa_status(2024)
#' }
fetch_essa_status <- function(end_year, level = "school") {
  df <- fetch_spr_data("ESSAAccountabilityStatus", end_year, level)
  df
}


#' Fetch ESSA Accountability Progress
#'
#' Downloads ESSA accountability progress indicators from SPR database.
#' Includes metrics on academic proficiency, growth, graduation rates, and
#' chronic absenteeism.
#'
#' @param end_year A school year (2017-2024)
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
  df <- fetch_spr_data("ESSAAccountabilityProgress", end_year, level)
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

    # Filter to specific school if requested
    if (!is.null(school_id)) {
      df <- df %>%
        dplyr::filter(school_id == school_id)
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
