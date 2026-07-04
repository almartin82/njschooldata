# ==============================================================================
# Tests for College & Career Readiness Data Fetching Functions
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


# ==============================================================================
# SAT/ACT Participation Tests
# ==============================================================================

test_that("fetch_sat_participation returns expected structure", {
  df <- fetch_sat_participation(2024)

  expect_true(all(spr_cols %in% names(df)))
  expect_true("sat_participation" %in% names(df))
  expect_true("act_participation" %in% names(df))
  expect_true("psat_participation" %in% names(df))
})

test_that("fetch_sat_participation works across multiple years", {
  df_2018 <- fetch_sat_participation(2018)
  df_2022 <- fetch_sat_participation(2022)

  expect_s3_class(df_2018, "data.frame")
  expect_s3_class(df_2022, "data.frame")
})


# ==============================================================================
# SAT/ACT Performance Tests
# ==============================================================================

test_that("fetch_sat_performance returns expected structure", {
  df <- fetch_sat_performance(2024)

  expect_true(all(spr_cols %in% names(df)))
  expect_true("test_type" %in% names(df))
  expect_true("school_avg" %in% names(df))
  expect_true("state_avg" %in% names(df))
})

test_that("fetch_sat_performance can filter by test type", {
  df_all <- fetch_sat_performance(2024)
  df_sat <- fetch_sat_performance(2024, test_type = "SAT")

  expect_true(nrow(df_sat) <= nrow(df_all))
  expect_true(all(df_sat$test_type %in% c("SAT", "All")))
})

test_that("fetch_sat_performance works across multiple years", {
  df_2019 <- fetch_sat_performance(2019)
  df_2023 <- fetch_sat_performance(2023)

  expect_s3_class(df_2019, "data.frame")
  expect_s3_class(df_2023, "data.frame")
})


# ==============================================================================
# AP/IB Participation Tests
# ==============================================================================

test_that("fetch_ap_participation returns expected structure", {
  df <- fetch_ap_participation(2024)

  expect_true(all(spr_cols %in% names(df)))
  expect_true("apib_exam_school" %in% names(df))
  expect_true("ap3_ib4_school" %in% names(df))
})

test_that("fetch_ap_participation includes dual enrollment", {
  df <- fetch_ap_participation(2024)

  expect_true("dual_enrollment_school" %in% names(df))
  expect_true("dual_enrollment_state" %in% names(df))
})

test_that("fetch_ap_performance is an alias for fetch_ap_participation", {
  df1 <- fetch_ap_participation(2024)
  df2 <- fetch_ap_performance(2024)

  expect_equal(names(df1), names(df2))
  expect_equal(nrow(df1), nrow(df2))
})

test_that("fetch_ap_participation works across multiple years", {
  df_2018 <- fetch_ap_participation(2018)
  df_2022 <- fetch_ap_participation(2022)

  expect_s3_class(df_2018, "data.frame")
  expect_s3_class(df_2022, "data.frame")
})

test_that("fetch_ap_participation returns the supported 2025 participation fields", {
  df <- fetch_ap_participation(2025)
  row <- df[
    df$district_id == "0110" &
      df$school_id == "010",
  ]

  expect_equal(nrow(row), 1)
  expect_equal(row$apib_coursework_school, 17.7, tolerance = 0.1)
  expect_equal(row$dual_enrollment_school, 30.6, tolerance = 0.1)
  expect_true(is.na(row$apib_exam_school))
  expect_true(is.na(row$ap3_ib4_school))
})

test_that("fetch_courses college_career handles 2025 district redesign sheets", {
  df <- fetch_courses("college_career", 2025, level = "district",
                      with_status = TRUE)

  expect_true(all(c(
    "sat_participation", "sat_performance", "ap_ib_participation",
    "cte", "industry_credentials", "work_based_learning", "apprenticeship"
  ) %in% df$course_domain))
  expect_length(setdiff(unique(df$metric), load_metric_registry()$metric), 0)
  expect_true("college_exam_benchmark_district" %in% df$metric)
  expect_true(all(!is.na(df$value_status)))
})


# ==============================================================================
# IB Participation Tests
# ==============================================================================

test_that("fetch_ib_participation returns AP/IB data", {
  df <- fetch_ib_participation(2024)

  # IB is included in AP/IB sheet
  expect_true("apib_exam_school" %in% names(df))
  expect_s3_class(df, "data.frame")
})


# ==============================================================================
# CTE Participation Tests
# ==============================================================================

test_that("fetch_cte_participation returns expected structure", {
  df <- fetch_cte_participation(2024)

  expect_true(all(spr_cols %in% names(df)))
  expect_true("subgroup" %in% names(df))
  expect_true("cte_participants" %in% names(df))
  expect_true("cte_concentrators" %in% names(df))
})

