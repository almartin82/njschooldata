ERA_BREAK_TYPES <- c("scale_break", "covid_gap", "definition_change")
ERA_BOUNDARY_BREAK_TYPES <- c("scale_break", "definition_change")
ERA_TREND_GUARD_BREAK_TYPES <- c("scale_break", "definition_change", "covid_gap")

#' Get era break metadata
#'
#' Returns the bundled era-break metadata used to segment trends across
#' assessment scale breaks, COVID gap years, and documented definition changes.
#'
#' @param break_set Optional character vector of break-set keys to return. If
#'   \code{NULL}, all break sets are returned.
#' @return A data frame with columns \code{break_set}, \code{break_year},
#'   \code{break_type}, \code{label}, \code{comparable_prior}, and
#'   \code{notes}.
#' @export
#' @examples
#' all_breaks <- get_era_breaks()
#' get_era_breaks("njsla")
#' get_era_breaks(c("grad", "attendance"))
get_era_breaks <- function(break_set = NULL) {
  validate_era_break_metadata(era_breaks)

  out <- era_breaks
  if (!is.null(break_set)) {
    out <- out[out$break_set %in% as.character(break_set), , drop = FALSE]
  }

  out
}

#' Tag rows with era identifiers
#'
#' Adds \code{era_id} and \code{is_break_year} to a data frame. The
#' \code{era_id} starts at 1 and increments at each \code{scale_break} or
#' \code{definition_change} break year in the selected break set. The break year
#' itself starts the new era. COVID gap years are flagged with
#' \code{is_break_year = TRUE} but do not increment \code{era_id}, because they
#' represent missing or disrupted years rather than a new assessment scale.
#'
#' @param df Data frame containing a year column.
#' @param break_set Single break-set key, such as \code{"njsla"} or
#'   \code{"attendance"}.
#' @param year_col Name of the year column in \code{df}; defaults to
#'   \code{"end_year"}.
#' @return \code{df} with \code{era_id} and \code{is_break_year} columns added.
#' @export
#' @examples
#' sample_years <- data.frame(end_year = 2014:2016, value = 1:3)
#' tag_era(sample_years, "njsla")
#' tag_era(data.frame(end_year = 2019:2022), "njsla")
#' tag_era(data.frame(school_year = 2024:2025), "econ_disadv", year_col = "school_year")
tag_era <- function(df, break_set, year_col = "end_year") {
  if (!is.data.frame(df)) {
    stop("`df` must be a data frame.", call. = FALSE)
  }
  if (!is.character(year_col) || length(year_col) != 1L || is.na(year_col)) {
    stop("`year_col` must be a single column name.", call. = FALSE)
  }
  if (!year_col %in% names(df)) {
    stop("Column `", year_col, "` was not found in `df`.", call. = FALSE)
  }

  breaks <- era_breaks_for_set(break_set)
  years <- as_era_years(df[[year_col]], year_col)
  boundary_years <- sort(unique(
    breaks$break_year[breaks$break_type %in% ERA_BOUNDARY_BREAK_TYPES]
  ))

  era_id <- rep(1L, length(years))
  for (break_year in boundary_years) {
    era_id <- era_id + ifelse(!is.na(years) & years >= break_year, 1L, 0L)
  }
  era_id[is.na(years)] <- NA_integer_

  out <- df
  out[["era_id"]] <- era_id
  out[["is_break_year"]] <- !is.na(years) & years %in% breaks$break_year
  out
}

