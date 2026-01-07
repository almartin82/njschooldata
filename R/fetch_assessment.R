# ==============================================================================
# Assessment Data Fetching Functions
# ==============================================================================
#
# This file contains functions for downloading PARCC/NJSLA assessment data from
# the NJ Department of Education website.
#
# ==============================================================================

#' Reads the raw PARCC Excel files from the state website
#'
#' Builds a URL and reads the xlsx file into a dataframe.
#'
#' @param end_year A school year. end_year is the end of the academic year - eg 2014-15
#' school year is end_year 2015. Valid values are 2015-2018.
#' @param grade_or_subj Grade level (eg 8) OR math subject code (eg ALG1, GEO, ALG2)
#' @param subj PARCC subject. c('ela' or 'math')
#' @return PARCC dataframe
#' @keywords internal
get_raw_parcc <- function(end_year, grade_or_subj, subj) {

  if (is.numeric(grade_or_subj)) {
    parcc_grade <- pad_grade(grade_or_subj)

    # In 2017 they forgot how grade levels work
    if (end_year == 2017 & grade_or_subj >= 10) {
      parcc_grade <- paste0("0", parcc_grade)
    }
    # In 2018 - honestly I just can't.
    # Fine, state of NJ, ELA003. it's only broken code, not life and death.
    if (end_year == 2018 & subj == "ela") {
      parcc_grade <- paste0("0", parcc_grade)
    }
  } else {
    parcc_grade <- grade_or_subj
  }

  stem <- "https://www.nj.gov/education/assessment/results/reports/"

  # After 2016 they added a spring / fall element
  # eg http://www.nj.gov/education/schools/achievement/16/parcc/spring/ELA03.xlsx
  # We're pulling spring only (for now)
  season_variant <- if (end_year >= 2016) {
    "spring/"
  } else {
    "parcc/"
  }

  sy <- as.numeric(substr(end_year, 3, 4))

  target_url <- paste0(
    stem, sy - 1, sy, "/", season_variant,
    parse_parcc_subj(subj), parcc_grade, ".xlsx"
  )

  tname <- tempfile(pattern = "parcc", tmpdir = tempdir(), fileext = ".xlsx")
  tdir <- tempdir()
  downloader::download(target_url, destfile = tname, mode = "wb")
  parcc <- readxl::read_excel(path = tname, skip = 2, na = "*", guess_max = 30000)

  # Last two rows are notes
  parcc <- parcc[1:(nrow(parcc) - 2), ]
  parcc
}


#' Reads the raw NJSLA Excel files from the state website
#'
#' Builds a URL and reads the xlsx file into a dataframe.
#'
#' @inheritParams get_raw_parcc
#' @return NJSLA dataframe
#' @keywords internal
get_raw_sla <- function(end_year, grade_or_subj, subj) {

  if (is.numeric(grade_or_subj)) {
    parcc_grade <- pad_grade(grade_or_subj)
    subj_prefix <- parse_parcc_subj(subj)
  } else if (grepl("ALG|GEO", grade_or_subj)) {
    parcc_grade <- gsub("ALG", "ALG0", grade_or_subj)
    subj_prefix <- ""
  } else {
    parcc_grade <- grade_or_subj
    subj_prefix <- parse_parcc_subj(subj)
  }

  stem <- "https://www.nj.gov/education/assessment/results/reports/"
  year_suffix <- paste0(end_year - 1, "-", substr(end_year, 3, 4))

  # URL format changed between 2019 and 2022
  # 2019: ELA03%20NJSLA%20DATA%202018-19.xlsx (spaces)
  # 2022+: ELA03_NJSLA_DATA_2021-22.xlsx (underscores)
  if (end_year == 2019) {
    filename <- paste0(
      subj_prefix, parcc_grade, "%20NJSLA%20DATA%20", year_suffix, ".xlsx"
    )
  } else {
    # 2022 and later use underscores
    filename <- paste0(
      subj_prefix, parcc_grade, "_NJSLA_DATA_", year_suffix, ".xlsx"
    )
  }

  target_url <- paste0(
    stem, substr(end_year - 1, 3, 4), substr(end_year, 3, 4), "/spring/", filename
  )

  tname <- tempfile(pattern = "njsla", tmpdir = tempdir(), fileext = ".xlsx")
  downloader::download(target_url, destfile = tname, mode = "wb")
  njsla <- readxl::read_excel(path = tname, skip = 2, na = "*", guess_max = 30000)

  # Last two rows are notes
  njsla <- njsla[1:(nrow(njsla) - 2), ]
  njsla
}


