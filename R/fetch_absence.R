# School SPR rates verified against the ChronicAbsenteeism sheet (2017–2024)
# and ChronicAbsenteeismStudentGroup (2025); see inst/source-reconciliation.md.
# 2020 remains excluded: retrieved 2026-10-31, HTTP 200 XLSX, but no
# ChronicAbsenteeism sheet in the 2019-2020 school SPR workbook:
# https://www.nj.gov/education/sprreports/download/DataFiles/2019-2020/Database_SchoolDetail.xlsx
.nj_absence_live_years <- c(2017:2019, 2021:2025)

absence_supported_years <- function(type = "chronic") {
  years <- get_source_years("absence")
  if (type == "by_grade") years <- years[years >= 2018L]
  if (type == "essa") years <- get_source_years("essa_chronic_absence")
  years
}

# ==============================================================================
# Unified Chronic Absenteeism Interface
# ==============================================================================
#
# Cross-state standard wrapper around NJ's existing chronic absenteeism
# functions. Normalizes subgroup names and provides tidy (long) format
# consistent with other state packages.
#
# ==============================================================================


# -----------------------------------------------------------------------------
# Subgroup Mapping
# -----------------------------------------------------------------------------

#' Map SPR subgroup names to cross-state standard names
#'
#' Normalizes NJ-specific subgroup labels to match the naming conventions
#' used across all 50 state packages, enabling cross-state comparisons
#' with code like \code{filter(subgroup == "econ_disadv")}.
#'
#' @param subgroup Character vector of SPR subgroup names
#' @return Character vector with standardized names
#' @keywords internal
standardize_absence_subgroups <- function(subgroup) {
  dplyr::case_when(
    subgroup == "total population" ~ "total",
    subgroup == "white" ~ "white",
    subgroup == "black" ~ "black",
    subgroup == "hispanic" ~ "hispanic",
    subgroup == "asian" ~ "asian",
    subgroup == "american indian" ~ "native_american",
    subgroup == "pacific islander" ~ "pacific_islander",
    subgroup == "multiracial" ~ "multiracial",
    subgroup == "economically disadvantaged" ~ "econ_disadv",
    subgroup == "limited english proficiency" ~ "lep",
    subgroup == "students with disabilities" ~ "special_ed",
    subgroup == "male" ~ "male",
    subgroup == "female" ~ "female",
    TRUE ~ subgroup

  )
}


# -----------------------------------------------------------------------------
# Tidy Absence
# -----------------------------------------------------------------------------

#' Tidy chronic absenteeism data
#'
#' Normalizes subgroup names to cross-state standards and adds entity-level
#' flags. Applied automatically when \code{fetch_absence(tidy = TRUE)}.
#'
#' @param df Data frame from \code{fetch_chronic_absenteeism()}
#' @return Data frame with standardized subgroup names
#' @export
#'
#' @examples
#' \dontrun{
#' ca <- fetch_chronic_absenteeism(2024)
#' ca_tidy <- tidy_absence(ca)
#' }
tidy_absence <- function(df) {
  if ("subgroup" %in% names(df)) {
    df$subgroup <- standardize_absence_subgroups(df$subgroup)
  }

  df
}


# -----------------------------------------------------------------------------
# Main Entry Points
# -----------------------------------------------------------------------------

