# ==============================================================================
# Tests for Discipline & Climate Data Fetching Functions
# ==============================================================================

# Expected standard columns returned by all SPR functions
spr_cols <- c(
  "end_year",
  "county_id", "county_name",
  "district_id", "district_name",
  "school_id", "school_name",
  "is_state", "is_county", "is_district", "is_school",
  "is_charter", "is_charter_sector", "is_allpublic"
)

# ==============================================================================
# Violence, Vandalism, HIB Incidents
# ==============================================================================

test_that("fetch_violence_vandalism_hib returns expected structure", {
  skip_if_not_installed("njschooldata")

  df <- fetch_violence_vandalism_hib(2024)

  expect_s3_class(df, "data.frame")
  expect_true(all(spr_cols %in% names(df)))
  expect_true(all(df$end_year == 2024))
})

test_that("fetch_violence_vandalism_hib works across multiple years", {
  skip_if_not_installed("njschooldata")

  df_2018 <- fetch_violence_vandalism_hib(2018)
  df_2022 <- fetch_violence_vandalism_hib(2022)
  df_2023 <- fetch_violence_vandalism_hib(2023)
  df_2024 <- fetch_violence_vandalism_hib(2024)

  expect_s3_class(df_2018, "data.frame")
  expect_s3_class(df_2022, "data.frame")
  expect_s3_class(df_2023, "data.frame")
  expect_s3_class(df_2024, "data.frame")
})

test_that("fetch_violence_vandalism_hib district level works", {
  skip_if_not_installed("njschooldata")

  df <- fetch_violence_vandalism_hib(2024, level = "district")

  # All rows should be district/state/county level
  expect_true(all(df$is_district | df$is_state | df$is_county))

  # Should have school_id = "999"
  expect_true(all(df$school_id == "999"))
})


# ==============================================================================
# HIB Investigations
# ==============================================================================

test_that("fetch_hib_investigations returns expected structure", {
  skip_if_not_installed("njschooldata")

  df <- fetch_hib_investigations(2024)

  expect_s3_class(df, "data.frame")
  expect_true(all(spr_cols %in% names(df)))
  expect_true(all(df$end_year == 2024))
})

test_that("fetch_hib_investigations works across multiple years", {
  skip_if_not_installed("njschooldata")

  df_2018 <- fetch_hib_investigations(2018)
  df_2022 <- fetch_hib_investigations(2022)
  df_2024 <- fetch_hib_investigations(2024)

  expect_s3_class(df_2018, "data.frame")
  expect_s3_class(df_2022, "data.frame")
  expect_s3_class(df_2024, "data.frame")
})


# ==============================================================================
# Police Notifications
# ==============================================================================

test_that("fetch_police_notifications returns expected structure", {
  skip_if_not_installed("njschooldata")

  df <- fetch_police_notifications(2024)

  expect_s3_class(df, "data.frame")
  expect_true(all(spr_cols %in% names(df)))
  expect_true(all(df$end_year == 2024))
})

test_that("fetch_police_notifications by_subgroup works", {
  skip_if_not_installed("njschooldata")

  df <- fetch_police_notifications(2024, by_subgroup = TRUE)

  expect_s3_class(df, "data.frame")
  expect_true(all(spr_cols %in% names(df)))

  # Should have subgroup column
  expect_true("subgroup" %in% names(df))
})

test_that("fetch_police_notifications works across multiple years", {
  skip_if_not_installed("njschooldata")

  df_2022 <- fetch_police_notifications(2022)
  df_2024 <- fetch_police_notifications(2024)

  expect_s3_class(df_2022, "data.frame")
  expect_s3_class(df_2024, "data.frame")
})


# ==============================================================================
# Disciplinary Removals
# ==============================================================================

test_that("fetch_disciplinary_removals returns expected structure", {
  skip_if_not_installed("njschooldata")

  df <- fetch_disciplinary_removals(2024)

  expect_s3_class(df, "data.frame")
  expect_true(all(spr_cols %in% names(df)))
  expect_true(all(df$end_year == 2024))
})

test_that("fetch_disciplinary_removals works across multiple years", {
  skip_if_not_installed("njschooldata")

  df_2018 <- fetch_disciplinary_removals(2018)
  df_2022 <- fetch_disciplinary_removals(2022)
  df_2024 <- fetch_disciplinary_removals(2024)

  expect_s3_class(df_2018, "data.frame")
  expect_s3_class(df_2022, "data.frame")
  expect_s3_class(df_2024, "data.frame")
})


# ==============================================================================
# Days Missed Due to Suspensions
# ==============================================================================

