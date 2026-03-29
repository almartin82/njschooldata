# TDD tests for issues #69, #125, #97
# These tests are written FIRST (red phase) before implementation.

# =============================================================================
# Issue #69: charter_sector_aggs should return the number of charters
# https://github.com/almartin82/njschooldata/issues/69
#
# Enrollment aggs already have n_schools. The gap is that PARCC, graduation
# rate, graduation count, and matric aggregation functions calculate
# n_charter_rows internally but don't expose it in the output.
# =============================================================================

test_that("grate_column_order includes n_schools column", {
  # Graduation rate aggregations should include a school count column
  # so users know how many schools contributed to the aggregate.
  col_fn_source <- readLines("../../R/graduation_aggs.R", warn = FALSE)
  grate_section <- paste(col_fn_source, collapse = "\n")

  expect_true(
    grepl("n_schools", grate_section),
    info = "grate_column_order should include n_schools column"
  )
})

test_that("gcount_column_order includes n_schools column", {
  col_fn_source <- readLines("../../R/graduation_aggs.R", warn = FALSE)
  expect_true(
    grepl("n_schools", paste(col_fn_source, collapse = "\n")),
    info = "gcount_column_order should include n_schools column"
  )
})

test_that("grate_aggregate_calcs returns n_schools", {
  # Create minimal test data matching the structure grate_aggregate_calcs expects
  test_data <- data.frame(
    host_district_id = c("3570", "3570", "3570"),
    district_name = c("School A", "School B", "School C"),
    school_name = c("School A", "School B", "School C"),
    grad_rate = c(0.85, 0.90, 0.88),
    cohort_count = c(100, 150, 120),
    graduated_count = c(85, 135, 106),
    is_charter = c(TRUE, TRUE, TRUE),
    stringsAsFactors = FALSE
  )

  result <- test_data %>%
    dplyr::group_by(host_district_id) %>%
    grate_aggregate_calcs()

  expect_true("n_schools" %in% names(result),
    info = "grate_aggregate_calcs should return n_schools column")
  expect_equal(result$n_schools, 3)
})

test_that("gcount_aggregate_calcs returns n_schools", {
  test_data <- data.frame(
    host_district_id = c("3570", "3570"),
    district_name = c("School A", "School B"),
    school_name = c("School A", "School B"),
    cohort_count = c(100, 150),
    graduated_count = c(85, 135),
    is_charter = c(TRUE, TRUE),
    stringsAsFactors = FALSE
  )

  result <- test_data %>%
    dplyr::group_by(host_district_id) %>%
    gcount_aggregate_calcs()

  expect_true("n_schools" %in% names(result),
    info = "gcount_aggregate_calcs should return n_schools column")
  expect_equal(result$n_schools, 2)
})

test_that("parcc_aggregate_calcs returns n_schools", {
  test_data <- data.frame(
    host_district_id = c("3570", "3570", "3570"),
    district_name = c("School A", "School B", "School C"),
    school_name = c("School A", "School B", "School C"),
    number_enrolled = c(100, 150, 120),
    number_not_tested = c(5, 10, 8),
    number_of_valid_scale_scores = c(95, 140, 112),
    scale_score_mean = c(750, 760, 755),
    pct_l1 = c(10, 8, 9),
    pct_l2 = c(20, 18, 19),
    pct_l3 = c(30, 32, 31),
    pct_l4 = c(25, 27, 26),
    pct_l5 = c(15, 15, 15),
    is_charter = c(TRUE, TRUE, TRUE),
    stringsAsFactors = FALSE
  )

  # parcc_aggregate_calcs expects perf level counts from parcc_perf_level_counts
  test_data <- parcc_perf_level_counts(test_data)

  result <- test_data %>%
    dplyr::group_by(host_district_id) %>%
    parcc_aggregate_calcs()

  expect_true("n_schools" %in% names(result),
    info = "parcc_aggregate_calcs should return n_schools column")
  expect_equal(result$n_schools, 3)
})


# =============================================================================
# Issue #125: county ids to names for sped data
# https://github.com/almartin82/njschooldata/issues/125
#
# Need a county_name_to_id() function that maps NJ county names to their
# 2-digit county codes. This is used to fill missing county_id in historic
# SPED data that only has county_name.
# =============================================================================

test_that("county_name_to_id maps all 21 NJ counties", {
  # All 21 NJ counties should be mappable
  counties <- c(
    "Atlantic", "Bergen", "Burlington", "Camden", "Cape May",
    "Cumberland", "Essex", "Gloucester", "Hudson", "Hunterdon",
    "Mercer", "Middlesex", "Monmouth", "Morris", "Ocean",
    "Passaic", "Salem", "Somerset", "Sussex", "Union", "Warren"
  )

  result <- county_name_to_id(counties)

  expect_equal(length(result), 21)
  expect_true(all(nchar(result) == 2),
    info = "All county IDs should be 2-digit zero-padded strings")
  expect_true(all(!is.na(result)),
    info = "All 21 standard NJ counties should map to an ID")
})

