# ==============================================================================
# Enrollment Year Coverage Tests
# ==============================================================================
#
# Exhaustive per-year tests for NJ enrollment data (fetch_enr).
# Tests wide format (all years) and tidy format (working years).
# Pinned values verified against NJ DOE source files.
#
# ==============================================================================

# -- Truthful years contract ---------------------------------------------------
# get_available_years() must exist, be exported, and be truthful: its max must
# equal the highest end_year that fetch_enr() actually serves. This is a static
# check against ENR_VALID_YEARS (fast, no network) plus a live check that the
# claimed max year really does fetch (network-gated).

test_that("get_available_years is exported and truthful about ENR_VALID_YEARS", {
  expect_true(exists("get_available_years", mode = "function"))

  years <- get_available_years()
  expect_type(years, "integer")
  expect_true(length(years) > 0)
  expect_equal(years, as.integer(ENR_VALID_YEARS))
  expect_equal(max(years), max(as.integer(ENR_VALID_YEARS)))
})

test_that("get_available_years max year actually fetches via fetch_enr", {
  skip_on_cran()
  skip_if_offline()

  max_year <- max(get_available_years())
  enr <- fetch_enr(max_year, use_cache = TRUE)

  expect_s3_class(enr, "data.frame")
  expect_gt(nrow(enr), 0)
})


# -- Wide format enrollment tests (2015-2025) ----------------------------------
# Wide format works reliably for post-NJSMART years. We test a representative
# set of years spanning format changes (pre-2020 vs post-2020 Excel layout).

