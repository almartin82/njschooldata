# ==============================================================================
# Input Validation Helpers for njschooldata
# ==============================================================================

# -----------------------------------------------------------------------------
# Year Range Configuration
# -----------------------------------------------------------------------------

#' Valid year ranges by data type
#' @keywords internal
year_ranges <- list(
  enrollment = list(min = 1999, max = 2025),
  parcc = list(min = 2015, max = 2024, skip = 2020),
  njask = list(min = 2004, max = 2014),
  hspa = list(min = 2004, max = 2014),
  gepa = list(min = 2004, max = 2007),
  grad_rate = list(min = 2011, max = 2024),
  grad_count = list(min = 2012, max = 2024),
  sped = list(min = 2002, max = 2019),
  tges = list(min = 1999, max = 2019),
  report_card = list(min = 2003, max = 2019),
  msgp = list(min = 2012, max = 2019),
  special_pop = list(min = 2017, max = 2019)
)

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------

#' Format valid values for error messages
#' @param values Vector of valid values
#' @param max_show Maximum number of values to show
#' @return Character string with formatted values
#' @keywords internal
format_valid_values <- function(values, max_show = 10) {
  if (length(values) > max_show) {
    shown <- c(
      utils::head(values, floor(max_show / 2)),
      "...",
      utils::tail(values, floor(max_show / 2))
    )
  } else {
    shown <- values
  }
  paste(shown, collapse = ", ")
}

#' Get valid years for a data type
#' @param data_type Character string identifying the data type
#' @return Integer vector of valid years
#' @export
#' @examples
#' get_valid_years("enrollment")
#' get_valid_years("parcc")
get_valid_years <- function(data_type) {
  range <- year_ranges[[data_type]]
  if (is.null(range)) {
    stop(sprintf("Unknown data type: '%s'", data_type))
  }

  valid_years <- seq(range$min, range$max)
  if (!is.null(range$skip)) {
    valid_years <- valid_years[!valid_years %in% range$skip]
  }

  valid_years
}

# -----------------------------------------------------------------------------
# Core Validation Functions
# -----------------------------------------------------------------------------

#' Validate end_year parameter
#'
#' Validates that end_year is a valid integer within the allowed range
#' for the specified data type.
#'
#' @param end_year The year to validate
#' @param data_type The type of data being requested (e.g., "enrollment", "parcc")
#' @return TRUE invisibly if valid, otherwise throws an error
#' @export
#' @examples
#' \dontrun{
#' validate_end_year(2024, "enrollment")  # Valid
#' validate_end_year(1990, "enrollment")  # Error: year out of range
#' validate_end_year(2020, "parcc")       # Error: COVID year
#' }
validate_end_year <- function(end_year, data_type) {
  # Type check

if (!is.numeric(end_year) || length(end_year) != 1) {
    stop(
      sprintf(
        "`end_year` must be a single numeric value, not %s.",
        class(end_year)[1]
      ),
      call. = FALSE
    )
  }

  # Integer check
  if (end_year != as.integer(end_year)) {
    stop(
      sprintf(
        "`end_year` must be an integer (e.g., 2024), not %.2f.",
        end_year
      ),
      call. = FALSE
    )
  }

  # Get valid years for this data type
  valid_years <- tryCatch(
    get_valid_years(data_type),
    error = function(e) {
      stop(
        sprintf("Unknown data_type: '%s'", data_type),
        call. = FALSE
      )
    }
  )

  # Range check
  if (!end_year %in% valid_years) {
    range <- year_ranges[[data_type]]

    # Special message for COVID year
    if (!is.null(range$skip) && end_year %in% range$skip) {
      stop(
        sprintf(
          "`end_year` = %d is not available for %s data.\n%s",
          end_year,
          gsub("_", " ", data_type),
          "Note: 2020 assessments were cancelled due to COVID-19."
        ),
        call. = FALSE
      )
    }

    stop(
      sprintf(
        "`end_year` = %d is not valid for %s data.\nValid years: %s",
        end_year,
        gsub("_", " ", data_type),
        format_valid_values(valid_years)
      ),
      call. = FALSE
    )
  }

  invisible(TRUE)
}

#' Validate grade parameter
#'
#' Validates that grade is valid for the specified assessment type and year.
#'
#' @param grade The grade to validate (numeric or character like "ALG1")
#' @param assessment_type The type of assessment ("njask", "parcc", etc.)
#' @param end_year The year of the assessment
#' @return TRUE invisibly if valid, otherwise throws an error
#' @export
validate_grade <- function(grade, assessment_type, end_year) {
  valid_grades <- get_valid_grades(assessment_type, end_year)

  if (is.null(valid_grades)) {
    stop(
      sprintf("Unknown assessment type: '%s'", assessment_type),
      call. = FALSE
    )
  }

  # Handle both numeric and character grades
  grade_valid <- if (is.numeric(grade)) {
    grade %in% valid_grades
  } else {
    toupper(grade) %in% toupper(as.character(valid_grades))
  }

  if (!grade_valid) {
    stop(
      sprintf(
        "`grade` = %s is not valid for %s in %d.\nValid grades: %s",
        format(grade),
        assessment_type,
        end_year,
        format_valid_values(valid_grades)
      ),
      call. = FALSE
    )
  }

  invisible(TRUE)
}