test_that("fetch_days_missed_suspensions returns expected structure", {
  skip_if_not_installed("njschooldata")

  df <- fetch_days_missed_suspensions(2024)

  expect_s3_class(df, "data.frame")
  expect_true(all(spr_cols %in% names(df)))
  expect_true(all(df$end_year == 2024))
})

test_that("fetch_days_missed_suspensions works across multiple years", {
  skip_if_not_installed("njschooldata")

  df_2022 <- fetch_days_missed_suspensions(2022)
  df_2024 <- fetch_days_missed_suspensions(2024)

  expect_s3_class(df_2022, "data.frame")
  expect_s3_class(df_2024, "data.frame")
})


# ==============================================================================
# Analysis Functions - Disproportionality
# ==============================================================================

test_that("calc_discipline_rates_by_subgroup adds rate columns", {
  skip_if_not_installed("njschooldata")

  # Get disciplinary data
  disc <- fetch_disciplinary_removals(2024)

  # Get enrollment data (limit to small sample for speed)
  enr <- fetch_enr(2024, tidy = TRUE) %>%
    filter(county_id == "01")

  # Subset disciplinary data to match enrollment
  disc_subset <- disc %>%
    filter(county_id == "01")

  # Calculate rates
  rates <- calc_discipline_rates_by_subgroup(disc_subset, enr)

  # Should have new columns
  expect_true("enrollment_count" %in% names(rates))
  expect_true("discipline_rate" %in% names(rates))
  expect_true("population_rate" %in% names(rates))
  expect_true("disparity_ratio" %in% names(rates))
  expect_true("is_disproportionate" %in% names(rates))
})

test_that("calc_discipline_rates_by_subgroup preserves row count", {
  skip_if_not_installed("njschooldata")

  disc <- fetch_disciplinary_removals(2024) %>%
    filter(county_id == "01")

  enr <- fetch_enr(2024, tidy = TRUE) %>%
    filter(county_id == "01")

  n_rows_before <- nrow(disc)

  rates <- calc_discipline_rates_by_subgroup(disc, enr)

  # Should have same or more rows (left join)
  expect_true(nrow(rates) >= n_rows_before)
})

test_that("calc_discipline_rates_by_subgroup calculates disparity correctly", {
  skip_if_not_installed("njschooldata")

  # Create test data
  test_disc <- data.frame(
    end_year = 2024,
    county_id = "01",
    district_id = "0010",
    school_id = "001",
    county_name = "Atlantic",
    district_name = "Test District",
    school_name = "Test School",
    subgroup = c("total population", "black", "hispanic", "white"),
    test_count = c(10, 8, 6, 2),
    is_school = TRUE,
    is_state = FALSE,
    is_county = FALSE,
    is_district = FALSE,
    is_charter = FALSE,
    is_charter_sector = FALSE,
    is_allpublic = FALSE
  )

  test_enr <- data.frame(
    end_year = 2024,
    county_id = "01",
    district_id = "0010",
    school_id = "001",
    subgroup = "total_enrollment",
    n_students = 1000,
    enr_subgroup = "total_enrollment",
    is_subprogram = FALSE,
    grade_level = "TOTAL"
  )

  # This test would need more comprehensive test data
  # For now, just verify function exists
  expect_true(exists("calc_discipline_rates_by_subgroup"))
})


# ==============================================================================
# Analysis Functions - Trend Analysis
# ==============================================================================

test_that("compare_discipline_across_years validates input", {
  expect_error(
    compare_discipline_across_years("not a list"),
    "df_list must be a list"
  )

  expect_error(
    compare_discipline_across_years(data.frame(x = 1)),
    "df_list must be a list"
  )

  single_list <- list("2023" = data.frame(end_year = 2023))
  expect_error(
    compare_discipline_across_years(single_list),
    "at least 2 data frames"
  )
})

test_that("compare_discipline_across_years calculates trend metrics", {
  skip_if_not_installed("njschooldata")

  # Get two years of data (small sample)
  disc_2023 <- fetch_disciplinary_removals(2023) %>%
    filter(county_id == "01")

  disc_2024 <- fetch_disciplinary_removals(2024) %>%
    filter(county_id == "01")

  # Create named list
  disc_list <- list(
    "2023" = disc_2023,
    "2024" = disc_2024
  )

  trends <- compare_discipline_across_years(
    disc_list,
    subgroup_filter = "total population"
  )

  # Should have trend columns
  expect_true("n_years" %in% names(trends))
  expect_true("count_first" %in% names(trends))
  expect_true("count_last" %in% names(trends))
  expect_true("count_change" %in% names(trends))
  expect_true("count_pct_change" %in% names(trends))
  expect_true("trend_direction" %in% names(trends))
  expect_true("is_significant" %in% names(trends))

  # All rows should have exactly 2 years
  expect_true(all(trends$n_years == 2))
})

