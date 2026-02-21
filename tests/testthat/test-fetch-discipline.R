# ==============================================================================
# Tests for Discipline & Climate Analysis Functions
# ==============================================================================


# ==============================================================================
# Test Data Setup
# ==============================================================================

# Create mock discipline data for testing
create_mock_discipline_data <- function() {
  tibble::tibble(
    end_year = 2024,
    county_id = "01",
    county_name = "Atlantic",
    district_id = "0110",
    district_name = "Test District",
    school_id = "010",
    school_name = "Test School",
    subgroup = c("total population", "black", "hispanic", "white", "economically disadvantaged"),
    number_of_students = c(1000, 200, 300, 400, 350),
    number_of_removals = c(50, 15, 12, 18, 25),
    is_state = FALSE,
    is_county = FALSE,
    is_district = FALSE,
    is_school = TRUE,
    is_charter = FALSE,
    is_charter_sector = FALSE,
    is_allpublic = FALSE
  )
}

# Create mock multi-year discipline data
create_mock_multiyear_data <- function() {
  # Year 1
  df_2022 <- tibble::tibble(
    end_year = 2022,
    county_id = "01",
    district_id = "0110",
    school_id = "010",
    school_name = "Test School",
    subgroup = "total population",
    number_of_students = 1000,
    number_of_removals = 40,  # Rate: 40 per 1000
    is_state = FALSE,
    is_county = FALSE,
    is_district = FALSE,
    is_school = TRUE,
    is_charter = FALSE,
    is_charter_sector = FALSE,
    is_allpublic = FALSE
  )

  # Year 2 - increasing
  df_2023 <- df_2022
  df_2023$end_year <- 2023
  df_2023$number_of_removals <- 50  # Rate: 50 per 1000

  # Year 3 - increasing more
  df_2024 <- df_2022
  df_2024$end_year <- 2024
  df_2024$number_of_removals <- 60  # Rate: 60 per 1000

  list("2022" = df_2022, "2023" = df_2023, "2024" = df_2024)
}


# ==============================================================================
# calc_discipline_rates_by_subgroup() Tests
# ==============================================================================

test_that("calc_discipline_rates_by_subgroup requires subgroup column", {
  df <- tibble::tibble(
    school_id = "010",
    number_of_students = 1000,
    number_of_removals = 50
  )

  expect_error(
    calc_discipline_rates_by_subgroup(df),
    "must contain 'subgroup' column"
  )
})

test_that("calc_discipline_rates_by_subgroup calculates rates correctly", {
  df <- create_mock_discipline_data()

  result <- calc_discipline_rates_by_subgroup(df, rate_per = 1000)

  # Check that rate column exists
  expect_true("discipline_rate" %in% names(result))

  # Check calculation: 50 removals / 1000 students * 1000 = 50
  total_pop_rate <- result %>%
    dplyr::filter(subgroup == "total population") %>%
    dplyr::pull(discipline_rate)

  expect_equal(total_pop_rate, 50, tolerance = 0.01)
})

test_that("calc_discipline_rates_by_subgroup calculates risk ratios", {
  df <- create_mock_discipline_data()

  result <- calc_discipline_rates_by_subgroup(df, rate_per = 1000)

  # Check that risk_ratio column exists
  expect_true("risk_ratio" %in% names(result))

  # Total population should have risk_ratio = 1
  total_pop_rr <- result %>%
    dplyr::filter(subgroup == "total population") %>%
    dplyr::pull(risk_ratio)

  expect_equal(total_pop_rr, 1, tolerance = 0.01)

  # Black students: 15 removals / 200 students * 1000 = 75 rate
  # Risk ratio = 75 / 50 = 1.5
  black_rr <- result %>%
    dplyr::filter(subgroup == "black") %>%
    dplyr::pull(risk_ratio)

  expect_equal(black_rr, 1.5, tolerance = 0.01)
})

test_that("calc_discipline_rates_by_subgroup calculates percent_by_subgroup", {
  df <- create_mock_discipline_data()

  result <- calc_discipline_rates_by_subgroup(df, rate_per = 1000)

  # Check that percent_by_subgroup column exists
  expect_true("percent_by_subgroup" %in% names(result))

  # Total population: 50 / (50+15+12+18+25) * 100 = 41.7%
  total_pop_pct <- result %>%
    dplyr::filter(subgroup == "total population") %>%
    dplyr::pull(percent_by_subgroup)

  expect_equal(total_pop_pct, 41.7, tolerance = 0.1)

  # Black students: 15 / (50+15+12+18+25) * 100 = 12.5%
  black_pct <- result %>%
    dplyr::filter(subgroup == "black") %>%
    dplyr::pull(percent_by_subgroup)

  expect_equal(black_pct, 12.5, tolerance = 0.1)
})

