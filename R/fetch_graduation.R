# ==============================================================================
# Graduation Data Fetching Functions
# ==============================================================================
#
# This file contains functions for downloading graduation data from the
# NJ Department of Education website.
#
# ==============================================================================

#' Get a raw graduation file from the NJ website
#'
#' @param end_year End of the academic year - eg 2006-07 is 2007.
#' Valid values are 1998-2025.
#' @param methodology One of c('4 year', '5 year')
#' @return data.frame with raw data from state file
#' @keywords internal
get_raw_grad_file <- function(end_year, methodology = "4 year") {

  if (end_year < 1998 | end_year > 2025) {
    stop("year not yet supported. Valid years are 1998-2025.")
  }

  # In 2026 NJ DOE retired the /schoolperformance/grad/ tree (data/ and docs/)
  # and consolidated every cohort file under /spr/adddata/doc/acgrdocs/. Most
  # filenames are unchanged; a few lost their spaces. URLs below point at the
  # current acgrdocs location.

  ########## 4 year ##########
  if (methodology == "4 year") {
    # Before cohort grad rate
    if (end_year <= 2010) {
      grd_constant <- "https://www.state.nj.us/education/data/grd/grd"
      grate_file <- paste0(grd_constant, substr(end_year + 1, 3, 4), "/grd.zip") %>%
        unzipper()

      if (grepl(".csv", tolower(grate_file))) {
        df <- readr::read_csv(grate_file, show_col_types = FALSE)
      } else if (grepl(".xls", tolower(grate_file))) {
        df <- readxl::read_xls(grate_file)
      }

      # 2011 is insane, no other way to describe it
    } else if (end_year == 2011) {
      grate_url <- "https://www.nj.gov/education/spr/adddata/doc/acgrdocs/ACGR2012_gradrate.xls"
      grate_file <- tempfile(fileext = ".xls")
      httr::GET(url = grate_url, httr::write_disk(grate_file))
      df <- readxl::read_excel(grate_file)

      grate_indices <- c(1:7, 9)
      df <- df[, grate_indices] %>%
        dplyr::mutate("GRADUATED_COUNT" = NA_integer_)

      # 2012 they transition the format but post it in a weird location
    } else if (end_year == 2012) {
      grate_url <- "https://www.nj.gov/education/spr/adddata/doc/acgrdocs/ACGR2012_grd.xls"
      grate_file <- tempfile(fileext = ".xls")
      httr::GET(url = grate_url, httr::write_disk(grate_file))
      df <- readxl::read_excel(grate_file)

      # 2013 on is the cohort grad rate era
    } else if (end_year >= 2013 & end_year <= 2017) {
      basic_suffix <- "_4Year.xlsx"
      num_skip <- 0

      grate_url <- paste0(
        "https://www.nj.gov/education/spr/adddata/doc/acgrdocs/ACGR",
        end_year, basic_suffix
      )
      grate_file <- tempfile(fileext = ".xlsx")
      httr::GET(url = grate_url, httr::write_disk(grate_file))
      df <- readxl::read_excel(grate_file, skip = num_skip)

      # Starting in 2018 the URLs are inconsistent, so hard code them
    } else if (end_year == 2018) {
      grate_url <- "https://www.nj.gov/education/spr/adddata/doc/acgrdocs/ACGR2018_4YearGraduation.xlsx"
      num_skip <- 3
      grate_file <- tempfile(fileext = ".xlsx")
      httr::GET(url = grate_url, httr::write_disk(grate_file))
      df <- readxl::read_excel(grate_file, skip = num_skip)
    } else if (end_year == 2019) {
      grate_url <- "https://www.nj.gov/education/spr/adddata/doc/acgrdocs/ACGR2019_Cohort2019_4-YearAdjustedCohortGraduationRatesByStudentGroup.xlsx"
      num_skip <- 3
      grate_file <- tempfile(fileext = ".xlsx")
      httr::GET(url = grate_url, httr::write_disk(grate_file))
      df <- readxl::read_excel(grate_file, skip = num_skip)
    } else if (end_year == 2020) {
      # 2020+ files include graduate counts (hence the larger header skip)
      grate_url <- "https://www.nj.gov/education/spr/adddata/doc/acgrdocs/Cohort2020_4YearAdjustedCohortGraduationRatesandCountsbyStudentGroup.xlsx"
      num_skip <- 5
      grate_file <- tempfile(fileext = ".xlsx")
      httr::GET(url = grate_url, httr::write_disk(grate_file))
      df <- readxl::read_excel(grate_file, skip = num_skip)
    } else if (end_year == 2021) {
      # 2020+ files include graduate counts (hence the larger header skip)
      grate_url <- "https://www.nj.gov/education/spr/adddata/doc/acgrdocs/Cohort2021_4YearAdjustedCohortGraduationRatesandCountsbyStudentGroup.xlsx"
      num_skip <- 5
      grate_file <- tempfile(fileext = ".xlsx")
      httr::GET(url = grate_url, httr::write_disk(grate_file))
      df <- readxl::read_excel(grate_file, skip = num_skip)
    } else if (end_year == 2022) {
      grate_url <- "https://www.nj.gov/education/spr/adddata/doc/acgrdocs/Cohort2022_4YearAdjustedCohortGraduationRatesandCountsbyStudentGroup.xlsx"
      num_skip <- 5
      grate_file <- tempfile(fileext = ".xlsx")
      httr::GET(url = grate_url, httr::write_disk(grate_file))
      df <- readxl::read_excel(grate_file, skip = num_skip)
    } else if (end_year == 2023) {
      grate_url <- "https://www.nj.gov/education/spr/adddata/doc/acgrdocs/Cohort2023_4YearAdjustedCohortGraduationRatesbyStudentGroup.xlsx"
      num_skip <- 5
      grate_file <- tempfile(fileext = ".xlsx")
      httr::GET(url = grate_url, httr::write_disk(grate_file))
      df <- readxl::read_excel(grate_file, skip = num_skip)
    } else if (end_year == 2024) {
      grate_url <- "https://www.nj.gov/education/spr/adddata/doc/acgrdocs/Cohort2024_4YearAdjustedCohortGraduationRatesbyStudentGroup.xlsx"
      num_skip <- 5
      grate_file <- tempfile(fileext = ".xlsx")
      httr::GET(url = grate_url, httr::write_disk(grate_file))
      df <- readxl::read_excel(grate_file, skip = num_skip)
    } else if (end_year == 2025) {
      # Cohort2025 keeps the row-6 header (num_skip = 5) but renamed columns:
      # "Graduation Rate" -> "Adjusted Cohort Graduation Rate",
      # "Cohort Count" -> "Adjusted Cohort Count" (handled in process_grate()).
      grate_url <- "https://www.nj.gov/education/spr/adddata/doc/acgrdocs/Cohort2025_4YearAdjustedCohortGraduationRatesbyStudentGroup.xlsx"
      num_skip <- 5
      grate_file <- tempfile(fileext = ".xlsx")
      httr::GET(url = grate_url, httr::write_disk(grate_file))
      df <- readxl::read_excel(grate_file, skip = num_skip)
    }

    ########## 5 year ##########
  } else if (methodology == "5 year") {

    if (end_year < 2012) {
      stop(paste0("5 year grad rate not available for ending year ", end_year))
    } else if (end_year == 2012) {
      grate_url <- "https://www.nj.gov/education/spr/adddata/doc/acgrdocs/ACGR2013_4And5YearCohort12.xlsx"
      num_skip <- 0
    } else if (end_year == 2013) {
      grate_url <- "https://www.nj.gov/education/spr/adddata/doc/acgrdocs/ACGR2014_4And5YearCohort13.xlsx"
      num_skip <- 0
    } else if (end_year == 2014) {
      grate_url <- "https://www.nj.gov/education/spr/adddata/doc/acgrdocs/ACGR2015_4And5YearCohort14.xlsx"
      num_skip <- 0
    } else if (end_year == 2015) {
      grate_url <- "https://www.nj.gov/education/spr/adddata/doc/acgrdocs/ACGR2016_4And5YearCohort14.xlsx"
      num_skip <- 0
    } else if (end_year == 2016) {
      grate_url <- "https://www.nj.gov/education/spr/adddata/doc/acgrdocs/ACGR2017_4And5YearCohort.xlsx"
      num_skip <- 0
    } else if (end_year == 2017) {
      grate_url <- "https://www.nj.gov/education/spr/adddata/doc/acgrdocs/ACGR2018_4and5YearGraduationRates.xlsx"
      num_skip <- 3
    } else if (end_year == 2018) {
      grate_url <- "https://www.nj.gov/education/spr/adddata/doc/acgrdocs/ACGR2019_Cohort20184-YearAnd5-YearAdjustedCohortGraduationRates.xlsx"
      num_skip <- 3
    } else if (end_year == 2019) {
      grate_url <- "https://www.nj.gov/education/spr/adddata/doc/acgrdocs/Cohort2019_4-YearAnd5-YearAdjustedCohortGraduationRates.xlsx"
      num_skip <- 3
    }

    grate_file <- tempfile(fileext = ".xlsx")
    httr::GET(url = grate_url, httr::write_disk(grate_file))
    df <- readxl::read_excel(grate_file, skip = num_skip)
  } else {
    stop(paste0("invalid methodology: ", methodology))
  }

  df$end_year <- end_year

  df
}


