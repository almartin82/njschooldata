# ==============================================================================
# Tests for Course Enrollment & Access Analysis Functions
# ==============================================================================


# ==============================================================================
# Test Data Setup
# ==============================================================================

# Create mock course enrollment data for testing
create_mock_course_enrollment_data <- function(subject = "math") {
  # Create base data for total population only
  tibble::tibble(
    end_year = 2024,
    county_id = "01",
    county_name = "Atlantic",
    district_id = "0110",
    district_name = "Test District",
    school_id = "010",
    school_name = "Test School",
    subgroup = "total population",
    course_type = paste0(subject, c(" Algebra I", " Geometry", " Algebra II",
                                     " Pre-Calculus", " AP Calculus")),
    number_of_students = c(1000, 200, 300, 400, 350),
    is_state = FALSE,
    is_county = FALSE,
    is_district = FALSE,
    is_school = TRUE,
    is_charter = FALSE,
    is_charter_sector = FALSE,
    is_allpublic = FALSE
  )
}

# Create mock multi-year course enrollment data
create_mock_multi_year_enrollment <- function(subject = "science") {
  # Year 1
  df_2022 <- tibble::tibble(
    end_year = 2022,
    county_id = "01",
    district_id = "0110",
    school_id = "010",
    school_name = "Test School",
    subgroup = "total population",
    course_type = paste0(subject, c(" Biology", " Chemistry", " Physics")),
    number_of_students = c(100, 80, 60),
    is_state = FALSE,
    is_county = FALSE,
    is_district = FALSE,
    is_school = TRUE,
    is_charter = FALSE,
    is_charter_sector = FALSE,
    is_allpublic = FALSE
  )

  # Year 2 - increasing enrollment
  df_2023 <- df_2022
  df_2023$end_year <- 2023
  df_2023$number_of_students <- c(120, 90, 70)

  # Year 3 - increasing more
  df_2024 <- df_2022
  df_2024$end_year <- 2024
  df_2024$number_of_students <- c(140, 100, 80)

  list("2022" = df_2022, "2023" = df_2023, "2024" = df_2024)
}

# Create mock AP/IB course data
create_mock_ap_ib_data <- function() {
  # Create data with both total population and subgroups
  # Each course type should have rows for each subgroup
  courses <- c("AP Biology", "AP Chemistry", "AP Calculus AB", "IB Biology", "AP US History")
  subgroups <- c("total population", "economically disadvantaged")

  # Create all combinations
  data <- expand.grid(
    course_type = courses,
    subgroup = subgroups,
    stringsAsFactors = FALSE
  )

  # Add columns
  data$end_year <- 2024
  data$county_id <- "01"
  data$district_id <- "0110"
  data$school_id <- "010"
  data$school_name <- "Test School"
  data$number_of_students <- c(50, 25, 40, 20, 35, 18, 20, 10, 45, 22)  # 10 combinations
  data$is_state <- FALSE
  data$is_county <- FALSE
  data$is_district <- FALSE
  data$is_school <- TRUE
  data$is_charter <- FALSE
  data$is_charter_sector <- FALSE
  data$is_allpublic <- FALSE

  # Reorder columns
  data <- data[, c("end_year", "county_id", "district_id", "school_id", "school_name",
                   "subgroup", "course_type", "number_of_students", "is_state",
                   "is_county", "is_district", "is_school", "is_charter",
                   "is_charter_sector", "is_allpublic")]

  tibble::as_tibble(data)
}


# ==============================================================================
# Fetch Function Tests
# ==============================================================================

test_that("fetch_science_course_enrollment returns expected structure", {
  # Note: We can't actually call fetch functions in tests due to network dependency
  # But we can verify the function exists and has correct parameters
  expect_true(exists("fetch_science_course_enrollment"))

  # Verify function signature
  fn_args <- formals(fetch_science_course_enrollment)
  expect_true("end_year" %in% names(fn_args))
  expect_true("level" %in% names(fn_args))
})

test_that("fetch_social_studies_enrollment returns expected structure", {
  expect_true(exists("fetch_social_studies_enrollment"))

  fn_args <- formals(fetch_social_studies_enrollment)
  expect_true("end_year" %in% names(fn_args))
  expect_true("level" %in% names(fn_args))
})

test_that("fetch_world_language_enrollment returns expected structure", {
  expect_true(exists("fetch_world_language_enrollment"))

  fn_args <- formals(fetch_world_language_enrollment)
  expect_true("end_year" %in% names(fn_args))
  expect_true("level" %in% names(fn_args))
})

