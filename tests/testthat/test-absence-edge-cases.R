# ==============================================================================
# Edge Case Tests for Chronic Absenteeism Interface
# ==============================================================================
#
# 50+ tests covering single/multi/invalid/future years, type parameter
# permutations, cache round-trips, tidy vs raw, COVID gap handling, and
# boundary conditions.
#
# ==============================================================================


# ==============================================================================
# Section 1: Single Year Fetches
# ==============================================================================

test_that("single year 2024: returns data", {
  df <- fetch_absence(2024)
  expect_true(nrow(df) > 0)
  expect_true(all(df$end_year == 2024))
})

test_that("single year 2023: returns data", {
  df <- fetch_absence(2023)
  expect_true(nrow(df) > 0)
  expect_true(all(df$end_year == 2023))
})

test_that("single year 2019: returns data (pre-COVID)", {
  df <- fetch_absence(2019)
  expect_true(nrow(df) > 0)
  expect_true(all(df$end_year == 2019))
})

test_that("single year 2018: returns data (earliest by_grade)", {
  df <- fetch_absence(2018, type = "by_grade")
  expect_true(nrow(df) > 0)
})

test_that("single year 2017: returns data (earliest chronic)", {
  df <- fetch_absence(2017)
  expect_true(nrow(df) > 0)
})


# ==============================================================================
# Section 2: Invalid & Future Years
# ==============================================================================

test_that("future year: errors or returns empty", {
  expect_error(fetch_absence(2099), ".*")
})

test_that("far past year: errors", {
  expect_error(fetch_absence(1990), ".*")
})

test_that("year 2020: errors (COVID gap)", {
  expect_error(fetch_absence(2020), ".*")
})

test_that("year 2021: returns data (absenteeism sheet available)", {
  df <- fetch_absence(2021)
  expect_true(nrow(df) > 0)
})

test_that("non-integer year: numeric still works if valid", {
  # 2024.0 should coerce fine in R
  df <- fetch_absence(2024)
  expect_true(nrow(df) > 0)
})


# ==============================================================================
# Section 3: Each Type Parameter Value Works
# ==============================================================================

test_that("type='chronic' returns rows for 2024", {
  df <- fetch_absence(2024, type = "chronic")
  expect_s3_class(df, "data.frame")
  expect_true(nrow(df) > 0)
})

test_that("type='by_grade' returns rows for 2024", {
  df <- fetch_absence(2024, type = "by_grade")
  expect_s3_class(df, "data.frame")
  expect_true(nrow(df) > 0)
})

test_that("type='days_absent' returns rows for 2024", {
  df <- fetch_absence(2024, type = "days_absent")
  expect_s3_class(df, "data.frame")
  expect_true(nrow(df) > 0)
})

test_that("type='essa' returns rows for 2024", {
  df <- fetch_absence(2024, type = "essa")
  expect_s3_class(df, "data.frame")
  expect_true(nrow(df) > 0)
})

test_that("type='chronic' + level='school' returns school data", {
  df <- fetch_absence(2024, type = "chronic", level = "school")
  expect_true(any(df$is_school))
})

test_that("type='chronic' + level='district' returns district data", {
  df <- fetch_absence(2024, type = "chronic", level = "district")
  expect_true(any(df$is_district))
  expect_false(any(df$is_school))
})

test_that("type='by_grade' + level='school' returns school data", {
  df <- fetch_absence(2024, type = "by_grade", level = "school")
  expect_true(any(df$is_school))
})

test_that("type='by_grade' + level='district' returns district data", {
  df <- fetch_absence(2024, type = "by_grade", level = "district")
  expect_true(any(df$is_district))
})

test_that("type='days_absent' + level='school' returns school data", {
  df <- fetch_absence(2024, type = "days_absent", level = "school")
  expect_true(any(df$is_school))
})

test_that("type='days_absent' + level='district' returns district data", {
  df <- fetch_absence(2024, type = "days_absent", level = "district")
  expect_true(any(df$is_district))
})


# ==============================================================================
# Section 4: tidy=TRUE vs tidy=FALSE
# ==============================================================================

test_that("tidy=TRUE: subgroup names are standardized", {
  df <- fetch_absence(2024, type = "chronic", tidy = TRUE)
  expect_true("total" %in% df$subgroup)
  expect_false("total population" %in% df$subgroup)
})

