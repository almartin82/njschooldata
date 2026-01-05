# ==============================================================================
# Tests for SPR Data Fetching Functions
# ==============================================================================


# Expected standard columns returned by fetch_spr_data
spr_cols <- c(
  "end_year",
  "county_id", "county_name",
  "district_id", "district_name",
  "school_id", "school_name",
  "is_state", "is_county", "is_district", "is_school",
  "is_charter", "is_charter_sector", "is_allpublic"
)

# Expected columns for chronic absenteeism
ca_cols <- c(
  "end_year",
  "county_id", "county_name",
  "district_id", "district_name",
  "school_id", "school_name",
  "subgroup",
  "chronically_absent_rate",
  "is_state", "is_county", "is_district", "is_school",
  "is_charter", "is_charter_sector", "is_allpublic"
)

# Expected columns for absenteeism by grade
ca_grade_cols <- c(
  "end_year",
  "county_id", "county_name",
  "district_id", "district_name",
  "school_id", "school_name",
  "subgroup",
  "grade_level",
  "chronically_absent_rate",
  "is_state", "is_county", "is_district", "is_school",
  "is_charter", "is_charter_sector", "is_allpublic"
)


# ==============================================================================
# Generic SPR Extractor Tests
# ==============================================================================

test_that("fetch_spr_data validates year range", {
  expect_error(
    fetch_spr_data("ChronicAbsenteeism", 2016),
    "SPR data available for years 2017-2024"
  )
  expect_error(
    fetch_spr_data("ChronicAbsenteeism", 2025),
    "SPR data available for years 2017-2024"
  )
})

test_that("fetch_spr_data validates level parameter", {
  expect_error(
    fetch_spr_data("ChronicAbsenteeism", 2024, level = "invalid"),
    "level must be one of 'school' or 'district'"
  )
})

test_that("fetch_spr_data returns standard columns", {
  df <- fetch_spr_data("ChronicAbsenteeism", 2024)

  expect_true(all(spr_cols %in% names(df)))
  expect_equal(df$end_year, 2024)
})

test_that("fetch_spr_data handles school level", {
  df <- fetch_spr_data("ChronicAbsenteeism", 2024, level = "school")

  # Should have school-level data
  expect_true(any(df$is_school))

  # School file should have actual school names (not "District Total")
  school_rows <- df %>% dplyr::filter(is_school)
  expect_true(all(school_rows$school_name != "District Total"))
})

test_that("fetch_spr_data handles district level", {
  df <- fetch_spr_data("ChronicAbsenteeism", 2024, level = "district")

  # All rows should have school_id = "999"
  expect_true(all(df$school_id == "999"))

  # All rows should be district/state/county level
  expect_true(all(df$is_district | df$is_state | df$is_county))

  # School names should be "District Total"
  expect_true(all(df$school_name == "District Total"))
})

test_that("fetch_spr_data adds aggregation flags correctly", {
  df <- fetch_spr_data("ChronicAbsenteeism", 2024, level = "school")

  # Check that flags are logical
  expect_true(is.logical(df$is_state))
  expect_true(is.logical(df$is_county))
  expect_true(is.logical(df$is_district))
  expect_true(is.logical(df$is_school))
  expect_true(is.logical(df$is_charter))
})

test_that("fetch_spr_data cleans subgroup names", {
  df <- fetch_spr_data("ChronicAbsenteeism", 2024, level = "school")

  if ("subgroup" %in% names(df)) {
    # Should have standardized subgroup names
    expect_true("total population" %in% df$subgroup)

    # Should not have raw subgroup names
    expect_false("Schoolwide" %in% df$subgroup)
    expect_false("Districtwide" %in% df$subgroup)
  }
})

test_that("fetch_spr_data errors on invalid sheet name", {
  expect_error(
    fetch_spr_data("NonExistentSheet", 2024),
    "not found"
  )
})


# ==============================================================================
# Chronic Absenteeism Tests
# ==============================================================================

test_that("fetch_chronic_absenteeism returns expected structure", {
  df <- fetch_chronic_absenteeism(2024)

  expect_true(all(ca_cols %in% names(df)))
})

test_that("fetch_chronic_absenteeism works across multiple years", {
  df_2018 <- fetch_chronic_absenteeism(2018)
  df_2019 <- fetch_chronic_absenteeism(2019)
  df_2022 <- fetch_chronic_absenteeism(2022)
  df_2023 <- fetch_chronic_absenteeism(2023)
  df_2024 <- fetch_chronic_absenteeism(2024)

  expect_s3_class(df_2018, "data.frame")
  expect_s3_class(df_2019, "data.frame")
  expect_s3_class(df_2022, "data.frame")
  expect_s3_class(df_2023, "data.frame")
  expect_s3_class(df_2024, "data.frame")
})

