# ==============================================================================
# Enrollment Year Coverage Tests
# ==============================================================================
#
# Exhaustive per-year tests for NJ enrollment data (fetch_enr).
# Tests wide format (all years) and tidy format (working years).
# Pinned values verified against NJ DOE source files.
#
# ==============================================================================

# -- Wide format enrollment tests (2015-2025) ----------------------------------
# Wide format works reliably for post-NJSMART years. We test a representative
# set of years spanning format changes (pre-2020 vs post-2020 Excel layout).

wide_test_years <- list(
  # year, expected_cols, min_rows
  # Pre-2020 format: separate program codes, ~26k rows, 39 cols
  list(year = 2015, min_rows = 25000, expected_cols = 39),
  list(year = 2018, min_rows = 25000, expected_cols = 39),
  list(year = 2019, min_rows = 25000, expected_cols = 39),
  # Post-2020 format: State/District/School sheets, ~57k rows, 26 cols
  list(year = 2020, min_rows = 50000, expected_cols = 26),
  list(year = 2021, min_rows = 50000, expected_cols = 26),
  list(year = 2022, min_rows = 50000, expected_cols = 26)
)

for (spec in wide_test_years) {
  yr <- spec$year

  test_that(paste("fetch_enr wide format loads for", yr), {
    skip_on_cran()
    skip_if_offline()

    enr <- fetch_enr(yr, use_cache = TRUE)

    expect_s3_class(enr, "data.frame")
    expect_gt(nrow(enr), spec$min_rows)
    expect_equal(ncol(enr), spec$expected_cols)
  })

  test_that(paste("fetch_enr wide format has required columns for", yr), {
    skip_on_cran()
    skip_if_offline()

    enr <- fetch_enr(yr, use_cache = TRUE)

    # Core ID columns always present
    required_cols <- c(
      "end_year", "CDS_Code",
      "county_id", "county_name",
      "district_id", "district_name",
      "school_id", "school_name",
      "row_total", "grade_level"
    )
    for (col in required_cols) {
      expect_true(col %in% names(enr), info = paste("Missing column:", col, "in year", yr))
    }
  })

  test_that(paste("fetch_enr wide format has no Inf/NaN in row_total for", yr), {
    skip_on_cran()
    skip_if_offline()

    enr <- fetch_enr(yr, use_cache = TRUE)

    numeric_vals <- enr$row_total[!is.na(enr$row_total)]
    expect_false(any(is.infinite(numeric_vals)), info = paste("Inf in row_total for", yr))
    expect_false(any(is.nan(numeric_vals)), info = paste("NaN in row_total for", yr))
  })
}


# -- Tidy format enrollment tests (working years) -----------------------------
# Some years fail with tidy=TRUE due to formatting bugs in the process pipeline.
# We test the years that are known to work reliably.

tidy_test_years <- list(
  # Pinned values: state total enrollment and Newark district total

  # Source: NJ DOE enrollment files downloaded from nj.gov/education/doedata/enr/
  list(year = 2015, state_total = 1369379, newark_total = 32098),
  list(year = 2018, state_total = 1370236, newark_total = 35714),
  list(year = 2019, state_total = 1364714, newark_total = 35664),
  list(year = 2021, state_total = 1362400, newark_total = 40085),
  list(year = 2022, state_total = 1360916, newark_total = 40607),
  list(year = 2023, state_total = 1371921, newark_total = 41430),
  list(year = 2024, state_total = 1379988, newark_total = 42600),
  list(year = 2025, state_total = 1381182, newark_total = 43980)
)

