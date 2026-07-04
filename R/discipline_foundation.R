# ==============================================================================
# Shared discipline-domain foundation helpers
# ==============================================================================

collapse_enrollment_denominator <- function(x) {
  x <- suppressWarnings(as.numeric(x))
  vals <- unique(x[!is.na(x)])
  if (length(vals) == 1) vals else NA_real_
}

discipline_total_enrollment_rows <- function(enrollment) {
  required_cols <- c(
    "end_year", "county_id", "district_id", "school_id",
    "program_code", "grade_level", "subgroup", "n_students"
  )
  missing_cols <- setdiff(required_cols, names(enrollment))
  if (length(missing_cols) > 0) {
    stop(
      "discipline enrollment denominator requires columns: ",
      paste(missing_cols, collapse = ", "),
      call. = FALSE
    )
  }

  enrollment %>%
    dplyr::filter(
      .data$program_code == "55",
      .data$grade_level == "TOTAL",
      .data$subgroup == "total_enrollment"
    ) %>%
    dplyr::group_by(
      .data$end_year,
      .data$county_id,
      .data$district_id,
      .data$school_id
    ) %>%
    dplyr::summarise(
      n_students = collapse_enrollment_denominator(.data$n_students),
      .groups = "drop"
    )
}

fetch_discipline_enrollment_denominator <- function(years) {
  years <- sort(unique(as.integer(years[!is.na(years)])))
  if (length(years) == 0) {
    return(tibble::tibble(
      end_year = integer(0),
      county_id = character(0),
      district_id = character(0),
      school_id = character(0),
      n_students = numeric(0)
    ))
  }

  pieces <- lapply(
    years,
    function(year) {
      discipline_total_enrollment_rows(
        fetch_enr(year, tidy = TRUE, use_cache = TRUE)
      )
    }
  )
  dplyr::bind_rows(pieces)
}

attach_discipline_enrollment_denominator <- function(df, enrollment = NULL) {
  if (!is.data.frame(df)) {
    stop("df must be a data frame.", call. = FALSE)
  }

  if ("n_students" %in% names(df)) {
    stop(
      "attach_discipline_enrollment_denominator() cannot add n_students ",
      "because df already has that column.",
      call. = FALSE
    )
  }

  key_cols <- c("end_year", "county_id", "district_id", "school_id")
  missing_cols <- setdiff(key_cols, names(df))
  if (length(missing_cols) > 0) {
    out <- df
    out$n_students <- NA_real_
    return(out)
  }

  denominator <- if (is.null(enrollment)) {
    fetch_discipline_enrollment_denominator(df$end_year)
  } else {
    discipline_total_enrollment_rows(enrollment)
  }

  dplyr::left_join(df, denominator, by = key_cols)
}

discipline_row_value_status <- function(df, cols) {
  cols <- intersect(cols, names(df))
  if (length(cols) == 0) {
    return(value_status_factor(rep("not_published", nrow(df))))
  }

  status_matrix <- do.call(
    cbind,
    lapply(cols, function(col) as.character(classify_value_status(df[[col]])))
  )
  if (is.null(dim(status_matrix))) {
    status_matrix <- matrix(status_matrix, ncol = 1)
  }

  status <- apply(
    status_matrix,
    1,
    function(row) {
      if (any(row == "suppressed")) return("suppressed")
      if (any(row == "actual")) return("actual")
      if (any(row == "not_yet_observed")) return("not_yet_observed")
      if (all(row == "not_applicable")) return("not_applicable")
      "not_published"
    }
  )

  value_status_factor(status)
}

discipline_primary_value_status <- function(df, cols) {
  cols <- intersect(cols, names(df))
  if (length(cols) == 0) {
    return(value_status_factor(rep("not_published", nrow(df))))
  }
  classify_value_status(df[[cols[[1]]]])
}

discipline_add_student_group_detail <- function(df, with_subgroup_std = FALSE) {
  if ("student_group_grade" %in% names(df) && !"subgroup" %in% names(df)) {
    split_cols <- spr_split_student_group_grade(df$student_group_grade)
    df$subgroup <- split_cols$subgroup
    df$subgroup[df$subgroup == "native hawaiian or pacific islander"] <-
      "pacific islander"
    df$grade_level <- split_cols$grade_level
  }

  if (isTRUE(with_subgroup_std) && "subgroup" %in% names(df)) {
    df <- add_subgroup_std(df)
  }

  df
}
