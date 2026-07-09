# -----------------------------------------------------------------------------
# Postsecondary Enrollment
# -----------------------------------------------------------------------------

#' Fetch Postsecondary Enrollment Rates from SPR Databases
#'
#' Downloads postsecondary enrollment rates from the NJ DOE School Performance
#' Reports (SPR) database workbooks.
#'
#' @param end_year A school year end year. Supported years are 2017 through 2023.
#'   Year is the end of the academic year; for example, use 2023 for the 2022-23
#'   school year.
#' @param level One of \code{"district"} or \code{"school"}. \code{"district"}
#'   returns district and state rows. \code{"school"} returns school, district,
#'   and state rows where present in the school workbook.
#'
#' @details
#' This fetcher reads two SPR database sheets and stacks them into one data
#' frame: \code{PostsecondaryEnrRatesFall} and
#' \code{PostsecondaryEnrRates16mos}. The fall sheet in database year \code{Y}
#' reports graduating class \code{Y}; the 16-month sheet in database year
#' \code{Y} reports graduating class \code{Y - 1}. This mapping was checked
#' against the \code{PostSecondaryEnrRateSummary} class-year trend rows in the
#' 2018-19, 2019-20, and 2020-21 SPR databases, and against the class-of-2020
#' fall enrollment drop in the 2019-20 database.
#'
#' \code{enrolled_any} is the share of the graduating class enrolled in
#' postsecondary education. The \code{enrolled_2yr}, \code{enrolled_4yr},
#' \code{enrolled_public}, \code{enrolled_private},
#' \code{enrolled_in_state}, and \code{enrolled_out_of_state} measures are
#' shares of enrolled graduates, not shares of all graduates.
#'
#' Values are returned as numeric lower/upper pairs for every measure. Plain
#' values such as \code{"57.1"} are returned with equal lower and upper bounds
#' and \code{value_format == "point"}. Range strings such as
#' \code{"69.8-72.0\%"} are returned without midpointing as lower and upper
#' bounds and \code{value_format == "range"}. Suppressed or missing values stay
#' missing; they are never converted to zero.
#'
#' The source sheets carry "Statewide" as a student-group row under every
#' entity, repeating the state value. Those rows are promoted to one
#' state-reference row per measurement window (\code{is_state == TRUE}, entity
#' identifiers \code{NA}), so an entity's own total row is the only
#' \code{"total population"} row bearing its identifiers.
#'
#' The 2023-24 SPR database (end_year 2024) shipped these postsecondary sheets
#' with zero data rows because National Student Clearinghouse data had not been
#' published. The redesigned 2024-25 SPR database (end_year 2025) removed these
#' sheets. Both years stop with an explanatory error instead of returning an
#' empty or fabricated data set.
#'
#' @return A data frame with database year, class year, measurement window,
#'   entity identifiers and names, subgroup, lower/upper measure columns,
#'   \code{value_format}, and entity aggregation flags.
#' @export
#'
#' @examples
#' \dontrun{
#' postsec <- fetch_postsecondary_enrollment(2023, level = "district")
#' school_postsec <- fetch_postsecondary_enrollment(2019, level = "school")
#' }
fetch_postsecondary_enrollment <- function(end_year, level = "district") {
  if (length(end_year) != 1 || is.na(end_year) || end_year != as.integer(end_year)) {
    stop("end_year must be a single integer from 2017 through 2023.", call. = FALSE)
  }
  end_year <- as.integer(end_year)

  if (end_year == 2024L) {
    stop(
      "The 2023-24 SPR database ships the postsecondary enrollment sheets with zero data rows; this is an upstream honest gap, not a package parsing failure.",
      call. = FALSE
    )
  }
  if (end_year == 2025L) {
    stop(
      "The postsecondary enrollment sheets were removed from the redesigned 2024-25 SPR database.",
      call. = FALSE
    )
  }
  if (end_year < 2017L || end_year > 2023L) {
    stop("end_year must be from 2017 through 2023.", call. = FALSE)
  }

  if (!level %in% c("school", "district")) {
    stop('level must be one of "school" or "district".', call. = FALSE)
  }

  # Raw subgroup labels are required here: these sheets carry a "Statewide"
  # STUDENT GROUP row under every district, and the standard subgroup cleaner
  # maps both "Districtwide" and "Statewide" to "total population", which would
  # leave two indistinguishable total rows per district (the state's rate first).
  fall <- fetch_spr_data("PostsecondaryEnrRatesFall", end_year, level,
                         clean_subgroups = FALSE)
  month16 <- fetch_spr_data("PostsecondaryEnrRates16mos", end_year, level,
                            clean_subgroups = FALSE)

  fall <- normalize_postsecondary_enrollment_sheet(
    fall, end_year, "fall", end_year
  )
  month16 <- normalize_postsecondary_enrollment_sheet(
    month16, end_year, "16_month", end_year - 1L
  )

  out <- dplyr::bind_rows(fall, month16)

  id_cols <- c(
    "county_id", "county_name", "district_id", "district_name",
    "school_id", "school_name", "subgroup"
  )
  measure_cols <- as.vector(t(outer(
    c(
      "enrolled_any", "enrolled_2yr", "enrolled_4yr",
      "enrolled_public", "enrolled_private", "enrolled_in_state",
      "enrolled_out_of_state"
    ),
    c("lower", "upper"),
    paste,
    sep = "_"
  )))
  flag_cols <- names(out)[grepl("^is_", names(out))]

  out %>%
    dplyr::select(
      dplyr::any_of(c(
        "end_year", "class_year", "measurement_window", id_cols,
        measure_cols, "value_format", flag_cols
      )),
      dplyr::everything()
    )
}