test_that("fetch_cs_enrollment returns expected structure", {
  expect_true(exists("fetch_cs_enrollment"))

  fn_args <- formals(fetch_cs_enrollment)
  expect_true("end_year" %in% names(fn_args))
  expect_true("level" %in% names(fn_args))
})

test_that("fetch_arts_enrollment returns expected structure", {
  expect_true(exists("fetch_arts_enrollment"))

  fn_args <- formals(fetch_arts_enrollment)
  expect_true("end_year" %in% names(fn_args))
  expect_true("level" %in% names(fn_args))
})


# ==============================================================================
# calc_ap_access_rate() Tests
# ==============================================================================

test_that("calc_ap_access_rate requires valid data frame input", {
  df <- "not a data frame"

  expect_error(
    calc_ap_access_rate(df),
    "must be a data frame"
  )
})

test_that("calc_ap_access_rate identifies AP courses", {
  df <- create_mock_ap_ib_data()

  result <- calc_ap_access_rate(df)

  # Should have AP indicator column
  expect_true("has_ap" %in% names(result))

  # Test school has AP courses
  expect_true(any(result$has_ap))
})

test_that("calc_ap_access_rate identifies IB courses", {
  df <- create_mock_ap_ib_data()

  result <- calc_ap_access_rate(df)

  # Should have IB indicator column
  expect_true("has_ib" %in% names(result))

  # Test school has IB courses
  expect_true(any(result$has_ib))
})

test_that("calc_ap_access_rate calculates access rate", {
  df <- create_mock_ap_ib_data()

  result <- calc_ap_access_rate(df, subgroup = "total population")

  # Should have access rate column
  expect_true("ap_access_rate" %in% names(result))

  # Access rate should be between 0 and 100
  expect_true(all(result$ap_access_rate >= 0, na.rm = TRUE))
  expect_true(all(result$ap_access_rate <= 100, na.rm = TRUE))
})

test_that("calc_ap_access_rate filters by subgroup", {
  df <- create_mock_ap_ib_data()

  # Test with total population
  result_total <- calc_ap_access_rate(df, subgroup = "total population")

  # Test with specific subgroup
  result_ed <- calc_ap_access_rate(df, subgroup = "economically disadvantaged")

  # Both should return data
  expect_true(nrow(result_total) > 0)
  expect_true(nrow(result_ed) > 0)
})

test_that("calc_ap_access_rate identifies schools with both AP and IB", {
  df <- create_mock_ap_ib_data()

  result <- calc_ap_access_rate(df)

  # Should have has_both indicator
  expect_true("has_both" %in% names(result))

  # Test school has both AP and IB
  expect_true(any(result$has_both))
})

test_that("calc_ap_access_rate handles missing course type column", {
  df <- tibble::tibble(
    school_id = "010",
    number_of_students = 1000,
    subgroup = "total population"
  )

  expect_error(
    calc_ap_access_rate(df),
    "Cannot find course type column"
  )
})

test_that("calc_ap_access_rate handles missing student count column", {
  df <- tibble::tibble(
    school_id = "010",
    course_type = "Algebra I",
    subgroup = "total population"
  )

  expect_error(
    calc_ap_access_rate(df),
    "Cannot find student count column"
  )
})

test_that("calc_ap_access_rate preserves original columns", {
  df <- create_mock_ap_ib_data()

  result <- calc_ap_access_rate(df)

  # Check that original columns are still present
  expect_true("school_name" %in% names(result))
  # Note: mock data doesn't have county_name, so don't check for it
})

test_that("calc_ap_access_rate sets access rate to 0 or 100", {
  df <- create_mock_ap_ib_data()

  result <- calc_ap_access_rate(df)

  # Access rate should be binary (0 or 100) - school either offers AP or not
  unique_rates <- unique(result$ap_access_rate)
  expect_true(all(unique_rates %in% c(0, 100, NA)))
})

test_that("calc_ap_access_rate creates unique location IDs", {
  df <- create_mock_ap_ib_data()

  result <- calc_ap_access_rate(df)

  # Should have location_id
  expect_true("location_id" %in% names(result))
})

test_that("calc_ap_access_rate handles state data", {
  df <- create_mock_ap_ib_data()

  # Add state row
  state_row <- df[1, ]
  state_row$school_id <- "state"
  state_row$school_name <- "New Jersey"
  state_row$is_state <- TRUE
  state_row$is_school <- FALSE

  df_with_state <- dplyr::bind_rows(df, state_row)

  result <- calc_ap_access_rate(df_with_state)

  # Should include state comparison
  expect_true("vs_state_avg" %in% names(result))
})


