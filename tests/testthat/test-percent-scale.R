# Source-row donors and provenance: fixtures/percent-scale and
# docs/percent-scale-evidence.md. Altered rates below are parser boundary probes,
# never published observations.
grad_scale_donor <- function(year) {
  read.csv(testthat::test_path("fixtures", "percent-scale",
                              paste0("graduation-", year, ".csv")),
           check.names = FALSE, colClasses = "character")
}

test_that("four-year conversion follows workbook units even on small slices", {
  raw <- grad_scale_donor(2025)
  raw[["Adjusted Cohort Graduation Rate"]] <- "0.7"
  expect_equal(njschooldata:::process_grate(raw, 2025)$grad_rate, 0.007)
  raw[["Adjusted Cohort Graduation Rate"]] <- "100.1"
  expect_true(is.na(njschooldata:::process_grate(raw, 2025)$grad_rate))
  expect_error(njschooldata:::process_grate(raw, 2026), "Unknown graduation rate scale")

  raw <- grad_scale_donor(2011)
  expect_equal(njschooldata:::process_grate(raw, 2011)$grad_rate, 0.8317)
  raw[["2011 Adjusted Cohort Grad Rate"]] <- "0.004"
  expect_equal(njschooldata:::process_grate(raw, 2011)$grad_rate, 0.004)
  raw[["2011 Adjusted Cohort Grad Rate"]] <- "1.01"
  expect_true(is.na(njschooldata:::process_grate(raw, 2011)$grad_rate))
})

test_that("both dual-cohort conversion branches preserve small percentages", {
  raw <- grad_scale_donor(2013)
  raw$FIVE_YR_GRAD_RATE <- "0.7"
  processed <- njschooldata:::process_grate(raw, 2013)
  for (method in c("4 year", "5 year")) {
    out <- njschooldata:::process_grad_rate(processed, 2013, method)
    rate <- if (method == "5 year") out$grad_rate else out$five_yr_grad_rate
    expect_equal(rate, 0.007)
    expect_error(njschooldata:::process_grad_rate(processed, 2026, method),
                 "Unknown graduation rate scale")
  }
  raw$FIVE_YR_GRAD_RATE <- "100.1"
  processed <- njschooldata:::process_grate(raw, 2013)
  expect_true(is.na(njschooldata:::process_grad_rate(processed, 2013, "5 year")$grad_rate))
  expect_true(is.na(njschooldata:::process_grad_rate(processed, 2013, "4 year")$five_yr_grad_rate))
})

retention_scale_probe <- function(retention, turnover) {
  list("2025" = data.frame(county_id = "80", district_id = "7325",
                            retention_rate = retention, turnover_rate = turnover))
}

test_that("retention analysis treats small caller-supplied percentages as percentages", {
  out <- analyze_retention_patterns(retention_scale_probe(0.7, 0.4), by_subgroup = FALSE)
  expect_equal(out$retention_rate, 0.7)
  expect_equal(out$turnover_rate, 0.4)
  expect_equal(out$stability_index, (0.7 + 100 - 0.4) / 2)
})

test_that("fractional retention inputs require declared units and unknown units stop", {
  out <- analyze_retention_patterns(retention_scale_probe(0.004, 0.007),
                                    by_subgroup = FALSE, rate_scale = "fraction")
  expect_equal(out$retention_rate, 0.4)
  expect_equal(out$turnover_rate, 0.7)
  expect_error(analyze_retention_patterns(retention_scale_probe(0.7, 0.4),
                                          rate_scale = "unknown"), "arg")
})

test_that("retention values outside declared units remain missing", {
  for (scale in c("percent", "fraction")) {
    out <- analyze_retention_patterns(retention_scale_probe(101, 102),
                                      by_subgroup = FALSE, rate_scale = scale)
    expect_true(is.na(out$retention_rate))
    expect_true(is.na(out$turnover_rate))
    expect_true(is.na(out$stability_index))
  }
})
