# Canonical vendorable multi-year frame driver, contract v1 (STANDARD M4).
# Requires base R; the default `combine` of multi_year_frame() needs dplyr.
# Sourcing is inert.
#
# Vendored byte-for-byte as R/multi_year.R in every package with a
# fetch_*_multi(). Edit ONLY contracts/partial-frame/v1/multi_year.R, then run
# scripts/partial-frame/sync.py. The package prefix (e.g. "txschooldata") is
# always an argument, never a constant here. Each package keeps its own
# droppable test, its own combine step and any missing_years arithmetic that
# genuinely differs (a STAAR year is missing when any of its grades is); the
# pieces below are what every package shares.
#
# The rule, one for all 50 packages (STANDARD M4, Andy 2026-11-09 Q4):
#
#   year not servable (prefilter,   default: stop.  allow_partial: warn naming
#   declared gap)                   the years, record them in missing_years.
#   per-year error                  default: stop, re-raised unchanged.
#                                   allow_partial: dropped (warned, recorded)
#                                   only when the package's `droppable(e)`
#                                   says it is a genuine source failure
#                                   (classified transport failure, bad source
#                                   bytes). Our parser on good bytes, policy,
#                                   integrity and unclassified errors: stop.
#   a year that returns 0 rows      stop in both modes, `{prefix}_empty_year_error`
#                                   naming the year. Never droppable.
#   every requested year a          allow_partial: an empty frame carrying
#   declared gap (none attempted)   requested_years and missing_years (= all);
#                                   the prefilter has already warned.
#   nothing served otherwise        stop, `{prefix}_no_year_served_error`.
#
# `requested_years` / `missing_years` are integer, always attached, in both
# modes, and attached LAST (column subsetting and summarise() drop them).
#
# `lapply()`, never `purrr::map()`: purrr rewraps whatever the year raises as
# purrr_error_indexed and leaves the original only on `$parent`, so a class
# test can no longer see it. One error handler with the class test inside it:
# a stop(e) from a class handler is caught by a sibling `error` handler of the
# same tryCatch(), which silently defeats the re-raise.

.multi_year_prefix <- function(prefix) {
  if (!is.character(prefix) || length(prefix) != 1L || is.na(prefix) ||
      !grepl("^[A-Za-z][A-Za-z0-9._]*$", prefix)) {
    stop("multi_year: `prefix` must be one package prefix, e.g. \"txschooldata\"",
         call. = FALSE)
  }
  prefix
}

.multi_year_condition <- function(message, classes, ...) {
  structure(c(list(message = message, call = NULL), list(...)),
            class = unique(c(classes, "error", "condition")))
}

# Availability prefilter. Returns list(years = the servable years in caller
# order, gaps = the requested years `available` cannot serve). Default mode
# stops; `refusal` (a string, or a function of the gap years returning one)
# keeps a family's own message, else a canonical one. Under allow_partial the
# gaps are dropped with a warning naming them; the caller records them in
# missing_years (multi_year_frame() does).
multi_year_prefilter <- function(years, available, allow_partial, family,
                                 prefix, refusal = NULL) {
  prefix <- .multi_year_prefix(prefix)
  gaps <- years[!years %in% available]
  if (length(gaps)) {
    if (!isTRUE(allow_partial)) {
      message <- if (is.function(refusal)) refusal(gaps) else if (!is.null(refusal)) {
        refusal
      } else {
        paste0(family, " data not available for years: ",
               paste(gaps, collapse = ", "),
               ". Set allow_partial to TRUE to accept a short frame; the ",
               "omission is then named in attr(x, \"missing_years\").")
      }
      stop(.multi_year_condition(
        as.character(message)[[1L]],
        c(paste0(prefix, "_unavailable_year_error"),
          "multi_year_unavailable_year_error"),
        years = as.integer(gaps), family = family))
    }
    warning(warningCondition(
      paste0(family, " years not available and omitted: ",
             paste(gaps, collapse = ", ")),
      class = c(paste0(prefix, "_omitted_years_warning"),
                "multi_year_omitted_years_warning")))
  }
  list(years = years[years %in% available], gaps = gaps)
}

# One item of a multi-year request. Returns the item's value, or NULL when the
# item was dropped under allow_partial. `droppable(e)` must answer TRUE or
# FALSE; anything it does not call droppable propagates unchanged.
multi_year_attempt <- function(expr, label, allow_partial, droppable, family,
                               drop_message = NULL, warning_call = FALSE) {
  tryCatch(expr, error = function(e) {
    if (!isTRUE(allow_partial)) stop(e)
    verdict <- droppable(e)
    if (!is.logical(verdict) || length(verdict) != 1L || is.na(verdict)) {
      stop("multi_year: `droppable(e)` must return TRUE or FALSE", call. = FALSE)
    }
    if (!verdict) stop(e)
    warning(if (is.null(drop_message)) {
      paste0("Could not fetch ", family, " for year ", label, ": ",
             conditionMessage(e))
    } else {
      drop_message(e)
    }, call. = warning_call)
    NULL
  })
}

