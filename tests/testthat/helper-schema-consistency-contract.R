# Shared checker for schema-consistency contract v1. Copied byte for byte into
# every state package; the canonical copy lives with the contract. Do not edit
# a package's copy: change the canonical one and recopy it fleet-wide.

# A network failure is the only error that may turn into NOT-CHECKED. A
# package's own guard or parser refusing a supported year is a real answer.
sc_is_network_error <- function(error) {
  if (inherits(error, "sc_network_error")) return(TRUE)
  text <- paste(c(class(error), conditionMessage(error)), collapse = " ")
  if (grepl("parse[_ ]error|integrity[_ ]error|coverage[_ ](error|refusal)|invalid connection",
            text, ignore.case = TRUE)) return(FALSE)
  grepl(paste0(
    "offline|\\bdns\\b|resolv(e|ing|ution)|timed?\\s*out|timeout|",
    "connect|HTTP[^0-9]*5[0-9]{2}|",
    "5[0-9]{2}[^a-z]*((internal )?server error|bad gateway)|",
    "service unavailable|gateway timeout"
  ), text, ignore.case = TRUE, perl = TRUE)
}

# Column names in order with their full class string.
sc_schema <- function(df) {
  stopifnot(is.data.frame(df))
  cls <- vapply(df, function(x) paste(class(x), collapse = "/"), character(1))
  stats::setNames(unname(cls), names(df))
}

# Human-readable differences of `schema` against `reference`; empty when equal.
sc_schema_diff <- function(reference, schema) {
  out <- character()
  missing <- setdiff(names(reference), names(schema))
  extra <- setdiff(names(schema), names(reference))
  if (length(missing)) out <- c(out, paste0("missing: ", paste(missing, collapse = ", ")))
  if (length(extra)) out <- c(out, paste0("extra: ", paste(extra, collapse = ", ")))
  shared <- intersect(names(reference), names(schema))
  changed <- shared[reference[shared] != schema[shared]]
  if (length(changed)) {
    out <- c(out, paste0("class: ", paste(sprintf("%s %s -> %s", changed,
      reference[changed], schema[changed]), collapse = ", ")))
  }
  if (!length(missing) && !length(extra) && !identical(names(reference), names(schema))) {
    out <- c(out, "order differs")
  }
  out
}

# One call returns one year. A frame whose `end_year` differs from the request,
# or whose source `school_year` column holds more than one school year (a trend
# sheet passed through unfiltered), mixes years under one label.
sc_year_span <- function(df, year) {
  out <- character()
  if ("end_year" %in% names(df)) {
    other <- setdiff(unique(stats::na.omit(as.integer(df$end_year))), as.integer(year))
    if (length(other)) out <- c(out, paste0("rows for end_year ", paste(sort(other), collapse = ", ")))
  }
  if ("school_year" %in% names(df)) {
    labels <- unique(stats::na.omit(as.character(df$school_year)))
    if (length(labels) > 1L) {
      out <- c(out, paste0("holds ", length(labels), " school years: ",
                           paste(sort(labels), collapse = ", ")))
    }
  }
  out
}

# Fetch every supported year and compare schemas. `fetch_one(year)` returns a
# data frame or raises. `known_breaks` is a character vector of reasons named
# by year: a year that differs from the modal schema or errors, on purpose.
sc_contract_check <- function(years, fetch_one, known_breaks = character()) {
  stopifnot(length(years) > 0L, !anyNA(years))
  years <- sort(unique(as.integer(years)))
  known <- names(known_breaks)
  if (length(known_breaks) && (is.null(known) || any(!nzchar(known)) ||
                               any(!nzchar(known_breaks)))) {
    stop("known_breaks must be reasons named by year", call. = FALSE)
  }
  schemas <- list(); not_checked <- character(); errors <- character(); spans <- list()
  for (year in years) {
    key <- as.character(year)
    result <- tryCatch(fetch_one(year), error = identity)
    if (inherits(result, "error")) {
      if (sc_is_network_error(result)) {
        not_checked[[key]] <- conditionMessage(result)
      } else {
        errors[[key]] <- conditionMessage(result)
      }
    } else if (!is.data.frame(result)) {
      errors[[key]] <- paste("returned", paste(class(result), collapse = "/"))
    } else {
      schemas[[key]] <- sc_schema(result)
      span <- sc_year_span(result, year)
      if (length(span)) spans[[key]] <- span
    }
  }
  differences <- list(); reference_year <- NA_integer_
  if (length(schemas)) {
    sig <- vapply(schemas, function(s) paste(names(s), s, sep = ":", collapse = "|"),
                  character(1))
    counts <- table(sig)
    top <- names(counts)[counts == max(counts)]
    reference_year <- max(as.integer(names(sig)[sig %in% top]))
    reference <- schemas[[as.character(reference_year)]]
    for (key in names(schemas)) {
      d <- c(sc_schema_diff(reference, schemas[[key]]), spans[[key]])
      if (length(d)) differences[[key]] <- d
    }
  }
  flagged <- union(names(differences), names(errors))
  list(
    checked = as.integer(names(schemas)),
    reference_year = reference_year,
    differences = differences,
    errors = errors,
    not_checked = not_checked,
    unexpected = sort(as.integer(setdiff(flagged, known))),
    stale_breaks = sort(as.integer(setdiff(intersect(known, as.character(years)), flagged))),
    unknown_break_years = sort(as.integer(setdiff(known, as.character(years))))
  )
}

