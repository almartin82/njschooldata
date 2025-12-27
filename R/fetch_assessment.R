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
    subj <- parse_parcc_subj(subj)
  } else if (grepl("ALG|GEO", grade_or_subj)) {
    parcc_grade <- gsub("ALG", "ALG0", grade_or_subj)
    subj <- ""
  } else {
    parcc_grade <- grade_or_subj
    subj <- parse_parcc_subj(subj)
  }

  stem <- "https://www.nj.gov/education/assessment/results/reports/"

  target_url <- paste0(
    stem, substr(end_year - 1, 3, 4), substr(end_year, 3, 4), "/spring/",
    subj, parcc_grade, "%20NJSLA%20DATA%20",
    # "2018-19"
    end_year - 1, "-", substr(end_year, 3, 4),
    ".xlsx"
  )
  # 19/njsla/spring/ALG01%20NJSLA%20DATA%202018-19.xlsx
  # 19/njsla/spring/ALG02%20NJSLA%20DATA%202018-19.xlsx

  tname <- tempfile(pattern = "njsla", tmpdir = tempdir(), fileext = ".xlsx")
  tdir <- tempdir()
  downloader::download(target_url, destfile = tname, mode = "wb")
  njsla <- readxl::read_excel(path = tname, skip = 2, na = "*", guess_max = 30000)

  # Last two rows are notes
  njsla <- njsla[1:(nrow(njsla) - 2), ]
  njsla
}


#' Gets and cleans up a PARCC data file
#'
#' `fetch_parcc` is a wrapper around `get_raw_parcc` and `process_parcc`
#' that gets a parcc file and performs any cleanup.
#'
#' @param end_year A school year. end_year is the end of the academic year - eg 2014-15
#' school year is end_year 2015. Valid values are 2015-2024.
#' @param grade_or_subj Grade level (eg 8) OR math subject code (eg ALG1, GEO, ALG2)
#' @param subj PARCC subject. c('ela' or 'math')
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
#' }
fetch_parcc <- function(end_year, grade_or_subj, subj, tidy = FALSE) {

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


#' Fetch all PARCC results
#'
#' Convenience function to download and combine all PARCC results
#' into single data frame.
#'
#' @return A data frame with all PARCC results
#' @export
#' @examples
#' \dontrun{
#' # Get all PARCC/NJSLA results (takes a while)
#' all_parcc <- fetch_all_parcc()
#' }
fetch_all_parcc <- function() {

  parcc_results <- list()

  # PARCC years 2015-2018, NJSLA 2019+
  # Note: 2020 assessments were cancelled due to COVID-19
  valid_years <- c(2015:2019, 2021:2024)

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
  }

  dplyr::bind_rows(parcc_results)
}