#' Get NJ graduation count data
#'
#' @param end_year End of the academic year - eg 2006-07 is 2007.
#' Valid values are 2012-2025.
#' @return dataframe with the number of graduates per school and district
#' @keywords internal
get_grad_count <- function(end_year) {
  if (end_year < 2012 | end_year > 2025) {
    stop(paste0(end_year, " not yet supported. Valid years are 2012-2025."))
  }

  df <- get_raw_grad_file(end_year)

  df %>%
    process_grate(end_year)
}


#' Get NJ graduation rate data
#'
#' @param end_year End of the academic year - 2011-2012 is 2012.
#' Valid values are 2011-2025.
#' @param methodology Character string specifying calculation methodology.
#' One of "4 year" or "5 year".
#' @return dataframe with the number of graduates per school and district
#' @keywords internal
get_grad_rate <- function(end_year, methodology) {
  if (end_year < 2011 | end_year > 2025) {
    stop("year not yet supported. Valid years are 2011-2025.")
  }

  df <- get_raw_grad_file(end_year, methodology) %>%
    dplyr::mutate("methodology" = methodology)

  df %>%
    process_grate(end_year)
}


#' Fetch Grad Counts
#'
#' Downloads and processes graduation count data.
#'
#' @param end_year End of the academic year - eg 2006-07 is 2007.
#' Valid values are 2012-2025.
#' @return dataframe with grad counts
#' @export
#' @examples
#' \dontrun{
#' # Get 2023 graduation counts
#' gcount_2023 <- fetch_grad_count(2023)
#' }
fetch_grad_count <- function(end_year) {
  df <- get_grad_count(end_year) %>%
    process_grad_count(end_year)

  df <- tidy_grad_count(df, end_year)

  df <- id_grad_aggs(df)

  possible_cols <- c(
    "end_year",
    "county_id", "county_name",
    "district_id", "district_name",
    "school_id", "school_name",
    "subgroup",
    "cohort_count", "graduated_count",
    "is_state",
    "is_county",
    "is_district",
    "is_charter_sector",
    "is_allpublic",
    "is_school",
    "is_charter"
  )

  df <- df %>%
    dplyr::select(dplyr::one_of(possible_cols))

  return(df)
}