test_that("chronic absenteeism has reasonable values", {
  df <- fetch_chronic_absenteeism(2024)

  # Chronic absenteeism rate should be 0-100 or NA
  valid_rates <- df$chronically_absent_rate[!is.na(df$chronically_absent_rate)]
  expect_true(all(valid_rates >= 0 & valid_rates <= 100))
})

test_that("fetch_chronic_absenteeism includes subgroup data", {
  df <- fetch_chronic_absenteeism(2024)

  # Should have subgroup column
  expect_true("subgroup" %in% names(df))

  # Should have total population
  expect_true("total population" %in% df$subgroup)
})


test_that("fetch_chronic_absenteeism district level works", {
  df <- fetch_chronic_absenteeism(2024, level = "district")

  # All rows should be district/state/county level
  expect_true(all(df$is_district | df$is_state | df$is_county))

  # Should have school_id = "999"
  expect_true(all(df$school_id == "999"))
})


# ==============================================================================
# Absenteeism by Grade Tests
# ==============================================================================

test_that("fetch_absenteeism_by_grade returns expected structure", {
  df <- fetch_absenteeism_by_grade(2024)

  expect_true(all(ca_grade_cols %in% names(df)))
})

test_that("fetch_absenteeism_by_grade includes grade_level", {
  df <- fetch_absenteeism_by_grade(2024)

  # Should have grade_level column
  expect_true("grade_level" %in% names(df))

  # Should have multiple grades
  expect_true(length(unique(df$grade_level)) > 1)
})


test_that("fetch_absenteeism_by_grade works across multiple years", {
  df_2018 <- fetch_absenteeism_by_grade(2018)
  df_2019 <- fetch_absenteeism_by_grade(2019)
  df_2022 <- fetch_absenteeism_by_grade(2022)

  expect_s3_class(df_2018, "data.frame")
  expect_s3_class(df_2019, "data.frame")
  expect_s3_class(df_2022, "data.frame")
})


# ==============================================================================
# Days Absent Tests
# ==============================================================================

test_that("fetch_days_absent returns expected structure", {
  df <- fetch_days_absent(2024)

  # Should have all standard columns
  expect_true(all(spr_cols %in% names(df)))

  # Should have subgroup
  expect_true("subgroup" %in% names(df))

  # Should have at least one of avg_days_absent or median_days_absent
  expect_true(
    "avg_days_absent" %in% names(df) || "median_days_absent" %in% names(df)
  )
})

test_that("fetch_days_absent works across multiple years", {
  df_2018 <- fetch_days_absent(2018)
  df_2019 <- fetch_days_absent(2019)
  df_2022 <- fetch_days_absent(2022)

  expect_s3_class(df_2018, "data.frame")
  expect_s3_class(df_2019, "data.frame")
  expect_s3_class(df_2022, "data.frame")
})


# ==============================================================================
# Caching Tests
# ==============================================================================

test_that("fetch_spr_data uses caching", {
  # Clear cache first
  njsd_cache_clear()

  # First call should be a cache miss
  df1 <- fetch_spr_data("ChronicAbsenteeism", 2024)
  cache_info_1 <- njsd_cache_info()
  expect_true(cache_info_1$misses > 0)

  # Second call should be a cache hit
  df2 <- fetch_spr_data("ChronicAbsenteeism", 2024)
  cache_info_2 <- njsd_cache_info()
  expect_true(cache_info_2$hits > 0)

  # Results should be identical
  expect_equal(nrow(df1), nrow(df2))
  expect_equal(names(df1), names(df2))
})


# ==============================================================================
# Integration Tests
# ==============================================================================

test_that("can extract multiple sheets from same year", {
  chronic <- fetch_spr_data("ChronicAbsenteeism", 2024)
  by_grade <- fetch_spr_data("ChronicAbsenteeismByGrade", 2024)
  days <- fetch_spr_data("DaysAbsent", 2024)

  expect_s3_class(chronic, "data.frame")
  expect_s3_class(by_grade, "data.frame")
  expect_s3_class(days, "data.frame")
})

test_that("chronic absenteeism functions are consistent", {
  # Using fetch_spr_data directly vs using convenience function
  df1 <- fetch_spr_data("ChronicAbsenteeism", 2024)
  df2 <- fetch_chronic_absenteeism(2024)

  # Should have same number of rows
  expect_equal(nrow(df1), nrow(df2))

  # Convenience function should have chronically_absent_rate column
  expect_true("chronically_absent_rate" %in% names(df2))
})

test_that("can combine multiple years of absenteeism data", {
  df_2022 <- fetch_chronic_absenteeism(2022)
  df_2023 <- fetch_chronic_absenteeism(2023)

  combined <- dplyr::bind_rows(df_2022, df_2023)

  # Should have data from both years
  expect_true(2022 %in% combined$end_year)
  expect_true(2023 %in% combined$end_year)

  expect_equal(length(unique(combined$end_year)), 2)
})