#' Reads the raw NJGPA Excel files from the state website
#'
#' NJGPA (New Jersey Graduation Proficiency Assessment) is the graduation
#' requirement assessment introduced in 2022.
#'
#' @param end_year A school year. Valid values are 2022-2024.
#' @param subj NJGPA subject. c('ela' or 'math')
#' @return NJGPA dataframe
#' @keywords internal
get_raw_njgpa <- function(end_year, subj) {

  if (end_year < 2022) {
    stop("NJGPA data is only available starting in 2022")
  }

  subj <- tolower(subj)
  subj_prefix <- if (subj == "ela") "ELAGP" else if (subj == "math") "MATGP" else {
    stop("NJGPA subject must be 'ela' or 'math'")
  }

  stem <- "https://www.nj.gov/education/assessment/results/reports/"
  year_suffix <- paste0(end_year - 1, "-", substr(end_year, 3, 4))

  filename <- paste0(subj_prefix, "_NJGPA_DATA_", year_suffix, ".xlsx")

  target_url <- paste0(
    stem, substr(end_year - 1, 3, 4), substr(end_year, 3, 4), "/njgpa/", filename
  )

  tname <- tempfile(pattern = "njgpa", tmpdir = tempdir(), fileext = ".xlsx")
  downloader::download(target_url, destfile = tname, mode = "wb")
  # NJGPA files have 3 header rows (description, title, suppression notes)
  # Row 4 contains actual column headers
  njgpa <- readxl::read_excel(path = tname, skip = 3, na = "*", guess_max = 30000)

  # Last two rows are notes
  njgpa <- njgpa[1:(nrow(njgpa) - 2), ]
  njgpa
}


#' Gets and cleans up a PARCC data file
#'
#' `fetch_parcc` is a wrapper around `get_raw_parcc` and `process_parcc`
#' that gets a parcc file and performs any cleanup.
#'
#' @param end_year A school year. end_year is the end of the academic year - eg 2014-15
#' school year is end_year 2015. Valid values are 2015-2024.
#' @param grade_or_subj Grade level (eg 8) OR math subject code (eg ALG1, GEO, ALG2).
#'   For science, valid grades are 5, 8, and 11.
#' @param subj Assessment subject: 'ela', 'math', or 'science'.
#'   Science assessments are only available for 2019+ and grades 5, 8, 11.
#' @param tidy Clean up the data frame to make it more compatible with
#' NJASK naming conventions and do some additional calculations? Default is FALSE.
#' @return Processed PARCC/NJSLA dataframe
#' @export
#' @examples
#' \dontrun{
#' # Get 2023 grade 4 math results
#' parcc_2023 <- fetch_parcc(2023, 4, "math")
#'
#' # Get 2023 Algebra 1 results
#' alg1_2023 <- fetch_parcc(2023, "ALG1", "math")
#'
#' # Get 2023 grade 8 science results
#' science_2023 <- fetch_parcc(2023, 8, "science")
#' }
fetch_parcc <- function(end_year, grade_or_subj, subj, tidy = FALSE) {

  subj <- tolower(subj)


  # Validate science parameters
  if (subj == "science") {
    if (end_year < 2019) {
      stop("Science assessments are only available starting in 2019")
    }
    if (!grade_or_subj %in% c(5, 8, 11)) {
      stop("Science assessments are only available for grades 5, 8, and 11")
    }
  }

  if (end_year >= 2019) {
    p <- get_raw_sla(end_year, grade_or_subj, subj)
  } else {
    p <- get_raw_parcc(end_year, grade_or_subj, subj)
  }
  p <- process_parcc(p, end_year, grade_or_subj, subj)

  if (tidy) {
    p$subgroup <- tidy_parcc_subgroup(p$subgroup)

    p <- p %>% parcc_perf_level_counts()
  }

  p
}