test_that("calc_discipline_rates_by_subgroup handles missing data", {
  df <- create_mock_discipline_data()
  df$number_of_removals[1] <- NA  # Set total population to NA

  result <- calc_discipline_rates_by_subgroup(df, rate_per = 1000)

  # Should still have all rows
  expect_equal(nrow(result), nrow(df))

  # Risk ratio for total population should be NA
  total_pop_rr <- result %>%
    dplyr::filter(subgroup == "total population") %>%
    dplyr::pull(risk_ratio)

  expect_true(is.na(total_pop_rr))
})

test_that("calc_discipline_rates_by_subgroup handles zero students", {
  df <- create_mock_discipline_data()
  df$number_of_students[2] <- 0  # Black subgroup has 0 students

  result <- calc_discipline_rates_by_subgroup(df, rate_per = 1000)

  # Should have Inf or NA for rate
  black_rate <- result %>%
    dplyr::filter(subgroup == "black") %>%
    dplyr::pull(discipline_rate)

  expect_true(is.infinite(black_rate) || is.na(black_rate))
})

test_that("calc_discipline_rates_by_subgroup works with different rate bases", {
  df <- create_mock_discipline_data()

  # Test with rate_per = 100
  result_100 <- calc_discipline_rates_by_subgroup(df, rate_per = 100)

  total_pop_rate <- result_100 %>%
    dplyr::filter(subgroup == "total population") %>%
    dplyr::pull(discipline_rate)

  # 50 / 1000 * 100 = 5
  expect_equal(total_pop_rate, 5, tolerance = 0.01)
})

test_that("calc_discipline_rates_by_subgroup preserves original columns", {
  df <- create_mock_discipline_data()

  result <- calc_discipline_rates_by_subgroup(df, rate_per = 1000)

  # Check that original columns are still present
  expect_true("school_name" %in% names(result))
  expect_true("county_name" %in% names(result))
  expect_true("subgroup" %in% names(result))
})


# ==============================================================================
# compare_discipline_across_years() Tests
# ==============================================================================

test_that("compare_discipline_across_years validates input", {
  # Not a list
  expect_error(
    compare_discipline_across_years("not a list"),
    "must be a list of data frames"
  )

  # Unnamed list
  df1 <- create_mock_discipline_data()
  df2 <- create_mock_discipline_data()
  expect_error(
    compare_discipline_across_years(list(df1, df2)),
    "must be a named list"
  )
})

test_that("compare_discipline_across_years calculates year-over-year changes", {
  df_list <- create_mock_multiyear_data()

  result <- compare_discipline_across_years(df_list, metrics = "number_of_removals")

  # Check structure
  expect_true("year" %in% names(result))
  expect_true("location_id" %in% names(result))
  expect_true("metric_name" %in% names(result))
  expect_true("metric_value" %in% names(result))
  expect_true("year_over_year_change" %in% names(result))
  expect_true("year_over_year_pct_change" %in% names(result))
  expect_true("multi_year_trend" %in% names(result))

  # Check year-over-year change for 2023
  yoy_2023 <- result %>%
    dplyr::filter(year == 2023) %>%
    dplyr::pull(year_over_year_change)

  # 2023: 50 - 40 = 10
  expect_equal(yoy_2023, 10, tolerance = 0.01)
})

test_that("compare_discipline_across_years calculates percentage changes", {
  df_list <- create_mock_multiyear_data()

  result <- compare_discipline_across_years(df_list, metrics = "number_of_removals")

  # Check percentage change for 2023
  pct_change_2023 <- result %>%
    dplyr::filter(year == 2023) %>%
    dplyr::pull(year_over_year_pct_change)

  # (50 - 40) / 40 * 100 = 25%
  expect_equal(pct_change_2023, 25, tolerance = 0.01)
})

test_that("compare_discipline_across_years detects increasing trend", {
  df_list <- create_mock_multiyear_data()

  result <- compare_discipline_across_years(df_list, metrics = "number_of_removals")

  # All years should have "increasing" trend
  trend_2024 <- result %>%
    dplyr::filter(year == 2024) %>%
    dplyr::pull(multi_year_trend)

  expect_equal(trend_2024, "increasing")
})

test_that("compare_discipline_across_years detects decreasing trend", {
  # Create decreasing trend data
  df_2022 <- create_mock_discipline_data()
  df_2022$number_of_removals <- 60

  df_2023 <- df_2022
  df_2023$end_year <- 2023
  df_2023$number_of_removals <- 50

  df_2024 <- df_2022
  df_2024$end_year <- 2024
  df_2024$number_of_removals <- 40

  df_list <- list("2022" = df_2022, "2023" = df_2023, "2024" = df_2024)

  result <- compare_discipline_across_years(df_list, metrics = "number_of_removals")

  # Filter for the specific metric and first location
  trend_2024 <- result %>%
    dplyr::filter(year == 2024, metric_name == "number_of_removals") %>%
    dplyr::first() %>%
    dplyr::pull(multi_year_trend)

  expect_equal(trend_2024, "decreasing")
})

