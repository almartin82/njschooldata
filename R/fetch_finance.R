# ==============================================================================
# Uniform finance front door: fetch_finance()
# ==============================================================================
#
# `fetch_finance()` is the canonical, cross-state-uniform entry point for NJ
# school finance. It returns one tidy schema regardless of which underlying NJ
# DOE source a metric comes from, so cross-state code such as
# `filter(metric == "per_pupil_total")` works unchanged.
#
# It does NOT replace the richer source-specific functions; it consolidates the
# data they already pull onto the standard `metric` vocabulary:
#
#   - SPENDING (per-pupil): the Taxpayers' Guide to Educational Spending (TGES),
#     via fetch_tges(). Per-pupil total expenditures and the major per-pupil
#     spending categories, reported as ACTUALS.
#   - REVENUE (state aid): the Governor's Budget Message "District Details"
#     workbook, via fetch_state_aid(). Total K-12 state aid per district.
#
# Both are NJ DOE sources. No value is sourced from a federal source; only the
# NCES join keys (nces_dist) are attached, from the bundled CCD crosswalk.
#
# FY <-> SY mapping: end_year is the FISCAL/SCHOOL year END. end_year = 2024 is
# FY2024 = school year 2023-24. TGES publishes a data year's ACTUALS in the guide
# released the following year (FY2024 actuals appear in the 2025 guide), so the
# spending side fetches fetch_tges(end_year + 1) and keeps calc_type == "Actuals".
# State aid is appropriated for the named year, so revenue uses
# fetch_state_aid(end_year) directly.
# ==============================================================================


# Standard metric vocabulary this package emits (see dev-docs/FINANCE-DATA-SPEC.md).
# `per_pupil_total` and `per_pupil_instruction` are the standard cross-state
# names; the remaining per_pupil_* category metrics are NJ-specific (NJ publishes
# these categories per-pupil rather than as absolute totals) and are documented
# in CLAUDE.md "Valid Filter Values (finance)". `revenue_state` is standard.
.finance_metrics <- c(
  "per_pupil_total",
  "per_pupil_instruction",
  "per_pupil_support_services",
  "per_pupil_administration",
  "per_pupil_operations_maintenance",
  "per_pupil_food_service",
  "revenue_state"
)

.finance_latest_observed_per_pupil_year <- 2024L
.finance_per_pupil_metrics <- .finance_metrics[grepl("^per_pupil_", .finance_metrics)]
.finance_levels <- c("all", "state", "district", "school")

# canonical tidy column order
.finance_cols <- c(
  "end_year", "state_id", "entity_name", "county",
  "is_state", "is_district", "is_school", "is_charter",
  "nces_dist", "nces_sch",
  "metric", "value", "is_per_pupil", "enrollment_denominator"
)

.finance_cols_with_status <- c(.finance_cols, "value_status")


#' Years for which NJ finance data is available
#'
#' @description The union of the two NJ DOE finance sources. The per-pupil
#' spending side (TGES actuals) is available for \code{2001}-\code{2024}; the
#' state-aid revenue side is available for \code{2019} onward. A given year emits
#' whichever metrics its sources publish - recent years (2025+) carry
#' \code{revenue_state} only, because that year's spending actuals are not yet
#' published.
#'
#' @return integer vector of available \code{end_year}s
#' @export
get_available_finance_years <- function() {
  spending <- 2001:.finance_latest_observed_per_pupil_year
  revenue  <- 2019:2026
  sort(unique(c(spending, revenue)))
}


normalize_finance_level <- function(level) {
  if (length(level) != 1L || is.na(level)) {
    stop("`level` must be one of: ", paste(.finance_levels, collapse = ", "),
         call. = FALSE)
  }
  level <- as.character(level)
  match.arg(level, .finance_levels)
}