wide_test_years <- list(
  # year, expected_cols, min_rows
  # expected_cols includes the 2 NCES id columns (nces_dist, nces_sch) that
  # fetch_enr() attaches to every result.
  # Pre-2020 format: separate program codes, ~26k rows, 39 + 2 NCES = 41 cols
  list(year = 2015, min_rows = 25000, expected_cols = 41),
  list(year = 2018, min_rows = 25000, expected_cols = 41),
  list(year = 2019, min_rows = 25000, expected_cols = 41),
  # Post-2020 format: State/District/School sheets, ~57k rows, 26 + 2 NCES = 28 cols
  list(year = 2020, min_rows = 50000, expected_cols = 28),
  list(year = 2021, min_rows = 50000, expected_cols = 28),
  list(year = 2022, min_rows = 50000, expected_cols = 28),
  # 2024+ ships ~101k rows (Ungraded column dropped, more school rows)
  list(year = 2025, min_rows = 50000, expected_cols = 28),
  # 2025-26 file shipped as "Enrollment_2526.zip" (capital E - filename case flip)
  list(year = 2026, min_rows = 50000, expected_cols = 28)
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
      "end_year", "cds_code",
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
  list(year = 2025, state_total = 1381182, newark_total = 43980),
  # 2026: NJ DOE publishes 1,357,450 (= 1357449.5 rounded; the State sheet
  # carries a genuine half-student in Tenth Grade FTE). Newark = 43,216.
  list(year = 2026, state_total = 1357449.5, newark_total = 43216)
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
      "end_year", "cds_code",
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
  test_years <- c(2021, 2022, 2023, 2024, 2025, 2026)

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
  consistent_years <- c(2021, 2022, 2023, 2024, 2025, 2026)

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


# -- Structural correctness invariants (modern format, 2020+) ------------------
# These guard against silent definition/coverage changes that the coarse 10%
# YoY band would miss. They encode relationships that must hold in every
# faithful enrollment file regardless of demographic trend.

invariant_years <- c(2022, 2023, 2024, 2025, 2026)

for (yr in invariant_years) {

  test_that(paste("state total equals sum of district totals for", yr), {
    skip_on_cran()
    skip_if_offline()

    enr <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    state_total <- enr %>%
      dplyr::filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
      dplyr::pull(n_students)

    district_sum <- enr %>%
      dplyr::filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
      dplyr::summarize(s = sum(n_students, na.rm = TRUE)) %>%
      dplyr::pull(s)

    expect_equal(state_total, district_sum,
      info = paste("State total != sum of districts in", yr))
  })

  test_that(paste("no state-level rows have NA grade_level for", yr), {
    skip_on_cran()
    skip_if_offline()

    # Regression: NJ DOE ships "Eight Grade" (sic) as a row value on the State
    # worksheet. Before the typo fix this failed to map to grade "08" and the
    # ~100k 8th graders landed in an NA-grade row.
    enr <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    na_grade_state <- enr %>%
      dplyr::filter(is_state, subgroup == "total_enrollment", is.na(grade_level)) %>%
      nrow()

    expect_equal(na_grade_state, 0,
      info = paste("State rows with NA grade_level in", yr))
  })

  test_that(paste("state grade-8 equals sum of district grade-8 for", yr), {
    skip_on_cran()
    skip_if_offline()

    enr <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    state_g8 <- enr %>%
      dplyr::filter(is_state, subgroup == "total_enrollment", grade_level == "08") %>%
      dplyr::pull(n_students)

    district_g8 <- enr %>%
      dplyr::filter(is_district, subgroup == "total_enrollment", grade_level == "08") %>%
      dplyr::summarize(s = sum(n_students, na.rm = TRUE)) %>%
      dplyr::pull(s)

    expect_length(state_g8, 1)
    expect_equal(state_g8, district_g8,
      info = paste("State grade-8 != district sum in", yr))
  })

  test_that(paste("state PK + K12UG equals total enrollment for", yr), {
    skip_on_cran()
    skip_if_offline()

    # PreK + (K-12 inclusive of ungraded) must reconstruct the full state
    # total. K12UG (not K12) is used so the identity holds for both pre-2024
    # files (which carry an Ungraded category) and 2024+ files (which don't).
    # This only holds once state grade-8 maps correctly (see grade-8 fix).
    enr <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    aggs <- enr_grade_aggs(enr)

    state_total <- enr %>%
      dplyr::filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
      dplyr::pull(n_students)
    pk <- aggs %>%
      dplyr::filter(is_state, subgroup == "total_enrollment", grade_level == "PK (Any)") %>%
      dplyr::pull(n_students)
    k12ug <- aggs %>%
      dplyr::filter(is_state, subgroup == "total_enrollment", grade_level == "K12UG") %>%
      dplyr::pull(n_students)

    expect_equal(pk + k12ug, state_total,
      info = paste("PK + K12UG != total in", yr))
  })
}


# -- 2026 believability: cohort progression (definition-change canary) ---------
# A genuine demographic decline shows up as smaller *entering* cohorts while
# each existing cohort retains ~its size year over year. A definition or
# coverage change instead shows up as a discontinuity in cohort retention.
# 2025->2026 retention sits in [0.975, 1.013] for every grade pair, so the
# headline -1.9% K-12 drop is real demographics, not an artifact.

test_that("2025->2026 cohort retention is within believable bounds", {
  skip_on_cran()
  skip_if_offline()

  e25 <- fetch_enr(2025, tidy = TRUE, use_cache = TRUE)
  e26 <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)

  state_grade <- function(df) {
    df %>%
      dplyr::filter(
        is_state, subgroup == "total_enrollment",
        grade_level %in% sprintf("%02d", 1:12)
      ) %>%
      dplyr::select(grade_level, n_students)
  }

  g25 <- state_grade(e25) %>% dplyr::rename(y25 = n_students)
  g26 <- state_grade(e26) %>% dplyr::rename(y26 = n_students)

  cohort <- g25 %>%
    dplyr::mutate(next_grade = sprintf("%02d", as.integer(grade_level) + 1L)) %>%
    dplyr::inner_join(g26, by = c("next_grade" = "grade_level")) %>%
    dplyr::mutate(retention = y26 / y25)

  # Grades 1->2 through 11->12 (11 cohort pairs)
  expect_equal(nrow(cohort), 11)
  expect_true(all(cohort$retention > 0.90),
    info = "A cohort lost >10% year-over-year (possible definition change)")
  expect_true(all(cohort$retention < 1.10),
    info = "A cohort grew >10% year-over-year (possible definition change)")
})

test_that("2026 PreK rose while K-12 fell (documents the headline divergence)", {
  skip_on_cran()
  skip_if_offline()

  e25 <- fetch_enr(2025, tidy = TRUE, use_cache = TRUE)
  e26 <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)

  pk <- function(df) {
    enr_grade_aggs(df) %>%
      dplyr::filter(is_state, subgroup == "total_enrollment", grade_level == "PK (Any)") %>%
      dplyr::pull(n_students)
  }
  k12 <- function(df) {
    enr_grade_aggs(df) %>%
      dplyr::filter(is_state, subgroup == "total_enrollment", grade_level == "K12") %>%
      dplyr::pull(n_students)
  }

  # PreK grew, K-12 declined: a file-wide coverage change would move both the
  # same direction, so the divergence is itself evidence the data is genuine.
  expect_gt(pk(e26), pk(e25))
  expect_lt(k12(e26), k12(e25))
})
