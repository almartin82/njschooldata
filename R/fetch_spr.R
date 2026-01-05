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