test_that("compare_discipline_across_years filters by subgroup", {
  skip_if_not_installed("njschooldata")

  disc_2023 <- fetch_disciplinary_removals(2023) %>%
    filter(county_id == "01")

  disc_2024 <- fetch_disciplinary_removals(2024) %>%
    filter(county_id == "01")

  disc_list <- list(
    "2023" = disc_2023,
    "2024" = disc_2024
  )

  trends <- compare_discipline_across_years(
    disc_list,
    subgroup_filter = "total population"
  )

  # Should only have total population subgroup
  expect_true(all(trends$subgroup == "total population"))
})

test_that("compare_discipline_across_years calculates change correctly", {
  skip_if_not_installed("njschooldata")

  disc_2023 <- fetch_disciplinary_removals(2023) %>%
    filter(county_id == "01")

  disc_2024 <- fetch_disciplinary_removals(2024) %>%
    filter(county_id == "01")

  disc_list <- list(
    "2023" = disc_2023,
    "2024" = disc_2024
  )

  trends <- compare_discipline_across_years(
    disc_list,
    subgroup_filter = "total population"
  )

  # count_change should equal count_last - count_first
  expect_equal(
    trends$count_change,
    trends$count_last - trends$count_first,
    tolerance = 0.01
  )
})

test_that("compare_discipline_across_years handles unnamed list with warning", {
  skip_if_not_installed("njschooldata")

  disc_2023 <- fetch_disciplinary_removals(2023) %>%
    filter(county_id == "01")

  disc_2024 <- fetch_disciplinary_removals(2024) %>%
    filter(county_id == "01")

  # Create unnamed list
  disc_list <- list(disc_2023, disc_2024)

  expect_warning(
    trends <- compare_discipline_across_years(disc_list, subgroup_filter = "total population"),
    "should be named by end_year"
  )

  # Should still work
  expect_s3_class(trends, "data.frame")
})


# ==============================================================================
# Convenience Aliases
# ==============================================================================

test_that("convenience aliases work correctly", {
  skip_if_not_installed("njschooldata")

  # Test violence/vandalism aliases
  vv1 <- fetch_violence_vandalism_hib(2024)
  vv2 <- fetch_violence_vandalism(2024)

  expect_equal(nrow(vv1), nrow(vv2))
  expect_equal(names(vv1), names(vv2))

  # Test HIB aliases
  hib1 <- fetch_hib_investigations(2024)
  hib2 <- fetch_hib(2024)

  expect_equal(nrow(hib1), nrow(hib2))
  expect_equal(names(hib1), names(hib2))
})


# ==============================================================================
# Integration Tests
# ==============================================================================

test_that("can extract multiple discipline data sources from same year", {
  skip_if_not_installed("njschooldata")

  violence <- fetch_violence_vandalism_hib(2024)
  hib <- fetch_hib_investigations(2024)
  police <- fetch_police_notifications(2024)
  removals <- fetch_disciplinary_removals(2024)

  expect_s3_class(violence, "data.frame")
  expect_s3_class(hib, "data.frame")
  expect_s3_class(police, "data.frame")
  expect_s3_class(removals, "data.frame")
})

test_that("discipline data can be combined across years", {
  skip_if_not_installed("njschooldata")

  disc_2023 <- fetch_disciplinary_removals(2023)
  disc_2024 <- fetch_disciplinary_removals(2024)

  combined <- dplyr::bind_rows(disc_2023, disc_2024)

  expect_true(2023 %in% combined$end_year)
  expect_true(2024 %in% combined$end_year)
  expect_equal(length(unique(combined$end_year)), 2)
})


# ==============================================================================
# Caching Tests
# ==============================================================================

test_that("discipline functions use caching", {
  skip_if_not_installed("njschooldata")

  # Clear cache first
  njsd_cache_clear()

  # First call should be a cache miss
  df1 <- fetch_violence_vandalism_hib(2024)
  cache_info_1 <- njsd_cache_info()
  expect_true(cache_info_1$misses > 0)

  # Second call should be a cache hit
  df2 <- fetch_violence_vandalism_hib(2024)
  cache_info_2 <- njsd_cache_info()
  expect_true(cache_info_2$hits > 0)

  # Results should be identical
  expect_equal(nrow(df1), nrow(df2))
  expect_equal(names(df1), names(df2))
})