#' Fetch Chronic Absenteeism Data (Cross-State Standard)
#'
#' Unified entry point for NJ chronic absenteeism data, matching the
#' \code{fetch_absence()} naming convention used across all state packages.
#' Wraps \code{fetch_chronic_absenteeism()} from the SPR database with
#' optional tidy normalization.
#'
#' @param end_year A school year (2017-2025). Year is the end of the academic
#'   year — e.g., the 2023-24 school year is \code{end_year = 2024}.
#' @param level One of \code{"school"} or \code{"district"}. Default
#'   \code{"school"} returns school-level data; \code{"district"} returns
#'   district and state-level data.
#' @param type One of \code{"chronic"} (default), \code{"by_grade"},
#'   \code{"days_absent"}, or \code{"essa"}. Selects which underlying
#'   absenteeism function to call.
#' @param tidy Logical; if \code{TRUE} (default), normalizes subgroup names to
#'   cross-state standards (e.g., \code{"econ_disadv"}, \code{"lep"},
#'   \code{"special_ed"}).
#' @param use_cache Logical; if \code{TRUE}, uses session cache for faster
#'   repeat calls.
#'
#' @return A data frame with chronic absenteeism data. When \code{tidy = TRUE},
#'   subgroup names are standardized:
#'   \itemize{
#'     \item \code{total} — total population
#'     \item \code{white}, \code{black}, \code{hispanic}, \code{asian} — race/ethnicity
#'     \item \code{native_american}, \code{pacific_islander}, \code{multiracial}
#'     \item \code{econ_disadv} — economically disadvantaged
#'     \item \code{lep} — limited English proficiency
#'     \item \code{special_ed} — students with disabilities
#'     \item \code{male}, \code{female}
#'   }
#'
#' The 2020 workbook omits the absence sheets; by_grade additionally excludes
#' 2017. For days_absent, the 2017 long distribution is reshaped without changing
#' values. Day-count bands abs_0, abs_1_5, abs_6_10 and abs_11_15 (2017-2023),
#' abs_15_plus (2017), and abs_over_15 (2018-2023) are distinct from the
#' percent-of-days bands in 2024-2025. The printed 15+ and over-15 boundaries
#' remain separate. Percent-of-days bands share names across 2024-2025 except
#' absent_gt0_to_6_9_pctdays (2024) and absent_0_1_to_6_9_pctdays (2025),
#' whose different printed lower bounds are retained. Every band is NA in
#' years that do not publish it. school_year is filtered before removal.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Get school-level chronic absenteeism with standard subgroup names
#' ca <- fetch_absence(2024)
#'
#' # District-level data
#' ca_dist <- fetch_absence(2024, level = "district")
#'
#' # Grade-level breakdown
#' ca_grade <- fetch_absence(2024, type = "by_grade")
#'
#' # Days absent distribution
#' days <- fetch_absence(2024, type = "days_absent")
#'
#' # ESSA chronic absenteeism (school-level only)
#' essa <- fetch_absence(2024, type = "essa")
#'
#' # Without tidy normalization (original NJ subgroup names)
#' ca_raw <- fetch_absence(2024, tidy = FALSE)
#'
#' # Cross-state filtering patterns
#' library(dplyr)
#' ca %>%
#'   filter(subgroup == "econ_disadv", is_district) %>%
#'   arrange(desc(chronically_absent_rate))
#' }
fetch_absence <- function(end_year, level = "school", type = "chronic",
                          tidy = TRUE, use_cache = TRUE) {

  valid_types <- c("chronic", "by_grade", "days_absent", "essa")
  if (!type %in% valid_types) {
    stop(
      "type must be one of: ",
      paste0("'", valid_types, "'", collapse = ", "),
      call. = FALSE
    )
  }

  # Check cache
  if (!end_year %in% absence_supported_years(type)) {
    stop("Absence type '", type, "' is not published for end_year ", end_year,
         ". Supported years: ", paste(absence_supported_years(type), collapse = ", "),
         call. = FALSE)
  }
  if (use_cache) {
    key <- make_cache_key("fetch_absence", end_year = end_year,
                          level = level, type = type, tidy = tidy)
    cached <- cache_get(key)
    if (!is.null(cached)) {
      message("Using cached absence data.")
      return(cached)
    }
  }

  # Dispatch to the appropriate underlying function

  df <- switch(type,
    chronic = fetch_chronic_absenteeism(end_year, level = level),
    by_grade = fetch_absenteeism_by_grade(end_year, level = level),
    days_absent = fetch_days_absent(end_year, level = level),
    essa = fetch_essa_chronic_absenteeism(end_year)
  )

  # Apply tidy normalization
  if (tidy) {
    df <- tidy_absence(df)
  }

  # Cache result
  if (use_cache) {
    cache_set(key, df)
  }

  df
}


#' Fetch Chronic Absenteeism Data for Multiple Years
#'
#' Convenience wrapper that calls \code{fetch_absence()} for each year and
#' binds the results. Skips years that fail (e.g., COVID gap 2020) with
#' a warning.
#'
#' @param end_years Integer vector of school years (e.g., \code{2017:2024}).
#' @param level One of \code{"school"} or \code{"district"}.
#' @param type One of \code{"chronic"}, \code{"by_grade"}, \code{"days_absent"},
#'   or \code{"essa"}.
#' @param tidy Logical; if \code{TRUE} (default), normalizes subgroup names.
#' @param use_cache Logical; if \code{TRUE} (default), caches each year.
#' @param allow_partial Logical; if \code{FALSE} (default), failed or
#'   structurally unavailable years abort the request. If \code{TRUE},
#'   successful years are returned with status from [get_source_results()].
#'
#' @return A data frame with all years bound together.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Get all available years of chronic absenteeism
#' ca_all <- fetch_absence_multi(2017:2024)
#'
#' # COVID gap: 2020 was not reported, will be skipped with a warning
#' ca_all <- fetch_absence_multi(2017:2024)
#'
#' # Multi-year trend by district
#' library(dplyr)
#' ca_all %>%
#'   filter(subgroup == "total", is_state) %>%
#'   select(end_year, chronically_absent_rate)
#' }
fetch_absence_multi <- function(end_years, level = "school", type = "chronic",
                                tidy = TRUE, use_cache = TRUE,
                                allow_partial = FALSE) {
  family <- if (identical(type, "essa")) {
    "essa_chronic_absence"
  } else {
    "absence"
  }
  captures <- lapply(sort(unique(end_years)), function(year) {
    capture_registered_source_call(
      function() fetch_absence(
        end_year = year,
        level = level,
        type = type,
        tidy = tidy,
        use_cache = use_cache
      ),
      family, year, domain = "absence", component = paste(type, level, sep = "/")
    )
  })
  combine_source_captures(
    captures, allow_partial = allow_partial,
    context = "Absence multi-year request"
  )
}
