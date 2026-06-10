# Tests for fetch_finance() — the canonical cross-state finance schema.

# canonical columns from docs/FINANCE-DATA-SPEC.md, in order
finance_cols <- c(
  "end_year", "state_id", "entity_name", "county",
  "is_state", "is_district", "is_school", "is_charter",
  "nces_dist", "nces_sch",
  "metric", "value", "is_per_pupil", "enrollment_denominator"
)

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

test_that("fetch_finance emits exactly the canonical columns in order", {
  skip_if_not(have_data, "NJ DOE finance source unavailable")
  expect_equal(names(fin), finance_cols)
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
