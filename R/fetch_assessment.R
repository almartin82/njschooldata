# ==============================================================================
# Assessment Data Fetching Functions
# ==============================================================================
#
# This file contains functions for downloading PARCC/NJSLA assessment data from
# the NJ Department of Education website.
#
# ==============================================================================

.parse_assessment_workbook <- function(path, skip) {
  data <- readxl::read_excel(
    path = path, skip = skip, na = "*", guess_max = 30000
  )
  if (nrow(data) < 3L) {
    stop("Assessment workbook has no data rows before its two note rows.",
         call. = FALSE)
  }
  data[seq_len(nrow(data) - 2L), , drop = FALSE]
}

.assessment_source_result <- function(url, skip,
                                      request_fn = .default_source_request) {
  transport <- download_source(
    url, source_type = "xlsx", request_fn = request_fn
  )
  if (!identical(transport$source_status, "actual")) return(transport)
  on.exit(unlink(transport$data), add = TRUE)
  parsed <- tryCatch(
    .parse_assessment_workbook(transport$data, skip),
    error = identity
  )
  if (inherits(parsed, "error")) {
    return(new_source_result(
      source_status = "parse_error",
      source_url = transport$source_url,
      retrieved_at = transport$retrieved_at,
      digest = transport$digest,
      error = conditionMessage(parsed)
    ))
  }
  new_source_result(
    data = parsed,
    source_status = "actual",
    source_url = transport$source_url,
    retrieved_at = transport$retrieved_at,
    digest = transport$digest
  )
}

#' Retrieve raw PARCC data with source provenance
#' @inheritParams get_raw_parcc
#' @param request_fn Injectable transport request function.
#' @return An `njsd_source_result`.
#' @keywords internal
get_raw_parcc_result <- function(end_year, grade_or_subj, subj,
                                 request_fn = .default_source_request) {
  validate_end_year(end_year, "parcc")
  url <- resolve_source_url(
    "parcc", end_year = end_year, grade = grade_or_subj, subject = subj
  )
  .assessment_source_result(url, skip = 2L, request_fn = request_fn)
}

#' Reads raw PARCC data from the state website
#' @param end_year School-year end year.
#' @param grade_or_subj Grade or course.
#' @param subj Subject.
#' @return PARCC data frame.
#' @keywords internal
get_raw_parcc <- function(end_year, grade_or_subj, subj) {
  source_result_data(get_raw_parcc_result(end_year, grade_or_subj, subj))
}

#' Retrieve raw NJSLA data with source provenance
#' @inheritParams get_raw_parcc
#' @param request_fn Injectable transport request function.
#' @return An `njsd_source_result`.
#' @keywords internal
get_raw_sla_result <- function(end_year, grade_or_subj, subj,
                               request_fn = .default_source_request) {
  validate_end_year(end_year, "parcc")
  url <- resolve_source_url(
    "parcc", end_year = end_year, grade = grade_or_subj, subject = subj
  )
  .assessment_source_result(url, skip = 2L, request_fn = request_fn)
}

#' Reads raw NJSLA data from the state website
#' @inheritParams get_raw_parcc
#' @return NJSLA data frame.
#' @keywords internal
get_raw_sla <- function(end_year, grade_or_subj, subj) {
  source_result_data(get_raw_sla_result(end_year, grade_or_subj, subj))
}

#' Retrieve raw NJGPA data with source provenance
#' @param end_year School-year end year.
#' @param subj Subject.
#' @param request_fn Injectable transport request function.
#' @return An `njsd_source_result`.
#' @keywords internal
get_raw_njgpa_result <- function(end_year, subj,
                                 request_fn = .default_source_request) {
  validate_end_year(end_year, "njgpa")
  url <- resolve_source_url("njgpa", end_year = end_year, subject = subj)
  .assessment_source_result(url, skip = 3L, request_fn = request_fn)
}

#' Reads raw NJGPA data from the state website
#' @param end_year School-year end year.
#' @param subj Subject.
#' @return NJGPA data frame.
#' @keywords internal
get_raw_njgpa <- function(end_year, subj) {
  source_result_data(get_raw_njgpa_result(end_year, subj))
}


