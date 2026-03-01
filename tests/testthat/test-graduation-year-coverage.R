# ==============================================================================
# Graduation Year Coverage Tests
# ==============================================================================
#
# Exhaustive per-year tests for NJ graduation data (fetch_grad_rate and
# fetch_grad_count). 4-year graduation rates available 2011-2024 (though
# 2011 is rate-only, no subgroups). Graduation counts available 2012-2024.
#
# Pinned values verified against NJ DOE graduation files at:
# https://www.nj.gov/education/schoolperformance/grad/
#
# ==============================================================================

# -- 4-Year Graduation Rate: pinned state values per year ----------------------

grate_4yr_pins <- list(
  # Pinned: state graduation rate for total population/total subgroup
  # Source: NJ DOE ACGR files
  # Note: 2012-2019 use subgroup="total population", 2020+ use subgroup="total"
  list(year = 2012, state_rate = 0.865, state_cohort = 108510, state_grads = 93818),
  list(year = 2013, state_rate = 0.875, state_cohort = 108676, state_grads = 95091),
  list(year = 2014, state_rate = 0.886, state_cohort = 106162, state_grads = 94059),
  list(year = 2015, state_rate = 0.897, state_cohort = 106113, state_grads = 95149),
  list(year = 2016, state_rate = 0.901, state_cohort = 106298, state_grads = 95736),
  list(year = 2017, state_rate = 0.905, state_cohort = 106379, state_grads = 96278),
  list(year = 2018, state_rate = 0.909, state_cohort = 106646, state_grads = 96955),
  list(year = 2019, state_rate = 0.906, state_cohort = 106670, state_grads = 96591),
  list(year = 2020, state_rate = 0.910, state_cohort = 105639, state_grads = 96084),
  list(year = 2021, state_rate = 0.906, state_cohort = 106508, state_grads = 96514),
  list(year = 2022, state_rate = 0.909, state_cohort = 106822, state_grads = 97079),
  list(year = 2023, state_rate = 0.911, state_cohort = 106157, state_grads = 96683),
  list(year = 2024, state_rate = 0.913, state_cohort = 107713, state_grads = 98300)
)

