# Shared checker for available-years contract v1. Copied byte for byte into
# every state package; the canonical copy lives with the contract. Do not edit
# a package's copy: change the canonical one and recopy it fleet-wide.

# A network failure is the only refusal that may turn into a skip. A package's
# own guard, coverage policy or parser refusing a year is a real answer.
ay_is_network_error <- function(error) {
  if (inherits(error, "ay_network_error")) return(TRUE)
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

# Probe every claimed year plus one beyond each end. `fetch_one(year)` returns
# a data frame (served when it has rows) or raises.
ay_contract_check <- function(claimed, fetch_one) {
  stopifnot(length(claimed) > 0L, !anyNA(claimed))
  claimed <- sort(unique(as.integer(claimed)))
  probes <- sort(unique(c(claimed, min(claimed) - 1L, max(claimed) + 1L)))
  served <- integer()
  network_errors <- character()
  for (year in probes) {
    result <- tryCatch(fetch_one(year), error = identity)
    if (inherits(result, "error")) {
      if (ay_is_network_error(result)) {
        network_errors <- c(network_errors,
                            sprintf("%d: %s", year, conditionMessage(result)))
      }
    } else if (is.data.frame(result) && nrow(result) > 0L) {
      served <- c(served, year)
    }
  }
  list(claimed_not_served = setdiff(claimed, served),
       served_not_claimed = setdiff(served, claimed),
       network_errors = network_errors)
}

# Call a fetcher the ordinary way: default arguments, the persistent cache,
# `source = "live"` then `"package"` where the fetcher has a `source` formal.
# A network error counts only when no mode served the year.
ay_fetch_one <- function(fetcher, args = list()) {
  formals_ <- names(formals(fetcher))
  modes <- if ("source" %in% formals_) c("live", "package") else NA_character_
  function(year) {
    call_args <- c(stats::setNames(list(year), formals_[[1L]]), args)
    if ("tidy" %in% formals_) call_args$tidy <- TRUE
    if ("use_cache" %in% formals_) call_args$use_cache <- TRUE
    network <- character()
    for (mode in modes) {
      if (!is.na(mode)) call_args$source <- mode
      result <- tryCatch(do.call(fetcher, call_args), error = identity)
      if (!inherits(result, "error")) {
        if (is.data.frame(result) && nrow(result) > 0L) return(result)
      } else if (ay_is_network_error(result)) {
        network <- c(network, paste0(mode, ": ", conditionMessage(result)))
      }
    }
    if (length(network)) {
      stop(structure(
        class = c("ay_network_error", "error", "condition"),
        list(message = paste(network, collapse = "; "), call = NULL)
      ))
    }
    data.frame()
  }
}

# Run the live contract for one declared type. Skips only on network failure.
ay_expect_contract <- function(type, get_available_years, fetcher, args = list()) {
  checked <- ay_contract_check(get_available_years(type), ay_fetch_one(fetcher, args))
  if (length(checked$network_errors)) {
    testthat::skip(paste("network:", paste(checked$network_errors, collapse = "; ")))
  }
  testthat::expect_identical(
    checked$claimed_not_served, integer(),
    info = paste(type, "claimed not served:",
                 paste(checked$claimed_not_served, collapse = ", "))
  )
  testthat::expect_identical(
    checked$served_not_claimed, integer(),
    info = paste(type, "served not claimed:",
                 paste(checked$served_not_claimed, collapse = ", "))
  )
}

# Proof the checker can fail, offline, with a stub fetcher.
ay_contract_self_test <- function() {
  stub <- function(year) {
    if (year %in% 2020:2022) data.frame(end_year = year) else data.frame()
  }
  bogus <- ay_contract_check(c(1990L, 2020:2022), stub)
  testthat::expect_identical(bogus$claimed_not_served, 1990L)
  hidden <- ay_contract_check(2021:2022, stub)
  testthat::expect_identical(hidden$served_not_claimed, 2020L)
  testthat::expect_length(hidden$network_errors, 0L)
  refused <- ay_contract_check(2020L, function(year) stop("coverage refusal"))
  testthat::expect_identical(refused$claimed_not_served, 2020L)
  testthat::expect_length(refused$network_errors, 0L)
  for (message in c("offline", "DNS lookup failed", "Timeout", "connection failed",
                    "HTTP 503", "Could not resolve host", "Failed to connect")) {
    network <- ay_contract_check(2020L, function(year) stop(message))
    testthat::expect_length(network$network_errors, 3L)
  }
  for (message in c("parse error", "end_year outside coverage", "HTTP 404",
                    "parse error reading connection", "invalid connection")) {
    testthat::expect_false(ay_is_network_error(simpleError(message)))
  }
  testthat::expect_true(ay_is_network_error(structure(
    list(message = "transport failed", call = NULL),
    class = c("curl_error_couldnt_connect", "error", "condition")
  )))

  # A live network failure is forgiven when package mode serves the year,
  # and reported when nothing serves it.
  flaky <- function(end_year, source = c("live", "package")) {
    if (source == "live") stop("Could not resolve host")
    if (end_year == 2020L) data.frame(end_year = end_year) else data.frame()
  }
  fetch <- ay_fetch_one(flaky)
  testthat::expect_equal(nrow(fetch(2020L)), 1L)
  testthat::expect_true(ay_is_network_error(tryCatch(fetch(2021L), error = identity)))
  invisible(TRUE)
}
