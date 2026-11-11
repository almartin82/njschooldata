# Multi-year composition: a short frame never arrives
# without a warning and the requested_years / missing_years attributes, and a
# strict failure keeps the underlying error text so a defect of ours is never
# reduced to a bare status that reads as an NJ DOE outage.

test_that("an allow_partial drop warns and records requested and missing years", {
  ok <- capture_source_call(function() tibble::tibble(end_year = 2024L, v = 1), "example", 2024L)
  gone <- capture_source_call(
    function() source_result_data(new_source_result(
      source_status = "source_unavailable", error = "HTTP 503"
    )),
    "example", 2025L
  )
  expect_warning(
    out <- combine_source_captures(list(ok, gone), allow_partial = TRUE,
                                   context = "example request"),
    "example request returned partial data; missing: 2025 \\[source_unavailable\\]",
    class = "njsd_partial_result"
  )
  expect_identical(nrow(out), 1L)
  expect_identical(attr(out, "requested_years"), c(2024L, 2025L))
  expect_identical(attr(out, "missing_years"), 2025L)

  expect_no_warning(full <- combine_source_captures(list(ok)))
  expect_identical(attr(full, "requested_years"), 2024L)
  expect_identical(attr(full, "missing_years"), integer(0))
})

test_that("a defect of ours is re-raised as itself, never labelled an outage", {
  # STANDARD M4 / Q4: it used to be captured as `source_unavailable` and only
  # its message survived; now the original condition propagates unchanged.
  caught <- tryCatch(
    capture_source_call(function() stop("object 'cohort' not found"), "example", 2019L),
    error = identity
  )
  expect_identical(class(caught)[[1]], "simpleError")
  expect_identical(conditionMessage(caught), "object 'cohort' not found")
})

test_that("a strict failure carries each source failure's own message", {
  gone <- capture_source_call(
    function() source_result_data(new_source_result(
      source_status = "source_unavailable", error = "HTTP 503 from nj.gov"
    )),
    "example", 2019L
  )
  expect_error(
    combine_source_captures(list(gone), context = "example request"),
    "2019 \\[source_unavailable: HTTP 503 from nj.gov\\]"
  )
})
