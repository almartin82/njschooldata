#!/usr/bin/env Rscript
# =============================================================================
# discovery-build.R — extend the statewide cache with optional rich categories.
# Strict by default: every requested slice must succeed before its aggregate
# cache is written. Use --allow-partial deliberately to persist partial output.
# =============================================================================
suppressMessages({
  description <- file.path(getwd(), "DESCRIPTION")
  if (file.exists(description) &&
      any(grepl("^Package: njschooldata$", readLines(description)))) {
    devtools::load_all(".", quiet = TRUE)
  } else {
    library(njschooldata)
  }
  library(dplyr)
  library(purrr)
})
options(timeout = max(1200, getOption("timeout")))
njsd_cache_enable(TRUE)

SW_DIR <- file.path("site", "_bundles", "_statewide")
DISCOVERY_MANIFEST_PATH <- file.path(
  "site", "_bundles", "discovery-build-manifest.json"
)
DISCOVERY_MANIFEST_ATTR <- "njsd_discovery_manifest_records"
dir.create(SW_DIR, recursive = TRUE, showWarnings = FALSE)

.discovery_manifest <- new.env(parent = emptyenv())
.discovery_manifest$rows <- data.frame(
  domain = character(), end_year = integer(), component = character(),
  requested = logical(), completed = logical(), source_status = character(),
  source_url = character(), retrieved_at = character(), digest = character(),
  warning = character(), error = character(), artifact = character(),
  stringsAsFactors = FALSE
)

log_msg <- function(...) cat(format(Sys.time(), "%H:%M:%S"), "|", ..., "\n")
sw_path <- function(name) file.path(SW_DIR, paste0(name, ".rds"))

discovery_failure <- function(status, error) {
  njschooldata:::new_source_result(
    source_status = status, error = as.character(error)
  )
}

is_discovery_failure <- function(x) {
  inherits(x, "njsd_source_result") &&
    !identical(x$source_status, "actual")
}

record_discovery <- function(domain, end_year = NA_integer_,
                             component = NA_character_, status,
                             result = NULL, error = NULL, artifact = NA_character_) {
  row <- data.frame(
    domain = as.character(domain), end_year = as.integer(end_year),
    component = as.character(component), requested = TRUE,
    completed = identical(status, "actual"), source_status = status,
    source_url = NA_character_, retrieved_at = NA_character_,
    digest = NA_character_, warning = NA_character_, error = NA_character_,
    artifact = as.character(artifact), stringsAsFactors = FALSE
  )
  if (!is.null(result)) {
    row$source_url <- result$source_url[[1]]
    row$retrieved_at <- if (is.na(result$retrieved_at[[1]])) {
      NA_character_
    } else {
      format(result$retrieved_at[[1]], tz = "UTC", usetz = TRUE)
    }
    row$digest <- result$digest[[1]]
    row$warning <- result$warning[[1]]
    row$error <- result$error[[1]]
  }
  if (!is.null(error)) row$error <- conditionMessage(error)
  .discovery_manifest$rows <- rbind(.discovery_manifest$rows, row)
  invisible(row)
}

capture_discovery <- function(fn, domain, end_year,
                              component = NA_character_) {
  value <- tryCatch(fn(), error = identity)
  if (inherits(value, "error")) {
    source_result <- njschooldata:::source_result_from_condition(value)
    status <- source_result$source_status
    result <- njschooldata:::source_result_record(source_result)
    record_discovery(
      domain, end_year, component, status, result = result, error = value
    )
    warning(sprintf(
      "%s %s%s: %s", domain, end_year,
      ifelse(is.na(component), "", paste0("/", component)),
      conditionMessage(value)
    ))
    return(discovery_failure(status, conditionMessage(value)))
  }

  result <- njschooldata:::select_source_result_record(value)
  if (nrow(result) && !identical(result$source_status[[1]], "actual")) {
    record_discovery(
      domain, end_year, component, result$source_status[[1]], result = result
    )
    return(discovery_failure(result$source_status[[1]], result$error[[1]]))
  }
  if (is.data.frame(value) && !nrow(value)) {
    error <- simpleError("Fetcher returned no rows for a requested source.")
    record_discovery(domain, end_year, component, "parse_error", error = error)
    return(discovery_failure("parse_error", conditionMessage(error)))
  }

  record_discovery(
    domain, end_year, component, "actual",
    result = if (nrow(result)) result else NULL
  )
  value
}

years_bind <- function(years, fn, label) {
  out <- map(years, function(year) {
    capture_discovery(function() fn(year), label, year)
  })
  ok <- !map_lgl(out, is_discovery_failure)
  log_msg(sprintf(
    "  %s: %d/%d years (%s)", label, sum(ok), length(years),
    paste(years[ok], collapse = ",")
  ))
  bind_rows(out[ok])
}

components_bind <- function(grid, fn, label) {
  out <- pmap(grid, function(year, grade, subj) {
    capture_discovery(
      function() fn(year, grade, subj), label, year,
      paste(grade, subj, sep = "/")
    )
  })
  ok <- !map_lgl(out, is_discovery_failure)
  log_msg(sprintf("  %s: %d/%d slices", label, sum(ok), nrow(grid)))
  bind_rows(out[ok])
}

restore_discovery_cache <- function(value, path, domain) {
  records <- attr(value, DISCOVERY_MANIFEST_ATTR, exact = TRUE)
  required_columns <- names(.discovery_manifest$rows)
  if (!is.data.frame(records) || !nrow(records) ||
      !all(required_columns %in% names(records))) {
    record_discovery(
      domain, status = "source_unavailable",
      error = simpleError(
        "Cached discovery artifact lacks source provenance; rebuild with --refresh."
      ),
      artifact = path
    )
    return(discovery_failure("source_unavailable", "Untrusted discovery cache."))
  }
  records <- records[, required_columns, drop = FALSE]
  records$artifact <- path
  .discovery_manifest$rows <- rbind(.discovery_manifest$rows, records)
  value
}