#' Fetch NJGPA (NJ Graduation Proficiency Assessment) data
#'
#' Downloads and processes NJGPA assessment results. NJGPA is the graduation
#' requirement assessment introduced in 2022, replacing the previous PARCC-based
#' graduation pathway.
#'
#' @param end_year A school year. Valid values are 2022-2024.
#' @param subj Assessment subject: 'ela' or 'math'
#' @param tidy Clean up the data frame? Default is FALSE.
#' @return Processed NJGPA dataframe
#' @export
#' @examples
#' \dontrun{
#' # Get 2023 NJGPA ELA results
#' njgpa_ela <- fetch_njgpa(2023, "ela")
#'
#' # Get 2024 NJGPA Math results
#' njgpa_math <- fetch_njgpa(2024, "math")
#' }
fetch_njgpa <- function(end_year, subj, tidy = FALSE) {

  if (end_year < 2022) {
    stop("NJGPA data is only available starting in 2022")
  }

  p <- get_raw_njgpa(end_year, subj)
  # Use the same processing as PARCC/NJSLA
  p <- process_parcc(p, end_year, grade = "GP", subj = subj)

  if (tidy) {
    p$subgroup <- tidy_parcc_subgroup(p$subgroup)
    p <- p %>% parcc_perf_level_counts()
  }

  p
}


#' Fetch all PARCC results
#'
#' Convenience function to download and combine all PARCC/NJSLA results
#' into single data frame, including ELA, Math, and Science assessments.
#'
#' @param include_science Include science assessments (2019+)? Default is TRUE.
#' @return A data frame with all PARCC/NJSLA results
#' @export
#' @examples
#' \dontrun{
#' # Get all PARCC/NJSLA results (takes a while)
#' all_parcc <- fetch_all_parcc()
#'
#' # Exclude science assessments
#' all_parcc_no_sci <- fetch_all_parcc(include_science = FALSE)
#' }
fetch_all_parcc <- function(include_science = TRUE) {

  parcc_results <- list()

  # PARCC years 2015-2018, NJSLA 2019+

  # Note: 2020 assessments cancelled due to COVID-19
  # Note: 2021 only has "Start Strong" pilot data, not standard NJSLA
  valid_years <- c(2015:2019, 2022:2024)

  for (i in valid_years) {
    # Normal grade level tests
    for (j in c(3:8)) {
      for (k in c("ela", "math")) {

        p <- tryCatch(
          {
            fetch_parcc(end_year = i, grade_or_subj = j, subj = k, tidy = TRUE)
          },
          error = function(e) {
            message(sprintf("Could not fetch %s grade %d %s: %s", i, j, k, e$message))
            NULL
          }
        )

        if (!is.null(p)) {
          parcc_results[[paste(i, j, k, sep = "_")]] <- p
        }
      }
    }
    # HS ELA
    if (i >= 2019) {
      # 11th grade optional and not reported starting in 2019
      for (j in c(9:10)) {
        p <- tryCatch(
          {
            fetch_parcc(end_year = i, grade_or_subj = j, subj = "ela", tidy = TRUE)
          },
          error = function(e) {
            message(sprintf("Could not fetch %s grade %d ela: %s", i, j, e$message))
            NULL
          }
        )

        if (!is.null(p)) {
          parcc_results[[paste(i, j, "ela", sep = "_")]] <- p
        }
      }
    } else {
      for (j in c(9:11)) {
        p <- tryCatch(
          {
            fetch_parcc(end_year = i, grade_or_subj = j, subj = "ela", tidy = TRUE)
          },
          error = function(e) {
            message(sprintf("Could not fetch %s grade %d ela: %s", i, j, e$message))
            NULL
          }
        )

        if (!is.null(p)) {
          parcc_results[[paste(i, j, "ela", sep = "_")]] <- p
        }
      }
    }

    # Specific math tests
    for (j in c("ALG1", "GEO", "ALG2")) {
      p <- tryCatch(
        {
          fetch_parcc(end_year = i, grade_or_subj = j, subj = "math", tidy = TRUE)
        },
        error = function(e) {
          message(sprintf("Could not fetch %s %s math: %s", i, j, e$message))
          NULL
        }
      )

      if (!is.null(p)) {
        parcc_results[[paste(i, j, "math", sep = "_")]] <- p
      }
    }

    # Science assessments (2019+ only, grades 5, 8, 11)
    if (include_science && i >= 2019) {
      for (j in c(5, 8, 11)) {
        p <- tryCatch(
          {
            fetch_parcc(end_year = i, grade_or_subj = j, subj = "science", tidy = TRUE)
          },
          error = function(e) {
            message(sprintf("Could not fetch %s grade %d science: %s", i, j, e$message))
            NULL
          }
        )

        if (!is.null(p)) {
          parcc_results[[paste(i, j, "science", sep = "_")]] <- p
        }
      }
    }
  }

  dplyr::bind_rows(parcc_results)
}


