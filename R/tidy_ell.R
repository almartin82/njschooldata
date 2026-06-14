# ==============================================================================
# English Learner (EL) Population Data — tidy contract
# ==============================================================================

#' Canonical column order for tidy EL population data
#' @keywords internal
ELL_TIDY_COLS <- c(
  "end_year",
  "county_id", "county_name",
  "district_id", "district_name",
  "school_id", "school_name",
  "cds_code", "nces_dist", "nces_sch",
  "is_state", "is_district", "is_school", "is_charter",
  "grade_level", "el_status", "subgroup",
  "n_students", "total_enrollment", "pct_of_enrollment",
  "n_students_lower", "n_students_upper"
)

#' Tidy English Learner population data
#'
#' Transforms processed EL data into the cross-state tidy contract: one row per
#' entity x year x grade x EL status x subgroup. NJ publishes a single current-EL
#' headcount per entity, so `el_status` is always `"current"` and `subgroup` is
#' always `"total"`. NJ does not suppress EL counts, so the suppression bounds
#' equal the point value wherever a count is published and are `NA` for the
#' percent-only district/school years (2020-2022).
#'
#' @param df processed EL data — output of `process_ell()`
#' @return tidy data.frame following [ELL_TIDY_COLS]
#' @export
tidy_ell <- function(df) {
  out <- df %>%
    dplyr::mutate(
      el_status = "current",
      subgroup = "total",
      n_students = .data$el_count,
      n_students_lower = .data$el_count,
      n_students_upper = .data$el_count
    )

  # ensure every contract column exists, then order
  for (col in ELL_TIDY_COLS) {
    if (!col %in% names(out)) out[[col]] <- NA
  }
  out %>%
    dplyr::select(dplyr::all_of(ELL_TIDY_COLS)) %>%
    dplyr::arrange(
      dplyr::desc(.data$is_state), dplyr::desc(.data$is_district),
      .data$cds_code
    )
}

#' Empty tidy EL frame (correctly typed)
#'
#' Returned for an unavailable year and used to validate the schema.
#'
#' @return zero-row data.frame with [ELL_TIDY_COLS]
#' @keywords internal
empty_ell_frame <- function() {
  data.frame(
    end_year = numeric(0),
    county_id = character(0), county_name = character(0),
    district_id = character(0), district_name = character(0),
    school_id = character(0), school_name = character(0),
    cds_code = character(0), nces_dist = character(0), nces_sch = character(0),
    is_state = logical(0), is_district = logical(0),
    is_school = logical(0), is_charter = logical(0),
    grade_level = character(0), el_status = character(0), subgroup = character(0),
    n_students = numeric(0), total_enrollment = numeric(0),
    pct_of_enrollment = numeric(0),
    n_students_lower = numeric(0), n_students_upper = numeric(0),
    stringsAsFactors = FALSE
  )
}
