# ==============================================================================
# Unified course / CTE / college-career front door
# ==============================================================================

.course_fetch_types <- c(
  "advanced_access",
  "courses_offered",
  "ap_ib_participation",
  "course_enrollment",
  "cte",
  "industry_credentials",
  "dual_enrollment",
  "sle",
  "work_based_learning",
  "apprenticeship",
  "sat_participation",
  "sat_performance",
  "college_career"
)

.course_entity_cols <- c(
  "end_year",
  "county_id", "county_name",
  "district_id", "district_name",
  "school_id", "school_name"
)

.course_flag_cols <- c(
  "is_state", "is_county", "is_district", "is_school",
  "is_charter", "is_charter_sector", "is_allpublic"
)

.course_dim_cols <- c(
  "school_year",
  "subgroup", "subgroup_std",
  "course_subject", "course_name", "grade_level",
  "career_cluster",
  "test_type", "subject", "benchmark",
  "graduation_year", "apprenticeship_year"
)

.course_output_cols <- c(
  "end_year", "course_domain", "source_fetcher",
  "county_id", "county_name",
  "district_id", "district_name",
  "school_id", "school_name",
  .course_dim_cols,
  .course_flag_cols,
  "metric", "value"
)

.course_output_cols_with_status <- c(.course_output_cols, "value_status")

.course_subject_fetchers <- c(
  math = "fetch_math_course_enrollment",
  science = "fetch_science_course_enrollment",
  social_studies = "fetch_social_studies_enrollment",
  world_language = "fetch_world_language_enrollment",
  computer_science = "fetch_cs_enrollment",
  arts = "fetch_arts_enrollment"
)

.course_subject_aliases <- c(
  cs = "computer_science",
  computer_science = "computer_science",
  computer = "computer_science",
  social = "social_studies",
  social_studies = "social_studies",
  world = "world_language",
  world_language = "world_language",
  language = "world_language",
  languages = "world_language",
  visual_arts = "arts",
  arts = "arts",
  math = "math",
  science = "science"
)

