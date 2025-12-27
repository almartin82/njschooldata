# ==============================================================================
# Enrollment Data Fetching Functions
# ==============================================================================
#
# This file contains functions for downloading enrollment data from the
# NJ Department of Education website.
#
# ==============================================================================

#' Read a zipped Excel fall enrollment file from the NJ state website
#'
#' @param end_year A school year. Year is the end of the academic year - eg 2006-07
#' school year is year '2007'. Valid values are 2000-2025.
#' @return Data frame with raw enrollment data
#' @keywords internal
get_raw_enr <- function(end_year) {

  # Sometime in 2022 they ripped, replaced, and rationalized the
  # url pattern for historic data
  # 1999 data URL no longer works (removed from NJ DOE website)

  # Build URL
  yy <- substr(end_year, 3, 4)
  enr_folder <- paste0("enr", yy)

  enr_filename <- paste0(
    "enrollment_",
    substr(end_year - 1, 3, 4),
    yy,
    ".zip"
  )

  enr_url <- paste0(
    "https://www.nj.gov/education/doedata/enr/", enr_folder, "/", enr_filename
  )

  # Download and unzip
  tname <- tempfile(pattern = "enr", tmpdir = tempdir(), fileext = ".zip")
  tdir <- tempdir()
  downloader::download(enr_url, dest = tname, mode = "wb")

  utils::unzip(tname, exdir = tdir)

  # Read file
  enr_files <- utils::unzip(tname, exdir = ".", list = TRUE)

  if (grepl(".xls", tolower(enr_files$Name[1]))) {
    this_file <- file.path(tdir, enr_files$Name[1])

    to_skip <- dplyr::case_when(
      end_year == 2018 ~ 1,
      end_year >= 2019 ~ 2,
      TRUE ~ 0
    )

    if (end_year < 2020) {
      enr <- readxl::read_excel(this_file, skip = to_skip)

      # Starting in the 2020 school year the format changes significantly
      # Three distinct worksheets to combine
    } else if (end_year >= 2020) {

      # In 2020 they leave a stray space in this sheet name
      enr_state <- readxl::read_excel(
        this_file, sheet = ifelse(end_year == 2020, "State ", "State"), skip = 2
      )
      enr_dist <- readxl::read_excel(this_file, sheet = "District", skip = 2)
      enr_sch <- readxl::read_excel(this_file, sheet = "School", skip = 2)

      # The delicious typos section (and column name changes over time)
      typo_names <- . %>%
        dplyr::rename_with(
          ~ dplyr::case_when(
            . == "Pre -K Halfday" ~ "Pre-K Halfday",
            . == "Pre-K FullDay" ~ "Pre-K Fullday",
            . == "Pre-K\r\n Full day" ~ "Pre-K Fullday",
            . == "Pre-K Half Day" ~ "Pre-K Halfday",
            . == "Eight Grade" ~ "Eighth Grade",
            . == "Reduced_Lunch" ~ "Reduced Lunch",
            . == "% Reduced_Lunch" ~ "%Reduced Lunch",
            # 2024+ renamed English Learners to Multilingual Learners
            . == "Multilingual Learners" ~ "English Learners",
            . == "%Multilingual Learners" ~ "%English Learners",
            # 2024+ renamed Hawaiian Native
            . == "Hawaiian Native" ~ "Pacific Islander",
            . == "%Hawaiian Native" ~ "%Pacific Islander",
            TRUE ~ .
          )
        )

      enr_state <- enr_state %>% typo_names()
      enr_dist <- enr_dist %>% typo_names()
      enr_sch <- enr_sch %>% typo_names()

      # Set some constants
      enr_dist <- enr_dist %>%
        dplyr::mutate(
          `School Code` = "999",
          `School Name` = "District Total"
        )

      # Combine state, dist, sch df by binding dist and sch and then
      # pivoting grade level columns long
      enr_dist_sch <- dplyr::bind_rows(enr_dist, enr_sch)

      # In 2020 they decided not to report above 95%?!
      # Set to 97.5 to split the difference
      if (end_year == 2020) {
        enr_dist_sch <- enr_dist_sch %>%
          dplyr::mutate(
            `%Free Lunch` = dplyr::if_else(`%Free Lunch` == ">95", "97.5", `%Free Lunch`),
            `%Reduced Lunch` = dplyr::if_else(`%Reduced Lunch` == ">95", "97.5", `%Reduced Lunch`),
            `%English Learners` = dplyr::if_else(`%English Learners` == ">95", "97.5", `%English Learners`),
            `%Migrant` = dplyr::if_else(`%Migrant` == ">95", "97.5", `%Migrant`),
            `%Military` = dplyr::if_else(`%Military` == ">95", "97.5", `%Military`),
            `%Homeless` = dplyr::if_else(`%Homeless` == ">95", "97.5", `%Homeless`)
          )
      }

      enr_dist_sch <- enr_dist_sch %>%
        dplyr::mutate(
          # Populations in this mutate block are only reported as pcts,
          # so convert percents into counts
          `Free Lunch` = as.numeric(`%Free Lunch`) / 100 * `Total Enrollment`,
          `Reduced Lunch` = as.numeric(`%Reduced Lunch`) / 100 * `Total Enrollment`,
          `English Learners` = as.numeric(`%English Learners`) / 100 * `Total Enrollment`,
          `Migrant` = as.numeric(`%Migrant`) / 100 * `Total Enrollment`,
          `Military` = as.numeric(`%Military`) / 100 * `Total Enrollment`,
          `Homeless` = as.numeric(`%Homeless`) / 100 * `Total Enrollment`
        )

      # Determine the last grade column (Ungraded removed in 2024+)
      last_grade_col <- if ("Ungraded" %in% names(enr_dist_sch)) {
        "Ungraded"
      } else {
        "Twelfth Grade"
      }

      # Get grade columns dynamically
      all_cols <- names(enr_dist_sch)
      start_idx <- which(all_cols == "Pre-K Halfday")
      end_idx <- which(all_cols == last_grade_col)
      grade_cols <- all_cols[start_idx:end_idx]

      enr <- enr_dist_sch %>%
        dplyr::select(
          `County Code`:`District Name`, `School Code`, `School Name`,
          dplyr::all_of(grade_cols)
        ) %>%
        tidyr::pivot_longer(
          cols = dplyr::all_of(grade_cols),
          names_to = "Grade",
          values_to = "Total Enrollment"
        ) %>%
        dplyr::bind_rows(
          enr_dist_sch %>%
            dplyr::select(-dplyr::all_of(grade_cols)) %>%
            dplyr::mutate(Grade = "All Grades")
        ) %>%
        dplyr::bind_rows(
          enr_state %>%
            dplyr::rename(
              "Total Enrollment" = "Total",
              "Native American" = "American Indian"
            )
        )
    }
  } else if (grepl(".csv", tolower(enr_files$Name[1]))) {
    enr <- readr::read_csv(
      file = file.path(tdir, enr_files$Name[1]),
      na = c("     . ", ".", ""),
      show_col_types = FALSE
    )
  }

  enr$end_year <- end_year

  # Specific fixes
  # 2010 pre-k disabled issue
  if (end_year == 2010) {
    mask <- enr$PROGRAM_CODE == "32" & enr$PROGRAM_NAME == "Half Day Preschool Dis"
    enr[mask, "PROGRAM_CODE"] <- "33"
  }

  # 2013 marin issue
  if (end_year == 2013) {
    mask <- enr$`SCHOOL NAME` == "LUIS MUNOZ MARIN ELEM SCH" & enr$`DISTRICT NAME` == "NEWARK"
    enr[mask, "DISTRICT NAME"] <- "THE NEWARK PUBLIC SCHOOLS"
  }

  return(enr)
}


#' Gets and processes a NJ enrollment file
#'
#' `fetch_enr` is a wrapper around `get_raw_enr` and `process_enr` that
#' downloads and cleans enrollment data for a given year.
#'
#' @param end_year A school year. Year is the end of the academic year - eg 2006-07
#' school year is year '2007'. Valid values are 2000-2025.
#' @param tidy If TRUE, takes the unwieldy wide data and normalizes into a
#' long, tidy data frame with limited headers - constants (school/district name and code),
#' subgroup (all the enrollment file subgroups), program/grade and measure (row_total, free lunch, etc).
#' @return Data frame with processed enrollment data
#' @export
#' @examples
#' \dontrun{
#' # Get 2023 enrollment data
#' enr_2023 <- fetch_enr(2023)
#'
#' # Get tidy (long format) enrollment data
#' enr_tidy <- fetch_enr(2023, tidy = TRUE)
#' }
fetch_enr <- function(end_year, tidy = FALSE) {
  enr_data <- get_raw_enr(end_year) %>%
    process_enr()

  if (tidy) {
    enr_data <- tidy_enr(enr_data) %>%
      id_enr_aggs()
  }

  enr_data
}