# Stop, in both modes, when any served item is a data frame with 0 rows.
# `labels` name the items (usually their years). `class` adds package classes
# after `{prefix}_empty_year_error`.
multi_year_check_rows <- function(results, labels, family, prefix,
                                  class = character()) {
  prefix <- .multi_year_prefix(prefix)
  empty <- vapply(results, function(x) is.data.frame(x) && nrow(x) == 0L,
                  logical(1))
  if (any(empty)) {
    stop(.multi_year_condition(
      paste0(family, " returned no rows for requested year(s) ",
             paste(labels[empty], collapse = ", "),
             ". A year with no rows is never bound into a multi-year frame."),
      c(paste0(prefix, "_empty_year_error"), class,
        "multi_year_empty_year_error"),
      years = labels[empty], family = family))
  }
  invisible(results)
}

# The per-item loop. `fetch_one(item)` serves one item; `label(item)` names it
# in warnings and in the 0-row stop; `drop_message(item, e)` overrides the
# drop warning; `progress(item)` returns a message() line. Returns
# list(results, dropped). Runs the 0-row stop before returning.
multi_year_fetch <- function(items, fetch_one, allow_partial, droppable,
                             family, prefix, label = function(item) item,
                             drop_message = NULL, progress = NULL,
                             warning_call = FALSE, empty_class = character()) {
  prefix <- .multi_year_prefix(prefix)
  if (!is.function(droppable)) {
    stop("multi_year: `droppable` must be a function of the condition",
         call. = FALSE)
  }
  results <- lapply(items, function(item) {
    if (!is.null(progress)) message(progress(item))
    multi_year_attempt(
      fetch_one(item), label(item), allow_partial, droppable, family,
      drop_message = if (is.null(drop_message)) NULL else
        function(e) drop_message(item, e),
      warning_call = warning_call)
  })
  labels <- vapply(items, function(item) paste(label(item), collapse = " "),
                   character(1))
  multi_year_check_rows(results, labels, family, prefix, class = empty_class)
  list(results = results,
       dropped = vapply(results, is.null, logical(1)))
}

# Decide whether anything was served. TRUE: at least one item served. FALSE:
# nothing was attempted, every requested year was a declared gap and the
# caller opted in (return the empty frame). Otherwise stop.
multi_year_require_served <- function(dropped, gaps, allow_partial, family,
                                      prefix, message = NULL) {
  prefix <- .multi_year_prefix(prefix)
  if (any(!dropped)) return(TRUE)
  if (!length(dropped) && length(gaps) && isTRUE(allow_partial)) return(FALSE)
  stop(.multi_year_condition(
    if (is.null(message)) {
      paste0("No ", family, " data could be fetched for any requested year")
    } else {
      message
    },
    c(paste0(prefix, "_no_year_served_error"), "multi_year_no_year_served_error"),
    family = family))
}

# Attach the declaration. `missing` keeps the caller's request order.
multi_year_declare <- function(out, requested, missing) {
  requested <- as.integer(requested)
  attr(out, "requested_years") <- requested
  attr(out, "missing_years") <- requested[requested %in% as.integer(missing)]
  out
}

# The whole rule for a one-item-per-year family. `available = NULL` skips the
# prefilter. `combine(parts)` binds the served frames (also called with an
# empty list for the all-declared-gap frame); `missing(gaps, years, dropped)`
# overrides which years are declared missing.
multi_year_frame <- function(years, fetch_one, allow_partial, droppable,
                             family, prefix, available = NULL, refusal = NULL,
                             combine = function(parts) dplyr::bind_rows(parts),
                             requested = years, drop_message = NULL,
                             progress = NULL, none_message = NULL,
                             empty_class = character(), missing = NULL) {
  force(requested)  # before `years` is narrowed below
  gaps <- years[0]
  if (!is.null(available)) {
    filtered <- multi_year_prefilter(years, available, allow_partial, family,
                                     prefix, refusal = refusal)
    years <- filtered$years
    gaps <- filtered$gaps
  }
  fetched <- multi_year_fetch(years, fetch_one, allow_partial, droppable,
                              family, prefix, drop_message = drop_message,
                              progress = progress, empty_class = empty_class)
  served <- multi_year_require_served(fetched$dropped, gaps, allow_partial,
                                      family, prefix, message = none_message)
  out <- combine(if (served) fetched$results[!fetched$dropped] else list())
  if (is.null(out)) out <- data.frame()
  lost <- if (is.null(missing)) c(gaps, years[fetched$dropped]) else
    missing(gaps, years, fetched$dropped)
  multi_year_declare(out, requested, lost)
}