#' Fetch Course, CTE, and College-Career Data
#'
#' @description
#' A unified long-schema front door over the package's existing course,
#' advanced-coursework, CTE, and college-career fetchers. This is additive: the
#' source-specific fetchers keep their existing default outputs, while
#' \code{fetch_courses()} delegates to them and normalizes published value
#' columns onto a common \code{metric}/\code{value} schema.
#'
#' @details
#' The \code{type} argument maps to existing fetchers as follows:
#' \itemize{
#'   \item \code{"advanced_access"} -- \code{\link{fetch_advanced_course_access}}
#'     with \code{type = "participation_by_group"}.
#'   \item \code{"courses_offered"} -- \code{\link{fetch_advanced_course_access}}
#'     with \code{type = "courses_offered"}.
#'   \item \code{"dual_enrollment"} -- \code{\link{fetch_advanced_course_access}}
#'     with \code{type = "participation_by_group"}, keeping the dual-enrollment
#'     rate metrics.
#'   \item \code{"sle"} -- \code{\link{fetch_advanced_course_access}} with
#'     \code{type = "sle"}.
#'   \item \code{"ap_ib_participation"} --
#'     \code{\link{fetch_ap_participation}}.
#'   \item \code{"course_enrollment"} -- one or more course-enrollment fetchers:
#'     \code{\link{fetch_math_course_enrollment}},
#'     \code{\link{fetch_science_course_enrollment}},
#'     \code{\link{fetch_social_studies_enrollment}},
#'     \code{\link{fetch_world_language_enrollment}},
#'     \code{\link{fetch_cs_enrollment}}, and
#'     \code{\link{fetch_arts_enrollment}}. Use \code{subject =} in \code{...}
#'     to keep one or more subjects; omitted means all subjects.
#'   \item \code{"cte"} -- \code{\link{fetch_cte_participation}}.
#'   \item \code{"industry_credentials"} --
#'     \code{\link{fetch_industry_credentials}}.
#'   \item \code{"work_based_learning"} --
#'     \code{\link{fetch_work_based_learning}}.
#'   \item \code{"apprenticeship"} -- \code{\link{fetch_apprenticeship_data}}.
#'   \item \code{"sat_participation"} -- \code{\link{fetch_sat_participation}}.
#'   \item \code{"sat_performance"} -- \code{\link{fetch_sat_performance}}; pass
#'     \code{test_type =} through \code{...} to filter.
#'   \item \code{"college_career"} -- stacks \code{"sat_participation"},
#'     \code{"sat_performance"}, \code{"ap_ib_participation"}, \code{"cte"},
#'     \code{"industry_credentials"}, \code{"work_based_learning"}, and
#'     \code{"apprenticeship"}.
#' }
#'
#' Value columns are classified with \code{\link{classify_value_status}} before
#' this dispatcher coerces them with \code{\link{spr_value_numeric}}. Suppressed
#' or unpublished cells therefore stay honest \code{NA} values; no counts or
#' rates are back-derived from another published cell.
#'
#' @param type Course data family. See details for valid values.
#' @param end_year A school year end, e.g. \code{2025} for SY2024-25.
#' @param level One of \code{"school"} or \code{"district"}, passed to the
#'   underlying fetcher.
#' @param ... Optional arguments for specific families. \code{subject} filters
#'   \code{type = "course_enrollment"}; \code{test_type} is passed to
#'   \code{type = "sat_performance"}.
#' @param with_status Logical, default \code{FALSE}. If \code{TRUE}, appends a
#'   \code{value_status} column classified from each raw published value token
#'   before numeric coercion in this dispatcher.
#' @param annotate Logical, default \code{FALSE}. If \code{TRUE}, appends
#'   registry metadata via \code{\link{annotate_metric}}.
#'
#' @return A tibble with entity identifiers, optional dimensions such as
#'   \code{subgroup}, \code{subgroup_std}, \code{course_subject},
#'   \code{course_name}, \code{career_cluster}, \code{test_type}, and
#'   \code{apprenticeship_year}, standard entity flags, \code{metric},
#'   \code{value}, and optionally \code{value_status}. Metric names are designed
#'   for lookup with \code{\link{annotate_metric}}.
#'
#' @examples
#' \dontrun{
#' fetch_courses("advanced_access", 2025)
#' fetch_courses("course_enrollment", 2024, subject = "science")
#' fetch_courses("cte", 2025, with_status = TRUE)
#' }
#'
#' @export
fetch_courses <- function(type = .course_fetch_types,
                          end_year,
                          level = "school",
                          ...,
                          with_status = FALSE,
                          annotate = FALSE) {
  type <- match.arg(type)
  dots <- list(...)

  out <- switch(
    type,
    advanced_access = .fetch_courses_advanced_access(
      end_year, level, "participation_by_group",
      metric_cols = c(
        "apib_pct_school", "apib_pct_district", "apib_pct_state",
        "dual_pct_school", "dual_pct_district", "dual_pct_state"
      ),
      course_domain = type,
      with_status = with_status
    ),
    courses_offered = .fetch_courses_advanced_access(
      end_year, level, "courses_offered",
      metric_cols = c("students_enrolled", "students_tested"),
      course_domain = type,
      with_status = with_status
    ),
    dual_enrollment = .fetch_courses_advanced_access(
      end_year, level, "participation_by_group",
      metric_cols = c("dual_pct_school", "dual_pct_district", "dual_pct_state"),
      course_domain = type,
      with_status = with_status
    ),
    sle = .fetch_courses_advanced_access(
      end_year, level, "sle",
      metric_cols = c("sle_pct_school", "sle_pct_district", "sle_pct_state"),
      course_domain = type,
      with_status = with_status
    ),
    ap_ib_participation = .fetch_courses_ap_ib_participation(
      end_year, level, with_status
    ),
    course_enrollment = .fetch_courses_course_enrollment(
      end_year, level, dots$subject, with_status
    ),
    cte = .fetch_courses_simple(
      fetch_cte_participation(end_year, level),
      course_domain = type,
      source_fetcher = "fetch_cte_participation",
      metric_cols = c(
        "cte_participants", "cte_concentrators",
        "state_cte_participants", "state_cte_concentrators"
      ),
      with_status = with_status
    ),
    industry_credentials = .fetch_courses_simple(
      fetch_industry_credentials(end_year, level),
      course_domain = type,
      source_fetcher = "fetch_industry_credentials",
      metric_cols = c(
        "students_enrolled", "earned_one_credential", "credentials_earned"
      ),
      with_status = with_status
    ),
    work_based_learning = .fetch_courses_simple(
      fetch_work_based_learning(end_year, level),
      course_domain = type,
      source_fetcher = "fetch_work_based_learning",
      metric_cols = c("students_participating", "pct_participating"),
      with_status = with_status
    ),
    apprenticeship = .fetch_courses_apprenticeship(
      end_year, level, with_status
    ),
    sat_participation = .fetch_courses_sat_participation(
      end_year, level, with_status
    ),
    sat_performance = .fetch_courses_sat_performance(
      end_year, level, dots$test_type, with_status
    ),
    college_career = .fetch_courses_college_career(
      end_year, level, dots, with_status
    )
  )

  if (isTRUE(annotate)) {
    out <- annotate_metric(out)
  }
  out
}

