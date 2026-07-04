# ==============================================================================
# Metric registry helpers
# ==============================================================================

.metric_registry_cache <- new.env(parent = emptyenv())


#' Load the bundled metric registry
#'
#' @description
#' Reads the package's bundled metric metadata table from
#' \code{inst/extdata/metric_registry.csv}. The registry records metric names,
#' labels, units, polarity, rate metadata, and source notes for tidy analysis.
#' It is authored from the metric columns and long-schema metric names emitted by
#' package fetchers and analysis helpers; it contains metadata only.
#'
#' The table is cached for the R session after the first read.
#'
#' @return A tibble with columns \code{domain}, \code{metric}, \code{label},
#'   \code{unit}, \code{polarity}, \code{is_rate},
#'   \code{denominator_metric}, \code{era_break_set}, and \code{notes}.
#'
#' @examples
#' registry <- load_metric_registry()
#' head(registry)
#' unique(registry$domain)
#'
#' @export
load_metric_registry <- function() {
  if (!is.null(.metric_registry_cache$registry)) {
    return(.metric_registry_cache$registry)
  }

  path <- system.file("extdata", "metric_registry.csv", package = "njschooldata")
  if (identical(path, "")) {
    stop("Bundled metric registry not found.", call. = FALSE)
  }

  registry <- readr::read_csv(
    path,
    col_types = readr::cols(
      domain = readr::col_character(),
      metric = readr::col_character(),
      label = readr::col_character(),
      unit = readr::col_character(),
      polarity = readr::col_character(),
      is_rate = readr::col_logical(),
      denominator_metric = readr::col_character(),
      era_break_set = readr::col_character(),
      notes = readr::col_character()
    ),
    show_col_types = FALSE
  )

  .metric_registry_cache$registry <- registry
  registry
}


.empty_metric_meta <- function(metric) {
  tibble::tibble(
    domain = NA_character_,
    metric = metric,
    label = NA_character_,
    unit = NA_character_,
    polarity = NA_character_,
    is_rate = NA,
    denominator_metric = NA_character_,
    era_break_set = NA_character_,
    notes = NA_character_
  )
}


#' Look up metadata for one metric
#'
#' @description
#' Returns the single metric-registry row for \code{metric}. If the metric is not
#' registered, returns a one-row tibble with \code{NA} metadata and warns once for
#' that lookup.
#'
#' @param metric Character scalar metric name.
#'
#' @return A one-row tibble with the metric registry schema.
#'
#' @examples
#' metric_meta("grad_rate")
#' metric_meta("per_pupil_total")
#' metric_meta("chronically_absent_rate")
#'
#' @export
metric_meta <- function(metric) {
  if (length(metric) != 1 || is.na(metric) || !nzchar(metric)) {
    stop("metric must be a non-empty character scalar.", call. = FALSE)
  }

  registry <- load_metric_registry()
  out <- registry[registry$metric == metric, , drop = FALSE]

  if (nrow(out) == 0) {
    warning(sprintf("Metric '%s' is not registered.", metric), call. = FALSE)
    return(.empty_metric_meta(metric))
  }

  if (nrow(out) > 1) {
    stop(sprintf("Metric '%s' has multiple registry rows.", metric), call. = FALSE)
  }

  out
}


#' Attach metric metadata to a data frame
#'
#' @description
#' Adds \code{polarity}, \code{unit}, and \code{is_rate} columns to a fetcher or
#' analysis output. For long outputs with a \code{metric} column, metadata is
#' joined per row. Otherwise provide a scalar \code{metric} name to apply the
#' same metadata to the whole frame.
#'
#' Existing data columns are preserved.
#'
#' @param df A data frame.
#' @param metric Optional character scalar metric name. If \code{NULL} and
#'   \code{df} has a \code{metric} column, metadata is joined by that column.
#'
#' @return \code{df} with added \code{polarity}, \code{unit}, and
#'   \code{is_rate} columns.
#'
#' @examples
#' annotate_metric(tibble::tibble(entity_name = "A", value = 0.82), "grad_rate")
#' finance <- tibble::tibble(metric = c("per_pupil_total", "revenue_state"), value = c(1, 2))
#' annotate_metric(finance)
#' annotate_metric(tibble::tibble(value = c(10, 20)), metric = "discipline_rate")
#'
#' @export
annotate_metric <- function(df, metric = NULL) {
  if (!is.data.frame(df)) {
    stop("df must be a data frame.", call. = FALSE)
  }

  registry <- load_metric_registry()
  meta <- registry %>%
    dplyr::select(
      dplyr::all_of(c("metric", "polarity", "unit", "is_rate"))
    )

  if (is.null(metric) && "metric" %in% names(df)) {
    missing_metrics <- setdiff(unique(as.character(df$metric)), registry$metric)
    missing_metrics <- missing_metrics[!is.na(missing_metrics)]
    if (length(missing_metrics) > 0) {
      warning(
        "Unregistered metric(s): ",
        paste(missing_metrics, collapse = ", "),
        call. = FALSE
      )
    }
    return(dplyr::left_join(df, meta, by = "metric"))
  }

  if (is.null(metric)) {
    stop("metric must be provided when df has no 'metric' column.", call. = FALSE)
  }
  if (length(metric) != 1 || is.na(metric) || !nzchar(metric)) {
    stop("metric must be a non-empty character scalar.", call. = FALSE)
  }

  row <- metric_meta(metric)
  df$polarity <- row$polarity[[1]]
  df$unit <- row$unit[[1]]
  df$is_rate <- row$is_rate[[1]]
  df
}


#' List registered metrics
#'
#' @description
#' Returns the bundled metric registry for browsing. Optionally filters to one or
#' more domains.
#'
#' @param domain Optional character vector of domains to keep.
#'
#' @return A tibble containing registry rows.
#'
#' @examples
#' list_metrics()
#' list_metrics("finance")
#' list_metrics(c("graduation", "assessment"))
#'
#' @export
list_metrics <- function(domain = NULL) {
  registry <- load_metric_registry()

  if (is.null(domain)) {
    return(registry)
  }

  registry %>%
    dplyr::filter(.data$domain %in% .env$domain)
}
