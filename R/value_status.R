# ==============================================================================
# Value-status classification
# ==============================================================================

.value_status_levels <- c(
  "actual",
  "suppressed",
  "not_published",
  "not_yet_observed",
  "not_applicable"
)

value_status_factor <- function(x) {
  factor(x, levels = .value_status_levels)
}


#' Classify why a raw value token is absent or present
#'
#' Reads a raw pre-coercion value token and classifies the reason its cleaned
#' numeric value is present or missing. Blank values and truly unknown
#' non-numeric tokens default to \code{not_published}; callers that know a more
#' specific structural reason should set status directly.
#'
#' @param raw A raw character vector before numeric coercion.
#' @return A factor with levels \code{actual}, \code{suppressed},
#'   \code{not_published}, \code{not_yet_observed}, and
#'   \code{not_applicable}.
#' @keywords internal
classify_value_status <- function(raw) {
  n <- length(raw)
  if (n == 0) return(value_status_factor(character(0)))

  missing_raw <- is.na(raw)
  token <- trimws(as.character(raw))
  token[missing_raw] <- NA_character_
  token_lc <- tolower(token)
  token_lc <- gsub("[[:space:]]+", " ", token_lc)

  status <- rep("not_published", n)

  not_applicable <- !missing_raw & !is.na(token_lc) &
    (grepl("^n\\s*/\\s*a\\b", token_lc) |
       token_lc %in% c("not applicable"))
  status[not_applicable] <- "not_applicable"

  numeric_token <- gsub(",", "", token, fixed = TRUE)
  numeric_token <- gsub("%", "", numeric_token, fixed = TRUE)
  numeric_token <- gsub("$", "", numeric_token, fixed = TRUE)
  parsed <- suppressWarnings(as.numeric(numeric_token))
  actual <- !missing_raw & !is.na(token) & token != "" &
    !is.na(parsed) & is.finite(parsed)
  status[actual] <- "actual"

  no_data <- missing_raw | is.na(token_lc) | token_lc == "" |
    grepl("no data available", token_lc, fixed = TRUE)
  status[no_data] <- "not_published"

  suppressed <- !missing_raw & !is.na(token_lc) &
    (
      token_lc %in% c("*", "n") |
        grepl("<\\s*=?\\s*(\\.[0-9]|[0-9])", token_lc) |
        grepl("fewer than\\s+[0-9]", token_lc) |
        grepl("less than\\s+[0-9]", token_lc) |
        grepl("below\\s+(essa\\s+)?n[- ]?size", token_lc)
    )
  status[suppressed] <- "suppressed"

  value_status_factor(status)
}


#' Pair SPR numeric coercion with value-status classification
#'
#' @param x A raw SPR value vector.
#' @return A list with \code{value} from \code{\link{spr_value_numeric}} and
#'   \code{status} from \code{\link{classify_value_status}}.
#' @keywords internal
spr_value_with_status <- function(x) {
  list(
    value = spr_value_numeric(x),
    status = classify_value_status(x)
  )
}


#' Pair DARS numeric coercion with value-status classification
#'
#' @param x A raw DARS value vector.
#' @return A list with \code{value} from \code{\link{rs_value_numeric}} and
#'   \code{status} from \code{\link{classify_value_status}}.
#' @keywords internal
rs_value_with_status <- function(x) {
  list(
    value = rs_value_numeric(x),
    status = classify_value_status(x)
  )
}


#' Pair staff numeric coercion with value-status classification
#'
#' @param x A raw staff value vector.
#' @return A list with \code{value} from \code{\link{staff_value_numeric}} and
#'   \code{status} from \code{\link{classify_value_status}}.
#' @keywords internal
staff_value_with_status <- function(x) {
  list(
    value = staff_value_numeric(x),
    status = classify_value_status(x)
  )
}


#' Pair report-card numeric coercion with value-status classification
#'
#' @param x A raw report-card value vector.
#' @return A list with \code{value} from \code{\link{rc_numeric_cleaner}} and
#'   \code{status} from \code{\link{classify_value_status}}.
#' @keywords internal
rc_numeric_with_status <- function(x) {
  list(
    value = suppressWarnings(rc_numeric_cleaner(x)),
    status = classify_value_status(x)
  )
}


#' Classify finance value status from structural context
#'
#' Finance values do not always have a raw cell token to parse. Per-pupil
#' actuals beyond the latest published actual year are not yet observed; missing
#' per-pupil values with zero or absent denominators are not published; present
#' numeric values are actual.
#'
#' @param metric Finance metric name.
#' @param value Numeric finance value.
#' @param end_year School/fiscal year end.
#' @param is_per_pupil Logical vector indicating per-pupil metrics. If omitted,
#'   inferred from metric names beginning with \code{per_pupil}.
#' @param enrollment_denominator Optional denominator vector for per-pupil rows.
#' @param latest_observed_per_pupil_year Latest year with per-pupil actuals in
#'   the current finance source.
#' @return A value-status factor.
#' @keywords internal
finance_value_status <- function(metric, value, end_year,
                                 is_per_pupil = NULL,
                                 enrollment_denominator = NULL,
                                 latest_observed_per_pupil_year = 2024L) {
  input_lengths <- c(length(metric), length(value), length(end_year),
                     length(is_per_pupil), length(enrollment_denominator))
  if (max(input_lengths) == 0) return(value_status_factor(character(0)))
  n <- max(input_lengths)

  metric <- rep(as.character(metric), length.out = n)
  value <- rep(as.numeric(value), length.out = n)
  end_year <- rep(as.integer(end_year), length.out = n)

  if (is.null(is_per_pupil)) {
    is_per_pupil <- grepl("^per_pupil", metric)
  } else {
    is_per_pupil <- rep(as.logical(is_per_pupil), length.out = n)
    infer <- is.na(is_per_pupil)
    is_per_pupil[infer] <- grepl("^per_pupil", metric[infer])
  }

  if (is.null(enrollment_denominator)) {
    enrollment_denominator <- rep(NA_real_, n)
  } else {
    enrollment_denominator <- rep(as.numeric(enrollment_denominator),
                                  length.out = n)
  }

  status <- rep("not_published", n)

  actual <- !is.na(value) & is.finite(value)
  status[actual] <- "actual"

  not_yet_observed <- !actual & is_per_pupil %in% TRUE &
    !is.na(end_year) & end_year > latest_observed_per_pupil_year
  status[not_yet_observed] <- "not_yet_observed"

  missing_denominator <- !actual & is_per_pupil %in% TRUE &
    (is.na(enrollment_denominator) | enrollment_denominator <= 0)
  status[missing_denominator & !not_yet_observed] <- "not_published"

  value_status_factor(status)
}