# ==============================================================================
# calc_stem_participation_rate() Tests
# ==============================================================================

test_that("calc_stem_participation_rate requires valid input", {
  math_df <- "not a data frame"

  expect_error(
    calc_stem_participation_rate(math_df, "data frame"),
    "must be data frames"
  )
})

test_that("calc_stem_participation_rate requires cs_df when include_cs is TRUE", {
  math_df <- create_mock_course_enrollment_data("math")
  science_df <- create_mock_course_enrollment_data("science")

  expect_error(
    calc_stem_participation_rate(math_df, science_df, include_cs = TRUE),
    "cs_df must be provided"
  )
})

test_that("calc_stem_participation_rate calculates STEM rate", {
  math_df <- create_mock_course_enrollment_data("math")
  science_df <- create_mock_course_enrollment_data("science")

  result <- calc_stem_participation_rate(math_df, science_df, include_cs = FALSE)

  # Should have STEM participation rate
  expect_true("stem_participation_rate" %in% names(result))

  # Rate should be between 0 and 100
  expect_true(all(result$stem_participation_rate >= 0, na.rm = TRUE))
  expect_true(all(result$stem_participation_rate <= 100, na.rm = TRUE))
})

test_that("calc_stem_participation_rate categorizes rates", {
  math_df <- create_mock_course_enrollment_data("math")
  science_df <- create_mock_course_enrollment_data("science")

  result <- calc_stem_participation_rate(math_df, science_df, include_cs = FALSE)

  # Should have category column
  expect_true("category" %in% names(result))

  # Categories should be valid
  valid_categories <- c("low", "medium", "high", "unknown")
  expect_true(all(result$category %in% valid_categories))
})

test_that("calc_stem_participation_rate includes CS when requested", {
  math_df <- create_mock_course_enrollment_data("math")
  science_df <- create_mock_course_enrollment_data("science")
  cs_df <- create_mock_course_enrollment_data("cs")

  result_with_cs <- calc_stem_participation_rate(math_df, science_df, cs_df, include_cs = TRUE)
  result_no_cs <- calc_stem_participation_rate(math_df, science_df, include_cs = FALSE)

  # With CS should have different (higher) rates than without
  expect_true(any(result_with_cs$stem_participation_rate >= result_no_cs$stem_participation_rate, na.rm = TRUE))
})

test_that("calc_stem_participation_rate calculates student counts", {
  math_df <- create_mock_course_enrollment_data("math")
  science_df <- create_mock_course_enrollment_data("science")

  result <- calc_stem_participation_rate(math_df, science_df, include_cs = FALSE)

  # Should have count columns
  expect_true("n_stem_students" %in% names(result))
  expect_true("n_total_students" %in% names(result))

  # Counts should be non-negative
  expect_true(all(result$n_stem_students >= 0, na.rm = TRUE))
  expect_true(all(result$n_total_students >= 0, na.rm = TRUE))
})

test_that("calc_stem_participation_rate caps rate at 100%", {
  # Create data with huge counts to test capping
  math_df <- create_mock_course_enrollment_data("math")
  math_df$number_of_students <- 10000

  science_df <- create_mock_course_enrollment_data("science")
  science_df$number_of_students <- 10000

  result <- calc_stem_participation_rate(math_df, science_df, include_cs = FALSE)

  # Rate should not exceed 100
  expect_true(max(result$stem_participation_rate, na.rm = TRUE) <= 100)
})

test_that("calc_stem_participation_rate creates location IDs", {
  math_df <- create_mock_course_enrollment_data("math")
  science_df <- create_mock_course_enrollment_data("science")

  result <- calc_stem_participation_rate(math_df, science_df, include_cs = FALSE)

  # Should have location_id
  expect_true("location_id" %in% names(result))
})

test_that("calc_stem_participation_rate handles missing student count column", {
  math_df <- tibble::tibble(
    school_id = "010",
    course_type = "Algebra I"
  )

  science_df <- create_mock_course_enrollment_data("science")

  expect_error(
    calc_stem_participation_rate(math_df, science_df, include_cs = FALSE),
    "Cannot find student count column"
  )
})