for (spec in grate_4yr_pins) {
  yr <- spec$year

  test_that(paste("fetch_grad_rate 4yr loads without error for", yr), {
    skip_on_cran()
    skip_if_offline()

    gr <- fetch_grad_rate(yr, methodology = "4 year")

    expect_s3_class(gr, "data.frame")
    expect_gt(nrow(gr), 0)
  })

  test_that(paste("fetch_grad_rate 4yr has required columns for", yr), {
    skip_on_cran()
    skip_if_offline()

    gr <- fetch_grad_rate(yr, methodology = "4 year")

    required_cols <- c(
      "end_year",
      "county_id", "county_name",
      "district_id", "district_name",
      "school_id", "school_name",
      "subgroup", "grad_rate",
      "methodology",
      "is_state", "is_district", "is_school", "is_charter"
    )
    for (col in required_cols) {
      expect_true(col %in% names(gr),
        info = paste("Missing column:", col, "in year", yr))
    }
  })

  test_that(paste("fetch_grad_rate 4yr state rate matches pin for", yr), {
    skip_on_cran()
    skip_if_offline()

    gr <- fetch_grad_rate(yr, methodology = "4 year")

    # Total subgroup name changed in 2020: "total population" -> "total"
    state <- gr %>%
      dplyr::filter(is_state) %>%
      dplyr::filter(grepl("^total", subgroup, ignore.case = TRUE))

    expect_equal(nrow(state), 1,
      info = paste("Expected exactly 1 state total row for", yr))

    # Pinned state graduation rate from NJ DOE ACGR file
    # Use tolerance for floating point rounding (grad_rate / 100 rounding)
    expect_equal(state$grad_rate, spec$state_rate, tolerance = 0.001,
      info = paste("State grad rate mismatch for", yr))
  })

  test_that(paste("fetch_grad_rate 4yr state cohort/grads match pins for", yr), {
    skip_on_cran()
    skip_if_offline()

    gr <- fetch_grad_rate(yr, methodology = "4 year")

    state <- gr %>%
      dplyr::filter(is_state) %>%
      dplyr::filter(grepl("^total", subgroup, ignore.case = TRUE))

    # Pinned cohort and grad counts from NJ DOE ACGR file
    expect_equal(state$cohort_count, spec$state_cohort,
      info = paste("State cohort count mismatch for", yr))
    expect_equal(state$graduated_count, spec$state_grads,
      info = paste("State grad count mismatch for", yr))
  })

  test_that(paste("fetch_grad_rate 4yr rates are in valid range for", yr), {
    skip_on_cran()
    skip_if_offline()

    gr <- fetch_grad_rate(yr, methodology = "4 year")

    valid_rates <- gr$grad_rate[!is.na(gr$grad_rate)]
    expect_true(all(valid_rates >= 0 & valid_rates <= 1),
      info = paste("Grad rates outside 0-1 range for", yr))
  })

  test_that(paste("fetch_grad_rate 4yr has core subgroups for", yr), {
    skip_on_cran()
    skip_if_offline()

    gr <- fetch_grad_rate(yr, methodology = "4 year")

    subgroups <- unique(gr$subgroup)

    # Core subgroups that should be present across all years
    core_subgroups <- c("white", "black", "hispanic", "asian")
    for (sg in core_subgroups) {
      expect_true(sg %in% subgroups,
        info = paste("Missing subgroup:", sg, "in year", yr))
    }
  })

  test_that(paste("fetch_grad_rate 4yr entity flags work for", yr), {
    skip_on_cran()
    skip_if_offline()

    gr <- fetch_grad_rate(yr, methodology = "4 year")

    # Should have state, district, and school rows
    expect_true(sum(gr$is_state) > 0,
      info = paste("No state rows for", yr))
    expect_true(sum(gr$is_district) > 0,
      info = paste("No district rows for", yr))
    expect_true(sum(gr$is_school) > 0,
      info = paste("No school rows for", yr))

    # State and school should not overlap
    state_and_school <- gr %>% dplyr::filter(is_state & is_school)
    expect_equal(nrow(state_and_school), 0,
      info = paste("Rows are both is_state and is_school in", yr))
  })
}


# -- Graduation Counts: pinned state values per year ---------------------------

gcount_pins <- list(
  # Pinned: state graduated_count for total population/total subgroup
  # Source: NJ DOE ACGR files
  list(year = 2012, state_grads = 93818),
  list(year = 2015, state_grads = 95149),
  list(year = 2019, state_grads = 96591),
  list(year = 2020, state_grads = 96084),
  list(year = 2024, state_grads = 98300)
)

for (spec in gcount_pins) {
  yr <- spec$year

  test_that(paste("fetch_grad_count loads without error for", yr), {
    skip_on_cran()
    skip_if_offline()

    gc <- fetch_grad_count(yr)

    expect_s3_class(gc, "data.frame")
    expect_gt(nrow(gc), 0)
  })

  test_that(paste("fetch_grad_count has required columns for", yr), {
    skip_on_cran()
    skip_if_offline()

    gc <- fetch_grad_count(yr)

    required_cols <- c(
      "end_year",
      "county_id", "county_name",
      "district_id", "district_name",
      "school_id", "school_name",
      "subgroup", "graduated_count",
      "is_state", "is_district", "is_school", "is_charter"
    )
    for (col in required_cols) {
      expect_true(col %in% names(gc),
        info = paste("Missing column:", col, "in year", yr))
    }
  })

  test_that(paste("fetch_grad_count state total matches pin for", yr), {
    skip_on_cran()
    skip_if_offline()

    gc <- fetch_grad_count(yr)

    state <- gc %>%
      dplyr::filter(is_state) %>%
      dplyr::filter(grepl("^total", subgroup, ignore.case = TRUE))

    expect_equal(nrow(state), 1,
      info = paste("Expected exactly 1 state total row for", yr))

    # Pinned state graduated_count from NJ DOE ACGR file
    expect_equal(state$graduated_count, spec$state_grads,
      info = paste("State grad count mismatch for", yr))
  })
}


