# ==============================================================================
# English Learner (EL) Population Data — public interface
# ==============================================================================

#' Fetch New Jersey English Learner (EL) population data
#'
#' Downloads and tidies the English Learner / Multilingual Learner headcount
#' from the NJ DOE Fall Enrollment files, at state, district, and school level.
#' This is the EL **population** feature (how many EL students are enrolled and
#' their share of total enrollment) — it is distinct from EL **proficiency**
#' assessment (WIDA ACCESS), exposed separately via [fetch_access()].
#'
#' New Jersey publishes a single current-EL headcount per entity, so the tidy
#' output carries `el_status == "current"` and `subgroup == "total"` for every
#' row. The source publishes only a total current-EL headcount, not a grade
#' breakdown, so `grade_level == "TOTAL"`. The EL share of enrollment
#' (`pct_of_enrollment`, 0-100) is computed fresh from the published headcount;
#' for the 2020-2022 district/school files, which publish only a percent, that
#' published percent is carried through and `n_students` is `NA` (the count is
#' never back-derived from the percent).
#'
#' @param end_year ending academic year. Valid values: 2006-2026. See
#'   [get_available_ell_years()].
#' @param tidy if `TRUE` (default), returns the long cross-state tidy contract
#'   (see [tidy_ell()]). If `FALSE`, returns the wider per-entity frame with
#'   `el_count`, `el_pct`, and `total_enrollment` as columns.
#' @param use_cache if `TRUE`, uses the session cache to avoid re-downloading.
#'   See [njsd_cache_info()].
#' @param with_status if `TRUE` (and `tidy = TRUE`), appends a `value_status`
#'   column classifying, per row, why the headcount is present or absent
#'   (`actual` where a count is published, `not_published` for the percent-only
#'   district/school entity-years 2020-2022). Classified from the raw count
#'   token before numeric coercion; the count is never back-derived from the
#'   percent. Default `FALSE` (the column is additive and off by default).
#' @return data.frame of EL population data with source provenance available
#'   from [get_source_results()]. Unsupported years fail explicitly.
#' @seealso [fetch_access()] for EL **proficiency** (WIDA ACCESS), which joins to
#'   this EL **population** feature on the CDS id backbone.
#' @export
#' @examples
#' \dontrun{
#' # Statewide and district EL counts for 2024-25
#' ell <- fetch_ell(2025)
#'
#' # State EL trend, EL share of enrollment
#' library(dplyr)
#' fetch_ell(2025) %>%
#'   filter(is_state) %>%
#'   select(end_year, n_students, pct_of_enrollment)
#'
#' # Districts with the highest EL share
#' fetch_ell(2025) %>%
#'   filter(is_district, total_enrollment > 1000) %>%
#'   arrange(desc(pct_of_enrollment)) %>%
#'   select(district_name, n_students, pct_of_enrollment) %>%
#'   head(10)
#' }
fetch_ell <- function(end_year, tidy = TRUE, use_cache = FALSE,
                      with_status = FALSE) {
  validate_end_year(end_year, "ell")

  if (use_cache) {
    key <- make_cache_key(
      "fetch_ell", end_year = end_year, tidy = tidy, with_status = with_status
    )
    cached <- cache_get(key)
    if (!is.null(cached)) {
      message("Using cached EL data.")
      return(cached)
    }
  }

  source_result <- get_raw_ell_result(end_year)
  processed <- source_result_data(source_result) %>% process_ell()
  out <- if (tidy) tidy_ell(processed) else processed

  if (with_status && tidy) {
    status <- processed %>%
      dplyr::transmute(
        end_year = .data$end_year,
        cds_code = .data$cds_code,
        value_status = classify_value_status(as.character(.data$el_count))
      )
    out <- dplyr::left_join(out, status, by = c("end_year", "cds_code"))
  }

  out <- attach_source_results(
    out,
    source_result_record(source_result, "ell", end_year, "enrollment")
  )

  if (use_cache) {
    cache_set(key, out)
  }
  out
}

#' Fetch NJ English Learner population data for multiple years
#'
#' @param end_years integer vector of ending academic years (2006-2026).
#' @param tidy if `TRUE` (default), returns the long tidy contract.
#' @param use_cache if `TRUE`, uses the session cache.
#' @param with_status if `TRUE` (and `tidy = TRUE`), appends the additive
#'   `value_status` column (see [fetch_ell()]).
#' @param allow_partial If `FALSE` (default), unavailable or failed years abort
#'   the request. If `TRUE`, successful years are returned with every request
#'   reported by [get_source_results()].
#' @return combined data.frame of EL population data and source-result status.
#' @seealso [fetch_access()] for EL proficiency (WIDA ACCESS).
#' @export
#' @examples
#' \dontrun{
#' # State EL share over a decade
#' library(dplyr)
#' fetch_ell_multi(2015:2025) %>%
#'   filter(is_state) %>%
#'   select(end_year, n_students, pct_of_enrollment)
#' }
fetch_ell_multi <- function(end_years, tidy = TRUE, use_cache = FALSE,
                            with_status = FALSE, allow_partial = FALSE) {
  captures <- lapply(sort(unique(end_years)), function(year) {
    capture_registered_source_call(
      function() fetch_ell(
        year, tidy = tidy, use_cache = use_cache, with_status = with_status
      ),
      "ell", year, domain = "ell", component = "enrollment"
    )
  })
  out <- combine_source_captures(
    captures, allow_partial = allow_partial,
    context = "EL population multi-year request"
  )
  if (nrow(out) == 0L) {
    records <- get_source_results(out)
    out <- empty_ell_frame()
    if (with_status && tidy) {
      out$value_status <- classify_value_status(character(0))
    }
    out <- attach_source_results(out, records)
  }
  out
}