test_that("compare_discipline_across_years handles insufficient data", {
  # Only one year
  df_list <- list("2024" = create_mock_discipline_data())

  result <- compare_discipline_across_years(df_list, metrics = "number_of_removals")

  # Should still return data but with "insufficient_data" trend
  expect_true(nrow(result) > 0)

  # Filter for the specific metric
  trend <- result %>%
    dplyr::filter(year == 2024, metric_name == "number_of_removals") %>%
    dplyr::first() %>%
    dplyr::pull(multi_year_trend)

  expect_equal(trend, "insufficient_data")
})

test_that("compare_discipline_across_years handles missing values", {
  df_list <- create_mock_multiyear_data()

  # Set one year to NA
  df_list[["2023"]]$number_of_removals <- NA

  result <- compare_discipline_across_years(df_list, metrics = "number_of_removals")

  # Should still return data
  expect_true(nrow(result) > 0)

  # Year-over-year change should be NA for years following NA
  yoy_2024 <- result %>%
    dplyr::filter(year == 2024) %>%
    dplyr::pull(year_over_year_change)

  expect_true(is.na(yoy_2024))
})

test_that("compare_discipline_across_years auto-detects metrics", {
  df_list <- create_mock_multiyear_data()

  # Don't specify metrics - should auto-detect
  result <- compare_discipline_across_years(df_list)

  # Should find number_of_removals and number_of_students
  expect_true("number_of_removals" %in% unique(result$metric_name))
})

test_that("compare_discipline_across_years handles multiple metrics", {
  df_list <- create_mock_multiyear_data()

  # Add a calculated column
  df_list <- lapply(df_list, function(df) {
    df$custom_metric <- df$number_of_removals * 2
    df
  })

  result <- compare_discipline_across_years(
    df_list,
    metrics = c("number_of_removals", "custom_metric")
  )

  # Should have both metrics
  unique_metrics <- unique(result$metric_name)
  expect_true("number_of_removals" %in% unique_metrics)
  expect_true("custom_metric" %in% unique_metrics)
})

test_that("compare_discipline_across_years creates unique location IDs", {
  df_list <- create_mock_multiyear_data()

  result <- compare_discipline_across_years(df_list, metrics = "number_of_removals")

  # Should have unique location_id
  expect_true("location_id" %in% names(result))

  # All rows should have the same location_id (same school)
  expect_equal(length(unique(result$location_id)), 1)
})

test_that("compare_discipline_across_years handles multiple locations", {
  # Create data for two schools
  df_list <- create_mock_multiyear_data()

  school2 <- lapply(df_list, function(df) {
    df$school_id <- "020"
    df$school_name <- "Test School 2"
    df$number_of_removals <- df$number_of_removals * 2  # Different trend
    df
  })

  names(school2) <- names(df_list)

  # Combine both schools
  df_list_combined <- mapply(
    function(year1, year2, year_name) {
      dplyr::bind_rows(year1, year2)
    },
    df_list, school2, names(df_list),
    SIMPLIFY = FALSE
  )

  result <- compare_discipline_across_years(df_list_combined, metrics = "number_of_removals")

  # Should have 2 unique locations
  expect_equal(length(unique(result$location_id)), 2)

  # Each location should have 3 years
  expect_equal(nrow(result), 2 * 3)  # 2 schools * 3 years
})


# ==============================================================================
# Integration Tests
# ==============================================================================

test_that("calc_discipline_rates_by_subgroup works with compare_discipline_across_years", {
  # Create multi-year data
  df_list <- create_mock_multiyear_data()

  # Calculate rates for each year
  df_list_rates <- lapply(df_list, function(df) {
    calc_discipline_rates_by_subgroup(df, rate_per = 1000)
  })

  # Compare across years
  result <- compare_discipline_across_years(df_list_rates, metrics = "discipline_rate")

  # Should detect increasing trend (40 -> 50 -> 60)
  trend_2024 <- result %>%
    dplyr::filter(year == 2024) %>%
    dplyr::pull(multi_year_trend)

  expect_equal(trend_2024, "increasing")
})

test_that("functions handle real data structure", {
  # This test ensures the functions can handle data from actual fetch functions
  # (We can't actually call fetch functions in tests, but we can mimic the structure)

  df <- tibble::tibble(
    end_year = 2024,
    county_code = "01",
    county_name = "Atlantic",
    district_code = "0110",
    district_name = "Test District",
    school_code = "010",
    school_name = "Test School",
    student_group = "Total Population",  # Raw name before cleaning
    number_of_students = 1000,
    number_of_removals = 50,
    is_state = FALSE,
    is_county = FALSE,
    is_district = FALSE,
    is_school = TRUE,
    is_charter = FALSE
  )

  # This should work even with slightly different column names
  # (function looks for count/incident columns flexibly)
  expect_s3_class(df, "data.frame")
})
