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
#' Valid values are 1998-2024.
#' @param methodology One of c('4 year', '5 year')
#' @return data.frame with raw data from state file
#' @keywords internal
get_raw_grad_file <- function(end_year, methodology = "4 year") {

  if (end_year < 1998 | end_year > 2024) {
    stop("year not yet supported. Valid years are 1998-2024.")
  }

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
      grate_url <- "https://www.state.nj.us/education/data/grate/2012/gradrate.xls"
      grate_file <- tempfile(fileext = ".xls")
      httr::GET(url = grate_url, httr::write_disk(grate_file))
      df <- readxl::read_excel(grate_file)

      grate_indices <- c(1:7, 9)
      df <- df[, grate_indices] %>%
        dplyr::mutate("GRADUATED_COUNT" = NA_integer_)

      # 2012 they transition the format but post it in a weird location
    } else if (end_year == 2012) {
      grate_url <- "https://www.nj.gov/education/schoolperformance/grad/data/ACGR2012_grd.xls"
      grate_file <- tempfile(fileext = ".xls")
      httr::GET(url = grate_url, httr::write_disk(grate_file))
      df <- readxl::read_excel(grate_file)

      # 2013 on is the cohort grad rate era
    } else if (end_year >= 2013 & end_year <= 2017) {
      basic_suffix <- "_4Year.xlsx"
      num_skip <- 0

      grate_url <- paste0(
        "https://www.nj.gov/education/schoolperformance/grad/data/ACGR",
        end_year, basic_suffix
      )
      grate_file <- tempfile(fileext = ".xlsx")
      httr::GET(url = grate_url, httr::write_disk(grate_file))
      df <- readxl::read_excel(grate_file, skip = num_skip)

      # Starting in 2018 the URLs are inconsistent, so hard code them
    } else if (end_year == 2018) {
      grate_url <- "https://www.nj.gov/education/schoolperformance/grad/data/ACGR2018_4YearGraduation.xlsx"
      num_skip <- 3
      grate_file <- tempfile(fileext = ".xlsx")
      httr::GET(url = grate_url, httr::write_disk(grate_file))
      df <- readxl::read_excel(grate_file, skip = num_skip)
    } else if (end_year == 2019) {
      grate_url <- "https://www.nj.gov/education/schoolperformance/grad/data/ACGR2019_Cohort%202019%204-Year%20Adjusted%20Cohort%20Graduation%20Rates%20by%20Student%20Group.xlsx"
      num_skip <- 3
      grate_file <- tempfile(fileext = ".xlsx")
      httr::GET(url = grate_url, httr::write_disk(grate_file))
      df <- readxl::read_excel(grate_file, skip = num_skip)
    } else if (end_year == 2020) {
      grate_url <- "https://www.nj.gov/education/schoolperformance/grad/data/Cohort%202020%204-Year%20Adjusted%20Cohort%20Graduation%20Rates%20by%20Student%20Group.xlsx"
      num_skip <- 3
      grate_file <- tempfile(fileext = ".xlsx")
      httr::GET(url = grate_url, httr::write_disk(grate_file))
      df <- readxl::read_excel(grate_file, skip = num_skip)
    } else if (end_year == 2021) {
      grate_url <- "https://www.nj.gov/education/schoolperformance/grad/data/Cohort%202021%204-Year%20Adjusted%20Cohort%20Graduation%20Rates%20by%20Student%20Group.xlsx"
      num_skip <- 3
      grate_file <- tempfile(fileext = ".xlsx")
      httr::GET(url = grate_url, httr::write_disk(grate_file))
      df <- readxl::read_excel(grate_file, skip = num_skip)
    } else if (end_year == 2022) {
      grate_url <- "https://www.nj.gov/education/schoolperformance/grad/data/Cohort%202022%204-Year%20Adjusted%20Cohort%20Graduation%20Rates%20by%20Student%20Group.xlsx"
      num_skip <- 3
      grate_file <- tempfile(fileext = ".xlsx")
      httr::GET(url = grate_url, httr::write_disk(grate_file))
      df <- readxl::read_excel(grate_file, skip = num_skip)
    } else if (end_year == 2023) {
      grate_url <- "https://www.nj.gov/education/schoolperformance/grad/data/Cohort%202023%204-Year%20Adjusted%20Cohort%20Graduation%20Rates%20by%20Student%20Group.xlsx"
      num_skip <- 3
      grate_file <- tempfile(fileext = ".xlsx")
      httr::GET(url = grate_url, httr::write_disk(grate_file))
      df <- readxl::read_excel(grate_file, skip = num_skip)
    } else if (end_year == 2024) {
      grate_url <- "https://www.nj.gov/education/schoolperformance/grad/data/Cohort%202024%204-Year%20Adjusted%20Cohort%20Graduation%20Rates%20by%20Student%20Group.xlsx"
      num_skip <- 3
      grate_file <- tempfile(fileext = ".xlsx")
      httr::GET(url = grate_url, httr::write_disk(grate_file))
      df <- readxl::read_excel(grate_file, skip = num_skip)
    }

    ########## 5 year ##########
  } else if (methodology == "5 year") {

    if (end_year < 2012) {
      stop(paste0("5 year grad rate not available for ending year ", end_year))
    } else if (end_year == 2012) {
      grate_url <- "https://www.nj.gov/education/schoolperformance/grad/data/ACGR2013_4And5YearCohort12.xlsx"
      num_skip <- 0
    } else if (end_year == 2013) {
      grate_url <- "https://www.nj.gov/education/schoolperformance/grad/data/ACGR2014_4And5YearCohort13.xlsx"
      num_skip <- 0
    } else if (end_year == 2014) {
      grate_url <- "https://www.nj.gov/education/schoolperformance/grad/data/ACGR2015_4And5YearCohort14.xlsx"
      num_skip <- 0
    } else if (end_year == 2015) {
      grate_url <- "https://www.nj.gov/education/schoolperformance/grad/data/ACGR2016_4And5YearCohort14.xlsx"
      num_skip <- 0
    } else if (end_year == 2016) {
      grate_url <- "https://www.nj.gov/education/schoolperformance/grad/data/ACGR2017_4And5YearCohort.xlsx"
      num_skip <- 0
    } else if (end_year == 2017) {
      grate_url <- "https://www.nj.gov/education/schoolperformance/grad/data/ACGR2018_4and5YearGraduationRates.xlsx"
      num_skip <- 3
    } else if (end_year == 2018) {
      grate_url <- "https://www.nj.gov/education/schoolperformance/grad/data/ACGR2019_Cohort%202018%204-Year%20and%205-Year%20Adjusted%20Cohort%20Graduation%20Rates.xlsx"
      num_skip <- 3
    } else if (end_year == 2019) {
      grate_url <- "https://www.nj.gov/education/schoolperformance/grad/data/Cohort%202019%204-Year%20and%205-Year%20Adjusted%20Cohort%20Graduation%20Rates.xlsx"
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
#' Valid values are 2012-2024.
#' @return dataframe with the number of graduates per school and district
#' @keywords internal
get_grad_count <- function(end_year) {
  if (end_year < 2012 | end_year > 2024) {
    stop(paste0(end_year, " not yet supported. Valid years are 2012-2024."))
  }

  df <- get_raw_grad_file(end_year)

  df %>%
    process_grate(end_year)
}


#' Get NJ graduation rate data
#'
#' @param end_year End of the academic year - 2011-2012 is 2012.
#' Valid values are 2011-2024.
#' @param methodology Character string specifying calculation methodology.
#' One of "4 year" or "5 year".
#' @return dataframe with the number of graduates per school and district
#' @keywords internal
get_grad_rate <- function(end_year, methodology) {
  if (end_year < 2011 | end_year > 2024) {
    stop("year not yet supported. Valid years are 2011-2024.")
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
#' Valid values are 2012-2024.
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
#' Valid values are 2011-2024.
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
    process_grad_rate(end_year)

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