.fetch_courses_advanced_access <- function(end_year, level, advanced_type,
                                           metric_cols, course_domain,
                                           with_status) {
  if (advanced_type == "participation_by_group" && end_year < 2021) {
    stop(
      "participation-by-group data is available for end_year >= 2021 (the ",
      "APIBDualEnrPartByStudentGrp sheet is absent from the 2017-2020 SPR ",
      "databases).",
      call. = FALSE
    )
  }
  if (advanced_type != "participation_by_group" && end_year < 2017) {
    stop(
      "advanced-coursework data is available for end_year >= 2017 (the SPR ",
      "databases do not go back further).",
      call. = FALSE
    )
  }

  df <- if (isTRUE(with_status)) {
    switch(
      advanced_type,
      courses_offered = .advanced_courses_offered(
        end_year, level, coerce_values = FALSE
      ),
      participation_by_group = .advanced_participation_by_group(
        end_year, level, coerce_values = FALSE
      ),
      sle = .advanced_sle_participation(
        end_year, level, coerce_values = FALSE
      )
    )
  } else {
    fetch_advanced_course_access(
      end_year = end_year,
      type = advanced_type,
      level = level
    )
  }

  .fetch_courses_simple(
    df,
    course_domain = course_domain,
    source_fetcher = "fetch_advanced_course_access",
    metric_cols = metric_cols,
    with_status = with_status
  )
}

.fetch_courses_ap_ib_participation <- function(end_year, level, with_status) {
  .fetch_courses_simple(
    fetch_ap_participation(end_year, level),
    course_domain = "ap_ib_participation",
    source_fetcher = "fetch_ap_participation",
    metric_cols = c(
      "apib_coursework_school", "apib_coursework_state",
      "apib_exam_school", "apib_exam_state",
      "ap3_ib4_school", "ap3_ib4_state",
      "dual_enrollment_school", "dual_enrollment_state"
    ),
    with_status = with_status
  )
}

.fetch_courses_course_enrollment <- function(end_year, level, subject,
                                             with_status) {
  subjects <- .normalize_course_subjects(subject)

  pieces <- lapply(subjects, function(.subject) {
    source_fetcher <- .course_subject_fetchers[[.subject]]
    fetcher <- get(source_fetcher, mode = "function")
    df <- fetcher(end_year, level)

    grade_col <- intersect(c("grade", "grades", "grade_band"), names(df))
    if (length(grade_col) > 0) {
      df$grade_level <- df[[grade_col[[1]]]]
    }
    df$course_subject <- .subject

    metric_cols <- setdiff(
      names(df),
      c(.course_entity_cols, .course_flag_cols, .course_dim_cols,
        "grade", "grades", "grade_band")
    )
    metric_cols <- metric_cols[
      !metric_cols %in% c("course_domain", "source_fetcher", "metric", "value")
    ]

    .fetch_courses_simple(
      df,
      course_domain = "course_enrollment",
      source_fetcher = source_fetcher,
      metric_cols = metric_cols,
      metric_name_map = stats::setNames(
        rep("students_enrolled", length(metric_cols)),
        metric_cols
      ),
      metric_source_dim = "course_name",
      with_status = with_status
    )
  })

  dplyr::bind_rows(pieces)
}