normalize_postsecondary_enrollment_sheet <- function(df, end_year,
                                                     measurement_window,
                                                     class_year) {
  if (!"county_name" %in% names(df)) {
    df$county_name <- NA_character_
  }
  if (!"district_name" %in% names(df)) {
    df$district_name <- NA_character_
  }
  if (!"school_name" %in% names(df)) {
    df$school_name <- NA_character_
  }

  # "Statewide" rides these sheets as a STUDENT GROUP row under every entity,
  # repeating the same state value. Promote it to a real state-reference row:
  # state flags on, entity identity blanked (the entity ids it rides under are
  # not the value's identity), then dedupe to one state row per sheet. Only
  # after that are subgroup labels standardized, so "Statewide" can never be
  # conflated with an entity's own "Districtwide"/"Schoolwide" total row.
  if ("subgroup" %in% names(df)) {
    is_state_ref <- !is.na(df$subgroup) & tolower(trimws(df$subgroup)) == "statewide"
    if (any(is_state_ref)) {
      df$is_state[is_state_ref] <- TRUE
      if ("is_district" %in% names(df)) df$is_district[is_state_ref] <- FALSE
      if ("is_school" %in% names(df)) df$is_school[is_state_ref] <- FALSE
      if ("is_charter" %in% names(df)) df$is_charter[is_state_ref] <- FALSE
      for (col in c("county_id", "county_name", "district_id", "district_name",
                    "school_id", "school_name")) {
        if (col %in% names(df)) df[[col]][is_state_ref] <- NA_character_
      }
      state_rows <- df[is_state_ref, , drop = FALSE]
      # The repeated state value must be constant before deduplication; if the
      # sheet ever carries differing "Statewide" values, refuse rather than
      # silently keeping an arbitrary one.
      value_cols <- names(state_rows)[grepl("enrolled", names(state_rows), ignore.case = TRUE)]
      for (col in value_cols) {
        vals <- unique(state_rows[[col]][!is.na(state_rows[[col]])])
        if (length(vals) > 1) {
          stop(
            "Statewide reference rows disagree within one sheet (column ", col,
            "); refusing to deduplicate.",
            call. = FALSE
          )
        }
      }
      state_rows <- state_rows[!duplicated(state_rows$subgroup), , drop = FALSE]
      df <- rbind(df[!is_state_ref, , drop = FALSE], state_rows)
    }
    df$subgroup <- clean_spr_subgroups(df$subgroup)
  }

  map <- postsecondary_enrollment_measure_map(names(df), measurement_window)
  df <- dplyr::rename(df, !!!map)

  measure_names <- names(map)
  for (measure in measure_names) {
    parsed <- parse_postsecondary_enrollment_value(df[[measure]])
    df[[paste0(measure, "_lower")]] <- parsed$lower
    df[[paste0(measure, "_upper")]] <- parsed$upper
  }

  any_parsed <- parse_postsecondary_enrollment_value(df$enrolled_any)

  df %>%
    dplyr::mutate(
      end_year = end_year,
      class_year = class_year,
      measurement_window = measurement_window,
      value_format = any_parsed$value_format
    ) %>%
    dplyr::select(-dplyr::all_of(measure_names))
}