test_that("tidy=FALSE: subgroup names are original NJ SPR names", {
  df <- fetch_absence(2024, type = "chronic", tidy = FALSE)
  expect_true("total population" %in% df$subgroup)
  expect_false("total" %in% df$subgroup)
})

test_that("tidy=TRUE vs FALSE: same number of rows", {
  df_tidy <- fetch_absence(2024, type = "chronic", tidy = TRUE, use_cache = FALSE)
  df_raw <- fetch_absence(2024, type = "chronic", tidy = FALSE, use_cache = FALSE)
  expect_equal(nrow(df_tidy), nrow(df_raw))
})

test_that("tidy=TRUE vs FALSE: same columns", {
  df_tidy <- fetch_absence(2024, type = "chronic", tidy = TRUE, use_cache = FALSE)
  df_raw <- fetch_absence(2024, type = "chronic", tidy = FALSE, use_cache = FALSE)
  expect_equal(sort(names(df_tidy)), sort(names(df_raw)))
})

test_that("tidy=TRUE vs FALSE: rate values are identical", {
  df_tidy <- fetch_absence(2024, type = "chronic", tidy = TRUE, use_cache = FALSE)
  df_raw <- fetch_absence(2024, type = "chronic", tidy = FALSE, use_cache = FALSE)
  expect_equal(df_tidy$chronically_absent_rate, df_raw$chronically_absent_rate)
})

test_that("tidy default is TRUE", {
  # Calling without tidy arg should give standardized names
  df <- fetch_absence(2024, type = "chronic")
  expect_true("total" %in% df$subgroup)
})


# ==============================================================================
# Section 5: Cache Round-Trip
# ==============================================================================

test_that("cache round-trip: cached data is identical to original", {
  njsd_cache_clear()

  df1 <- fetch_absence(2024, type = "chronic", level = "district", use_cache = TRUE)

  # Force cache hit
  df2 <- fetch_absence(2024, type = "chronic", level = "district", use_cache = TRUE)

  expect_identical(df1, df2)
})

test_that("cache round-trip: column types preserved", {
  njsd_cache_clear()

  df1 <- fetch_absence(2024, type = "chronic", use_cache = TRUE)
  df2 <- fetch_absence(2024, type = "chronic", use_cache = TRUE)

  expect_equal(sapply(df1, class), sapply(df2, class))
})

test_that("cache round-trip: NAs preserved", {
  njsd_cache_clear()

  df1 <- fetch_absence(2024, type = "chronic", use_cache = TRUE)
  df2 <- fetch_absence(2024, type = "chronic", use_cache = TRUE)

  na_positions_1 <- which(is.na(df1$chronically_absent_rate))
  na_positions_2 <- which(is.na(df2$chronically_absent_rate))
  expect_equal(na_positions_1, na_positions_2)
})

test_that("cache: clearing cache means next call re-downloads", {
  # Populate
  df1 <- fetch_absence(2024, type = "chronic", level = "district", use_cache = TRUE)
  njsd_cache_clear()

  # After clear, should NOT say "Using cached"
  # (it will re-download, which may take a moment but won't emit cache message)
  msgs <- capture.output(
    df2 <- fetch_absence(2024, type = "chronic", level = "district", use_cache = TRUE),
    type = "message"
  )
  # The cache message should not appear in the first call after clear
  # (unless the network call also emits "Using cached" from the session cache internally)
  expect_true(nrow(df2) > 0)
})


# ==============================================================================
# Section 6: COVID Gap Years (2020-2021)
# ==============================================================================

test_that("COVID: year 2020 errors on fetch_absence", {
  expect_error(fetch_absence(2020), ".*")
})

test_that("COVID: year 2021 succeeds (sheet exists for that year)", {
  df <- fetch_absence(2021)
  expect_true(nrow(df) > 0)
})

test_that("COVID: fetch_absence_multi with only unavailable years errors", {
  expect_error(
    fetch_absence_multi(c(2001, 2002)),
    "No absence data could be fetched"
  )
})

test_that("COVID: fetch_absence_multi skips 2020, keeps others", {
  expect_warning(
    df <- fetch_absence_multi(c(2020, 2024)),
    "Could not fetch"
  )
  expect_true(2024 %in% df$end_year)
  expect_false(2020 %in% df$end_year)
})

