# Tests for fetch_finance() — the canonical cross-state finance schema.

# canonical columns from docs/FINANCE-DATA-SPEC.md, in order
finance_cols <- c(
  "end_year", "state_id", "entity_name", "county",
  "is_state", "is_district", "is_school", "is_charter",
  "nces_dist", "nces_sch",
  "metric", "value", "is_per_pupil", "enrollment_denominator"
)

finance_cols_with_status <- c(finance_cols, "value_status")

# standard + NJ-specific metric vocabulary this package emits
finance_metrics <- c(
  "per_pupil_total", "per_pupil_instruction", "per_pupil_support_services",
  "per_pupil_administration", "per_pupil_operations_maintenance",
  "per_pupil_food_service", "revenue_state"
)

# fetch one year once and reuse; skip the whole block if the NJ DOE site is down.
# suppressWarnings: get_raw_state_aid logs a benign download.file 404 when it
# falls back from the direct workbook URL to the archived zip.
fin <- tryCatch(suppressWarnings(fetch_finance(2024)), error = function(e) NULL)
have_data <- !is.null(fin) && nrow(fin) > 0


test_that("get_available_finance_years returns a sane integer range", {
  yrs <- get_available_finance_years()
  expect_true(is.numeric(yrs))
  expect_true(all(yrs == as.integer(yrs)))
  expect_true(2024 %in% yrs)
  expect_true(min(yrs) >= 2001)
})

test_that("an unavailable year returns the empty, correctly-typed tidy frame", {
  e <- empty_finance_frame()
  expect_equal(names(e), finance_cols)
  expect_equal(nrow(e), 0L)
  expect_type(e$value, "double")
  expect_type(e$state_id, "character")
  expect_type(e$is_state, "logical")
})

test_that("finance metric registry rows match the finance contract", {
  registry <- load_metric_registry()
  rows <- registry[registry$metric %in% finance_metrics, , drop = FALSE]

  expect_equal(nrow(rows), length(finance_metrics))
  expect_equal(sort(rows$metric), sort(finance_metrics))
  expect_true(all(rows$domain == "finance"))
  expect_true(all(rows$unit == "dollars"))
  expect_true(all(rows$polarity == "neutral"))
  expect_true(all(!rows$is_rate))
  expect_true(all(is.na(rows$denominator_metric) | rows$denominator_metric == ""))
})

test_that("finance FY/SY alignment assertion fails loudly on off-by-one rows", {
  spending <- tibble::tibble(end_year = 2024L, metric = "per_pupil_total")
  revenue <- tibble::tibble(end_year = 2024L, metric = "revenue_state")

  expect_invisible(assert_finance_year_alignment(
    spending, revenue, end_year = 2024L, tges_report_year = 2025L
  ))

  expect_error(
    assert_finance_year_alignment(
      spending, revenue, end_year = 2024L, tges_report_year = 2024L
    ),
    "following year"
  )
  expect_error(
    assert_finance_year_alignment(
      spending, revenue, end_year = 2024L, tges_report_year = 2026L
    ),
    "following year"
  )
  expect_error(
    assert_finance_year_alignment(
      tibble::tibble(end_year = 2023L, metric = "per_pupil_total"),
      revenue,
      end_year = 2024L,
      tges_report_year = 2025L
    ),
    "spending"
  )
  expect_error(
    assert_finance_year_alignment(
      spending,
      tibble::tibble(end_year = 2025L, metric = "revenue_state"),
      end_year = 2024L,
      tges_report_year = 2025L
    ),
    "state aid"
  )
})

test_that("fetch_finance emits exactly the canonical columns in order", {
  skip_if_not(have_data, "NJ DOE finance source unavailable")
  expect_equal(names(fin), finance_cols)
})