#' Assert a year span does not cross an era break
#'
#' Stops when the span from \code{min(years)} to \code{max(years)} crosses a
#' \code{scale_break} or \code{definition_change}, or includes a
#' \code{covid_gap}, for the selected break set. Single-year inputs do not span
#' a break. This is a trend guard for code that should not connect lines across
#' regime changes or missing/disrupted COVID years.
#'
#' @param years Vector of whole-number ending years.
#' @param break_set Single break-set key, such as \code{"njsla"} or
#'   \code{"attendance"}.
#' @return The input \code{years}, invisibly, when the span is valid.
#' @export
#' @examples
#' assert_no_break_span(2016:2018, "njsla")
#' try(assert_no_break_span(2014:2016, "njsla"), silent = TRUE)
#' try(assert_no_break_span(c(2019, 2022), "njsla"), silent = TRUE)
assert_no_break_span <- function(years, break_set) {
  years_int <- as_era_years(years, "years")
  years_int <- sort(unique(years_int[!is.na(years_int)]))

  if (length(years_int) <= 1L) {
    return(invisible(years))
  }

  start_year <- min(years_int)
  end_year <- max(years_int)
  breaks <- era_breaks_for_set(break_set)
  guard_breaks <- breaks[
    breaks$break_type %in% ERA_TREND_GUARD_BREAK_TYPES,
    ,
    drop = FALSE
  ]

  is_boundary <- guard_breaks$break_type %in% ERA_BOUNDARY_BREAK_TYPES
  crosses_boundary <- is_boundary &
    start_year < guard_breaks$break_year &
    end_year >= guard_breaks$break_year
  includes_gap <- guard_breaks$break_type == "covid_gap" &
    start_year <= guard_breaks$break_year &
    end_year >= guard_breaks$break_year

  violations <- guard_breaks[crosses_boundary | includes_gap, , drop = FALSE]
  if (nrow(violations) > 0) {
    stop(
      "Year span ",
      start_year,
      "-",
      end_year,
      " crosses era break(s) for break_set '",
      validate_single_break_set(break_set),
      "': ",
      format_era_break_violations(violations),
      ". Split the trend at these years or call tag_era() and group by era_id.",
      call. = FALSE
    )
  }

  invisible(years)
}

era_breaks_for_set <- function(break_set) {
  break_set <- validate_single_break_set(break_set)
  breaks <- get_era_breaks(break_set)

  if (nrow(breaks) == 0) {
    available <- paste(sort(unique(era_breaks$break_set)), collapse = ", ")
    stop(
      "Unknown break_set '",
      break_set,
      "'. Available break_set values: ",
      available,
      ".",
      call. = FALSE
    )
  }

  breaks[order(breaks$break_year, breaks$break_type), , drop = FALSE]
}

validate_single_break_set <- function(break_set) {
  break_set <- as.character(break_set)
  if (length(break_set) != 1L || is.na(break_set) || !nzchar(break_set)) {
    stop("`break_set` must be a single non-empty character value.", call. = FALSE)
  }

  break_set
}

as_era_years <- function(years, arg) {
  if (inherits(years, "Date") || inherits(years, "POSIXt")) {
    stop("`", arg, "` must contain ending years, not date-time values.", call. = FALSE)
  }
  if (is.list(years)) {
    stop("`", arg, "` must be an atomic vector of whole-number years.", call. = FALSE)
  }
  if (is.factor(years)) {
    years <- as.character(years)
  }

  numeric_years <- suppressWarnings(as.numeric(years))
  bad <- !is.na(years) & (
    is.na(numeric_years) |
      !is.finite(numeric_years) |
      numeric_years != floor(numeric_years)
  )
  if (any(bad)) {
    bad_values <- unique(as.character(years[bad]))
    stop(
      "`",
      arg,
      "` must contain whole-number ending years. Invalid value(s): ",
      paste(bad_values, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  as.integer(numeric_years)
}

validate_era_break_metadata <- function(breaks) {
  required_cols <- c(
    "break_set",
    "break_year",
    "break_type",
    "label",
    "comparable_prior",
    "notes"
  )
  missing_cols <- setdiff(required_cols, names(breaks))
  if (length(missing_cols) > 0) {
    stop(
      "era_breaks is missing required column(s): ",
      paste(missing_cols, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  unsupported <- setdiff(unique(breaks$break_type), ERA_BREAK_TYPES)
  if (length(unsupported) > 0) {
    stop(
      "era_breaks contains unsupported break_type value(s): ",
      paste(unsupported, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  invisible(breaks)
}

format_era_break_violations <- function(violations) {
  paste(
    paste0(
      violations$break_year,
      " ",
      violations$break_type,
      " (",
      violations$label,
      ")"
    ),
    collapse = ", "
  )
}