#' Fetch all NJGPA results
#'
#' Convenience function to download and combine all NJGPA (graduation proficiency)
#' results into a single data frame.
#'
#' @return A data frame with all NJGPA results (ELA and Math)
#' @export
#' @examples
#' \dontrun{
#' # Get all NJGPA results
#' all_njgpa <- fetch_all_njgpa()
#' }
fetch_all_njgpa <- function() {

  njgpa_results <- list()

  # NJGPA started in 2022
  valid_years <- c(2022:2024)

  for (i in valid_years) {
    for (k in c("ela", "math")) {
      p <- tryCatch(
        {
          fetch_njgpa(end_year = i, subj = k, tidy = TRUE)
        },
        error = function(e) {
          message(sprintf("Could not fetch NJGPA %s %s: %s", i, k, e$message))
          NULL
        }
      )

      if (!is.null(p)) {
        njgpa_results[[paste(i, k, sep = "_")]] <- p
      }
    }
  }

  dplyr::bind_rows(njgpa_results)
}


# -----------------------------------------------------------------------------
# ACCESS for ELLs Functions
# -----------------------------------------------------------------------------

#' Get the URL for ACCESS for ELLs data file
#'
#' Builds the URL for a given year's ACCESS data file.
#' URL structure changed between years.
#'
#' @param end_year A school year (2022-2024)
#' @return URL string
#' @keywords internal
get_access_url <- function(end_year) {
  if (end_year < 2022) {
    stop("ACCESS for ELLs data is only available starting in 2022")
  }

  sy_start <- substr(end_year - 1, 3, 4)
  sy_end <- substr(end_year, 3, 4)
  year_suffix <- paste0(end_year - 1, "-", sy_end)

  stem <- "https://www.nj.gov/education/assessment/results/reports/"


  # URL structure differs by year
  # 2023-2024: /access/ directory
  # 2022: /dlm/ directory
  if (end_year >= 2023) {
    dir <- "access"
  } else {
    dir <- "dlm"
  }

  paste0(stem, sy_start, sy_end, "/", dir, "/ACCESS_ELLS_DataFile_", year_suffix, ".xlsx")
}


#' Reads the raw ACCESS for ELLs Excel file from the state website
#'
#' Downloads the ACCESS file and reads a specific grade sheet.
#'
#' @param end_year A school year (2022-2024)
#' @param grade Grade level: "K" or 0 for Kindergarten, or 1-12 for other grades.
#'   Use "all" to get all grades combined.
#' @return ACCESS dataframe for the specified grade
#' @keywords internal
get_raw_access <- function(end_year, grade = "all") {

  target_url <- get_access_url(end_year)

  tname <- tempfile(pattern = "access", tmpdir = tempdir(), fileext = ".xlsx")
  downloader::download(target_url, destfile = tname, mode = "wb")

  # Map grade to sheet name
  if (grade == "all") {
    # Read all grade sheets and combine
    sheets <- readxl::excel_sheets(tname)
    # Skip first sheet (Workbook Overview)
    grade_sheets <- sheets[sheets != sheets[1]]

    all_data <- lapply(grade_sheets, function(sheet) {
      df <- readxl::read_excel(
        path = tname, sheet = sheet, skip = 3, na = "*", guess_max = 10000
      )
      # Extract grade from sheet name
      if (sheet == "Kindergarten") {
        df$grade <- "K"
      } else {
        df$grade <- gsub("Grade ", "", sheet)
      }
      df
    })

    access_data <- dplyr::bind_rows(all_data)
  } else {
    # Convert grade to sheet name
    if (grade %in% c("K", "0", 0)) {
      sheet_name <- "Kindergarten"
      grade_label <- "K"
    } else {
      sheet_name <- paste0("Grade ", grade)
      grade_label <- as.character(grade)
    }

    access_data <- readxl::read_excel(
      path = tname, sheet = sheet_name, skip = 3, na = "*", guess_max = 10000
    )
    access_data$grade <- grade_label
  }

  access_data
}