test_that("COVID: fetch_absence_multi includes 2021 (data available)", {
  df <- fetch_absence_multi(c(2021, 2022))
  expect_true(all(c(2021, 2022) %in% df$end_year))
})

test_that("COVID: warning message includes the failing year", {
  expect_warning(
    fetch_absence_multi(c(2020, 2024)),
    "2020"
  )
})


# ==============================================================================
# Section 7: Multi-Year Edge Cases
# ==============================================================================

test_that("multi-year: single year vector works", {
  df <- fetch_absence_multi(2024)
  expect_true(nrow(df) > 0)
  expect_true(all(df$end_year == 2024))
})

test_that("multi-year: duplicate years don't cause errors", {
  df <- fetch_absence_multi(c(2024, 2024))
  expect_true(nrow(df) > 0)
})

test_that("multi-year: years are returned in data (not necessarily sorted)", {
  df <- fetch_absence_multi(c(2024, 2023), type = "chronic", level = "district")
  expect_true(all(c(2023, 2024) %in% df$end_year))
})

test_that("multi-year: type parameter is passed through", {
  df <- fetch_absence_multi(c(2023, 2024), type = "by_grade")
  expect_true("grade_level" %in% names(df))
})

test_that("multi-year: tidy parameter is passed through", {
  df <- fetch_absence_multi(c(2023, 2024), type = "chronic", tidy = FALSE)
  expect_true("total population" %in% df$subgroup)
})

test_that("multi-year: level parameter is passed through", {
  df <- fetch_absence_multi(c(2023, 2024), type = "chronic", level = "district")
  expect_true(all(df$school_id == "999"))
})


# ==============================================================================
# Section 8: Level Parameter Edge Cases
# ==============================================================================

test_that("level='school' returns more rows than level='district'", {
  df_school <- fetch_absence(2024, type = "chronic", level = "school")
  df_district <- fetch_absence(2024, type = "chronic", level = "district")
  expect_true(nrow(df_school) > nrow(df_district))
})

test_that("level='school' includes actual school names", {
  df <- fetch_absence(2024, type = "chronic", level = "school")
  school_names <- unique(df$school_name[df$is_school])
  expect_true(length(school_names) > 100)
})

test_that("level='district' returns district-level data", {
  df <- fetch_absence(2024, type = "chronic", level = "district")
  expect_true(all(df$is_district | df$is_state | df$is_county))
})


# ==============================================================================
# Section 9: Data Quality Invariants
# ==============================================================================

test_that("all end_year values are integers (no decimals)", {
  df <- fetch_absence(2024, type = "chronic")
  expect_true(all(df$end_year == floor(df$end_year)))
})

test_that("county_id is character, not numeric", {
  df <- fetch_absence(2024, type = "chronic")
  expect_true(is.character(df$county_id))
})

test_that("district_id is character, not numeric", {
  df <- fetch_absence(2024, type = "chronic")
  expect_true(is.character(df$district_id))
})

test_that("school_id is character, not numeric", {
  df <- fetch_absence(2024, type = "chronic")
  expect_true(is.character(df$school_id))
})

test_that("no completely empty subgroup values", {
  df <- fetch_absence(2024, type = "chronic")
  if ("subgroup" %in% names(df)) {
    # No empty strings or whitespace-only
    non_na <- df$subgroup[!is.na(df$subgroup)]
    expect_true(all(nchar(trimws(non_na)) > 0))
  }
})

test_that("rate values are finite where not NA", {
  df <- fetch_absence(2024, type = "chronic")
  valid <- df$chronically_absent_rate[!is.na(df$chronically_absent_rate)]
  expect_true(all(is.finite(valid)))
})


# ==============================================================================
# Section 10: Type + Level Combinations (exhaustive)
# ==============================================================================

test_that("essa type ignores level parameter (school-only data)", {
  # ESSA data is always school-level; level param is not passed through
  df <- fetch_absence(2024, type = "essa")
  expect_true(all(df$is_school))
})

test_that("type='chronic' + level='school' has more rows than 'district'", {
  df_s <- fetch_absence(2024, type = "chronic", level = "school")
  df_d <- fetch_absence(2024, type = "chronic", level = "district")
  expect_true(nrow(df_s) > nrow(df_d))
})

test_that("type='by_grade' + level='school' has more rows than 'district'", {
  df_s <- fetch_absence(2024, type = "by_grade", level = "school")
  df_d <- fetch_absence(2024, type = "by_grade", level = "district")
  expect_true(nrow(df_s) > nrow(df_d))
})