.fetch_courses_apprenticeship <- function(end_year, level, with_status) {
  df <- fetch_apprenticeship_data(end_year, level)
  metric_cols <- grep(
    "^(year_20[0-9]{2}|apprenticeships_[1-8]_yr|apprenticeship_8_year_total)$",
    names(df),
    value = TRUE
  )

  long <- .fetch_courses_simple(
    df,
    course_domain = "apprenticeship",
    source_fetcher = "fetch_apprenticeship_data",
    metric_cols = metric_cols,
    with_status = with_status,
    keep_metric_source = TRUE
  )

  is_legacy_year <- grepl("^year_20[0-9]{2}$", long$.metric_source)
  is_window <- grepl("^apprenticeships_[1-8]_yr$", long$.metric_source)

  long$apprenticeship_year <- NA_character_
  long$apprenticeship_year[is_legacy_year] <- sub(
    "^year_", "", long$.metric_source[is_legacy_year]
  )
  long$apprenticeship_year[is_window] <- sub(
    "^apprenticeships_([1-8])_yr$", "\\1_yr", long$.metric_source[is_window]
  )
  long$metric[is_legacy_year | is_window] <- "apprenticeship_count"

  .courses_finalize(long, with_status)
}

.fetch_courses_sat_participation <- function(end_year, level, with_status) {
  df <- fetch_sat_participation(end_year, level)
  metric_name_map <- c(
    state_sat = "sat_participation_state",
    state_act = "act_participation_state",
    state_psat = "psat_participation_state"
  )

  .fetch_courses_simple(
    df,
    course_domain = "sat_participation",
    source_fetcher = "fetch_sat_participation",
    metric_cols = c(
      "sat_participation", "act_participation", "psat_participation",
      "state_sat", "state_act", "state_psat"
    ),
    metric_name_map = metric_name_map,
    with_status = with_status
  )
}

.fetch_courses_sat_performance <- function(end_year, level, test_type,
                                           with_status) {
  if (is.null(test_type)) test_type <- "all"
  df <- fetch_sat_performance(end_year, level, test_type = test_type)

  entity_avg_metric <- if (level == "district") {
    "college_exam_avg_score_district"
  } else {
    "college_exam_avg_score_school"
  }
  entity_benchmark_metric <- if (level == "district") {
    "college_exam_benchmark_district"
  } else {
    "college_exam_benchmark_school"
  }
  metric_name_map <- c(
    school_avg = entity_avg_metric,
    state_avg = "college_exam_avg_score_state",
    pct_benchmark = entity_benchmark_metric,
    state_pct_benchmark = "college_exam_benchmark_state"
  )

  .fetch_courses_simple(
    df,
    course_domain = "sat_performance",
    source_fetcher = "fetch_sat_performance",
    metric_cols = names(metric_name_map),
    metric_name_map = metric_name_map,
    with_status = with_status
  )
}

.fetch_courses_college_career <- function(end_year, level, dots, with_status) {
  pieces <- list(
    fetch_courses("sat_participation", end_year, level, with_status = with_status),
    fetch_courses(
      "sat_performance", end_year, level,
      test_type = dots$test_type %||% "all",
      with_status = with_status
    ),
    fetch_courses("ap_ib_participation", end_year, level, with_status = with_status),
    fetch_courses("cte", end_year, level, with_status = with_status),
    fetch_courses("industry_credentials", end_year, level, with_status = with_status),
    fetch_courses("work_based_learning", end_year, level, with_status = with_status),
    fetch_courses("apprenticeship", end_year, level, with_status = with_status)
  )

  dplyr::bind_rows(pieces)
}