#' Get valid grades for an assessment type and year
#'
#' Returns the valid grade levels for a given assessment type and year.
#'
#' @param assessment_type The type of assessment
#' @param end_year The year of the assessment
#' @return Vector of valid grades (may include character values like "ALG1")
#' @export
#' @examples
#' get_valid_grades("njask", 2010)
#' get_valid_grades("parcc", 2023)
get_valid_grades <- function(assessment_type, end_year) {
  if (assessment_type == "njask") {
    if (end_year >= 2008) {
      return(3:8)
    } else if (end_year %in% c(2006, 2007)) {
      return(3:7)
    } else {
      return(c(3, 4))
    }
  } else if (assessment_type == "parcc") {
    # NJSLA (2019+) or PARCC (2015-2018)
    if (end_year >= 2019) {
      return(c(3:10, "ALG1", "GEO", "ALG2"))
    } else {
      return(c(3:11, "ALG1", "GEO", "ALG2"))
    }
  } else if (assessment_type == "hspa") {
    return(11)
  } else if (assessment_type == "gepa") {
    return(8)
  }

  NULL
}

#' Validate subject parameter
#'
#' Validates that subject is either "ela" or "math".
#'
#' @param subj The subject to validate
#' @return TRUE invisibly if valid, otherwise throws an error
#' @keywords internal
validate_subject <- function(subj) {
  valid_subjects <- c("ela", "math")

  if (!tolower(subj) %in% valid_subjects) {
    stop(
      sprintf(
        '`subj` = "%s" is not valid.\nValid subjects: %s',
        subj,
        paste(valid_subjects, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  invisible(TRUE)
}

#' Validate methodology parameter for graduation data
#'
#' Validates that methodology is either "4 year" or "5 year" and
#' that 5-year rates are available for the specified year.
#'
#' @param methodology The methodology to validate
#' @param end_year Optional year to check availability
#' @return TRUE invisibly if valid, otherwise throws an error
#' @keywords internal
validate_methodology <- function(methodology, end_year = NULL) {
  valid_methodologies <- c("4 year", "5 year")

  if (!methodology %in% valid_methodologies) {
    stop(
      sprintf(
        '`methodology` = "%s" is not valid.\nValid values: %s',
        methodology,
        paste(valid_methodologies, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  # 5 year not available before 2012
  if (!is.null(end_year) && methodology == "5 year" && end_year < 2012) {
    stop(
      sprintf(
        "5-year graduation rate is not available before 2012. Got end_year = %d.",
        end_year
      ),
      call. = FALSE
    )
  }

  invisible(TRUE)
}

#' Validate logical/boolean parameter
#'
#' @param value The value to validate
#' @param param_name The name of the parameter (for error messages)
#' @return TRUE invisibly if valid, otherwise throws an error
#' @keywords internal
validate_logical <- function(value, param_name) {
  if (!is.logical(value) || length(value) != 1 || is.na(value)) {
    stop(
      sprintf(
        '`%s` must be TRUE or FALSE, not %s.',
        param_name,
        format(value)
      ),
      call. = FALSE
    )
  }

  invisible(TRUE)
}

# -----------------------------------------------------------------------------
# Combined Validation for Common Patterns
# -----------------------------------------------------------------------------

#' Validate PARCC/NJSLA parameters
#'
#' Validates all parameters for fetch_parcc() in one call.
#'
#' @param end_year The year
#' @param grade_or_subj The grade or subject code
#' @param subj The subject ("ela" or "math")
#' @return TRUE invisibly if valid, otherwise throws an error
#' @keywords internal
validate_parcc_call <- function(end_year, grade_or_subj, subj) {
  validate_end_year(end_year, "parcc")
  validate_subject(subj)

  # Grade validation depends on subject
  if (is.numeric(grade_or_subj)) {
    if (tolower(subj) == "ela") {
      valid <- if (end_year >= 2019) 3:10 else 3:11
    } else {
      valid <- 3:8
    }

    if (!grade_or_subj %in% valid) {
      assess_name <- if (end_year >= 2019) "NJSLA" else "PARCC"
      stop(
        sprintf(
          "Grade %d is not valid for %s %s in %d.\nValid grades: %s",
          grade_or_subj,
          toupper(subj),
          assess_name,
          end_year,
          format_valid_values(valid)
        ),
        call. = FALSE
      )
    }
  } else {
    # Character grade (ALG1, GEO, ALG2)
    valid_courses <- c("ALG1", "GEO", "ALG2")
    if (!toupper(grade_or_subj) %in% valid_courses) {
      stop(
        sprintf(
          '`grade_or_subj` = "%s" is not valid.\nValid values: %s or %s',
          grade_or_subj,
          paste(3:11, collapse = ", "),
          paste(valid_courses, collapse = ", ")
        ),
        call. = FALSE
      )
    }

    # Course-specific tests must be math
    if (tolower(subj) != "math") {
      stop(
        sprintf(
          "Course '%s' is only available for math, not %s.",
          grade_or_subj,
          subj
        ),
        call. = FALSE
      )
    }
  }

  invisible(TRUE)
}
