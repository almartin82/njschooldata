finance_component_rows <- function(end_year, metric) {
  tibble::tibble(
    end_year = as.integer(end_year),
    state_id = "0010",
    entity_name = "Observed district",
    county = "ATLANTIC",
    is_state = FALSE,
    is_district = TRUE,
    is_school = FALSE,
    is_charter = FALSE,
    metric = metric,
    value = 100,
    is_per_pupil = startsWith(metric, "per_pupil_"),
    enrollment_denominator = if (startsWith(metric, "per_pupil_")) 50 else NA_real_
  )
}

finance_result <- function(status = "actual", component = "spending",
                           end_year = 2024L) {
  metric <- if (component == "spending") "per_pupil_total" else "revenue_state"
  new_source_result(
    data = if (status == "actual") finance_component_rows(end_year, metric) else NULL,
    source_status = status,
    source_url = paste0("https://www.nj.gov/", component, ".xlsx"),
    retrieved_at = as.POSIXct("2026-07-20", tz = "UTC"),
    error = if (status %in% c("source_unavailable", "parse_error")) "fixture failure" else NULL
  )
}

mock_finance_components <- function(spending, revenue) {
  local_mocked_bindings(
    get_finance_spending_result = function(end_year) spending,
    get_finance_revenue_result = function(end_year) revenue,
    .package = "njschooldata",
    .env = parent.frame()
  )
}

test_that("finance is complete only when both required sources succeed", {
  mock_finance_components(finance_result(), finance_result(component = "state_aid"))
  out <- fetch_finance(2024, use_cache = FALSE)
  expect_setequal(out$metric, c("per_pupil_total", "revenue_state"))
  expect_equal(get_source_results(out)$source_status, c("actual", "actual"))
})

test_that("one-source outage is strict unless partial mode is explicit", {
  mock_finance_components(
    finance_result("source_unavailable"),
    finance_result(component = "state_aid")
  )
  expect_error(fetch_finance(2024), class = "njsd_source_unavailable")

  partial <- fetch_finance(2024, allow_partial = TRUE)
  expect_identical(unique(partial$metric), "revenue_state")
  expect_equal(
    get_source_results(partial)$source_status,
    c("source_unavailable", "actual")
  )
})

test_that("parse failures remain distinct from source outages", {
  mock_finance_components(
    finance_result("parse_error"),
    finance_result(component = "state_aid")
  )
  expect_error(fetch_finance(2024), class = "njsd_parse_error")
})

test_that("structural non-publication is not treated as a request failure", {
  mock_finance_components(
    finance_result("not_yet_observed"),
    finance_result(component = "state_aid", end_year = 2025)
  )
  out <- fetch_finance(2025)
  expect_identical(unique(out$metric), "revenue_state")
  expect_equal(
    get_source_results(out)$source_status,
    c("not_yet_observed", "actual")
  )
})

test_that("all-source failure cannot look like a complete empty response", {
  mock_finance_components(
    finance_result("source_unavailable"),
    finance_result("parse_error", component = "state_aid")
  )
  expect_error(fetch_finance(2024), class = "njsd_source_unavailable")

  partial <- fetch_finance(2024, allow_partial = TRUE)
  expect_equal(nrow(partial), 0L)
  expect_equal(
    get_source_results(partial)$source_status,
    c("source_unavailable", "parse_error")
  )
})

test_that("finance registry boundaries are strict unless partial is explicit", {
  expect_error(fetch_finance(2000), class = "njsd_not_published")
  expect_error(fetch_finance(2027), class = "njsd_not_yet_observed")

  partial <- fetch_finance(2027, allow_partial = TRUE)
  expect_equal(nrow(partial), 0L)
  expect_identical(
    get_source_results(partial)$source_status,
    "not_yet_observed"
  )
})