#' Fetch Grad Rate
#'
#' Downloads and processes graduation rate data.
#'
#' @param end_year End of the academic year - eg 2006-07 is 2007.
#' Valid values are 2011-2025.
#' @param methodology Character string specifying calculation methodology.
#' One of "4 year" or "5 year".
#' @return dataframe with grad rate
#' @export
#' @examples
#' \dontrun{
#' # Get 2023 graduation rates
#' grate_2023 <- fetch_grad_rate(2023)
#'
#' # Get 5-year graduation rates
#' grate_5yr <- fetch_grad_rate(2019, methodology = "5 year")
#' }
fetch_grad_rate <- function(end_year, methodology = "4 year") {
  df <- get_grad_rate(end_year, methodology) %>%
    process_grad_rate(end_year, methodology)

  df <- tidy_grad_rate(df, end_year, methodology)

  df <- id_grad_aggs(df)

  df <- df %>%
    dplyr::select(
      end_year,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      subgroup,
      grad_rate,
      dplyr::one_of("four_yr_grad_rate", "five_yr_grad_rate"),
      cohort_count, graduated_count,
      methodology,
      is_state,
      is_county,
      is_district,
      is_school,
      is_charter,
      is_charter_sector,
      is_allpublic
    )

  return(df)
}


# -----------------------------------------------------------------------------
# 6-Year Graduation Rate Functions (from School Performance Reports database)
# -----------------------------------------------------------------------------