test_that("with_status is additive and preserves the default finance columns", {
  skip_if_not(have_data, "NJ DOE finance source unavailable")

  fin_status <- tryCatch(
    suppressWarnings(fetch_finance(2024, with_status = TRUE)),
    error = function(e) NULL
  )
  skip_if(is.null(fin_status) || nrow(fin_status) == 0, "NJ DOE finance source unavailable")

  expect_equal(names(fin_status), finance_cols_with_status)
  expect_equal(fin_status[, finance_cols], fin)
})

test_that("metrics conform to the documented vocabulary", {
  skip_if_not(have_data, "NJ DOE finance source unavailable")
  expect_true(all(unique(fin$metric) %in% finance_metrics))
  # the two standard cross-state names must be present for 2024
  expect_true("per_pupil_total" %in% fin$metric)
  expect_true("revenue_state" %in% fin$metric)
})

test_that("values are non-negative and finite (NAs allowed for suppressed)", {
  skip_if_not(have_data, "NJ DOE finance source unavailable")
  v <- fin$value[!is.na(fin$value)]
  expect_true(all(is.finite(v)))
  expect_true(all(v >= 0))
})

test_that("per-pupil flag matches the metric family", {
  skip_if_not(have_data, "NJ DOE finance source unavailable")
  pp <- fin[grepl("^per_pupil_", fin$metric), ]
  rev <- fin[grepl("^revenue_", fin$metric), ]
  expect_true(all(pp$is_per_pupil))
  expect_true(all(!rev$is_per_pupil))
})

test_that("there is a statewide aggregate row and it is positive", {
  skip_if_not(have_data, "NJ DOE finance source unavailable")
  st <- fin[fin$is_state & fin$metric == "per_pupil_total", ]
  expect_equal(nrow(st), 1L)
  expect_true(st$value > 0)
  # statewide per-pupil total should be a plausible NJ figure (>$10k, <$60k)
  expect_true(st$value > 10000 && st$value < 60000)
})

test_that("one observation per district per metric (no duplication)", {
  skip_if_not(have_data, "NJ DOE finance source unavailable")
  d <- fin[fin$is_district, ]
  counts <- stats::aggregate(value ~ state_id + metric, data = d, FUN = length)
  expect_equal(sum(counts$value > 1), 0L)
})

test_that("entity flags are mutually consistent", {
  skip_if_not(have_data, "NJ DOE finance source unavailable")
  expect_true(all(xor(fin$is_state, fin$is_district)))
  expect_true(all(!fin$is_school))
})

test_that("school-level finance requests return a structural not-published gap", {
  school_gap <- fetch_finance(2024, level = "school", with_status = TRUE)

  expect_equal(names(school_gap), finance_cols_with_status)
  expect_equal(nrow(school_gap), length(finance_metrics))
  expect_equal(sort(school_gap$metric), sort(finance_metrics))
  expect_true(all(is.na(school_gap$value)))
  expect_true(all(!school_gap$is_state))
  expect_true(all(!school_gap$is_district))
  expect_true(all(!school_gap$is_school))
  expect_true(all(as.character(school_gap$value_status) == "not_published"))
})

test_that("nces_dist is attached to most districts and never fabricated for state rows", {
  skip_if_not(have_data, "NJ DOE finance source unavailable")
  # state aggregate rows must not carry a district NCES id
  expect_true(all(is.na(fin$nces_dist[fin$is_state])))
  # nces_sch is always NA (NJ finance is district-level only)
  expect_true(all(is.na(fin$nces_sch)))
  d <- fin[fin$is_district & fin$metric == "per_pupil_total", ]
  match_rate <- mean(!is.na(d$nces_dist))
  expect_true(match_rate > 0.85)
})

test_that("per_pupil_total carries an enrollment denominator for districts", {
  skip_if_not(have_data, "NJ DOE finance source unavailable")
  d <- fin[fin$is_district & fin$metric == "per_pupil_total", ]
  expect_true(mean(!is.na(d$enrollment_denominator)) > 0.85)
})