.fetch_courses_simple <- function(df, course_domain, source_fetcher, metric_cols,
                                  metric_name_map = NULL,
                                  metric_source_dim = NULL,
                                  with_status = FALSE,
                                  keep_metric_source = FALSE) {
  if ("subgroup" %in% names(df)) {
    df <- add_subgroup_std(df)
  }

  metric_cols <- intersect(metric_cols, names(df))
  if (length(metric_cols) == 0) {
    return(empty_courses_frame(with_status = with_status))
  }

  long <- tidyr::pivot_longer(
    df,
    cols = dplyr::all_of(metric_cols),
    names_to = ".metric_source",
    values_to = ".raw_value",
    values_transform = list(.raw_value = as.character)
  )

  long$course_domain <- course_domain
  long$source_fetcher <- source_fetcher

  if (!is.null(metric_source_dim)) {
    long[[metric_source_dim]] <- long$.metric_source
  }

  long$metric <- long$.metric_source
  if (!is.null(metric_name_map)) {
    mapped <- metric_name_map[long$.metric_source]
    has_mapping <- !is.na(mapped)
    long$metric[has_mapping] <- unname(mapped[has_mapping])
  }

  if (isTRUE(with_status)) {
    long$value_status <- classify_value_status(long$.raw_value)
  }
  long$value <- spr_value_numeric(long$.raw_value)
  long$.raw_value <- NULL

  if (!isTRUE(keep_metric_source)) {
    long$.metric_source <- NULL
  }

  .courses_finalize(long, with_status, keep_metric_source = keep_metric_source)
}

.courses_finalize <- function(df, with_status, keep_metric_source = FALSE) {
  if (!isTRUE(with_status) && "value_status" %in% names(df)) {
    df$value_status <- NULL
  }
  if (!isTRUE(keep_metric_source) && ".metric_source" %in% names(df)) {
    df$.metric_source <- NULL
  }

  target_cols <- if (isTRUE(with_status)) {
    .course_output_cols_with_status
  } else {
    .course_output_cols
  }

  missing <- setdiff(target_cols, names(df))
  for (col in missing) {
    df[[col]] <- .courses_missing_column(col, nrow(df))
  }

  ordered <- c(target_cols, setdiff(names(df), target_cols))
  tibble::as_tibble(df[, ordered, drop = FALSE])
}

.courses_missing_column <- function(col, n) {
  if (col %in% .course_flag_cols) {
    return(rep(NA, n))
  }
  if (col == "value") {
    return(rep(NA_real_, n))
  }
  if (col == "value_status") {
    return(value_status_factor(rep(NA_character_, n)))
  }
  if (col == "end_year") {
    return(rep(NA_real_, n))
  }

  rep(NA_character_, n)
}

empty_courses_frame <- function(with_status = FALSE) {
  out <- tibble::tibble(
    end_year = numeric(0),
    course_domain = character(0),
    source_fetcher = character(0),
    county_id = character(0),
    county_name = character(0),
    district_id = character(0),
    district_name = character(0),
    school_id = character(0),
    school_name = character(0),
    school_year = character(0),
    subgroup = character(0),
    subgroup_std = character(0),
    course_subject = character(0),
    course_name = character(0),
    grade_level = character(0),
    career_cluster = character(0),
    test_type = character(0),
    subject = character(0),
    benchmark = character(0),
    graduation_year = character(0),
    apprenticeship_year = character(0),
    is_state = logical(0),
    is_county = logical(0),
    is_district = logical(0),
    is_school = logical(0),
    is_charter = logical(0),
    is_charter_sector = logical(0),
    is_allpublic = logical(0),
    metric = character(0),
    value = double(0)
  )
  if (isTRUE(with_status)) {
    out$value_status <- value_status_factor(character(0))
  }
  out
}

.normalize_course_subjects <- function(subject) {
  if (is.null(subject)) {
    return(names(.course_subject_fetchers))
  }

  subject <- tolower(as.character(subject))
  if (any(subject %in% c("all", "*"))) {
    return(names(.course_subject_fetchers))
  }

  mapped <- .course_subject_aliases[subject]
  bad <- is.na(mapped)
  if (any(bad)) {
    stop(
      "Unknown course_enrollment subject(s): ",
      paste(subject[bad], collapse = ", "),
      ". Valid subjects: ",
      paste(names(.course_subject_fetchers), collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  unique(unname(mapped))
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}
