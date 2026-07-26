test_that("source results expose a stable provenance contract", {
  result <- new_source_result(
    data = data.frame(value = 1),
    source_status = "actual",
    source_url = "https://www.nj.gov/example.csv",
    retrieved_at = as.POSIXct("2026-07-20 12:00:00", tz = "UTC"),
    digest = "abc123"
  )

  expect_s3_class(result, "njsd_source_result")
  expect_identical(result$source_status, "actual")
  expect_identical(source_result_data(result), result$data)

  status <- source_result_record(result, domain = "example", end_year = 2025)
  expect_named(status, c(
    "domain", "end_year", "component", "source_status", "source_url",
    "retrieved_at", "digest", "warning", "error"
  ))
  expect_identical(status$source_status, "actual")
})

test_that("source results distinguish publication, outage, and parser failures", {
  statuses <- c(
    "actual", "not_published", "not_yet_observed",
    "source_unavailable", "parse_error"
  )

  for (status in statuses) {
    result <- new_source_result(
      source_status = status,
      source_url = "https://www.nj.gov/example.xlsx",
      error = if (status %in% c("source_unavailable", "parse_error")) "boom" else NULL
    )
    expect_identical(result$source_status, status)
  }

  expect_error(
    new_source_result(source_status = "suppressed"),
    "source_status"
  )
})

test_that("strict source extraction raises typed actionable conditions", {
  unavailable <- new_source_result(
    source_status = "source_unavailable",
    source_url = "https://www.nj.gov/missing.xlsx",
    error = "HTTP 503 after 3 attempts"
  )
  parse_failure <- new_source_result(
    source_status = "parse_error",
    source_url = "https://www.nj.gov/bad.xlsx",
    error = "invalid workbook"
  )

  expect_error(source_result_data(unavailable), class = "njsd_source_unavailable")
  expect_error(source_result_data(parse_failure), class = "njsd_parse_error")
  expect_error(
    source_result_data(new_source_result(source_status = "not_published")),
    class = "njsd_not_published"
  )
})

test_that("data objects retain source results without using value_status", {
  result <- new_source_result(
    data = tibble::tibble(value = 10),
    source_status = "actual",
    source_url = "https://www.nj.gov/example.csv"
  )
  out <- attach_source_results(result$data, list(result))
  records <- get_source_results(out)

  expect_s3_class(records, "data.frame")
  expect_identical(records$source_status, "actual")
  expect_false("value_status" %in% names(records))
})

test_that("multi-source composition reports every success and failure", {
  success <- capture_source_call(
    function() tibble::tibble(end_year = 2024L, value = 1),
    "example", 2024L
  )
  unavailable <- capture_source_call(
    function() source_result_data(new_source_result(
      source_status = "source_unavailable", error = "HTTP 503"
    )),
    "example", 2025L
  )
  parse_failure <- capture_source_call(
    function() source_result_data(new_source_result(
      source_status = "parse_error", error = "schema changed"
    )),
    "example", 2026L
  )

  expect_error(
    combine_source_captures(
      list(success, unavailable, parse_failure), context = "example request"
    ),
    "2025.*source_unavailable.*2026.*parse_error",
    class = "njsd_parse_error"
  )

  partial <- combine_source_captures(
    list(success, unavailable, parse_failure), allow_partial = TRUE
  )
  expect_equal(nrow(partial), 1L)
  expect_identical(
    get_source_results(partial)$source_status,
    c("actual", "source_unavailable", "parse_error")
  )
})

test_that("structural gaps distinguish publication from future observation", {
  not_published <- source_gap_capture(
    "example", 2020L, source_status = "not_published"
  )
  future <- source_gap_capture(
    "example", 2027L, source_status = "not_yet_observed"
  )
  out <- combine_source_captures(
    list(not_published, future), allow_partial = TRUE
  )
  expect_identical(
    get_source_results(out)$source_status,
    c("not_published", "not_yet_observed")
  )
})

test_that("shared condition and record helpers preserve the most specific status", {
  not_published <- tryCatch(
    source_result_data(new_source_result(source_status = "not_published")),
    error = identity
  )
  expect_identical(
    source_status_from_condition(not_published),
    "not_published"
  )
  expect_identical(
    source_status_from_condition(simpleError("HTTP 503")),
    "source_unavailable"
  )

  value <- attach_source_results(
    data.frame(value = 1),
    rbind(
      source_result_record(new_source_result(source_status = "actual")),
      source_result_record(new_source_result(source_status = "parse_error"))
    )
  )
  expect_identical(
    select_source_result_record(value)$source_status,
    "parse_error"
  )
})

test_that("composition preserves source-result objects returned directly", {
  result <- new_source_result(
    source_status = "not_published",
    source_url = "https://www.nj.gov/example.xlsx"
  )
  capture <- capture_source_call(function() result, "example", 2020)

  expect_null(capture$data)
  expect_identical(capture$records$source_status, "not_published")
  expect_identical(
    select_source_result_record(result)$source_status,
    "not_published"
  )
})

test_that("post-download transformations preserve provenance on parse errors", {
  result <- new_source_result(
    data = data.frame(value = 1), source_status = "actual",
    source_url = "https://www.nj.gov/example.xlsx",
    retrieved_at = as.POSIXct("2026-07-20", tz = "UTC"), digest = "abc"
  )
  transformed <- transform_source_result(
    result, function(data) stop("schema changed")
  )

  expect_identical(transformed$source_status, "parse_error")
  expect_identical(transformed$source_url, result$source_url)
  expect_identical(transformed$digest, "abc")
  expect_match(transformed$error, "schema changed")
})

test_that("NJGPA post-download schema failures are typed parse errors", {
  raw <- new_source_result(
    data = data.frame(value = 1), source_status = "actual",
    source_url = "https://www.nj.gov/example/njgpa.xlsx"
  )
  local_mocked_bindings(
    get_raw_njgpa_result = function(...) raw,
    process_parcc = function(...) stop("NJGPA schema changed"),
    .package = "njschooldata"
  )

  error <- tryCatch(fetch_njgpa(2025, "ela"), error = identity)
  expect_s3_class(error, "njsd_parse_error")
  expect_match(conditionMessage(error), "NJGPA schema changed")
})

test_that("report-card multi-year requests expose every year status", {
  success <- attach_source_results(
    list(sheet = data.frame(value = 1)),
    source_result_record(
      new_source_result(source_status = "actual"), "report_card", 2018
    )
  )
  local_mocked_bindings(
    get_one_rc_database = function(end_year) {
      if (end_year == 2019) {
        source_result_data(new_source_result(
          source_status = "parse_error", error = "schema changed"
        ))
      }
      success
    },
    .package = "njschooldata"
  )

  expect_error(
    suppressMessages(get_rc_databases(2018:2019)),
    "2019.*parse_error",
    class = "njsd_parse_error"
  )
  partial <- suppressMessages(get_rc_databases(2018:2019, allow_partial = TRUE))
  expect_named(partial, "2018")
  expect_identical(
    get_source_results(partial)$source_status,
    c("actual", "parse_error")
  )
})