#' Gets and cleans up a PARCC data file
#'
#' `fetch_parcc` is a wrapper around `get_raw_parcc` and `process_parcc`
#' that gets a parcc file and performs any cleanup.
#'
#' @param end_year A school year. end_year is the end of the academic year - eg 2014-15
#' school year is end_year 2015. Valid values are 2015-2025.
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
    source_result <- get_raw_sla_result(end_year, grade_or_subj, subj)
  } else {
    source_result <- get_raw_parcc_result(end_year, grade_or_subj, subj)
  }
  source_result <- transform_source_result(source_result, function(p) {
    p <- process_parcc(p, end_year, grade_or_subj, subj)
    if (tidy) {
      p$subgroup <- tidy_parcc_subgroup(p$subgroup)
      p <- p %>% parcc_perf_level_counts()
    }
    p
  })
  p <- source_result_data(source_result)

  attach_source_results(
    p,
    source_result_record(
      source_result, "parcc", end_year,
      paste(toupper(subj), grade_or_subj, sep = "-")
    )
  )
}


#' Fetch NJGPA (NJ Graduation Proficiency Assessment) data
#'
#' Downloads and processes NJGPA assessment results. NJGPA is the graduation
#' requirement assessment introduced in 2022, replacing the previous PARCC-based
#' graduation pathway.
#'
#' @param end_year A school year. Valid values are 2022-2025.
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

  source_result <- get_raw_njgpa_result(end_year, subj)
  source_result <- transform_source_result(source_result, function(p) {
    # Use the same processing as PARCC/NJSLA
    p <- process_parcc(p, end_year, grade = "GP", subj = subj)
    if (tidy) {
      p$subgroup <- tidy_parcc_subgroup(p$subgroup)
      p <- p %>% parcc_perf_level_counts()
    }
    p
  })
  p <- source_result_data(source_result)

  attach_source_results(
    p,
    source_result_record(
      source_result, "njgpa", end_year, toupper(subj)
    )
  )
}


#' Build the registered PARCC/NJSLA request grid
#'
#' @param include_science Include science assessments (2019+)? Default is TRUE.
#' @return A data frame with one row per requested year, grade, and subject.
#' @keywords internal
.parcc_request_grid <- function(include_science = TRUE) {
  years <- get_source_years("parcc")
  requests <- list()
  for (year in years) {
    ela_grades <- if (year >= 2019) 3:10 else 3:11
    requests[[length(requests) + 1L]] <- expand.grid(
      end_year = year, grade = ela_grades, subject = "ela",
      stringsAsFactors = FALSE
    )
    requests[[length(requests) + 1L]] <- expand.grid(
      end_year = year, grade = 3:8, subject = "math",
      stringsAsFactors = FALSE
    )
    requests[[length(requests) + 1L]] <- expand.grid(
      end_year = year, grade = c("ALG1", "GEO", "ALG2"), subject = "math",
      stringsAsFactors = FALSE
    )
    if (isTRUE(include_science) && year >= 2019) {
      requests[[length(requests) + 1L]] <- expand.grid(
        end_year = year, grade = c(5, 8, 11), subject = "science",
        stringsAsFactors = FALSE
      )
    }
  }
  dplyr::bind_rows(requests)
}