#' Get SPR database URL for 6-year graduation rates
#'
#' Builds the URL for the School Performance Reports database containing
#' 6-year graduation cohort profile data.
#'
#' @param end_year A school year (2021-2025). Year is the end of the academic
#'   year - eg 2020-21 school year is end_year '2021'.
#' @param level One of "school" or "district". Determines which database file
#'   to download.
#' @return URL string
#' @keywords internal
get_spr_6yr_grad_url <- function(end_year, level = "school") {
  valid_years <- c(2021, 2022, 2023, 2024, 2025)
  if (!end_year %in% valid_years) {
    stop(paste0(
      "6-year graduation rate data is available for years: ",
      paste(valid_years, collapse = ", "),
      ". Earlier years do not include 6-year graduation cohort profiles."
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


#' Clean 6-year graduation subgroup names
#'
#' Standardizes subgroup names from the SPR 6-year graduation data to match
#' the naming conventions used elsewhere in the package.
#'
#' @param group Vector of subgroup names
#' @return Vector of cleaned subgroup names
#' @keywords internal
clean_6yr_grad_subgroups <- function(group) {
  dplyr::case_when(
    # 2024-25 SPR uses "All Students" for the total row; earlier years used
    # "Schoolwide"/"Districtwide"
    tolower(group) %in% c("schoolwide", "districtwide", "all students") ~ "total population",
    tolower(group) == "american indian or alaska native" ~ "american indian",
    tolower(group) == "black or african american" ~ "black",
    tolower(group) == "economically disadvantaged students" ~ "economically disadvantaged",
    tolower(group) %in% c("english learners", "multilingual learners") ~ "limited english proficiency",
    tolower(group) %in% c("two or more races") ~ "multiracial",
    # 2024-25 SPR renamed "Hispanic" -> "Hispanic/Latino"
    tolower(group) %in% c("hispanic", "hispanic/latino") ~ "hispanic",
    tolower(group) == "native hawaiian or pacific islander" ~ "pacific islander",
    tolower(group) == "asian, native hawaiian, or pacific islander" ~ "asian",
    tolower(group) == "students with disabilities" ~ "students with disabilities",
    TRUE ~ tolower(group)
  )
}


#' Fetch 6-Year Graduation Rate data
#'
#' Downloads and processes 6-year graduation rate data from the NJ School
#' Performance Reports database. This data shows the percentage of students
#' who graduated within six years of entering high school.
#'
#' The 6-year graduation data is from a different source than the 4-year and
#' 5-year data (SPR database vs ACGR files), which is why it has its own
#' fetch function rather than being an option in \code{fetch_grad_rate()}.
#'
#' @param end_year A school year. Year is the end of the academic year - eg
#'   2020-21 school year is end_year '2021'. Valid values are 2021-2025.
#' @param level One of "school" or "district". "school" returns school-level
#'   data, "district" returns district and state-level data.
#' @return dataframe with 6-year graduation rates including:
#'   \itemize{
#'     \item end_year, county_id, county_name, district_id, district_name
#'     \item school_id, school_name (for school-level data)
#'     \item subgroup - student group (total population, racial/ethnic groups, etc.)
#'     \item grad_rate_6yr - 6-year graduation rate (0-100 scale)
#'     \item continuing_rate - percentage of students still enrolled after 6 years
#'     \item non_continuing_rate - percentage who dropped out or left
#'     \item persistence_rate - graduates + continuing students (high school persistence)
#'     \item Aggregation flags (is_state, is_district, is_school, is_charter)
#'   }
#' @export
#' @examples
#' \dontrun{
#' # Get 2024 school-level 6-year graduation rates
#' grad6_2024 <- fetch_6yr_grad_rate(2024)
#'
#' # Get district-level 6-year graduation rates
#' grad6_dist <- fetch_6yr_grad_rate(2024, level = "district")
#' }
fetch_6yr_grad_rate <- function(end_year, level = "school") {

  target_url <- get_spr_6yr_grad_url(end_year, level)

  tname <- tempfile(pattern = "spr_6yr", tmpdir = tempdir(), fileext = ".xlsx")

  # The SPR database files are large (the 2024-25 school file is ~368 MB), so
  # bump the download timeout above R's 60-second default for the duration of
  # the fetch and restore it afterward.
  old_timeout <- getOption("timeout")
  on.exit(options(timeout = old_timeout), add = TRUE)
  options(timeout = max(old_timeout, 1200))

  downloader::download(target_url, destfile = tname, mode = "wb")

  if (end_year >= 2025) {
    # SY2024-25 restructured the SPR database: the 6-year cohort profile moved
    # from the "6YrGraduationCohortProfile" sheet to the combined
    # "GraduationCohortProfile" sheet (which now holds 4/5/6-year cohorts and
    # requires filtering CohortType == "6-Year"). Headers moved to row 4
    # (skip = 3), rate columns gained _School/_District/_State suffixes, and
    # rate values are now percent strings (e.g. "81.6%").
    suppressers <- c(
      "*", "N", "NA", "", "-", "n/a",
      "Fewer than 10 students in the cohort.",
      "Fewer than 10 graduates."
    )
    df <- readxl::read_excel(
      path = tname,
      sheet = "GraduationCohortProfile",
      skip = 3,
      na = suppressers,
      guess_max = 30000
    )

    df <- df %>%
      dplyr::filter(.data$CohortType == "6-Year")

    if (level == "school") {
      df <- df %>%
        dplyr::rename(
          county_id = CountyCode,
          county_name = CountyName,
          district_id = DistrictCode,
          district_name = DistrictName,
          school_id = SchoolCode,
          school_name = SchoolName,
          subgroup = StudentGroup,
          grad_rate_6yr = Graduated_School,
          continuing_rate = Continuing_School,
          non_continuing_rate = NonContinuing_School,
          persistence_rate = Persisting_School
        ) %>%
        dplyr::select(
          county_id, county_name,
          district_id, district_name,
          school_id, school_name,
          subgroup,
          grad_rate_6yr, continuing_rate, non_continuing_rate, persistence_rate
        )
    } else {
      # District file has no SchoolCode/SchoolName. Real district rows carry
      # their rate in the _District columns; the statewide aggregate row leaves
      # _District blank and only populates _State. The _State columns are
      # repeated on every district row as a reference, so we pull from them ONLY
      # for the statewide row -- using them as a general fallback would fabricate
      # the statewide value onto suppressed districts (whose _District is NA).
      df <- df %>%
        dplyr::rename(
          county_id = CountyCode,
          county_name = CountyName,
          district_id = DistrictCode,
          district_name = DistrictName,
          subgroup = StudentGroup
        ) %>%
        dplyr::mutate(
          .is_state_row = !is.na(county_id) & county_id == "State",
          grad_rate_6yr = dplyr::if_else(.is_state_row, Graduated_State, Graduated_District),
          continuing_rate = dplyr::if_else(.is_state_row, Continuing_State, Continuing_District),
          non_continuing_rate = dplyr::if_else(.is_state_row, NonContinuing_State, NonContinuing_District),
          persistence_rate = dplyr::if_else(.is_state_row, Persisting_State, Persisting_District),
          school_id = "999",
          school_name = "District Total"
        ) %>%
        dplyr::select(
          county_id, county_name,
          district_id, district_name,
          school_id, school_name,
          subgroup,
          grad_rate_6yr, continuing_rate, non_continuing_rate, persistence_rate
        )
    }

    # Strip the trailing "%" from percent strings before numeric coercion.
    rate_cols <- c("grad_rate_6yr", "continuing_rate", "non_continuing_rate", "persistence_rate")
    for (col in rate_cols) {
      df[[col]] <- gsub("%", "", as.character(df[[col]]), fixed = TRUE)
    }
  } else {
    # 2017-2024: legacy "6YrGraduationCohortProfile" sheet, headers on row 1,
    # numeric rate columns named Graduates / Continuing Students /
    # Non-Continuing Student (+ HighSchoolPersistance from 2024).
    df <- readxl::read_excel(
      path = tname,
      sheet = "6YrGraduationCohortProfile",
      na = c("*", "N", "NA", "", "-"),
      guess_max = 10000
    )

    # Check if HighSchoolPersistance column exists (added in 2024)
    has_persistence <- "HighSchoolPersistance" %in% names(df) |
      "StateHighSchoolPersistance" %in% names(df)

    # Standardize column names based on level
    if (level == "school") {
      df <- df %>%
        dplyr::rename(
          county_id = CountyCode,
          county_name = CountyName,
          district_id = DistrictCode,
          district_name = DistrictName,
          school_id = SchoolCode,
          school_name = SchoolName,
          subgroup = StudentGroup,
          grad_rate_6yr = Graduates,
          continuing_rate = `Continuing Students`,
          non_continuing_rate = `Non-Continuing Student`
        )

      # Add persistence_rate if available, otherwise calculate or set NA
      if (has_persistence) {
        df <- df %>% dplyr::rename(persistence_rate = HighSchoolPersistance)
      } else {
        # Calculate persistence = graduates + continuing (not available in early years)
        df <- df %>% dplyr::mutate(persistence_rate = NA_real_)
      }

      df <- df %>%
        dplyr::select(
          county_id, county_name,
          district_id, district_name,
          school_id, school_name,
          subgroup,
          grad_rate_6yr, continuing_rate, non_continuing_rate, persistence_rate
        )
    } else {
      # District/state file: no SchoolCode/SchoolName. The statewide aggregate
      # row (CountyCode == "State") leaves the base rate columns blank and stores
      # its values in parallel "State: <col>" columns -- but those "State:"
      # columns are repeated on *every* district row as a reference, so we pull
      # from them ONLY for the statewide row. Filling NA base values for ordinary
      # (suppressed) districts from the "State:" columns would fabricate data.
      is_state_row <- !is.na(df$CountyCode) & df$CountyCode == "State"
      fill_state <- function(base_col, state_col) {
        base <- df[[base_col]]
        if (state_col %in% names(df)) {
          dplyr::if_else(is_state_row, df[[state_col]], base)
        } else {
          base
        }
      }

      df <- df %>%
        dplyr::mutate(
          grad_rate_6yr = fill_state("Graduates", "State: Graduates"),
          continuing_rate = fill_state("Continuing Students", "State: Continuing Students"),
          non_continuing_rate = fill_state("Non-Continuing Student", "State: Non-Continuing Student"),
          persistence_rate = if (has_persistence) {
            fill_state("HighSchoolPersistance", "State: HighSchoolPersistance")
          } else {
            NA_real_
          },
          school_id = "999",
          school_name = "District Total"
        ) %>%
        dplyr::rename(
          county_id = CountyCode,
          county_name = CountyName,
          district_id = DistrictCode,
          district_name = DistrictName,
          subgroup = StudentGroup
        ) %>%
        dplyr::select(
          county_id, county_name,
          district_id, district_name,
          school_id, school_name,
          subgroup,
          grad_rate_6yr, continuing_rate, non_continuing_rate, persistence_rate
        )
    }
  }

  # Convert rate columns to numeric
  rate_cols <- c("grad_rate_6yr", "continuing_rate", "non_continuing_rate", "persistence_rate")
  for (col in rate_cols) {
    df[[col]] <- as.numeric(df[[col]])
  }

  # Clean subgroup names
  df$subgroup <- clean_6yr_grad_subgroups(df$subgroup)

  # Add metadata
  df$end_year <- end_year
  df$methodology <- "6 year"

  # Remove rows without county_id
  df <- df %>%
    dplyr::filter(!is.na(county_id))

  # Every year's SPR cohort profile -- the legacy "6YrGraduationCohortProfile"
  # (2017-2024) and the 2024-25 "GraduationCohortProfile" -- puts the literal
  # string "State" in the CountyCode/DistrictCode of the statewide aggregate row
  # rather than the numeric 99/9999 codes used elsewhere. Normalize so the
  # aggregation flags below classify the statewide row as is_state (it was
  # silently FALSE for 2017-2024 before this).
  df <- df %>%
    dplyr::mutate(
      district_id = dplyr::if_else(district_id == "State", "9999", district_id),
      county_id = dplyr::if_else(county_id == "State", "99", county_id)
    )

  # Add aggregation flags
  df <- df %>%
    dplyr::mutate(
      is_state = district_id == "9999" & county_id == "99",
      is_county = district_id == "9999" & !county_id == "99",
      is_district = school_id %in% c("888", "997", "999") & !is_state,
      is_charter_sector = FALSE,
      is_allpublic = FALSE,
      is_school = !school_id %in% c("888", "997", "999") & !is_state,
      is_charter = county_id == "80"
    )

  # Reorder columns
  df %>%
    dplyr::select(
      end_year,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      subgroup,
      grad_rate_6yr, continuing_rate, non_continuing_rate, persistence_rate,
      methodology,
      is_state, is_county, is_district, is_school,
      is_charter, is_charter_sector, is_allpublic
    )
}


#' Fetch all 6-Year Graduation Rate data
#'
#' Convenience function to download and combine all available 6-year
#' graduation rate data into a single data frame.
#'
#' @param level One of "school", "district", or "both". "both" combines
#'   school and district data. Default is "school".
#' @return A data frame with all 6-year graduation rate results (2021-2025)
#' @export
#' @examples
#' \dontrun{
#' # Get all school-level 6-year graduation data
#' all_grad6 <- fetch_all_6yr_grad_rate()
#'
#' # Get both school and district data
#' all_grad6_both <- fetch_all_6yr_grad_rate(level = "both")
#' }
fetch_all_6yr_grad_rate <- function(level = "school") {

  results <- list()

  # 6-year graduation data available 2021-2025
  valid_years <- c(2021, 2022, 2023, 2024, 2025)

  if (level == "both") {
    for (year in valid_years) {
      for (lvl in c("school", "district")) {
        result <- tryCatch(
          {
            fetch_6yr_grad_rate(end_year = year, level = lvl)
          },
          error = function(e) {
            message(sprintf("Could not fetch 6yr grad rate %s %s: %s", year, lvl, e$message))
            NULL
          }
        )
        if (!is.null(result)) {
          results[[paste(year, lvl, sep = "_")]] <- result
        }
      }
    }
  } else {
    for (year in valid_years) {
      result <- tryCatch(
        {
          fetch_6yr_grad_rate(end_year = year, level = level)
        },
        error = function(e) {
          message(sprintf("Could not fetch 6yr grad rate %s: %s", year, e$message))
          NULL
        }
      )
      if (!is.null(result)) {
        results[[as.character(year)]] <- result
      }
    }
  }

  dplyr::bind_rows(results)
}