#' Process raw ACCESS for ELLs data
#'
#' Cleans and standardizes ACCESS data.
#'
#' @param access_file Output of get_raw_access
#' @param end_year A school year (2022-2024)
#' @return Processed ACCESS dataframe
#' @keywords internal
process_access <- function(access_file, end_year) {

  # Standardize column names
  access_name_vector <- c(
    "county_id", "county_name",
    "district_id", "district_name",
    "school_id", "school_name",
    "valid_scores",
    "pct_l1", "pct_l2", "pct_l3", "pct_l4", "pct_l5", "pct_l6",
    "grade"
  )
  names(access_file) <- access_name_vector

  # Make numeric
  access_file$valid_scores <- as.numeric(access_file$valid_scores)
  access_file$pct_l1 <- as.numeric(access_file$pct_l1)
  access_file$pct_l2 <- as.numeric(access_file$pct_l2)
  access_file$pct_l3 <- as.numeric(access_file$pct_l3)
  access_file$pct_l4 <- as.numeric(access_file$pct_l4)
  access_file$pct_l5 <- as.numeric(access_file$pct_l5)
  access_file$pct_l6 <- as.numeric(access_file$pct_l6)

  # Add metadata
  access_file$testing_year <- end_year
  access_file$assess_name <- "ACCESS"
  access_file$test_name <- "ACCESS for ELLs"

  # Calculate proficient_above
  # WIDA considers Level 4.5+ as "proficient" for English language proficiency

  # We approximate this as pct_l5 + pct_l6 (fully proficient levels)
  access_file <- access_file %>%
    dplyr::rowwise() %>%
    dplyr::mutate(
      proficient_above = ifelse(
        is.finite(pct_l5),
        sum(pct_l5, pct_l6, na.rm = TRUE),
        NA_real_
      )
    ) %>%
    dplyr::ungroup()

  # Remove rows without county_id (header remnants, footers)
  access_file <- access_file %>%
    dplyr::filter(!is.na(county_id))

  # Tag record types
  access_file$is_state <- FALSE
  access_file$is_district <- grepl("District Total", access_file$school_name, ignore.case = TRUE)
  access_file$is_school <- !access_file$is_district & !is.na(access_file$school_id)
  access_file$is_charter <- access_file$county_id == "80"

  # Column order
  access_file %>%
    dplyr::select(
      testing_year, assess_name, test_name, grade,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      valid_scores,
      pct_l1, pct_l2, pct_l3, pct_l4, pct_l5, pct_l6,
      proficient_above,
      is_state, is_district, is_school, is_charter
    )
}


#' Fetch ACCESS for ELLs data
#'
#' Downloads and processes ACCESS for ELLs (English Language Learner)
#' assessment results. ACCESS measures English language proficiency
#' for ELL students across grades K-12.
#'
#' @param end_year A school year. Valid values are 2022-2024.
#' @param grade Grade level: "K" or 0 for Kindergarten, 1-12 for other grades,
#'   or "all" (default) to get all grades combined.
#' @return Processed ACCESS dataframe with columns including:
#'   \itemize{
#'     \item testing_year, assess_name, test_name, grade
#'     \item county_id, county_name, district_id, district_name
#'     \item school_id, school_name, valid_scores
#'     \item pct_l1 through pct_l6 (proficiency level percentages)
#'     \item proficient_above (L5 + L6 percentage)
#'   }
#' @export
#' @examples
#' \dontrun{
#' # Get 2024 ACCESS results for all grades
#' access_2024 <- fetch_access(2024)
#'
#' # Get 2024 ACCESS results for Grade 3 only
#' access_g3 <- fetch_access(2024, grade = 3)
#'
#' # Get Kindergarten ACCESS results
#' access_k <- fetch_access(2024, grade = "K")
#' }
fetch_access <- function(end_year, grade = "all") {

  if (end_year < 2022) {
    stop("ACCESS for ELLs data is only available starting in 2022")
  }

  access_data <- get_raw_access(end_year, grade)
  process_access(access_data, end_year)
}