# -- Cross-year graduation rate consistency ------------------------------------

test_that("state 4yr grad rate is monotonically reasonable (no wild swings)", {
  skip_on_cran()
  skip_if_offline()

  # NJ state graduation rate has been between 85-95% for the past decade
  test_years <- c(2015, 2019, 2024)

  for (yr in test_years) {
    gr <- fetch_grad_rate(yr)
    state <- gr %>%
      dplyr::filter(is_state) %>%
      dplyr::filter(grepl("^total", subgroup, ignore.case = TRUE))

    expect_true(state$grad_rate > 0.85,
      info = paste("State grad rate suspiciously low for", yr))
    expect_true(state$grad_rate < 0.98,
      info = paste("State grad rate suspiciously high for", yr))
  }
})

test_that("year-over-year state grad rate change is < 5%", {
  skip_on_cran()
  skip_if_offline()

  test_years <- c(2020, 2021, 2022, 2023, 2024)

  state_rates <- numeric(length(test_years))
  for (i in seq_along(test_years)) {
    gr <- fetch_grad_rate(test_years[i])
    state <- gr %>%
      dplyr::filter(is_state) %>%
      dplyr::filter(grepl("^total", subgroup, ignore.case = TRUE))
    state_rates[i] <- state$grad_rate
  }

  # Year-over-year change should be less than 5 percentage points
  for (i in 2:length(state_rates)) {
    abs_change <- abs(state_rates[i] - state_rates[i - 1])
    expect_true(abs_change < 0.05,
      info = paste("YoY grad rate change too large between",
                   test_years[i - 1], "and", test_years[i],
                   ":", round(abs_change * 100, 1), "pp"))
  }
})


# -- Total subgroup name consistency audit -------------------------------------
# This test documents the naming inconsistency between years

test_that("grad rate total subgroup naming change at 2020 boundary", {
  skip_on_cran()
  skip_if_offline()

  # Pre-2020 uses "total population"
  gr2019 <- fetch_grad_rate(2019)
  state_2019 <- gr2019 %>% dplyr::filter(is_state)
  expect_true("total population" %in% state_2019$subgroup,
    info = "2019 should use 'total population'")

  # Post-2020 uses "total"
  gr2020 <- fetch_grad_rate(2020)
  state_2020 <- gr2020 %>% dplyr::filter(is_state)
  expect_true("total" %in% state_2020$subgroup,
    info = "2020 should use 'total'")
})


# -- 5-Year Graduation Rate ---------------------------------------------------

test_that("fetch_grad_rate 5yr loads for 2019", {
  skip_on_cran()
  skip_if_offline()

  gr5 <- fetch_grad_rate(2019, methodology = "5 year")

  expect_s3_class(gr5, "data.frame")
  expect_gt(nrow(gr5), 0)
  expect_true("methodology" %in% names(gr5))
})

test_that("fetch_grad_rate 5yr rejects pre-2012 years", {
  expect_error(fetch_grad_rate(2011, methodology = "5 year"))
})


# -- Graduation count: no negative values --------------------------------------

test_that("fetch_grad_count has no negative graduated_count", {
  skip_on_cran()
  skip_if_offline()

  gc <- fetch_grad_count(2024)

  valid_counts <- gc$graduated_count[!is.na(gc$graduated_count)]
  expect_true(all(valid_counts >= 0),
    info = "Negative graduated_count values found")
})

test_that("fetch_grad_count has no Inf/NaN in graduated_count", {
  skip_on_cran()
  skip_if_offline()

  gc <- fetch_grad_count(2024)

  valid_counts <- gc$graduated_count[!is.na(gc$graduated_count)]
  expect_false(any(is.infinite(valid_counts)),
    info = "Inf in graduated_count")
  expect_false(any(is.nan(valid_counts)),
    info = "NaN in graduated_count")
})
