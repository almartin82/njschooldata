# ==============================================================================
# Source request results
# ==============================================================================

.njsd_source_statuses <- c(
  "actual",
  "not_published",
  "not_yet_observed",
  "source_unavailable",
  "parse_error"
)

.source_context_value <- function(x) {
  if (is.null(x) || !length(x)) NA_character_ else as.character(x[[1]])
}

#' Create an internal source result
#'
#' Source request status is deliberately separate from row-level
#' `value_status`: it describes whether an artifact was retrieved and parsed,
#' not whether an individual observation was reported or suppressed.
#'
#' @param data Parsed data, or `NULL` when no usable source was produced.
#' @param source_status One of the registered source statuses.
#' @param source_url Requested source URL.
#' @param retrieved_at Retrieval timestamp, when a request was made.
#' @param warning Optional warning context.
#' @param error Optional error context.
#' @param digest Optional SHA-256 digest of the retrieved artifact.
#' @return An object of class `njsd_source_result`.
#' @keywords internal
new_source_result <- function(data = NULL, source_status,
                              source_url = NA_character_,
                              retrieved_at = NULL, warning = NULL,
                              error = NULL, digest = NULL) {
  if (length(source_status) != 1L || is.na(source_status) ||
      !source_status %in% .njsd_source_statuses) {
    stop(
      "`source_status` must be one of: ",
      paste(.njsd_source_statuses, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  if (!is.null(retrieved_at)) {
    retrieved_at <- as.POSIXct(retrieved_at, tz = "UTC")
  }
  structure(
    list(
      data = data,
      source_status = as.character(source_status),
      source_url = .source_context_value(source_url),
      retrieved_at = retrieved_at,
      digest = .source_context_value(digest),
      warning = .source_context_value(warning),
      error = .source_context_value(error)
    ),
    class = "njsd_source_result"
  )
}

#' Extract data from a source result
#'
#' @param result A source result.
#' @param allow_partial If `TRUE`, return the result's data even when its source
#'   status is not `actual`. The default is strict.
#' @return The parsed data.
#' @keywords internal
source_result_data <- function(result, allow_partial = FALSE) {
  if (!inherits(result, "njsd_source_result")) {
    stop("`result` must be an njsd_source_result.", call. = FALSE)
  }
  if (identical(result$source_status, "actual") || isTRUE(allow_partial)) {
    return(result$data)
  }

  message <- paste0(
    "NJ DOE source result is ", result$source_status,
    if (!is.na(result$source_url)) paste0(" (", result$source_url, ")") else "",
    if (!is.na(result$error)) paste0(": ", result$error) else ""
  )
  condition <- structure(
    list(message = message, call = NULL, result = result),
    class = c(
      paste0("njsd_", result$source_status),
      "njsd_source_error",
      "error",
      "condition"
    )
  )
  stop(condition)
}

#' Flatten source provenance to a stable record
#'
#' @param result A source result.
#' @param domain Canonical data family.
#' @param end_year Requested school-year end year.
#' @param component Optional component within a composed response.
#' @return A one-row data frame.
#' @keywords internal
source_result_record <- function(result, domain = NA_character_,
                                 end_year = NA_integer_,
                                 component = NA_character_) {
  if (!inherits(result, "njsd_source_result")) {
    stop("`result` must be an njsd_source_result.", call. = FALSE)
  }
  retrieved_at <- result$retrieved_at
  if (is.null(retrieved_at)) retrieved_at <- as.POSIXct(NA, tz = "UTC")
  data.frame(
    domain = .source_context_value(domain),
    end_year = as.integer(end_year)[1],
    component = .source_context_value(component),
    source_status = result$source_status,
    source_url = result$source_url,
    retrieved_at = retrieved_at,
    digest = result$digest,
    warning = result$warning,
    error = result$error,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

.empty_source_result_records <- function() {
  data.frame(
    domain = character(), end_year = integer(), component = character(),
    source_status = character(), source_url = character(),
    retrieved_at = as.POSIXct(character(), tz = "UTC"),
    digest = character(), warning = character(), error = character(),
    stringsAsFactors = FALSE
  )
}

#' Attach source-result provenance to returned data
#'
#' @param data A returned data object.
#' @param results Source results or already flattened result records.
#' @return `data` with source provenance stored in an attribute.
#' @keywords internal
attach_source_results <- function(data, results) {
  if (is.data.frame(results)) {
    records <- results
  } else if (!length(results)) {
    records <- .empty_source_result_records()
  } else {
    records <- do.call(rbind, lapply(results, source_result_record))
    rownames(records) <- NULL
  }
  attr(data, "njsd_source_results") <- records
  data
}

#' Inspect source-request status and provenance
#'
#' Canonical fetchers attach one record for every required or optional source.
#' These records describe request-level success or failure and are distinct from
#' row-level `value_status` classifications.
#'
#' @param x An object returned by a canonical fetcher.
#' @return A data frame with source status, URL, retrieval time, digest, and
#'   warning/error context.
#' @export
get_source_results <- function(x) {
  records <- attr(x, "njsd_source_results", exact = TRUE)
  if (is.null(records)) .empty_source_result_records() else records
}

source_status_from_condition <- function(error) {
  if (inherits(error, "njsd_source_error") &&
      inherits(error$result, "njsd_source_result")) {
    return(error$result$source_status)
  }
  if (inherits(error, "njsd_parse_error")) "parse_error" else "source_unavailable"
}

source_result_from_condition <- function(error) {
  if (inherits(error, "njsd_source_error") &&
      inherits(error$result, "njsd_source_result")) {
    return(error$result)
  }
  new_source_result(
    source_status = source_status_from_condition(error),
    error = conditionMessage(error)
  )
}

select_source_result_record <- function(value) {
  if (inherits(value, "njsd_source_result")) {
    return(source_result_record(value))
  }
  records <- get_source_results(value)
  if (!nrow(records)) return(records)
  priority <- match(
    records$source_status,
    c("parse_error", "source_unavailable", "not_published",
      "not_yet_observed", "actual")
  )
  priority[is.na(priority)] <- Inf
  records[which.min(priority), , drop = FALSE]
}

# Capture one requested source call without representing failure as NULL. This
# is the shared building block for multi-year/domain composition.
capture_source_call <- function(fn, domain, end_year,
                                component = NA_character_) {
  value <- tryCatch(fn(), error = identity)
  if (inherits(value, "error")) {
    result <- source_result_from_condition(value)
    return(structure(
      list(
        data = NULL,
        records = source_result_record(result, domain, end_year, component)
      ),
      class = "njsd_source_capture"
    ))
  }

  if (inherits(value, "njsd_source_result")) {
    return(structure(
      list(
        data = if (identical(value$source_status, "actual")) value$data else NULL,
        records = source_result_record(value, domain, end_year, component)
      ),
      class = "njsd_source_capture"
    ))
  }

  records <- get_source_results(value)
  if (!nrow(records)) {
    records <- source_result_record(
      new_source_result(data = value, source_status = "actual"),
      domain, end_year, component
    )
  }
  structure(
    list(data = value, records = records),
    class = "njsd_source_capture"
  )
}

transform_source_result <- function(result, fn) {
  if (!inherits(result, "njsd_source_result")) {
    stop("`result` must be an njsd_source_result.", call. = FALSE)
  }
  if (!identical(result$source_status, "actual")) return(result)

  transformed <- tryCatch(fn(result$data), error = identity)
  if (inherits(transformed, "error")) {
    return(new_source_result(
      source_status = "parse_error", source_url = result$source_url,
      retrieved_at = result$retrieved_at, digest = result$digest,
      warning = result$warning, error = conditionMessage(transformed)
    ))
  }
  new_source_result(
    data = transformed, source_status = "actual",
    source_url = result$source_url, retrieved_at = result$retrieved_at,
    digest = result$digest, warning = result$warning
  )
}

source_gap_capture <- function(domain, end_year, component = NA_character_,
                               source_status, warning = NULL, error = NULL) {
  result <- new_source_result(
    source_status = source_status, warning = warning, error = error
  )
  structure(
    list(
      data = NULL,
      records = source_result_record(result, domain, end_year, component)
    ),
    class = "njsd_source_capture"
  )
}

source_gap_status <- function(data_type, end_year) {
  family <- resolve_data_family(data_type)
  entry <- get_source_registry()[[family]]
  end_year <- as.integer(end_year)
  if (end_year %in% entry$skipped_years) return("not_published")
  if (length(entry$raw_years) && end_year > max(entry$raw_years)) {
    return("not_yet_observed")
  }
  "not_published"
}

capture_registered_source_call <- function(fn, data_type, end_year,
                                            domain = data_type,
                                            component = NA_character_) {
  family <- resolve_data_family(data_type)
  entry <- get_source_registry()[[family]]
  if (as.integer(end_year) %in% entry$raw_years) {
    return(capture_source_call(fn, domain, end_year, component))
  }
  warning <- entry$skipped_reasons[[as.character(end_year)]]
  if (is.null(warning)) {
    warning <- paste0(
      "No registered ", family, " source for end_year ", end_year, "."
    )
  }
  source_gap_capture(
    domain, end_year, component,
    source_status = source_gap_status(family, end_year), warning = warning
  )
}

combine_source_captures <- function(captures, allow_partial = FALSE,
                                    context = "multi-source request",
                                    failure_statuses = setdiff(
                                      .njsd_source_statuses, "actual"
                                    ),
                                    combine = c("rows", "list")) {
  combine <- match.arg(combine)
  if (!length(captures)) {
    return(attach_source_results(tibble::tibble(), list()))
  }
  if (!all(vapply(captures, inherits, logical(1), "njsd_source_capture"))) {
    stop("All inputs must be njsd_source_capture objects.", call. = FALSE)
  }

  records <- do.call(rbind, lapply(captures, `[[`, "records"))
  incomplete <- records$source_status %in% failure_statuses
  if (any(incomplete) && !isTRUE(allow_partial)) {
    failures <- records[incomplete, , drop = FALSE]
    worst <- if ("parse_error" %in% failures$source_status) {
      "parse_error"
    } else if ("source_unavailable" %in% failures$source_status) {
      "source_unavailable"
    } else {
      failures$source_status[[1]]
    }
    details <- paste0(
      failures$end_year,
      ifelse(is.na(failures$component), "", paste0("/", failures$component)),
      " [", failures$source_status, "]"
    )
    source_result_data(new_source_result(
      source_status = worst,
      error = paste0(context, " incomplete: ", paste(details, collapse = ", "))
    ))
  }

  data <- lapply(captures, `[[`, "data")
  present <- !vapply(data, is.null, logical(1))
  out <- if (combine == "rows") {
    dplyr::bind_rows(data[present])
  } else {
    data[present]
  }
  attach_source_results(out, records)
}
