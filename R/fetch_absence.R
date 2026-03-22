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
    subgroup == "students with disability" ~ "special_ed",
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
#' @param end_year A school year (2017-2024). Year is the end of the academic
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
#' binds the results. Skips years that fail (e.g., COVID gap 2020-2021) with
#' a warning.
#'
#' @param end_years Integer vector of school years (e.g., \code{2017:2024}).
#' @param level One of \code{"school"} or \code{"district"}.
#' @param type One of \code{"chronic"}, \code{"by_grade"}, \code{"days_absent"},
#'   or \code{"essa"}.
#' @param tidy Logical; if \code{TRUE} (default), normalizes subgroup names.
#' @param use_cache Logical; if \code{TRUE} (default), caches each year.
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
#' # COVID gap: 2020-2021 were not reported, will be skipped with a warning
#' ca_all <- fetch_absence_multi(2017:2024)
#'
#' # Multi-year trend by district
#' library(dplyr)
#' ca_all %>%
#'   filter(subgroup == "total", is_state) %>%
#'   select(end_year, chronically_absent_rate)
#' }
fetch_absence_multi <- function(end_years, level = "school", type = "chronic",
                                tidy = TRUE, use_cache = TRUE) {

  results <- list()

  for (yr in end_years) {
    result <- tryCatch(
      {
        fetch_absence(
          end_year = yr,
          level = level,
          type = type,
          tidy = tidy,
          use_cache = use_cache
        )
      },
      error = function(e) {
        warning(
          sprintf("Could not fetch absence data for %d: %s", yr, e$message),
          call. = FALSE
        )
        NULL
      }
    )

    if (!is.null(result)) {
      results[[as.character(yr)]] <- result
    }
  }

  if (length(results) == 0) {
    stop("No absence data could be fetched for any requested year.", call. = FALSE)
  }

  dplyr::bind_rows(results)
}