#' Fetch all ACCESS for ELLs results
#'
#' Convenience function to download and combine all available ACCESS
#' for ELLs results into a single data frame.
#'
#' @return A data frame with all ACCESS results (2022-2024, all grades)
#' @export
#' @examples
#' \dontrun{
#' # Get all ACCESS results (takes a while)
#' all_access <- fetch_all_access()
#' }
fetch_all_access <- function() {

  access_results <- list()

  # ACCESS data available 2022-2024
  valid_years <- c(2022:2024)

  for (year in valid_years) {
    result <- tryCatch(
      {
        fetch_access(end_year = year, grade = "all")
      },
      error = function(e) {
        message(sprintf("Could not fetch ACCESS %s: %s", year, e$message))
        NULL
      }
    )

    if (!is.null(result)) {
      access_results[[as.character(year)]] <- result
    }
  }

  dplyr::bind_rows(access_results)
}


# -----------------------------------------------------------------------------
# Chronic Absenteeism Functions
# -----------------------------------------------------------------------------

#' Get the URL for ESSA Accountability Workbook containing chronic absenteeism data
#'
#' Builds the URL for a given year's accountability workbook file.
#'
#' @param end_year A school year (2017-2024, excluding 2020-2021)
#' @return URL string
#' @keywords internal
get_chronic_absenteeism_url <- function(end_year) {

  valid_years <- c(2017, 2018, 2019, 2022, 2023, 2024)
  if (!end_year %in% valid_years) {
    stop(paste0(
      "Chronic absenteeism data is available for years: ",
      paste(valid_years, collapse = ", "),
      ". Years 2020-2021 were not reported due to COVID-19."
    ))
  }

  stem <- "https://www.nj.gov/education/title1/accountability/docs/"

  # URL patterns differ by year
  urls <- list(
    "2024" = paste0(stem, "2024/2023_24_Accountability_Workbook_File_Comprehensive_Support_and_Improvement.xlsx"),
    "2023" = paste0(stem, "2024/2022_2023_Accountability_Workbook_File_Comprehensive_Support_and_Improvement.xlsx"),
    "2022" = paste0(stem, "22/Public_Comprehensive_Workbook_File_January_2023.xlsx"),
    "2019" = paste0(stem, "19/2018-19%20Accountability%20Workbook%20File,%20Comprehensive%20Support%20and%20Improvement.xlsx"),
    "2018" = paste0(stem, "18/Final%202017-18%20Accountability%20Workbook%20File,%20Comprehensive%20Support%20and%20Improvement.xlsx"),
    "2017" = paste0(stem, "18/Final%202016-17%20Accountability%20Workbook%20File,%20Comprehensive%20Support%20and%20Improvement.xlsx")
  )

  urls[[as.character(end_year)]]
}


#' Fetch Chronic Absenteeism data
#'
#' Downloads and processes chronic absenteeism data from ESSA Accountability
#' Workbooks. Data shows attendance rates by student subgroup; chronic
#' absenteeism rate = 100 - attendance rate.
#'
#' Note: This data is from ESSA accountability workbooks and covers schools
#' included in ESSA accountability calculations (approximately 2,300+ schools).
#' Data for 2020-2021 is not available due to COVID-19 pandemic disruptions.
#'
#' @param end_year A school year. Valid values are 2017-2019 and 2022-2024.
#' @return Processed chronic absenteeism dataframe with columns including:
#'   \itemize{
#'     \item county_id, district_id, school_id, configuration
#'     \item Attendance rates by student subgroup (asian, black, hispanic, etc.)
#'     \item total_attendance_rate, total_chronic_absenteeism_rate
#'   }
#' @export
#' @examples
#' \dontrun{
#' # Get 2024 chronic absenteeism data
#' ca_2024 <- fetch_chronic_absenteeism(2024)
#'
#' # Calculate chronic absenteeism rates
#' ca_2024$chronic_absent_black <- 100 - ca_2024$attendance_black
#' }
fetch_chronic_absenteeism <- function(end_year) {

  target_url <- get_chronic_absenteeism_url(end_year)

  tname <- tempfile(pattern = "ca", tmpdir = tempdir(), fileext = ".xlsx")
  downloader::download(target_url, destfile = tname, mode = "wb")

  # Read Chronic Absenteeism sheet
  ca_data <- readxl::read_excel(
    path = tname,
    sheet = "Chronic Absenteeism",
    skip = 6,
    na = c("*", "N", "NA", ""),
    guess_max = 5000
  )

  # Standardize column names
  # The columns are: County Code, District Code, School Code, Configuration,

  # then attendance rates by subgroup, then z-scores and indicator scores
  col_names <- c(
    "county_id", "district_id", "school_id", "configuration",
    "attendance_asian_pacific", "attendance_black", "attendance_ed",
    "attendance_hispanic", "attendance_ell", "attendance_native_american",
    "attendance_multiracial", "attendance_swd", "attendance_white",
    "attendance_total"
  )

  # Only rename the first 14 columns (the rest are z-scores and summary stats)
  if (ncol(ca_data) >= 14) {
    names(ca_data)[1:14] <- col_names
  }

  # Keep only the relevant columns
  ca_data <- ca_data[, 1:min(14, ncol(ca_data))]

  # Make attendance columns numeric
  attendance_cols <- grep("^attendance_", names(ca_data), value = TRUE)
  for (col in attendance_cols) {
    ca_data[[col]] <- as.numeric(ca_data[[col]])
  }

  # Add metadata
  ca_data$testing_year <- end_year

  # Calculate chronic absenteeism rate (100 - attendance rate)
  ca_data$chronic_absenteeism_total <- 100 - ca_data$attendance_total

  # Remove rows without county_id
  ca_data <- ca_data %>%
    dplyr::filter(!is.na(county_id))

  # Tag record types
  ca_data$is_school <- TRUE
  ca_data$is_district <- FALSE
  ca_data$is_charter <- ca_data$county_id == "80"

  # Reorder columns
  ca_data %>%
    dplyr::select(
      testing_year,
      county_id, district_id, school_id, configuration,
      dplyr::starts_with("attendance_"),
      chronic_absenteeism_total,
      is_school, is_district, is_charter
    )
}