# Validate the package END-year convention at the point the finance sources are
# combined. TGES spending actuals are published in the following guide year
# (FY2024 actuals in the 2025 guide); state aid is already keyed to the requested
# fiscal/school END year. A one-year drift here silently corrupts trends.
assert_finance_year_alignment <- function(spending, revenue, end_year,
                                          tges_report_year) {
  end_year <- as.integer(end_year)
  if (length(end_year) != 1L || is.na(end_year)) {
    stop("`end_year` must be a single year.", call. = FALSE)
  }

  expected_tges_report_year <- end_year + 1L
  tges_report_year <- as.integer(tges_report_year)
  if (length(tges_report_year) != 1L || is.na(tges_report_year) ||
      tges_report_year != expected_tges_report_year) {
    stop(
      "Finance FY/SY alignment failed: TGES spending actuals for end_year ",
      end_year,
      " must come from the following year guide (",
      expected_tges_report_year,
      "), not ",
      paste(tges_report_year, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  assert_source_year <- function(df, source_label) {
    if (is.null(df) || nrow(df) == 0) return(invisible(TRUE))
    if (!"end_year" %in% names(df)) {
      stop(
        "Finance FY/SY alignment failed: ",
        source_label,
        " rows are missing `end_year`.",
        call. = FALSE
      )
    }

    row_year <- as.integer(df$end_year)
    bad <- !is.na(row_year) & row_year != end_year
    if (any(bad)) {
      bad_years <- sort(unique(row_year[bad]))
      stop(
        "Finance FY/SY alignment failed: ",
        source_label,
        " row end_year must equal requested end_year ",
        end_year,
        ". Off-year value(s): ",
        paste(bad_years, collapse = ", "),
        ".",
        call. = FALSE
      )
    }

    invisible(TRUE)
  }

  assert_source_year(spending, "spending")
  assert_source_year(revenue, "state aid")
  invisible(TRUE)
}


finance_tges_report_year <- function(end_year) {
  as.integer(end_year) + 1L
}


filter_finance_level <- function(df, level) {
  if (identical(level, "all") || is.null(df) || nrow(df) == 0) {
    return(df)
  }
  if (identical(level, "state")) {
    return(df[df$is_state %in% TRUE, , drop = FALSE])
  }
  if (identical(level, "district")) {
    return(df[df$is_district %in% TRUE, , drop = FALSE])
  }
  df[0, , drop = FALSE]
}


finance_school_gap_frame <- function(end_year, with_status = FALSE) {
  metric <- .finance_metrics
  out <- tibble::tibble(
    end_year               = as.integer(end_year),
    state_id               = NA_character_,
    entity_name            = NA_character_,
    county                 = NA_character_,
    is_state               = FALSE,
    is_district            = FALSE,
    is_school              = FALSE,
    is_charter             = NA,
    nces_dist              = NA_character_,
    nces_sch               = NA_character_,
    metric                 = metric,
    value                  = NA_real_,
    is_per_pupil           = metric %in% .finance_per_pupil_metrics,
    enrollment_denominator = NA_real_
  )

  if (isTRUE(with_status)) {
    out$value_status <- finance_value_status(
      metric = out$metric,
      value = out$value,
      end_year = out$end_year,
      is_per_pupil = out$is_per_pupil,
      enrollment_denominator = out$enrollment_denominator,
      latest_observed_per_pupil_year = .finance_latest_observed_per_pupil_year,
      structural_not_published = TRUE
    )
  }

  out[, if (isTRUE(with_status)) .finance_cols_with_status else .finance_cols,
      drop = FALSE]
}


add_unobserved_per_pupil_finance <- function(df, end_year) {
  if (is.null(df) || nrow(df) == 0 ||
      end_year <= .finance_latest_observed_per_pupil_year) {
    return(df)
  }

  missing_metrics <- setdiff(.finance_per_pupil_metrics, unique(df$metric))
  if (length(missing_metrics) == 0) {
    return(df)
  }

  entity_cols <- c(
    "end_year", "state_id", "entity_name", "county",
    "is_state", "is_district", "is_school", "is_charter"
  )
  entities <- unique(df[df$is_state %in% TRUE | df$is_district %in% TRUE,
                        entity_cols, drop = FALSE])
  if (nrow(entities) == 0) {
    return(df)
  }

  gap_entities <- entities[rep(seq_len(nrow(entities)),
                               each = length(missing_metrics)), ,
                           drop = FALSE]
  gaps <- gap_entities
  gaps$metric <- rep(missing_metrics, times = nrow(entities))
  gaps$value <- NA_real_
  gaps$is_per_pupil <- TRUE
  gaps$enrollment_denominator <- NA_real_

  dplyr::bind_rows(df, gaps)
}


# repair invalid-UTF-8 strings (CP1252 bytes in NJ DOE source names) so string
# ops never error. Only strings that fail UTF-8 validation are re-decoded.
.finance_clean_utf8 <- function(x) {
  x <- as.character(x)
  bad <- is.na(iconv(x, "UTF-8", "UTF-8"))
  bad[is.na(bad)] <- FALSE
  if (any(bad)) x[bad] <- iconv(x[bad], "CP1252", "UTF-8", sub = "")
  x
}


# build a district_id -> nces_dist map from the bundled crosswalk (identifiers
# only). district_id is unique statewide in NJ, so no county_id is needed.
.finance_nces_map <- function() {
  xwalk <- load_nces_crosswalk()
  d <- xwalk[xwalk$entity_level == "District", , drop = FALSE]
  d <- d[!is.na(d$nces_dist) & nchar(d$nces_dist) == 7, c("district_id", "nces_dist")]
  unique(d)
}


# attach nces_dist by district_id; nces_sch is always NA (NJ finance is
# district-level only). Unmatched stays NA - never fabricated.
attach_nces_finance <- function(df) {
  m <- .finance_nces_map()
  df[["nces_dist"]] <- NULL
  df <- dplyr::left_join(df, m, by = c("state_id" = "district_id"))
  df$nces_dist[is.na(df$state_id)] <- NA_character_
  df$nces_sch <- NA_character_
  df
}


# NJ's source publishes real per-pupil values above $100k for county
# special-services districts; pass them through unchanged for raw fidelity rather
# than rescaling, capping, or fabricating a comparable number. The only guard kept
# here is zero/blank enrollment denominators on per-pupil rows, which are source
# no-data markers, not valid enrollment denominators.
sanitize_finance_quality <- function(df) {
  if (is.null(df) || nrow(df) == 0) return(df)

  bad_denominator <- df$is_per_pupil %in% TRUE &
    !is.na(df$enrollment_denominator) &
    df$enrollment_denominator <= 0
  df$enrollment_denominator[bad_denominator] <- NA_real_

  df
}


# ------------------------------------------------------------------------------
# revenue side: total K-12 state aid per district (and the statewide total)
# ------------------------------------------------------------------------------
get_finance_revenue <- function(end_year) {
  end_year <- as.integer(end_year)
  if (end_year < 2019) return(NULL)

  sa <- tryCatch(fetch_state_aid(end_year), error = function(e) NULL)
  if (is.null(sa)) return(NULL)

  # the published current-year total column normalizes to fy_NN_k_12_aid
  total_cat <- paste0("fy_", sprintf("%02d", end_year %% 100L), "_k_12_aid")
  rev <- sa[sa$aid_category == total_cat & (sa$is_district | sa$is_state), , drop = FALSE]
  if (nrow(rev) == 0) return(NULL)

  tibble::tibble(
    end_year               = end_year,
    state_id               = ifelse(rev$is_state, NA_character_, rev$district_id),
    entity_name            = ifelse(rev$is_state, "New Jersey", rev$district_name),
    county                 = ifelse(rev$is_state, NA_character_, rev$county_name),
    is_state               = rev$is_state,
    is_district            = rev$is_district,
    is_school              = FALSE,
    is_charter             = NA,
    metric                 = "revenue_state",
    value                  = as.numeric(rev$amount),
    is_per_pupil           = FALSE,
    enrollment_denominator = NA_real_
  )
}


# ------------------------------------------------------------------------------
# spending side: per-pupil expenditures (ACTUALS) from the TGES guide published
# the year after the data year
# ------------------------------------------------------------------------------

# pull one per-pupil metric out of a single TGES table for the target data year
.finance_pull_pp <- function(tges, table, value_col, metric, target_year,
                             denom_col = NULL, include_state = FALSE) {
  tbl <- .tges_get_table(tges, table)
  if (is.null(tbl) || !value_col %in% names(tbl)) return(NULL)
  if (!"end_year" %in% names(tbl)) return(NULL)

  tbl <- tbl[!is.na(tbl$end_year) & tbl$end_year == target_year, , drop = FALSE]
  if ("calc_type" %in% names(tbl)) {
    tbl <- tbl[tbl$calc_type == "Actuals", , drop = FALSE]
  }
  if (nrow(tbl) == 0) return(NULL)

  dist_name <- if ("district_name" %in% names(tbl)) as.character(tbl$district_name) else NA_character_
  dist_id   <- if ("district_id"   %in% names(tbl)) as.character(tbl$district_id)   else NA_character_
  county    <- if ("county_name"   %in% names(tbl)) as.character(tbl$county_name)   else NA_character_

  # the statewide-average row label drifts across guide vintages: ALL CAPS
  # ("STATE AVERAGE - ALL OPERATING TYPES", 2017 guide), title case with a dash
  # (2019-2023), and title case with a colon (2025). Match case-insensitively so
  # the state row is captured for every year; "State Median" never matches.
  is_state_row <- grepl("^State Average", dist_name, ignore.case = TRUE)
  is_dist_row  <- grepl("^[0-9]{4}$", dist_id) & !is.na(dist_id)

  keep <- is_dist_row | (include_state & is_state_row)
  tbl  <- tbl[keep, , drop = FALSE]
  if (nrow(tbl) == 0) return(NULL)
  is_state_row <- is_state_row[keep]

  denom <- rep(NA_real_, nrow(tbl))
  if (!is.null(denom_col) && denom_col %in% names(tbl)) {
    denom <- suppressWarnings(as.numeric(tbl[[denom_col]]))
  }

  tibble::tibble(
    end_year               = target_year,
    state_id               = ifelse(is_state_row, NA_character_, as.character(tbl$district_id)),
    entity_name            = ifelse(is_state_row, "New Jersey", as.character(tbl$district_name)),
    county                 = ifelse(is_state_row, NA_character_, as.character(tbl$county_name)),
    is_state               = is_state_row,
    is_district            = !is_state_row,
    is_school              = FALSE,
    is_charter             = NA,
    metric                 = metric,
    value                  = suppressWarnings(as.numeric(tbl[[value_col]])),
    is_per_pupil           = TRUE,
    enrollment_denominator = denom
  )
}


get_finance_spending <- function(end_year) {
  end_year   <- as.integer(end_year)
  report_year <- finance_tges_report_year(end_year)
  if (report_year < 2002 || report_year > 2025) return(NULL)

  tg <- tryCatch(fetch_tges(report_year), error = function(e) NULL)
  if (is.null(tg)) return(NULL)

  pieces <- list(
    # per_pupil_total carries the published statewide-average row + the ADE+sent
    # denominator NJ uses for total per-pupil spending
    .finance_pull_pp(tg, "CSG1AA_AVGS", "Per Pupil Total Expenditures",
                     "per_pupil_total", end_year,
                     denom_col = "Average Daily Enrollment plus Sent Pupils",
                     include_state = TRUE),
    .finance_pull_pp(tg, "CSG2",  "Per Pupil costs", "per_pupil_instruction",            end_year),
    .finance_pull_pp(tg, "CSG6",  "Per Pupil costs", "per_pupil_support_services",       end_year),
    .finance_pull_pp(tg, "CSG8",  "Per Pupil costs", "per_pupil_administration",         end_year),
    .finance_pull_pp(tg, "CSG10", "Per Pupil costs", "per_pupil_operations_maintenance", end_year),
    .finance_pull_pp(tg, "CSG12", "Per Pupil costs", "per_pupil_food_service",           end_year)
  )
  pieces <- purrr::compact(pieces)
  if (length(pieces) == 0) return(NULL)
  out <- dplyr::bind_rows(pieces)
  attr(out, "tges_report_year") <- report_year
  out
}


#' Fetch NJ school finance in the canonical cross-state schema
#'
#' @description The uniform front door for NJ school finance. Consolidates the
#' two NJ DOE finance sources this package already pulls - per-pupil spending
#' from the Taxpayers' Guide to Educational Spending (\code{\link{fetch_tges}})
#' and total K-12 state aid from the Governor's Budget Message district details
#' (\code{\link{fetch_state_aid}}) - onto one tidy schema with a standard
#' \code{metric} vocabulary, so cross-state code works unchanged.
#'
#' @details
#' \strong{FY <-> SY mapping.} \code{end_year} is the fiscal / school year END:
#' \code{end_year = 2024} is FY2024, school year 2023-24. NJ publishes a year's
#' spending ACTUALS in the guide released the following year, so the spending
#' side fetches the \code{end_year + 1} guide and keeps the actuals; state aid is
#' appropriated for the named year and is read directly.
#'
#' \strong{Metrics emitted.}
#' \itemize{
#'   \item \code{per_pupil_total} - total per-pupil expenditures (ESSA-style),
#'     with \code{enrollment_denominator} = average daily enrollment plus sent
#'     pupils. Carries a statewide-average row (\code{is_state}).
#'   \item \code{per_pupil_instruction} - classroom instruction per pupil.
#'   \item \code{per_pupil_support_services}, \code{per_pupil_administration},
#'     \code{per_pupil_operations_maintenance}, \code{per_pupil_food_service} -
#'     NJ-specific per-pupil category metrics (NJ reports these per-pupil rather
#'     than as absolute totals).
#'   \item \code{revenue_state} - total K-12 state aid (absolute dollars).
#'     Carries a statewide-total row.
#' }
#' Years 2025+ carry \code{revenue_state} only (that year's spending actuals are
#' not yet published); years before 2019 carry per-pupil spending only. Values
#' are nominal dollars exactly as published - no rescaling, no fabrication. The
#' federal \code{nces_dist} identifier is attached from the bundled CCD
#' crosswalk; unmatched districts keep \code{NA}.
#'
#' \strong{Entity grain.} NJ finance in this front door is district/state only.
#' NJ's school-level per-pupil expenditure reporting is a separate source that
#' is not wired here, so \code{is_school} remains \code{FALSE}. If
#' \code{level = "school"} is requested, the function returns structural gap
#' rows; use \code{with_status = TRUE} to see \code{value_status =
#' "not_published"} for those rows.
#'
#' @param end_year school year (end of the academic year). See
#'   \code{\link{get_available_finance_years}} for valid values.
#' @param tidy logical, default \code{TRUE}. The tidy long schema is the only
#'   supported (and only) shape; \code{tidy = FALSE} currently returns the same
#'   long frame and is reserved for a future wide form.
#' @param use_cache logical, default \code{TRUE}. Reserved for parity with other
#'   fetchers; the underlying TGES/state-aid downloads use the package session
#'   cache.
#' @param with_status logical, default \code{FALSE}. If \code{TRUE}, adds
#'   \code{value_status}, classifying present values as \code{actual}, current
#'   per-pupil actuals not yet published as \code{not_yet_observed}, and missing
#'   values with absent per-pupil denominators as \code{not_published}.
#' @param level entity grain to return: \code{"all"} (default, state and
#'   district rows), \code{"state"}, \code{"district"}, or \code{"school"}.
#'   School-level NJ finance is not published in this fetcher; school requests
#'   return structural gap rows only.
#'
#' @return A tibble in the canonical finance schema: \code{end_year},
#'   \code{state_id}, \code{entity_name}, \code{county}, \code{is_state},
#'   \code{is_district}, \code{is_school}, \code{is_charter}, \code{nces_dist},
#'   \code{nces_sch}, \code{metric}, \code{value}, \code{is_per_pupil},
#'   \code{enrollment_denominator}, and optionally \code{value_status}.
#'
#' @examples
#' \dontrun{
#' library(dplyr)
#'
#' # One year, all metrics
#' fin <- fetch_finance(2024)
#' fin %>% count(metric)
#'
#' # Per-pupil total spending, highest-spending districts
#' fetch_finance(2024) %>%
#'   filter(is_district, metric == "per_pupil_total") %>%
#'   arrange(desc(value)) %>%
#'   select(entity_name, value, enrollment_denominator)
#'
#' # Statewide per-pupil total
#' fetch_finance(2024) %>%
#'   filter(is_state, metric == "per_pupil_total") %>%
#'   select(end_year, value)
#'
#' # Total K-12 state aid for one district
#' fetch_finance(2024) %>%
#'   filter(metric == "revenue_state", state_id == "3570") %>%
#'   select(entity_name, value)
#' }
#'
#' @export
fetch_finance <- function(end_year, tidy = TRUE, use_cache = TRUE,
                          with_status = FALSE, level = "all") {
  level <- normalize_finance_level(level)
  end_year <- as.integer(end_year)
  if (is.na(end_year)) stop("`end_year` must be a year, e.g. 2024.", call. = FALSE)

  if (identical(level, "school")) {
    return(tibble::as_tibble(finance_school_gap_frame(
      end_year,
      with_status = with_status
    )))
  }

  spending <- get_finance_spending(end_year)
  revenue  <- get_finance_revenue(end_year)
  tges_report_year <- attr(spending, "tges_report_year", exact = TRUE)
  if (is.null(tges_report_year)) {
    tges_report_year <- finance_tges_report_year(end_year)
  }
  assert_finance_year_alignment(
    spending = spending,
    revenue = revenue,
    end_year = end_year,
    tges_report_year = tges_report_year
  )

  out <- dplyr::bind_rows(spending, revenue)
  if (is.null(out) || nrow(out) == 0) {
    return(empty_finance_frame(with_status = with_status))
  }

  # the NJ DOE files carry some CP1252 bytes (e.g. a curly apostrophe 0x92 in
  # charter names) declared as unknown/Latin-1, which break UTF-8 string ops
  # (distinct/joins/printing). Repair only the invalid strings, never the data.
  out$entity_name <- .finance_clean_utf8(out$entity_name)
  out$county      <- .finance_clean_utf8(out$county)

  out <- sanitize_finance_quality(out)
  if (isTRUE(with_status)) {
    out <- add_unobserved_per_pupil_finance(out, end_year)
    out$value_status <- finance_value_status(
      metric = out$metric,
      value = out$value,
      end_year = out$end_year,
      is_per_pupil = out$is_per_pupil,
      enrollment_denominator = out$enrollment_denominator,
      latest_observed_per_pupil_year = .finance_latest_observed_per_pupil_year
    )
  }
  out <- filter_finance_level(out, level)
  out <- attach_nces_finance(out)
  out <- out[, if (isTRUE(with_status)) .finance_cols_with_status else .finance_cols,
             drop = FALSE]
  # the NJ DOE source occasionally repeats a district's row verbatim (e.g. a
  # charter listed twice with identical figures); collapse exact duplicates so
  # there is one observation per entity-metric. Genuinely conflicting values
  # would survive this and be surfaced by the test suite.
  out <- dplyr::distinct(out)
  tibble::as_tibble(out)
}


#' Fetch multiple years of NJ school finance
#'
#' @param end_year_vector vector of school years (end of the academic year). See
#'   \code{\link{get_available_finance_years}} for valid values.
#' @param end_years alias for \code{end_year_vector}, used by cross-state
#'   discovery tooling.
#' @param tidy logical, default \code{TRUE}. See \code{\link{fetch_finance}}.
#' @param use_cache logical, default \code{TRUE}. See \code{\link{fetch_finance}}.
#' @param with_status logical, default \code{FALSE}. See
#'   \code{\link{fetch_finance}}.
#' @param level entity grain to return. See \code{\link{fetch_finance}}.
#'
#' @return A single tibble, the per-year results of \code{\link{fetch_finance}}
#'   stacked.
#'
#' @examples
#' \dontrun{
#' library(dplyr)
#'
#' # Statewide per-pupil total over time
#' fetch_finance_multi(2018:2024) %>%
#'   filter(is_state, metric == "per_pupil_total") %>%
#'   select(end_year, value)
#' }
#'
#' @export
fetch_finance_multi <- function(end_year_vector = NULL, end_years = NULL,
                                tidy = TRUE, use_cache = TRUE,
                                with_status = FALSE, level = "all") {
  if (is.null(end_year_vector)) {
    end_year_vector <- end_years
  } else if (!is.null(end_years) &&
             !identical(as.integer(end_year_vector), as.integer(end_years))) {
    stop("Supply either `end_year_vector` or `end_years`, not conflicting values.",
         call. = FALSE)
  }

  if (is.null(end_year_vector)) {
    end_year_vector <- get_available_finance_years()
  }

  purrr::map_dfr(end_year_vector, function(.y) {
    message(.y)
    fetch_finance(.y, tidy = tidy, use_cache = use_cache,
                  with_status = with_status, level = level)
  })
}


# correctly-typed empty tidy frame (Under-Construction / no-data fallback)
empty_finance_frame <- function(with_status = FALSE) {
  out <- tibble::tibble(
    end_year               = integer(0),
    state_id               = character(0),
    entity_name            = character(0),
    county                 = character(0),
    is_state               = logical(0),
    is_district            = logical(0),
    is_school              = logical(0),
    is_charter             = logical(0),
    nces_dist              = character(0),
    nces_sch               = character(0),
    metric                 = character(0),
    value                  = double(0),
    is_per_pupil           = logical(0),
    enrollment_denominator = double(0)
  )
  if (isTRUE(with_status)) {
    out$value_status <- value_status_factor(character(0))
  }
  out
}