test_that("fetch_cte_participation includes subgroup data", {
  df <- fetch_cte_participation(2024)

  expect_true("subgroup" %in% names(df))
  expect_true("total population" %in% df$subgroup)
})

test_that("fetch_cte_participation works across multiple years", {
  df_2019 <- fetch_cte_participation(2019)
  df_2023 <- fetch_cte_participation(2023)

  expect_s3_class(df_2019, "data.frame")
  expect_s3_class(df_2023, "data.frame")
})


# ==============================================================================
# Industry Credentials Tests
# ==============================================================================

test_that("fetch_industry_credentials returns expected structure", {
  df <- fetch_industry_credentials(2024)

  expect_true(all(spr_cols %in% names(df)))
  expect_true("career_cluster" %in% names(df))
  expect_true("credentials_earned" %in% names(df))
})

test_that("fetch_industry_credentials has multiple career clusters", {
  df <- fetch_industry_credentials(2024)

  expect_true(length(unique(df$career_cluster)) > 1)
})

test_that("fetch_industry_credentials works across multiple years", {
  df_2018 <- fetch_industry_credentials(2018)
  df_2022 <- fetch_industry_credentials(2022)

  expect_s3_class(df_2018, "data.frame")
  expect_s3_class(df_2022, "data.frame")
})


# ==============================================================================
# Work-Based Learning Tests
# ==============================================================================

test_that("fetch_work_based_learning returns expected structure", {
  df <- fetch_work_based_learning(2024)

  expect_true(all(spr_cols %in% names(df)))
  expect_true("career_cluster" %in% names(df))
  expect_true("students_participating" %in% names(df))
})

test_that("fetch_work_based_learning has multiple career clusters", {
  df <- fetch_work_based_learning(2024)

  expect_true(length(unique(df$career_cluster)) > 1)
})

test_that("fetch_work_based_learning works across multiple years", {
  df_2019 <- fetch_work_based_learning(2019)
  df_2023 <- fetch_work_based_learning(2023)

  expect_s3_class(df_2019, "data.frame")
  expect_s3_class(df_2023, "data.frame")
})


# ==============================================================================
# Apprenticeship Tests
# ==============================================================================

test_that("fetch_apprenticeship_data returns expected structure", {
  df <- fetch_apprenticeship_data(2024)

  expect_true(all(spr_cols %in% names(df)))
  # Should have year columns (at least year_2023 for recent data)
  expect_true(any(grepl("^year_", names(df))))
})

test_that("fetch_apprenticeship_data has year columns", {
  df <- fetch_apprenticeship_data(2024)

  year_cols <- grep("^year_", names(df), value = TRUE)
  expect_true(length(year_cols) > 0)
})

test_that("fetch_apprenticeship_data works across multiple years", {
  df_2019 <- fetch_apprenticeship_data(2019)
  df_2023 <- fetch_apprenticeship_data(2023)

  expect_s3_class(df_2019, "data.frame")
  expect_s3_class(df_2023, "data.frame")
})


# ==============================================================================
# Seal of Biliteracy Tests
# ==============================================================================

test_that("fetch_biliteracy_seal returns expected structure", {
  df <- fetch_biliteracy_seal(2024)

  expect_true(all(spr_cols %in% names(df)))
  expect_true("language" %in% names(df))
  expect_true("seals_earned" %in% names(df))
})

test_that("fetch_biliteracy_seal has multiple languages", {
  df <- fetch_biliteracy_seal(2024)

  # Filter out school/state rows
  lang_rows <- df %>%
    dplyr::filter(is_school) %>%
    dplyr::filter(!is.na(language))

  expect_true(nrow(lang_rows) > 0)
})

test_that("fetch_biliteracy_seal works across multiple years", {
  df_2018 <- fetch_biliteracy_seal(2018)
  df_2022 <- fetch_biliteracy_seal(2022)

  expect_s3_class(df_2018, "data.frame")
  expect_s3_class(df_2022, "data.frame")
})


# ==============================================================================
# Integration Tests
# ==============================================================================

test_that("can combine multiple years of college readiness data", {
  df_2022 <- fetch_sat_participation(2022)
  df_2023 <- fetch_sat_participation(2023)

  combined <- dplyr::bind_rows(df_2022, df_2023)

  expect_true(length(unique(combined$end_year)) == 2)
  expect_s3_class(combined, "data.frame")
})

test_that("college readiness functions handle district level", {
  df_sat <- fetch_sat_participation(2024, level = "district")
  df_ap <- fetch_ap_participation(2024, level = "district")

  expect_true(all(df_sat$school_id == "999"))
  expect_true(all(df_ap$school_id == "999"))
})
