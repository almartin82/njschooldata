# Canonical tests for the vendored multi-year frame driver (R/multi_year.R).
# Vendored byte-for-byte as tests/testthat/test-partial-frame-canonical.R; edit
# ONLY contracts/partial-frame/v1/test-partial-frame-canonical.R, then run
# scripts/partial-frame/sync.py. No network, no package data: every year below
# is served by a stub. A package's own partial-frame tests stay beside this one.
#
# Errors are asserted on the FIRST class a caller's tryCatch() sees, never with
# expect_error(class = ), which walks `$parent` and passes against a purrr
# wrapper (docs/PARTIAL-FRAME-CONTRACT.md).

mfc_source_failure <- function(year) {
  errorCondition(paste("source down for", year),
                 class = c("mfcpkg_acquisition_error", "transport_acquisition_error"))
}
mfc_droppable <- function(e) inherits(e, "mfcpkg_acquisition_error")
mfc_frame <- function(year) data.frame(end_year = year, n = year - 2000L)
mfc_catch <- function(expr) tryCatch(expr, error = identity)
mfc_run <- function(years, fetch_one = mfc_frame, allow_partial = FALSE,
                    available = NULL, ...) {
  multi_year_frame(years, fetch_one, allow_partial, mfc_droppable,
                   family = "widgets", prefix = "mfcpkg",
                   available = available, ...)
}

test_that("a complete request binds every year and declares nothing missing", {
  out <- expect_silent(mfc_run(c(2023, 2024)))
  expect_identical(out$end_year, c(2023, 2024))
  expect_identical(attr(out, "requested_years"), c(2023L, 2024L))
  expect_identical(attr(out, "missing_years"), integer(0))
})

test_that("a classified source failure stops by default, class intact", {
  fetch <- function(y) if (y == 2024) stop(mfc_source_failure(y)) else mfc_frame(y)
  caught <- mfc_catch(mfc_run(c(2023, 2024, 2025), fetch))
  expect_identical(class(caught)[[1]], "mfcpkg_acquisition_error")
})

test_that("under allow_partial a classified failure is dropped, warned and recorded", {
  fetch <- function(y) if (y == 2024) stop(mfc_source_failure(y)) else mfc_frame(y)
  expect_warning(out <- mfc_run(c(2023, 2024, 2025), fetch, allow_partial = TRUE),
                 "Could not fetch widgets for year 2024: source down for 2024")
  expect_identical(out$end_year, c(2023, 2025))
  expect_identical(attr(out, "requested_years"), c(2023L, 2024L, 2025L))
  expect_identical(attr(out, "missing_years"), 2024L)
})

test_that("an unclassified error is never dropped, even under allow_partial", {
  parse <- errorCondition("our parser broke", class = "mfcpkg_parse_error")
  fetch <- function(y) if (y == 2024) stop(parse) else mfc_frame(y)
  caught <- mfc_catch(mfc_run(c(2023, 2024), fetch, allow_partial = TRUE))
  expect_identical(caught, parse)
  plain <- function(y) if (y == 2024) stop("typo in our code") else mfc_frame(y)
  caught <- mfc_catch(mfc_run(c(2023, 2024), plain, allow_partial = TRUE))
  expect_identical(class(caught)[[1]], "simpleError")
  expect_identical(conditionMessage(caught), "typo in our code")
})

test_that("a droppable test that does not answer TRUE or FALSE stops loudly", {
  fetch <- function(y) stop(mfc_source_failure(y))
  caught <- mfc_catch(multi_year_frame(2024, fetch, TRUE, function(e) NA,
                                       "widgets", "mfcpkg"))
  expect_match(conditionMessage(caught), "must return TRUE or FALSE")
})

test_that("a 0-row year stops in both modes and names the year", {
  fetch <- function(y) if (y == 2024) mfc_frame(y)[0, ] else mfc_frame(y)
  for (partial in c(FALSE, TRUE)) {
    caught <- mfc_catch(mfc_run(c(2023, 2024, 2025), fetch, allow_partial = partial))
    expect_identical(class(caught)[[1]], "mfcpkg_empty_year_error")
    expect_s3_class(caught, "multi_year_empty_year_error")
    expect_identical(caught$years, "2024")
    expect_match(conditionMessage(caught), "widgets returned no rows for requested year\\(s\\) 2024")
  }
})

test_that("package classes ride on the 0-row stop after the canonical class", {
  fetch <- function(y) mfc_frame(y)[0, ]
  caught <- mfc_catch(mfc_run(2024, fetch, empty_class = "mfcpkg_source_error"))
  expect_identical(class(caught)[1:2], c("mfcpkg_empty_year_error", "mfcpkg_source_error"))
})

test_that("the prefilter stops by default, with the family's own refusal when given", {
  caught <- mfc_catch(mfc_run(c(2023, 2024), available = 2023))
  expect_identical(class(caught)[[1]], "mfcpkg_unavailable_year_error")
  expect_identical(caught$years, 2024L)
  caught <- mfc_catch(mfc_run(c(2023, 2024), available = 2023, refusal = "no 2024 here"))
  expect_identical(conditionMessage(caught), "no 2024 here")
  caught <- mfc_catch(mfc_run(c(2023, 2024), available = 2023,
                              refusal = function(gaps) paste("gaps:", gaps)))
  expect_identical(conditionMessage(caught), "gaps: 2024")
})