test_that("county_name_to_id returns correct codes for known counties", {
  expect_equal(county_name_to_id("Atlantic"), "01")
  expect_equal(county_name_to_id("Essex"), "07")
  expect_equal(county_name_to_id("Hudson"), "09")
  expect_equal(county_name_to_id("Warren"), "21")
})

test_that("county_name_to_id handles case insensitivity", {
  expect_equal(county_name_to_id("atlantic"), "01")
  expect_equal(county_name_to_id("ESSEX"), "07")
  expect_equal(county_name_to_id("Bergen"), "02")
})

test_that("county_name_to_id handles special categories", {
  # Charter schools use county code 80, state aggregate uses 99
  expect_equal(county_name_to_id("Charter Schools"), "80")
  expect_equal(county_name_to_id("State"), "99")
})

test_that("county_name_to_id returns NA for unknown counties", {
  expect_true(is.na(county_name_to_id("Fake County")))
  expect_true(is.na(county_name_to_id("")))
})

test_that("clean_sped_df fills county_id from county_name when missing", {
  # Simulate historic SPED data with county_name but no county_id
  test_data <- data.frame(
    end_year = c(2024, 2024, 2024),
    county_name = c("Essex", "Hudson", "Bergen"),
    district_id = c("3570", "2280", "0100"),
    district_name = c("Newark", "Jersey City", "Hackensack"),
    gened_num = c(1000, 800, 600),
    sped_num = c(150, 120, 90),
    sped_rate = c(15.0, 15.0, 15.0),
    stringsAsFactors = FALSE
  )

  result <- clean_sped_df(test_data, 2024)

  expect_true("county_id" %in% names(result),
    info = "clean_sped_df should add county_id even when not in source data")
  expect_equal(result$county_id, c("07", "09", "02"))
})


# =============================================================================
# Issue #97: collapse/clean up schools and districts field when aggregating
# https://github.com/almartin82/njschooldata/issues/97
#
# Current: "School A, School A, School A, School B, School B"
# Target:  "School A (3), School B (2)"
# =============================================================================

test_that("collapse_names deduplicates and counts repeated names", {
  input <- c("School A", "School A", "School A",
             "School B", "School B")
  result <- collapse_names(input)

  expect_true(grepl("School A \\(3\\)", result))
  expect_true(grepl("School B \\(2\\)", result))
  expect_false(grepl("School A, School A", result),
    info = "Should not have repeated names")
})

test_that("collapse_names handles single occurrence without count", {
  input <- c("School A", "School B", "School C")
  result <- collapse_names(input)

  # Single occurrences should not have a count suffix
  expect_equal(result, "School A, School B, School C")
})

test_that("collapse_names handles single school", {
  input <- c("Only School")
  result <- collapse_names(input)
  expect_equal(result, "Only School")
})

test_that("collapse_names handles all same school", {
  input <- c("Same School", "Same School", "Same School")
  result <- collapse_names(input)
  expect_equal(result, "Same School (3)")
})

test_that("grate_aggregate_calcs uses collapse_names for schools", {
  test_data <- data.frame(
    host_district_id = c("3570", "3570", "3570"),
    district_name = c("Newark", "Newark", "Newark"),
    school_name = c("School A", "School A", "School B"),
    grad_rate = c(0.85, 0.90, 0.88),
    cohort_count = c(100, 150, 120),
    graduated_count = c(85, 135, 106),
    is_charter = c(TRUE, TRUE, TRUE),
    stringsAsFactors = FALSE
  )

  result <- test_data %>%
    dplyr::group_by(host_district_id) %>%
    grate_aggregate_calcs()

  # Should use deduplicated format, not raw toString
  expect_true(grepl("School A \\(2\\)", result$schools),
    info = "Repeated school names should be collapsed with counts")
  expect_true(grepl("School B", result$schools))
  expect_false(grepl("School A, School A", result$schools),
    info = "Should not have raw repeated names")
})

test_that("parcc_aggregate_calcs uses collapse_names for schools", {
  test_data <- data.frame(
    host_district_id = c("3570", "3570"),
    district_name = c("Newark", "Newark"),
    school_name = c("Same School", "Same School"),
    number_enrolled = c(100, 150),
    number_not_tested = c(5, 10),
    number_of_valid_scale_scores = c(95, 140),
    scale_score_mean = c(750, 760),
    pct_l1 = c(10, 8), pct_l2 = c(20, 18), pct_l3 = c(30, 32),
    pct_l4 = c(25, 27), pct_l5 = c(15, 15),
    is_charter = c(TRUE, TRUE),
    stringsAsFactors = FALSE
  )

  test_data <- parcc_perf_level_counts(test_data)

  result <- test_data %>%
    dplyr::group_by(host_district_id) %>%
    parcc_aggregate_calcs()

  expect_equal(result$schools, "Same School (2)")
})