#' Fetch all PARCC results
#'
#' Convenience function to download and combine all PARCC/NJSLA results
#' into single data frame, including ELA, Math, and Science assessments.
#'
#' @param include_science Include science assessments (2019+)? Default is TRUE.
#' @param allow_partial If `FALSE` (default), any unavailable or unparseable
#'   requested source fails the combined request. If `TRUE`, successful sources
#'   are returned and every request is reported by [get_source_results()].
#' @return A data frame with all PARCC/NJSLA results and source-result records.
#' @export
#' @examples
#' \dontrun{
#' # Get all PARCC/NJSLA results (takes a while)
#' all_parcc <- fetch_all_parcc()
#'
#' # Exclude science assessments
#' all_parcc_no_sci <- fetch_all_parcc(include_science = FALSE)
#' }
fetch_all_parcc <- function(include_science = TRUE, allow_partial = FALSE) {
  requests <- .parcc_request_grid(include_science)
  captures <- lapply(seq_len(nrow(requests)), function(index) {
    request <- requests[index, ]
    grade <- if (grepl("^[0-9]+$", request$grade)) {
      as.integer(request$grade)
    } else {
      request$grade
    }
    capture_source_call(
      function() fetch_parcc(
        end_year = request$end_year,
        grade_or_subj = grade,
        subj = request$subject,
        tidy = TRUE
      ),
      domain = "parcc",
      end_year = request$end_year,
      component = paste(grade, request$subject, sep = "/")
    )
  })
  combine_source_captures(
    captures, allow_partial = allow_partial,
    context = "PARCC/NJSLA multi-source request"
  )
}


#' Fetch all NJGPA results
#'
#' Convenience function to download and combine all NJGPA (graduation proficiency)
#' results into a single data frame.
#'
#' @param allow_partial If `FALSE` (default), any unavailable or unparseable
#'   subject fails the request. If `TRUE`, successful subjects are returned and
#'   all subject/year statuses are available through [get_source_results()].
#' @return A data frame with all NJGPA results (ELA and Math) and source status.
#' @export
#' @examples
#' \dontrun{
#' # Get all NJGPA results
#' all_njgpa <- fetch_all_njgpa()
#' }
fetch_all_njgpa <- function(allow_partial = FALSE) {
  requests <- expand.grid(
    end_year = get_source_years("njgpa"),
    subject = c("ela", "math"),
    stringsAsFactors = FALSE
  )
  captures <- lapply(seq_len(nrow(requests)), function(index) {
    request <- requests[index, ]
    capture_source_call(
      function() fetch_njgpa(request$end_year, request$subject, tidy = TRUE),
      domain = "njgpa", end_year = request$end_year,
      component = request$subject
    )
  })
  combine_source_captures(
    captures, allow_partial = allow_partial,
    context = "NJGPA multi-source request"
  )
}


# -----------------------------------------------------------------------------
# ACCESS for ELLs Functions
# -----------------------------------------------------------------------------

#' Get the URL for ACCESS for ELLs data file
#'
#' Builds the URL for a given year's ACCESS data file.
#' URL structure changed between years.
#'
#' @param end_year A school year (2022-2025)
#' @return URL string
#' @keywords internal
get_access_url <- function(end_year) {
  validate_end_year(end_year, "access")
  resolve_source_url("access", end_year = end_year)
}