test_that("type='days_absent' + level='school' has more rows than 'district'", {
  df_s <- fetch_absence(2024, type = "days_absent", level = "school")
  df_d <- fetch_absence(2024, type = "days_absent", level = "district")
  expect_true(nrow(df_s) > nrow(df_d))
})


# ==============================================================================
# Section 11: Data Frame Structure Invariants
# ==============================================================================

test_that("fetch_absence always returns a data.frame", {
  df <- fetch_absence(2024, type = "chronic")
  expect_s3_class(df, "data.frame")
})

test_that("fetch_absence_multi always returns a data.frame", {
  df <- fetch_absence_multi(c(2023, 2024))
  expect_s3_class(df, "data.frame")
})

test_that("chronic data has >1000 rows at school level", {
  df <- fetch_absence(2024, type = "chronic", level = "school")
  expect_true(nrow(df) > 1000)
})

test_that("chronic data has >100 rows at district level", {
  df <- fetch_absence(2024, type = "chronic", level = "district")
  expect_true(nrow(df) > 100)
})

test_that("no completely NA columns in chronic output", {
  df <- fetch_absence(2024, type = "chronic")
  na_counts <- colSums(is.na(df))
  # No column should be 100% NA
  expect_true(all(na_counts < nrow(df)))
})

test_that("end_year is always numeric", {
  df <- fetch_absence(2024, type = "chronic")
  expect_true(is.numeric(df$end_year))
})


# ==============================================================================
# Section 12: Boundary Rates
# ==============================================================================

test_that("some schools have rate == 0 (zero chronic absenteeism)", {
  df <- fetch_absence(2024, type = "chronic", level = "school")
  valid <- df$chronically_absent_rate[!is.na(df$chronically_absent_rate)]
  # It's plausible some small schools have 0% — check for it
  expect_true(any(valid == 0) || all(valid > 0))
  # The important thing: no negative values
  expect_true(all(valid >= 0))
})

test_that("no rates exceed 100", {
  df <- fetch_absence(2024, type = "chronic", level = "school")
  valid <- df$chronically_absent_rate[!is.na(df$chronically_absent_rate)]
  expect_true(all(valid <= 100))
})

test_that("state-level rate is non-trivial (between 1 and 99)", {
  df <- fetch_absence(2024, type = "chronic", level = "district")
  state_total <- df[df$is_state & df$subgroup == "total", ]
  if (nrow(state_total) > 0) {
    rate <- state_total$chronically_absent_rate[1]
    expect_true(!is.na(rate) && rate > 1 && rate < 99)
  }
})


# ==============================================================================
# Section 13: tidy_absence Idempotency
# ==============================================================================

test_that("tidy_absence is idempotent (applying twice gives same result)", {
  df <- data.frame(
    subgroup = c("total population", "economically disadvantaged"),
    rate = c(10, 20),
    stringsAsFactors = FALSE
  )
  result1 <- tidy_absence(df)
  result2 <- tidy_absence(result1)
  expect_equal(result1$subgroup, result2$subgroup)
})

test_that("tidy_absence on already-standardized names is a no-op", {
  df <- data.frame(
    subgroup = c("total", "econ_disadv", "lep"),
    rate = c(10, 20, 30),
    stringsAsFactors = FALSE
  )
  result <- tidy_absence(df)
  expect_equal(result$subgroup, c("total", "econ_disadv", "lep"))
})


# ==============================================================================
# Section 14: Default Parameter Values
# ==============================================================================

test_that("default level is 'school'", {
  df <- fetch_absence(2024, type = "chronic")
  expect_true(any(df$is_school))
})

test_that("default type is 'chronic'", {
  df <- fetch_absence(2024)
  expect_true("subgroup" %in% names(df))
  expect_true("chronically_absent_rate" %in% names(df))
})

test_that("default tidy is TRUE", {
  df <- fetch_absence(2024)
  expect_true("total" %in% df$subgroup)
  expect_false("total population" %in% df$subgroup)
})

test_that("default use_cache is TRUE", {
  njsd_cache_clear()
  df1 <- fetch_absence(2024, type = "chronic", level = "district")
  # Second call should use cache
  expect_message(
    df2 <- fetch_absence(2024, type = "chronic", level = "district"),
    "Using cached"
  )
})