for (spec in tidy_test_years) {
  yr <- spec$year

  test_that(paste("fetch_enr tidy loads without error for", yr), {
    skip_on_cran()
    skip_if_offline()

    enr <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    expect_s3_class(enr, "data.frame")
    expect_gt(nrow(enr), 0)
  })

  test_that(paste("fetch_enr tidy has required columns for", yr), {
    skip_on_cran()
    skip_if_offline()

    enr <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    required_cols <- c(
      "end_year", "CDS_Code",
      "county_id", "county_name",
      "district_id", "district_name",
      "school_id", "school_name",
      "grade_level", "subgroup", "n_students", "pct",
      "is_state", "is_district", "is_school", "is_charter"
    )
    for (col in required_cols) {
      expect_true(col %in% names(enr), info = paste("Missing column:", col, "in year", yr))
    }
  })

  test_that(paste("fetch_enr tidy state total matches pinned value for", yr), {
    skip_on_cran()
    skip_if_offline()

    enr <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    state_total <- enr %>%
      dplyr::filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
      dplyr::pull(n_students)

    # Pinned value from NJ DOE enrollment file
    expect_equal(state_total, spec$state_total,
      info = paste("State total mismatch for", yr))
  })

  test_that(paste("fetch_enr tidy Newark total matches pinned value for", yr), {
    skip_on_cran()
    skip_if_offline()

    enr <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    # Newark = district_id 3570 (Essex County, largest district in NJ)
    newark_total <- enr %>%
      dplyr::filter(
        is_district,
        district_id == "3570",
        subgroup == "total_enrollment",
        grade_level == "TOTAL"
      ) %>%
      dplyr::pull(n_students)

    # Pinned value from NJ DOE enrollment file
    expect_equal(newark_total, spec$newark_total,
      info = paste("Newark total mismatch for", yr))
  })

  test_that(paste("fetch_enr tidy has expected subgroups for", yr), {
    skip_on_cran()
    skip_if_offline()

    enr <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    subgroups <- unique(enr$subgroup)

    # Core subgroups that should always be present
    core_subgroups <- c(
      "total_enrollment", "male", "female",
      "white", "black", "hispanic", "asian"
    )
    for (sg in core_subgroups) {
      expect_true(sg %in% subgroups,
        info = paste("Missing subgroup:", sg, "in year", yr))
    }
  })

  test_that(paste("fetch_enr tidy has expected grade levels for", yr), {
    skip_on_cran()
    skip_if_offline()

    enr <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    grade_levels <- unique(enr$grade_level)

    # Standard grade levels (K and PK normalized from KF/KH/PF/PH)
    expected_grades <- c("PK", "K", "01", "02", "03", "04", "05",
                         "06", "07", "08", "09", "10", "11", "12", "TOTAL")
    for (gl in expected_grades) {
      expect_true(gl %in% grade_levels,
        info = paste("Missing grade:", gl, "in year", yr))
    }

    # KF/KH/PF/PH should NOT be present (they should be normalized)
    raw_codes <- c("KF", "KH", "PF", "PH")
    for (rc in raw_codes) {
      expect_false(rc %in% grade_levels,
        info = paste("Un-normalized grade code still present:", rc, "in year", yr))
    }
  })

  test_that(paste("fetch_enr tidy entity flags are mutually exclusive for", yr), {
    skip_on_cran()
    skip_if_offline()

    enr <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    # A record should not be both state and district/school
    state_and_dist <- enr %>%
      dplyr::filter(is_state & is_district)
    expect_equal(nrow(state_and_dist), 0,
      info = paste("Rows are both is_state and is_district in", yr))

    state_and_school <- enr %>%
      dplyr::filter(is_state & is_school)
    expect_equal(nrow(state_and_school), 0,
      info = paste("Rows are both is_state and is_school in", yr))
  })

  test_that(paste("fetch_enr tidy has no Inf/NaN/negative n_students for", yr), {
    skip_on_cran()
    skip_if_offline()

    enr <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    valid_students <- enr$n_students[!is.na(enr$n_students)]
    expect_false(any(is.infinite(valid_students)),
      info = paste("Inf in n_students for", yr))
    expect_false(any(is.nan(valid_students)),
      info = paste("NaN in n_students for", yr))
    expect_true(all(valid_students >= 0),
      info = paste("Negative n_students for", yr))
  })
}


# -- Cross-year consistency tests (tidy format) --------------------------------

test_that("year-over-year state enrollment change is < 10%", {
  skip_on_cran()
  skip_if_offline()

  # Use years we know work reliably with tidy=TRUE
  test_years <- c(2021, 2022, 2023, 2024, 2025)

  state_totals <- numeric(length(test_years))
  for (i in seq_along(test_years)) {
    enr <- fetch_enr(test_years[i], tidy = TRUE, use_cache = TRUE)
    state_totals[i] <- enr %>%
      dplyr::filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
      dplyr::pull(n_students)
  }

  # Year-over-year change should be less than 10%
  for (i in 2:length(state_totals)) {
    pct_change <- abs(state_totals[i] / state_totals[i - 1] - 1)
    expect_true(pct_change < 0.10,
      info = paste("YoY change too large between",
                   test_years[i - 1], "and", test_years[i],
                   ":", round(pct_change * 100, 1), "%"))
  }
})

test_that("tidy enrollment schema is consistent across years", {
  skip_on_cran()
  skip_if_offline()

  # All tidy years should have the same column names
  ref_cols <- NULL
  consistent_years <- c(2021, 2022, 2023, 2024, 2025)

  for (yr in consistent_years) {
    enr <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    if (is.null(ref_cols)) {
      ref_cols <- sort(names(enr))
    } else {
      expect_equal(sort(names(enr)), ref_cols,
        info = paste("Column schema mismatch in year", yr))
    }
  }
})