#' Fetch all Chronic Absenteeism data
#'
#' Convenience function to download and combine all available chronic
#' absenteeism data into a single data frame.
#'
#' @return A data frame with all chronic absenteeism results (2017-2019, 2022-2024)
#' @export
#' @examples
#' \dontrun{
#' # Get all chronic absenteeism data
#' all_ca <- fetch_all_chronic_absenteeism()
#' }
fetch_all_chronic_absenteeism <- function() {

  ca_results <- list()

  # Chronic absenteeism data available 2017-2019, 2022-2024
  # (2020-2021 not reported due to COVID)
  valid_years <- c(2017, 2018, 2019, 2022, 2023, 2024)

  for (year in valid_years) {
    result <- tryCatch(
      {
        fetch_chronic_absenteeism(end_year = year)
      },
      error = function(e) {
        message(sprintf("Could not fetch chronic absenteeism %s: %s", year, e$message))
        NULL
      }
    )

    if (!is.null(result)) {
      ca_results[[as.character(year)]] <- result
    }
  }

  dplyr::bind_rows(ca_results)
}


# -----------------------------------------------------------------------------
# Postsecondary Enrollment Functions
# -----------------------------------------------------------------------------

#' Parse postsecondary enrollment range string
#'
#' Extracts lower and upper bounds from range strings like "58.3-60.1%"
#'
#' @param range_string Character vector of range strings
#' @return Data frame with lower_bound and upper_bound columns
#' @keywords internal
parse_postsec_range <- function(range_string) {
  # Handle NA and "N" values
  lower <- rep(NA_real_, length(range_string))
  upper <- rep(NA_real_, length(range_string))

  # Find valid ranges (contain a dash and percent)
  valid <- !is.na(range_string) & grepl("-", range_string) & grepl("%", range_string)

  if (any(valid)) {
    # Extract the two numbers from strings like "58.3-60.1%"
    cleaned <- gsub("%", "", range_string[valid])
    parts <- strsplit(cleaned, "-")
    lower[valid] <- as.numeric(sapply(parts, `[`, 1))
    upper[valid] <- as.numeric(sapply(parts, `[`, 2))
  }

  data.frame(lower_bound = lower, upper_bound = upper)
}