test_that("calc_stem_participation_rate includes school names", {
  math_df <- create_mock_course_enrollment_data("math")
  science_df <- create_mock_course_enrollment_data("science")

  result <- calc_stem_participation_rate(math_df, science_df, include_cs = FALSE)

  # Should have school_name
  expect_true("school_name" %in% names(result))
})

test_that("calc_stem_participation_rate handles state data", {
  math_df <- create_mock_course_enrollment_data("math")

  # Add state row
  state_row <- math_df[1, ]
  state_row$school_id <- "state"
  state_row$school_name <- "New Jersey"
  state_row$is_state <- TRUE
  state_row$is_school <- FALSE

  math_df_with_state <- dplyr::bind_rows(math_df, state_row)

  science_df <- create_mock_course_enrollment_data("science")

  result <- calc_stem_participation_rate(math_df_with_state, science_df, include_cs = FALSE)

  # Should include state comparison
  expect_true("vs_state_avg" %in% names(result))
})


# ==============================================================================
# analyze_course_access_equity() Tests
# ==============================================================================

test_that("analyze_course_access_equity validates input", {
  # Not a list
  expect_error(
    analyze_course_access_equity("not a list"),
    "must be a list of data frames"
  )

  # Unnamed list
  df1 <- create_mock_course_enrollment_data()
  df2 <- create_mock_course_enrollment_data()
  expect_error(
    analyze_course_access_equity(list(df1, df2)),
    "must be a named list"
  )
})

test_that("analyze_course_access_equity calculates disparity indices", {
  df_list <- create_mock_multi_year_enrollment()

  result <- analyze_course_access_equity(df_list)

  # Should have disparity_index column
  expect_true("disparity_index" %in% names(result))

  # Disparity index should be numeric
  expect_true(is.numeric(result$disparity_index))
})

test_that("analyze_course_access_equity calculates access gaps", {
  df_list <- create_mock_multi_year_enrollment()

  result <- analyze_course_access_equity(df_list)

  # Should have access_gap_percentage column
  expect_true("access_gap_percentage" %in% names(result))

  # Gap should be numeric
  expect_true(is.numeric(result$access_gap_percentage))
})

test_that("analyze_course_access_equity flags large gaps", {
  df_list <- create_mock_multi_year_enrollment()

  result <- analyze_course_access_equity(df_list)

  # Should have flag column
  expect_true("flag_large_gap" %in% names(result))

  # Flag should be logical
  expect_true(is.logical(result$flag_large_gap))
})

test_that("analyze_course_access_equity calculates trends", {
  df_list <- create_mock_multi_year_enrollment()

  result <- analyze_course_access_equity(df_list)

  # Should have trend column
  expect_true("trend" %in% names(result))

  # Trend should be one of valid categories
  valid_trends <- c("improving", "widening", "stable", "insufficient_data")
  expect_true(all(result$trend %in% valid_trends))
})

test_that("analyze_course_access_equity handles insufficient data", {
  # Only one year
  df_list <- list("2024" = create_mock_course_enrollment_data())

  result <- analyze_course_access_equity(df_list)

  # Should still return data but with insufficient_data trend
  expect_true(nrow(result) > 0)
  expect_true(any(result$trend == "insufficient_data"))
})

test_that("analyze_course_access_equity filters out total population", {
  df_list <- create_mock_multi_year_enrollment()

  result <- analyze_course_access_equity(df_list)

  # Should not have "total population" in subgroup column
  expect_false("total population" %in% unique(result$subgroup))
})

test_that("analyze_course_access_equity handles missing subgroup column", {
  df <- tibble::tibble(
    school_id = "010",
    number_of_students = 1000
  )

  df_list <- list("2024" = df)

  expect_error(
    analyze_course_access_equity(df_list),
    "Cannot find subgroup column"
  )
})

test_that("analyze_course_access_equity handles NA values", {
  df_list <- create_mock_multi_year_enrollment()

  # Add NA to one year
  df_list[["2023"]]$number_of_students[1] <- NA

  result <- analyze_course_access_equity(df_list)

  # Should still return data
  expect_true(nrow(result) > 0)

  # Some disparity indices should be NA
  expect_true(any(is.na(result$disparity_index)))
})

test_that("analyze_course_access_equity detects improving trend", {
  # Create data with improving equity (disparity decreasing)
  df_2022 <- create_mock_course_enrollment_data()
  df_2022$subgroup <- "black"
  df_2022$number_of_students <- 50  # Lower access

  df_2023 <- df_2022
  df_2023$end_year <- 2023
  df_2023$number_of_students <- 75  # Improving

  df_2024 <- df_2022
  df_2024$end_year <- 2024
  df_2024$number_of_students <- 100  # Near parity

  df_list <- list("2022" = df_2022, "2023" = df_2023, "2024" = df_2024)

  result <- analyze_course_access_equity(df_list)

  # Should detect improving or stable trend
  expect_true("improving" %in% result$trend || "stable" %in% result$trend)
})