test_that("under allow_partial the prefilter warns, names and records the gap", {
  attempted <- integer(0)
  fetch <- function(y) { attempted <<- c(attempted, y); mfc_frame(y) }
  expect_warning(out <- mfc_run(c(2023, 2024, 2025), fetch, allow_partial = TRUE,
                                available = c(2023, 2025)),
                 "widgets years not available and omitted: 2024")
  expect_identical(attempted, c(2023, 2025))
  expect_identical(attr(out, "missing_years"), 2024L)
  expect_identical(attr(out, "requested_years"), c(2023L, 2024L, 2025L))
})

test_that("every year a declared gap: empty frame under allow_partial, stop by default", {
  expect_warning(out <- mfc_run(c(2020, 2021), allow_partial = TRUE, available = 2023),
                 "omitted: 2020, 2021")
  expect_true(is.data.frame(out))
  expect_identical(nrow(out), 0L)
  expect_identical(attr(out, "requested_years"), c(2020L, 2021L))
  expect_identical(attr(out, "missing_years"), c(2020L, 2021L))
  rbinder <- function(parts) do.call(rbind, parts)
  expect_warning(out <- mfc_run(2020, allow_partial = TRUE, available = 2023,
                                combine = rbinder))
  expect_true(is.data.frame(out))
  expect_identical(attr(out, "missing_years"), 2020L)
  caught <- mfc_catch(mfc_run(c(2020, 2021), available = 2023))
  expect_identical(class(caught)[[1]], "mfcpkg_unavailable_year_error")
})

test_that("nothing served after a source failure stops, even with a declared gap", {
  fetch <- function(y) stop(mfc_source_failure(y))
  caught <- mfc_catch(suppressWarnings(
    mfc_run(c(2023, 2024), fetch, allow_partial = TRUE, available = 2024)))
  expect_identical(class(caught)[[1]], "mfcpkg_no_year_served_error")
  expect_identical(conditionMessage(caught),
                   "No widgets data could be fetched for any requested year")
  caught <- mfc_catch(suppressWarnings(
    mfc_run(2024, fetch, allow_partial = TRUE, none_message = "nothing at all")))
  expect_identical(conditionMessage(caught), "nothing at all")
})

test_that("an empty request with no gap stops rather than returning a blank frame", {
  caught <- mfc_catch(mfc_run(integer(0)))
  expect_identical(class(caught)[[1]], "mfcpkg_no_year_served_error")
})

test_that("the declaration is integer and attached last, whatever combine does", {
  out <- mfc_run(c(2023, 2024), combine = function(parts) {
    x <- do.call(rbind, parts)
    attr(x, "missing_years") <- "stale"
    x[, c("end_year", "n")]
  })
  expect_identical(attr(out, "missing_years"), integer(0))
  expect_type(attr(out, "requested_years"), "integer")
  out <- multi_year_declare(data.frame(), c(2025, 2023, 2024), c(2024, 2025))
  expect_identical(attr(out, "missing_years"), c(2025L, 2024L))
})

test_that("a missing() override replaces the declared-missing arithmetic", {
  out <- mfc_run(c(2023, 2024), missing = function(gaps, years, dropped) 2023)
  expect_identical(attr(out, "missing_years"), 2023L)
})

test_that("a purrr-style wrapper is not looked through unless droppable does it", {
  inner <- mfc_source_failure(2024)
  wrapped <- structure(list(message = "In index: 1.", call = NULL, parent = inner),
                       class = c("purrr_error_indexed", "rlang_error", "error", "condition"))
  fetch <- function(y) stop(wrapped)
  caught <- mfc_catch(mfc_run(2024, fetch, allow_partial = TRUE))
  expect_identical(class(caught)[[1]], "purrr_error_indexed")
})

test_that("the per-item loop serves items in order and reports progress", {
  said <- character()
  fetched <- withCallingHandlers(
    multi_year_fetch(list(c(2023, 3), c(2023, 4)),
                     function(it) mfc_frame(it[[1]]), FALSE,
                     mfc_droppable, "STAAR", "mfcpkg",
                     progress = function(it) paste("grade", it[[2]])),
    message = function(m) {
      said <<- c(said, conditionMessage(m))
      invokeRestart("muffleMessage")
    })
  expect_identical(said, c("grade 3\n", "grade 4\n"))
  expect_identical(fetched$dropped, c(FALSE, FALSE))
  expect_length(fetched$results, 2L)
  caught <- mfc_catch(multi_year_fetch(list(c(2023, 3)), function(it) mfc_frame(2023)[0, ],
                                       FALSE, mfc_droppable, "STAAR", "mfcpkg"))
  expect_identical(caught$years, "2023 3")
})

test_that("a custom drop message and a non-function droppable", {
  fetch <- function(y) stop(mfc_source_failure(y))
  seen <- character()
  fetched <- withCallingHandlers(
    multi_year_fetch(c(2023, 2024), fetch, TRUE, mfc_droppable, "widgets",
                     "mfcpkg", drop_message = function(y, e) paste("lost", y)),
    warning = function(w) {
      seen <<- c(seen, conditionMessage(w))
      invokeRestart("muffleWarning")
    })
  expect_identical(seen, c("lost 2023", "lost 2024"))
  expect_identical(fetched$dropped, c(TRUE, TRUE))
  caught <- mfc_catch(multi_year_fetch(2024, fetch, TRUE, TRUE, "widgets", "mfcpkg"))
  expect_match(conditionMessage(caught), "`droppable` must be a function")
  caught <- mfc_catch(multi_year_fetch(2024, fetch, TRUE, mfc_droppable, "w", "bad prefix"))
  expect_match(conditionMessage(caught), "`prefix` must be one package prefix")
})