test_that("real per-pupil values above $100k pass through with raw fidelity", {
  skip_if_not(have_data, "NJ DOE finance source unavailable")
  # County special-services districts genuinely spend more than $100k per pupil.
  # These were formerly NA-ed by a blunt magnitude cap; the canonical front door
  # now passes them through unchanged so the value matches the published source.
  pp <- fin[fin$is_per_pupil & !is.na(fin$value), ]
  expect_true(any(pp$value > 100000))

  bergen <- fin$value[which(fin$state_id == "0285" &
                              fin$metric == "per_pupil_total")]
  expect_true(length(bergen) == 1 && bergen > 100000)

  tg <- tryCatch(suppressWarnings(fetch_tges(2025)), error = function(e) NULL)
  skip_if(is.null(tg), "TGES source unavailable")
  aa <- tg[["CSG1AA_AVGS"]]
  raw <- aa[which(aa$end_year == 2024 & aa$calc_type == "Actuals" &
                    aa$district_id == "0285"), "Per Pupil Total Expenditures",
            drop = TRUE]
  expect_equal(as.numeric(bergen), as.numeric(raw[1]))
})

test_that("zero/blank per-pupil denominators are still NA-ed", {
  f11 <- tryCatch(suppressWarnings(fetch_finance(2011)), error = function(e) NULL)
  skip_if(is.null(f11) || nrow(f11) == 0, "NJ DOE finance source unavailable")
  bad_denoms <- f11[f11$is_per_pupil & !is.na(f11$enrollment_denominator) &
                      f11$enrollment_denominator <= 0, ]
  expect_equal(nrow(bad_denoms), 0L)
})

test_that("fetch_finance_multi accepts the cross-state end_years alias", {
  f <- tryCatch(
    suppressWarnings(fetch_finance_multi(end_years = c(2024, 2025))),
    error = function(e) NULL
  )
  skip_if(is.null(f) || nrow(f) == 0, "NJ DOE finance source unavailable")
  expect_true(all(c(2024, 2025) %in% unique(f$end_year)))
  expect_equal(names(f), finance_cols)
})

test_that("tidy values match the raw TGES source (fidelity)", {
  skip_if_not(have_data, "NJ DOE finance source unavailable")
  tg <- tryCatch(suppressWarnings(fetch_tges(2025)), error = function(e) NULL)
  skip_if(is.null(tg), "TGES source unavailable")
  aa <- tg[["CSG1AA_AVGS"]]
  raw <- aa[which(aa$end_year == 2024 & aa$calc_type == "Actuals" &
                    aa$district_id == "3570"), "Per Pupil Total Expenditures",
            drop = TRUE]
  fin_val <- fin$value[which(fin$state_id == "3570" &
                               fin$metric == "per_pupil_total")]
  expect_equal(as.numeric(fin_val), as.numeric(raw[1]))
})

test_that("a revenue-only recent year emits revenue_state and no spending", {
  f25 <- tryCatch(suppressWarnings(fetch_finance(2025)), error = function(e) NULL)
  skip_if(is.null(f25) || nrow(f25) == 0, "state aid source unavailable")
  expect_true(all(f25$metric == "revenue_state"))
  expect_equal(names(f25), finance_cols)
})

test_that("with_status marks current-year per-pupil actuals as not yet observed", {
  f25 <- tryCatch(
    suppressWarnings(fetch_finance(2025, with_status = TRUE)),
    error = function(e) NULL
  )
  skip_if(is.null(f25) || nrow(f25) == 0, "state aid source unavailable")

  pp <- f25[grepl("^per_pupil_", f25$metric), , drop = FALSE]
  rev <- f25[f25$metric == "revenue_state", , drop = FALSE]

  expect_gt(nrow(pp), 0)
  expect_true(all(is.na(pp$value)))
  expect_true(all(as.character(pp$value_status) == "not_yet_observed"))
  expect_true(all(as.character(rev$value_status) == "actual"))
  expect_equal(names(f25), finance_cols_with_status)
})