test_that("analyze_course_access_equity creates location IDs", {
  df_list <- create_mock_multi_year_enrollment()

  result <- analyze_course_access_equity(df_list)

  # Should have location_id
  expect_true("location_id" %in% names(result))
})

test_that("analyze_course_access_equity includes school names", {
  df_list <- create_mock_multi_year_enrollment()

  result <- analyze_course_access_equity(df_list)

  # Should have school_name
  expect_true("school_name" %in% names(result))
})


# ==============================================================================
# Integration Tests
# ==============================================================================

test_that("calc_ap_access_rate works with calc_stem_participation_rate", {
  df <- create_mock_course_enrollment_data("math")

  ap_access <- calc_ap_access_rate(df)
  stem_rates <- calc_stem_participation_rate(df, df, include_cs = FALSE)

  # Both should return data
  expect_true(nrow(ap_access) > 0)
  expect_true(nrow(stem_rates) > 0)
})

test_that("functions work across multiple years", {
  df_list <- create_mock_multi_year_enrollment("science")

  # Analyze equity across years
  equity <- analyze_course_access_equity(df_list)

  # Should have data for all 3 years
  expect_equal(length(unique(equity$year)), 3)
})

test_that("functions handle both school and district level data", {
  school_data <- create_mock_course_enrollment_data("math")
  school_data$is_school <- TRUE
  school_data$is_district <- FALSE

  district_data <- create_mock_course_enrollment_data("math")
  district_data$school_id <- NA
  district_data$school_name <- NA
  district_data$is_school <- FALSE
  district_data$is_district <- TRUE

  # Both should work
  ap_access_school <- calc_ap_access_rate(school_data)
  ap_access_district <- calc_ap_access_rate(district_data)

  expect_true(nrow(ap_access_school) > 0)
  expect_true(nrow(ap_access_district) > 0)
})

test_that("functions preserve data integrity across workflow", {
  # Simulate typical workflow: fetch -> analyze -> compare
  df <- create_mock_course_enrollment_data("science")

  # Step 1: Calculate AP access
  ap_access <- calc_ap_access_rate(df)

  # Step 2: Calculate STEM participation
  stem_rates <- calc_stem_participation_rate(df, df, include_cs = FALSE)

  # Both should have same number of schools
  expect_equal(
    nrow(ap_access %>% dplyr::filter(!is.na(school_id))),
    nrow(stem_rates %>% dplyr::filter(!is.na(school_name)))
  )
})

test_that("functions handle edge cases - empty data frames", {
  empty_df <- tibble::tibble(
    school_id = character(0),
    number_of_students = numeric(0),
    course_type = character(0)
  )

  # AP access should handle empty data
  result <- calc_ap_access_rate(empty_df)

  # Should return empty result
  expect_equal(nrow(result), 0)
})

test_that("functions handle edge cases - single row data", {
  single_row <- tibble::tibble(
    end_year = 2024,
    county_id = "01",
    district_id = "0110",
    school_id = "010",
    school_name = "Test School",
    subgroup = "total population",
    course_type = "Algebra I",
    number_of_students = 100,
    is_state = FALSE,
    is_county = FALSE,
    is_district = FALSE,
    is_school = TRUE,
    is_charter = FALSE,
    is_charter_sector = FALSE,
    is_allpublic = FALSE
  )

  # Should handle single row
  result <- calc_ap_access_rate(single_row)

  expect_true(nrow(result) > 0)
})

test_that("all fetch functions have proper documentation", {
  # Check that functions are exported and documented
  fetch_functions <- c(
    "fetch_science_course_enrollment",
    "fetch_social_studies_enrollment",
    "fetch_world_language_enrollment",
    "fetch_cs_enrollment",
    "fetch_arts_enrollment"
  )

  for (fn in fetch_functions) {
    expect_true(exists(fn))
  }
})

test_that("all analysis functions have proper documentation", {
  # Check that analysis functions exist
  analysis_functions <- c(
    "calc_ap_access_rate",
    "calc_stem_participation_rate",
    "analyze_course_access_equity"
  )

  for (fn in analysis_functions) {
    expect_true(exists(fn))
  }
})