cache_or_build <- function(name, builder, refresh = FALSE,
                           allow_partial = FALSE) {
  path <- sw_path(name)
  if (!refresh && file.exists(path)) {
    log_msg("[cached]", name)
    return(restore_discovery_cache(readRDS(path), path, name))
  }

  log_msg("[build ]", name, "...")
  start <- nrow(.discovery_manifest$rows)
  value <- tryCatch(builder(), error = identity)
  if (inherits(value, "error")) {
    status <- njschooldata:::source_status_from_condition(value)
    record_discovery(
      name, status = status, error = value
    )
    warning(name, " failed: ", conditionMessage(value))
    return(discovery_failure(status, conditionMessage(value)))
  }

  built_rows <- if (nrow(.discovery_manifest$rows) > start) {
    seq.int(start + 1L, nrow(.discovery_manifest$rows))
  } else {
    integer()
  }
  if (is.data.frame(value) && !nrow(value)) {
    message <- "Builder returned no rows after category composition."
    record_discovery(
      name, status = "parse_error", error = simpleError(message)
    )
    return(discovery_failure("parse_error", message))
  }
  if (!length(built_rows)) {
    result <- njschooldata:::select_source_result_record(value)
    status <- if (nrow(result)) result$source_status[[1]] else "actual"
    record_discovery(
      name, status = status, result = if (nrow(result)) result else NULL
    )
    built_rows <- nrow(.discovery_manifest$rows)
  }
  incomplete <- !.discovery_manifest$rows$completed[built_rows]
  if (any(incomplete) && !isTRUE(allow_partial)) {
    return(discovery_failure(
      "source_unavailable",
      "Strict discovery category is incomplete; artifact was not written."
    ))
  }
  if (is_discovery_failure(value)) return(value)

  .discovery_manifest$rows$artifact[built_rows] <- path
  attr(value, DISCOVERY_MANIFEST_ATTR) <-
    .discovery_manifest$rows[built_rows, , drop = FALSE]
  saveRDS(value, path)
  value
}

write_discovery_manifest <- function(allow_partial = FALSE) {
  dir.create(dirname(DISCOVERY_MANIFEST_PATH), recursive = TRUE,
             showWarnings = FALSE)
  jsonlite::write_json(
    list(
      generated_at = format(Sys.time(), tz = "UTC", usetz = TRUE),
      allow_partial = isTRUE(allow_partial),
      requests = .discovery_manifest$rows
    ),
    DISCOVERY_MANIFEST_PATH, pretty = TRUE, dataframe = "rows",
    na = "null", auto_unbox = TRUE
  )
}

assert_discovery_coverage <- function(allow_partial = FALSE) {
  write_discovery_manifest(allow_partial)
  incomplete <- !.discovery_manifest$rows$completed
  if (any(incomplete) && !isTRUE(allow_partial)) {
    rows <- .discovery_manifest$rows[incomplete, , drop = FALSE]
    stop(
      "Strict discovery build is incomplete for: ",
      paste0(
        rows$domain, "/", ifelse(is.na(rows$end_year), "current", rows$end_year),
        ifelse(is.na(rows$component), "", paste0("/", rows$component)),
        " [", rows$source_status, "]",
        collapse = ", "
      ),
      ". See ", DISCOVERY_MANIFEST_PATH, ".", call. = FALSE
    )
  }
  invisible(!any(incomplete))
}

main <- function(args = commandArgs(trailingOnly = TRUE)) {
  refresh <- "--refresh" %in% args
  allow_partial <- "--allow-partial" %in% args
  unknown <- setdiff(args, c("--refresh", "--allow-partial"))
  if (length(unknown)) {
    stop("Unknown discovery-build argument(s): ", paste(unknown, collapse = ", "),
         call. = FALSE)
  }

  build <- function(name, builder) {
    cache_or_build(name, builder, refresh, allow_partial)
  }

  build("sat_part", function() {
    years_bind(2018:2024, fetch_sat_participation, "sat_part")
  })
  build("sat_perf", function() {
    years_bind(2018:2024, fetch_sat_performance, "sat_perf")
  })
  build("apib", function() {
    years_bind(2018:2024, fetch_ap_participation, "apib")
  })
  build("removals", function() {
    years_bind(
      2019:2024,
      function(year) fetch_disciplinary_removals(year, level = "district"),
      "removals"
    ) %>% filter(is_district)
  })
  build("police", function() {
    years_bind(
      2019:2024,
      function(year) fetch_police_notifications(year, level = "district"),
      "police"
    ) %>% filter(is_district)
  })
  build("hib", function() {
    years_bind(
      2019:2024,
      function(year) fetch_hib_investigations(year, level = "district"),
      "hib"
    ) %>% filter(is_district)
  })
  build("sped", function() years_bind(2017:2024, fetch_sped, "sped"))

  grid <- expand.grid(
    year = c(2017, 2018, 2019, 2022, 2023, 2024),
    grade = sprintf("%02d", 3:8), subj = c("ela", "math"),
    stringsAsFactors = FALSE
  )
  build("njsla", function() {
    components_bind(
      grid,
      function(year, grade, subj) {
        fetch_parcc(year, grade, subj, tidy = TRUE)
      },
      "njsla"
    ) %>% filter(is_district)
  })

  assert_discovery_coverage(allow_partial)
  log_msg("discovery-build complete")
}

if (sys.nframe() == 0L) {
  main()
}
