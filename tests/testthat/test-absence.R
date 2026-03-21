# ==============================================================================
# Tests for Unified Chronic Absenteeism Interface
# ==============================================================================


# ==============================================================================
# Subgroup Mapping Tests (offline — no network required)
# ==============================================================================

test_that("standardize_absence_subgroups maps NJ names to cross-state standards", {
  input <- c(
    "total population", "white", "black", "hispanic", "asian",
    "american indian", "pacific islander", "multiracial",
    "economically disadvantaged", "limited english proficiency",
    "students with disability", "male", "female"
  )

  expected <- c(
    "total", "white", "black", "hispanic", "asian",
    "native_american", "pacific_islander", "multiracial",
    "econ_disadv", "lep",
    "special_ed", "male", "female"
  )

  result <- standardize_absence_subgroups(input)
  expect_equal(result, expected)
})

test_that("standardize_absence_subgroups passes through unknown values", {
  expect_equal(standardize_absence_subgroups("unknown_group"), "unknown_group")
})


# ==============================================================================
# tidy_absence Tests (offline)
# ==============================================================================

test_that("tidy_absence normalizes subgroup column", {
  df <- data.frame(
    end_year = 2024,
    subgroup = c("total population", "economically disadvantaged", "black"),
    chronically_absent_rate = c(15.2, 22.1, 18.5),
    stringsAsFactors = FALSE
  )

  result <- tidy_absence(df)
  expect_equal(result$subgroup, c("total", "econ_disadv", "black"))
})

test_that("tidy_absence handles data without subgroup column", {
  df <- data.frame(
    end_year = 2024,
    grade_level = c("01", "02"),
    chronically_absent_rate = c(15.2, 12.1)
  )

  # Should not error
  result <- tidy_absence(df)
  expect_equal(nrow(result), 2)
})


# ==============================================================================
# Input Validation Tests (offline)
# ==============================================================================

test_that("fetch_absence validates type parameter", {
  expect_error(
    fetch_absence(2024, type = "invalid"),
    "type must be one of"
  )
})

test_that("fetch_absence validates type against known options", {
  expect_error(fetch_absence(2024, type = "enrollment"), "type must be one of")
})


# ==============================================================================
# Network Integration Tests
# ==============================================================================

test_that("fetch_absence returns tidy data by default", {
  df <- fetch_absence(2024)

  # Should have standardized subgroup names
  expect_true("total" %in% df$subgroup)
  expect_false("total population" %in% df$subgroup)

  # Should have cross-state standard names
  expect_true(any(c("econ_disadv", "lep", "special_ed") %in% df$subgroup))
})

test_that("fetch_absence with tidy=FALSE returns original names", {
  df <- fetch_absence(2024, tidy = FALSE)

  # Should have original NJ subgroup names
  expect_true("total population" %in% df$subgroup)
})

test_that("fetch_absence type='chronic' returns expected columns", {
  df <- fetch_absence(2024)

  expected_cols <- c(
    "end_year", "county_id", "county_name",
    "district_id", "district_name",
    "school_id", "school_name",
    "subgroup", "chronically_absent_rate",
    "is_state", "is_county", "is_district", "is_school",
    "is_charter"
  )
  expect_true(all(expected_cols %in% names(df)))
})

test_that("fetch_absence type='by_grade' includes grade_level", {
  df <- fetch_absence(2024, type = "by_grade")

  expect_true("grade_level" %in% names(df))
  expect_true(length(unique(df$grade_level)) > 1)
})

test_that("fetch_absence type='days_absent' works", {
  df <- fetch_absence(2024, type = "days_absent")

  expect_s3_class(df, "data.frame")
  expect_true(nrow(df) > 0)
})

test_that("fetch_absence type='essa' works", {
  df <- fetch_absence(2024, type = "essa")

  expect_s3_class(df, "data.frame")
  expect_true("chronic_absenteeism_total" %in% names(df))
})

test_that("fetch_absence district level works", {
  df <- fetch_absence(2024, level = "district")

  expect_true(all(df$is_district | df$is_state | df$is_county))
  expect_true(all(df$school_id == "999"))
})

test_that("fetch_absence caching works", {
  # First call populates cache
  df1 <- fetch_absence(2024, use_cache = TRUE)

  # Second call should use cache (message emitted)
  expect_message(
    df2 <- fetch_absence(2024, use_cache = TRUE),
    "Using cached"
  )

  expect_equal(nrow(df1), nrow(df2))
})


# ==============================================================================
# Multi-Year Tests
# ==============================================================================

test_that("fetch_absence_multi binds multiple years", {
  df <- fetch_absence_multi(c(2023, 2024))

  expect_true(all(c(2023, 2024) %in% df$end_year))
  expect_true(nrow(df) > 0)
})

test_that("fetch_absence_multi warns on unavailable years", {
  expect_warning(
    df <- fetch_absence_multi(c(2020, 2024)),
    "Could not fetch"
  )

  # Should still return 2024 data
  expect_true(2024 %in% df$end_year)
})

test_that("fetch_absence_multi errors when no years succeed", {
  expect_error(
    fetch_absence_multi(c(2020, 2021)),
    "No absence data could be fetched"
  )
})
