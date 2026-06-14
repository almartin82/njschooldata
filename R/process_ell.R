# ==============================================================================
# English Learner (EL) Population Data — processing
# ==============================================================================

#' Process raw English Learner population data
#'
#' Adds entity-level aggregation flags, standardizes the grade level, and
#' computes the EL share of enrollment. County aggregate rows are dropped so the
#' output carries only state / district / school entities (the cross-state
#' contract). The EL share is computed fresh from the published headcount where
#' a count exists; for the 2020-2022 district/school files that publish only a
#' percent, the published percent is carried through unchanged (never used to
#' back-derive a count).
#'
#' @param df raw EL data — output of `get_raw_ell()`
#' @return data.frame (wide, one row per entity) with entity flags,
#'   `grade_level`, `total_enrollment`, `el_count`, `el_pct`, and
#'   `pct_of_enrollment`
#' @keywords internal
process_ell <- function(df) {
  df %>%
    dplyr::mutate(
      is_state = .data$district_id == "9999" & .data$county_id == "99",
      is_county = .data$district_id == "9999" & .data$county_id != "99",
      is_district = .data$school_id == "999" & !.data$is_state & !.data$is_county,
      is_school = .data$school_id != "999",
      is_charter = .data$county_id == "80"
    ) %>%
    # cross-state contract is state / district / school only
    dplyr::filter(!.data$is_county) %>%
    dplyr::select(-"is_county") %>%
    dplyr::mutate(
      grade_level = "TOTAL",
      total_enrollment = as.numeric(.data$total_enrollment),
      el_count = as.numeric(.data$el_count),
      # EL share of enrollment, as a percentage (0-100):
      #   - where a real headcount exists, compute fresh from the count
      #   - otherwise carry the published percent (district/school 2020-2022)
      #   - NA when the denominator is missing/zero (never fabricated)
      pct_of_enrollment = dplyr::if_else(
        !is.na(.data$el_count) &
          !is.na(.data$total_enrollment) & .data$total_enrollment > 0,
        .data$el_count / .data$total_enrollment * 100,
        .data$el_pct
      )
    )
}