#' Parse a validated ACCESS for ELLs workbook
#'
#' Reads a specific grade sheet from an adapter-validated local workbook.
#'
#' @param path Path to a validated ACCESS workbook.
#' @param grade Grade level: "K" or 0 for Kindergarten, or 1-12 for other grades.
#'   Use "all" to get all grades combined.
#' @return ACCESS dataframe for the specified grade
#' @keywords internal
.parse_access_workbook <- function(path, grade = "all") {
  # Map grade to sheet name
  if (grade == "all") {
    # Read all grade sheets and combine
    sheets <- readxl::excel_sheets(path)
    # Skip first sheet (Workbook Overview)
    grade_sheets <- sheets[sheets != sheets[1]]

    all_data <- lapply(grade_sheets, function(sheet) {
      df <- readxl::read_excel(
        path = path, sheet = sheet, skip = 3, na = "*", guess_max = 10000
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
      path = path, sheet = sheet_name, skip = 3, na = "*", guess_max = 10000
    )
    access_data$grade <- grade_label
  }

  access_data
}

get_raw_access_result <- function(end_year, grade = "all",
                                  request_fn = .default_source_request) {
  target_url <- get_access_url(end_year)
  transport <- download_source(
    target_url, source_type = "xlsx", request_fn = request_fn
  )
  if (!identical(transport$source_status, "actual")) return(transport)
  on.exit(unlink(transport$data), add = TRUE)

  parsed <- tryCatch(
    .parse_access_workbook(transport$data, grade),
    error = identity
  )
  if (inherits(parsed, "error")) {
    return(new_source_result(
      source_status = "parse_error", source_url = transport$source_url,
      retrieved_at = transport$retrieved_at, digest = transport$digest,
      error = conditionMessage(parsed)
    ))
  }
  new_source_result(
    data = parsed, source_status = "actual",
    source_url = transport$source_url,
    retrieved_at = transport$retrieved_at, digest = transport$digest
  )
}

get_raw_access <- function(end_year, grade = "all") {
  source_result_data(get_raw_access_result(end_year, grade))
}


#' Process raw ACCESS for ELLs data
#'
#' Cleans and standardizes ACCESS data.
#'
#' @param access_file Output of get_raw_access
#' @param end_year A school year (2022-2025)
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
  access_file <- access_file %>%
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

  # Every ACCESS test-taker is a current English Learner, so the standardized
  # subgroup is `lep`. Appended at the tail (additive) so the join to the EL
  # population feature (fetch_ell) shares a subgroup vocabulary. subgroup_std
  # lands immediately after subgroup.
  access_file$subgroup <- "limited english proficiency"
  add_subgroup_std(access_file)
}


#' Fetch ACCESS for ELLs data
#'
#' Downloads and processes ACCESS for ELLs (English Language Learner)
#' assessment results. ACCESS measures English language proficiency
#' for ELL students across grades K-12.
#'
#' @param end_year A school year. Valid values are 2022-2025.
#' @param grade Grade level: "K" or 0 for Kindergarten, 1-12 for other grades,
#'   or "all" (default) to get all grades combined.
#' @return Processed ACCESS dataframe with columns including:
#'   \itemize{
#'     \item testing_year, assess_name, test_name, grade
#'     \item county_id, county_name, district_id, district_name
#'     \item school_id, school_name, valid_scores
#'     \item pct_l1 through pct_l6 (proficiency level percentages)
#'     \item proficient_above (L5 + L6 percentage)
#'     \item subgroup, subgroup_std (always the English Learner group; `lep`)
#'   }
#' @seealso [fetch_ell()] for the EL **population** feature (headcount and share
#'   of enrollment), which joins to these proficiency results on the CDS id
#'   backbone.
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
  source_result <- get_raw_access_result(end_year, grade)
  access_data <- source_result_data(source_result)
  out <- process_access(access_data, end_year)
  attach_source_results(
    out,
    source_result_record(source_result, "access", end_year, as.character(grade))
  )
}


#' Fetch all ACCESS for ELLs results
#'
#' Convenience function to download and combine all available ACCESS
#' for ELLs results into a single data frame.
#'
#' @param allow_partial If `FALSE` (default), a failed year aborts the request.
#'   If `TRUE`, successful years are returned with request status available from
#'   [get_source_results()].
#' @return A data frame with all ACCESS results (2022-2025, all grades)
#' @export
#' @examples
#' \dontrun{
#' # Get all ACCESS results (takes a while)
#' all_access <- fetch_all_access()
#' }
fetch_all_access <- function(allow_partial = FALSE) {
  years <- get_source_years("access")
  captures <- lapply(years, function(year) {
    capture_source_call(
      function() fetch_access(end_year = year, grade = "all"),
      domain = "access", end_year = year, component = "all"
    )
  })
  combine_source_captures(
    captures, allow_partial = allow_partial,
    context = "ACCESS multi-year request"
  )
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
  validate_end_year(end_year, "essa_chronic_absence")
  resolve_source_url("essa_chronic_absence", end_year = end_year)
}