# Call a fetcher with the year as its first formal plus fixed arguments,
# through the persistent cache where the fetcher has a `use_cache` formal.
sc_fetch_one <- function(fetcher, args = list()) {
  formals_ <- names(formals(fetcher))
  function(year) {
    call_args <- c(stats::setNames(list(year), formals_[[1L]]), args)
    if ("use_cache" %in% formals_ && !"use_cache" %in% names(args)) {
      call_args$use_cache <- TRUE
    }
    do.call(fetcher, call_args)
  }
}

sc_format_report <- function(label, result) {
  lines <- sprintf("%s: reference schema is %s", label, result$reference_year)
  for (key in names(result$differences)) {
    lines <- c(lines, sprintf("  %s: %s", key, paste(result$differences[[key]], collapse = "; ")))
  }
  for (key in names(result$errors)) {
    lines <- c(lines, sprintf("  %s: error: %s", key, result$errors[[key]]))
  }
  if (length(result$unexpected)) {
    lines <- c(lines, paste0("  unexpected: ", paste(result$unexpected, collapse = ", ")))
  }
  if (length(result$stale_breaks)) {
    lines <- c(lines, paste0("  known break no longer differs (remove it): ",
                             paste(result$stale_breaks, collapse = ", ")))
  }
  if (length(result$unknown_break_years)) {
    lines <- c(lines, paste0("  known break for an unsupported year: ",
                             paste(result$unknown_break_years, collapse = ", ")))
  }
  for (key in names(result$not_checked)) {
    lines <- c(lines, sprintf("  %s: NOT-CHECKED (network): %s", key, result$not_checked[[key]]))
  }
  paste(lines, collapse = "\n")
}

sc_expect_contract <- function(label, years, fetch_one, known_breaks = character()) {
  result <- sc_contract_check(years, fetch_one, known_breaks)
  if (length(result$checked) + length(result$errors) < 2L) {
    testthat::skip(paste0(label, ": fewer than two years reachable. ",
                          sc_format_report(label, result)))
  }
  ok <- !length(result$unexpected) && !length(result$stale_breaks) &&
    !length(result$unknown_break_years)
  testthat::expect(ok, sc_format_report(label, result))
  if (length(result$not_checked)) {
    message(sc_format_report(label, result))
  }
  invisible(result)
}

# The checker must be able to fail.
sc_contract_self_test <- function() {
  base <- function(year) data.frame(end_year = year, id = "a", n = 1, stringsAsFactors = FALSE)
  same <- sc_contract_check(2020:2022, base)
  testthat::expect_identical(same$unexpected, integer())
  testthat::expect_identical(same$checked, 2020:2022)
  drift <- list(
    missing = function(year) base(year)[c("end_year", "id")],
    extra = function(year) cbind(base(year), extra = TRUE),
    class = function(year) transform(base(year), n = as.character(n)),
    order = function(year) base(year)[c("id", "end_year", "n")],
    long_wide = function(year) data.frame(end_year = year, id = "a", group = "x", pct = 1)
  )
  for (kind in names(drift)) {
    stub <- function(year) if (year == 2021L) drift[[kind]](year) else base(year)
    r <- sc_contract_check(2020:2022, stub)
    testthat::expect_identical(r$unexpected, 2021L, info = kind)
    testthat::expect_identical(r$reference_year, 2022L, info = kind)
    testthat::expect_true(length(r$differences[["2021"]]) > 0L, info = kind)
    known <- sc_contract_check(2020:2022, stub, c(`2021` = "documented"))
    testthat::expect_identical(known$unexpected, integer(), info = kind)
  }
  # Same schema every year, but one year carries a trend sheet's other years.
  trend <- function(year) {
    df <- base(year)
    df$school_year <- "x"
    if (year == 2021L) df <- rbind(df, transform(df, school_year = "y"))
    df
  }
  mixed <- sc_contract_check(2020:2022, trend)
  testthat::expect_identical(mixed$unexpected, 2021L)
  testthat::expect_match(mixed$differences[["2021"]], "holds 2 school years")
  relabel <- sc_contract_check(2020:2021, function(year) base(if (year == 2021L) 2019L else year))
  testthat::expect_identical(relabel$unexpected, 2021L)
  stale <- sc_contract_check(2020:2022, base, c(`2021` = "documented"))
  testthat::expect_identical(stale$stale_breaks, 2021L)
  testthat::expect_identical(sc_contract_check(2020:2022, base, c(`2019` = "x"))$unknown_break_years,
                             2019L)
  refused <- sc_contract_check(2020:2021, function(year) {
    if (year == 2021L) stop("year not supported") else base(year)
  })
  testthat::expect_identical(refused$unexpected, 2021L)
  for (message in c("offline", "Could not resolve host", "HTTP 503", "Timeout")) {
    net <- sc_contract_check(2020:2021, function(year) {
      if (year == 2021L) stop(message) else base(year)
    })
    testthat::expect_identical(net$unexpected, integer(), info = message)
    testthat::expect_identical(names(net$not_checked), "2021", info = message)
  }
  # A drifted minority year never becomes the reference; ties go to the latest.
  tie <- sc_contract_check(2020:2021, function(year) if (year == 2020L) drift$extra(year) else base(year))
  testthat::expect_identical(tie$reference_year, 2021L)
  testthat::expect_identical(tie$unexpected, 2020L)
  testthat::expect_error(sc_contract_check(2020L, base, c("no year")), "named by year")
  invisible(TRUE)
}