#' Fetch Postsecondary Enrollment Rates
#'
#' Downloads postsecondary enrollment rate data from the NJ DOE website.
#' Data is sourced from the National Student Clearinghouse and shows the
#' percentage of high school graduates enrolling in postsecondary institutions.
#'
#' @details
#' The data includes both school-level and district-level rates. Rates are
#' reported as ranges because a small percentage of graduates cannot be
#' matched to the National Student Clearinghouse database.
#'
#' Two measurement types are available:
#' \itemize{
#'   \item \code{fall}: Enrollment in fall immediately after graduation
#'   \item \code{16_month}: Enrollment within 16 months of graduation
#' }
#'
#' The \code{lower_bound} represents confirmed enrollments only (conservative).
#' The \code{upper_bound} assumes non-matched graduates also enrolled (optimistic).
#'
#' @return A data frame with postsecondary enrollment rates in long format,
#'   containing columns for county, district, school identifiers, cohort_year,
#'   measurement_type (fall or 16_month), lower_bound, and upper_bound.
#' @export
#' @examples
#' \dontrun{
#' # Get all postsecondary enrollment data
#' postsec <- fetch_postsecondary()
#'
#' # Filter for 16-month rates only
#' postsec_16mo <- postsec[postsec$measurement_type == "16_month", ]
#'
#' # Filter for district-level data only
#' district_rates <- postsec[postsec$is_district, ]
#' }
fetch_postsecondary <- function() {

  target_url <- paste0(
    "https://www.nj.gov/education/schoolperformance/grad/docs/",
    "Postsecondary_Enrollment_Rate_Trends_Fall_16month_Rates.xlsx"
  )

  tname <- tempfile(pattern = "postsec", tmpdir = tempdir(), fileext = ".xlsx")
  downloader::download(target_url, destfile = tname, mode = "wb")

  # Read with skip = 9 to get the header row
  postsec_raw <- readxl::read_excel(
    path = tname,
    sheet = 1,
    skip = 9,
    na = c("N", "NA", ""),
    guess_max = 5000
  )

  # Clean column names
  postsec_raw <- janitor::clean_names(postsec_raw)

  # Rename identifier columns
  postsec_raw <- postsec_raw %>%
    dplyr::rename(
      cds_code = cds_county_district_school_code,
      record_type = school_district_state
    )

  # Identify fall and 16-month columns
  fall_cols <- grep("^fall_postsecondary", names(postsec_raw), value = TRUE)
  month16_cols <- grep("^x16_month_postsecondary", names(postsec_raw), value = TRUE)

  # Process fall enrollment columns
  fall_data <- list()
  for (col in fall_cols) {
    # Extract year from column name (e.g., "fall_postsecondary_enrollment_class_of_2019")
    year <- as.integer(gsub(".*class_of_", "", col))
    bounds <- parse_postsec_range(postsec_raw[[col]])

    fall_data[[as.character(year)]] <- postsec_raw %>%
      dplyr::select(
        cds_code, county_code, county_name, district_code, district_name,
        school_code, school_name, record_type
      ) %>%
      dplyr::mutate(
        cohort_year = year,
        measurement_type = "fall",
        lower_bound = bounds$lower_bound,
        upper_bound = bounds$upper_bound
      )
  }

  # Process 16-month enrollment columns
  month16_data <- list()
  for (col in month16_cols) {
    # Extract year from column name
    year <- as.integer(gsub(".*class_of_", "", col))
    bounds <- parse_postsec_range(postsec_raw[[col]])

    month16_data[[as.character(year)]] <- postsec_raw %>%
      dplyr::select(
        cds_code, county_code, county_name, district_code, district_name,
        school_code, school_name, record_type
      ) %>%
      dplyr::mutate(
        cohort_year = year,
        measurement_type = "16_month",
        lower_bound = bounds$lower_bound,
        upper_bound = bounds$upper_bound
      )
  }

  # Combine all data
  postsec_long <- dplyr::bind_rows(
    dplyr::bind_rows(fall_data),
    dplyr::bind_rows(month16_data)
  )

  # Rename to standard column names
  postsec_long <- postsec_long %>%
    dplyr::rename(
      county_id = county_code,
      district_id = district_code,
      school_id = school_code
    )

  # Add flags for record type

  postsec_long <- postsec_long %>%
    dplyr::mutate(
      is_school = record_type == "School",
      is_district = record_type == "District",
      is_state = record_type == "State",
      is_charter = county_id == "80"
    )

  # Remove rows without valid data
  postsec_long <- postsec_long %>%
    dplyr::filter(!is.na(lower_bound) | !is.na(upper_bound))

  # Reorder columns
  postsec_long %>%
    dplyr::select(
      cohort_year, measurement_type,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      cds_code, record_type,
      lower_bound, upper_bound,
      is_school, is_district, is_state, is_charter
    ) %>%
    dplyr::arrange(cohort_year, measurement_type, county_id, district_id, school_id)
}