.get_raw_essa_chronic_absence_result <- function(
    end_year, request_fn = .default_source_request) {
  target_url <- get_chronic_absenteeism_url(end_year)
  transport <- download_source(
    target_url, source_type = "xlsx", request_fn = request_fn
  )
  if (!identical(transport$source_status, "actual")) return(transport)
  on.exit(unlink(transport$data), add = TRUE)

  parsed <- tryCatch(
    readxl::read_excel(
      path = transport$data,
      sheet = "Chronic Absenteeism",
      skip = 6,
      na = c("*", "N", "NA", ""),
      guess_max = 5000
    ),
    error = identity
  )
  if (inherits(parsed, "error")) {
    return(new_source_result(
      source_status = "parse_error", source_url = transport$source_url,
      retrieved_at = transport$retrieved_at, digest = transport$digest,
      error = conditionMessage(parsed)
    ))
  }
  new_source_result(
    data = parsed, source_status = "actual",
    source_url = transport$source_url,
    retrieved_at = transport$retrieved_at, digest = transport$digest
  )
}


#' Fetch ESSA Chronic Absenteeism data
#'
#' Downloads and processes chronic absenteeism data from ESSA Accountability
#' Workbooks. Data shows attendance rates by student subgroup; chronic
#' absenteeism rate = 100 - attendance rate.
#'
#' Note: This data is from ESSA accountability workbooks and covers schools
#' included in ESSA accountability calculations (approximately 2,300+ schools).
#' Data for 2020-2021 is not available due to COVID-19 pandemic disruptions.
#'
#' For chronic absenteeism data from SPR databases (2017-2024), use
#' \code{\link{fetch_chronic_absenteeism}} instead.
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
#' # Get 2024 chronic absenteeism data from ESSA workbooks
#' ca_2024 <- fetch_essa_chronic_absenteeism(2024)
#'
#' # Calculate chronic absenteeism rates
#' ca_2024$chronic_absent_black <- 100 - ca_2024$attendance_black
#' }
fetch_essa_chronic_absenteeism <- function(end_year) {
  source_result <- .get_raw_essa_chronic_absence_result(end_year)
  ca_data <- source_result_data(source_result)

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
  out <- ca_data %>%
    dplyr::select(
      testing_year,
      county_id, district_id, school_id, configuration,
      dplyr::starts_with("attendance_"),
      chronic_absenteeism_total,
      is_school, is_district, is_charter
    )
  attach_source_results(
    out,
    source_result_record(
      source_result, "essa_chronic_absence", end_year, "chronic"
    )
  )
}


#' Fetch all Chronic Absenteeism data
#'
#' Convenience function to download and combine all available chronic
#' absenteeism data into a single data frame.
#'
#' @param allow_partial If `FALSE` (default), any failed year aborts the
#'   combined request. If `TRUE`, successful years are returned with request
#'   status available from [get_source_results()].
#' @return A data frame with all chronic absenteeism results (2017-2019, 2022-2024)
#' @export
#' @examples
#' \dontrun{
#' # Get all chronic absenteeism data
#' all_ca <- fetch_all_chronic_absenteeism()
#' }
fetch_all_chronic_absenteeism <- function(allow_partial = FALSE) {
  years <- get_source_years("essa_chronic_absence")
  captures <- lapply(years, function(year) {
    capture_source_call(
      function() fetch_essa_chronic_absenteeism(end_year = year),
      domain = "essa_chronic_absence", end_year = year,
      component = "chronic"
    )
  })
  combine_source_captures(
    captures, allow_partial = allow_partial,
    context = "ESSA chronic-absence multi-year request"
  )
}


# -----------------------------------------------------------------------------
# Postsecondary Enrollment Functions
# -----------------------------------------------------------------------------

#' Legacy Postsecondary Enrollment Trends Workbook
#'
#' The standalone NJ DOE postsecondary enrollment trends workbook that this
#' legacy function downloaded has been removed from the NJ DOE website.
#'
#' @details
#' The former source URL returned HTTP 404 when checked in July 2026. Use
#' \code{\link{fetch_postsecondary_enrollment}} instead; it reads the
#' postsecondary enrollment sheets from the School Performance Reports database
#' workbooks for supported years.
#'
#' @return This function always errors.
#' @export
fetch_postsecondary <- function() {
  stop(
    paste0(
      "The standalone NJ DOE postsecondary enrollment trends workbook was ",
      "removed from the NJ DOE site (HTTP 404 observed July 2026). Use ",
      "fetch_postsecondary_enrollment() instead."
    ),
    call. = FALSE
  )
}