postsecondary_enrollment_measure_map <- function(nms, measurement_window) {
  if (measurement_window == "fall") {
    legacy_fall <- c(
      enrolled_any = "post_sec_enrolled_percent",
      enrolled_2yr = "postsec_enrolled_2_yr",
      enrolled_4yr = "postsec_enrolled_4_yr"
    )
    current_fall <- c(
      enrolled_any = "enrolled_percent",
      enrolled_2yr = "enrolled_2_yr",
      enrolled_4yr = "enrolled_4_yr"
    )

    if (all(unname(legacy_fall) %in% nms)) {
      return(legacy_fall)
    }
    if (all(unname(current_fall) %in% nms)) {
      return(current_fall)
    }
  }

  if (measurement_window == "16_month") {
    legacy_16 <- c(
      enrolled_any = "enrolled_percent",
      enrolled_2yr = "enrolled_2_yr",
      enrolled_4yr = "enrolled_4_yr",
      enrolled_public = "enrolled_public",
      enrolled_private = "enrolled_private",
      enrolled_in_state = "enrolled_in_state",
      enrolled_out_of_state = "enrolled_out_of_state"
    )
    current_16 <- c(
      enrolled_any = "enrolled_percent",
      enrolled_2yr = "enrolled_2_yr",
      enrolled_4yr = "enrolled_4_yr",
      enrolled_public = "enrolled_public",
      enrolled_private = "enrolled_private",
      enrolled_in_state = "enrolled_in_state",
      enrolled_out_of_state = "enrolled_out_state"
    )

    if (all(unname(legacy_16) %in% nms)) {
      return(legacy_16)
    }
    if (all(unname(current_16) %in% nms)) {
      return(current_16)
    }
  }

  stop(
    paste0(
      "Unsupported postsecondary enrollment column layout for ",
      measurement_window, " sheet. Columns after clean_name_vector: ",
      paste(nms, collapse = ", ")
    ),
    call. = FALSE
  )
}

parse_postsecondary_enrollment_value <- function(x) {
  value <- trimws(as.character(x))
  value[value == ""] <- NA_character_
  value <- gsub("%", "", value, fixed = TRUE)

  lower <- rep(NA_real_, length(value))
  upper <- rep(NA_real_, length(value))
  value_format <- rep(NA_character_, length(value))

  is_range <- !is.na(value) & grepl("^\\s*-?\\d+(\\.\\d+)?\\s*-\\s*-?\\d+(\\.\\d+)?\\s*$", value)
  if (any(is_range)) {
    parts <- strsplit(value[is_range], "\\s*-\\s*")
    lower[is_range] <- as.numeric(vapply(parts, `[`, character(1), 1))
    upper[is_range] <- as.numeric(vapply(parts, `[`, character(1), 2))
    value_format[is_range] <- "range"
  }

  is_point <- !is.na(value) & !is_range & grepl("^\\s*-?\\d+(\\.\\d+)?\\s*$", value)
  if (any(is_point)) {
    lower[is_point] <- as.numeric(value[is_point])
    upper[is_point] <- as.numeric(value[is_point])
    value_format[is_point] <- "point"
  }

  data.frame(lower = lower, upper = upper, value_format = value_format)
}
