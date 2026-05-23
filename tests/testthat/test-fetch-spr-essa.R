# ==============================================================================
# Tests for ESSA Accountability Suite Fetchers
# ==============================================================================
#
# Live-network tests for the redesigned 2024-25 SPR ESSA accountability sheets:
#   fetch_spr_essa_targets()            (6 long-term-goal target sheets)
#   fetch_spr_accountability_summative()
#   fetch_spr_tsi()
#   fetch_spr_essa_status_counts()
#
# Pinned values verified against the NJ DOE 2024-25 SPR workbooks at:
#   https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/
# Reference school: Absecon (county 01, district 0010), Emma C Attales (school
# 050), All Students (-> "total population"), SY2024-25.
#
# ==============================================================================

spr_cols <- c(
  "end_year",
  "county_id", "county_name",
  "district_id", "district_name",
  "school_id", "school_name",
  "is_state", "is_county", "is_district", "is_school",
  "is_charter", "is_charter_sector", "is_allpublic"
)

# The 2024-25 School DB is ~352 MB and the District DB ~114 MB; raise R's
# default 60s download timeout for the duration of the calling test.
local_big_download_timeout <- function(seconds = 600, env = parent.frame()) {
  old <- getOption("timeout")
  options(timeout = seconds)
  withr::defer(options(timeout = old), envir = env)
  invisible(old)
}


# ==============================================================================
# Argument validation (no network)
# ==============================================================================

test_that("fetch_spr_essa_targets rejects invalid indicator", {
  expect_error(
    fetch_spr_essa_targets(2025, indicator = "nonsense"),
    "indicator must be one of"
  )
})

test_that("ESSA suite errors (does not fabricate) for pre-2025 years", {
  expect_error(fetch_spr_essa_targets(2024), "end_year >= 2025")
  expect_error(fetch_spr_accountability_summative(2024), "end_year >= 2025")
  expect_error(fetch_spr_tsi(2023), "end_year >= 2025")
  expect_error(fetch_spr_essa_status_counts(2020), "end_year >= 2025")
})


# ==============================================================================
# fetch_spr_essa_targets()
# ==============================================================================

test_that("fetch_spr_essa_targets proficiency returns expected structure", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_spr_essa_targets(2025, indicator = "proficiency")

  expect_s3_class(df, "data.frame")
  expect_gt(nrow(df), 0)
  expect_true(all(spr_cols %in% names(df)))
  expect_true(all(c(
    "subgroup", "indicator", "measure", "indicator_performance",
    "annual_target", "long_term_goal", "target_status"
  ) %in% names(df)))

  # `indicator` is the constant request label; `measure` is the sheet breakdown.
  expect_true(all(df$indicator == "proficiency"))
  expect_true(all(c("ELA Proficiency", "Math Proficiency") %in% df$measure))

  # Value columns are numeric; percentages live on a 0-100 scale.
  expect_type(df$indicator_performance, "double")
  vals <- df$indicator_performance[!is.na(df$indicator_performance)]
  expect_true(all(vals >= 0 & vals <= 100))
})

test_that("fetch_spr_essa_targets proficiency values match the raw NJ DOE file", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  ref <- fetch_spr_essa_targets(2025, indicator = "proficiency") %>%
    dplyr::filter(
      county_id == "01", district_id == "0010", school_id == "050",
      subgroup == "total population", measure == "ELA Proficiency"
    )

  expect_equal(nrow(ref), 1)
  # Pinned from ProficiencyTargets, SY2024-25, All Students, ELA Proficiency:
  expect_equal(ref$indicator_performance, 56.2)
  expect_equal(ref$annual_target, 52.4)
  expect_equal(ref$long_term_goal, 59.2)
  expect_equal(ref$target_status, "Met Target")
})

test_that("fetch_spr_essa_targets growth uses state-standard columns (numeric, no %)", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_spr_essa_targets(2025, indicator = "growth")

  # Growth sheet has state_standard_growth + target_status, no annual/goal cols.
  expect_true("state_standard_growth" %in% names(df))
  expect_false("annual_target" %in% names(df))
  expect_false("long_term_goal" %in% names(df))

  ref <- df %>%
    dplyr::filter(
      county_id == "01", district_id == "0010", school_id == "050",
      subgroup == "total population", measure == "ELA Growth"
    )
  expect_equal(nrow(ref), 1)
  # Pinned: ELA Growth performance = 55, state standard = 40.
  expect_equal(ref$indicator_performance, 55)
  expect_equal(ref$state_standard_growth, 40)
})

test_that("fetch_spr_essa_targets variants expose the right indicator columns", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  expect_true("target_state_average" %in%
    names(fetch_spr_essa_targets(2025, indicator = "absenteeism")))

  # Persistence is performance-only: no target/status columns.
  persist <- fetch_spr_essa_targets(2025, indicator = "persistence")
  expect_false("target_status" %in% names(persist))
  expect_false("annual_target" %in% names(persist))
  expect_true("indicator_performance" %in% names(persist))
})

test_that("fetch_spr_essa_targets district level flags state and district rows", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_spr_essa_targets(2025, indicator = "graduation", level = "district")

  expect_true(all(df$school_id == "999"))
  expect_true(any(df$is_state))
  expect_true(any(df$is_district))
})


# ==============================================================================
# fetch_spr_accountability_summative()
# ==============================================================================

test_that("fetch_spr_accountability_summative returns expected structure", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_spr_accountability_summative(2025)

  expect_s3_class(df, "data.frame")
  expect_gt(nrow(df), 0)
  expect_true(all(spr_cols %in% names(df)))
  expect_true(all(c(
    "subgroup", "title_i", "school_configuration",
    "summative_score", "summative_rating",
    "ela_proficiency_actual_performance", "math_proficiency_indicator_score"
  ) %in% names(df)))

  # Performance/score columns are numeric; label columns stay character.
  expect_type(df$summative_score, "double")
  expect_type(df$title_i, "character")
})

test_that("fetch_spr_accountability_summative values match the raw NJ DOE file", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  ref <- fetch_spr_accountability_summative(2025) %>%
    dplyr::filter(
      county_id == "01", district_id == "0010", school_id == "050",
      subgroup == "total population"
    )

  expect_equal(nrow(ref), 1)
  # Pinned: Emma C Attales summative score = 54.60; ELA proficiency actual = 56.2%.
  expect_equal(ref$summative_score, 54.60)
  expect_equal(ref$ela_proficiency_actual_performance, 56.2)
  expect_equal(ref$title_i, "Yes")
})


# ==============================================================================
# fetch_spr_tsi()
# ==============================================================================

test_that("fetch_spr_tsi returns expected structure with normalized names", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_spr_tsi(2025)

  expect_s3_class(df, "data.frame")
  expect_gt(nrow(df), 0)
  expect_true(all(spr_cols %in% names(df)))
  expect_true(all(c(
    "identified_for_tsi", "tsi_criteria_met",
    "all_targets_not_met_below_status_2425",
    "subgroup", "indicator", "actual_value_2425", "target_2425"
  ) %in% names(df)))

  # identified_for_tsi is a Yes/No flag; value columns are numeric.
  expect_true(all(c("Yes", "No") %in% df$identified_for_tsi))
  expect_type(df$actual_value_2425, "double")
})

test_that("fetch_spr_tsi identifies at least one school for TSI", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  identified <- fetch_spr_tsi(2025) %>%
    dplyr::filter(identified_for_tsi == "Yes") %>%
    dplyr::distinct(county_id, district_id, school_id)

  expect_gt(nrow(identified), 0)
})


# ==============================================================================
# fetch_spr_essa_status_counts()
# ==============================================================================

test_that("fetch_spr_essa_status_counts returns expected structure", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_spr_essa_status_counts(2025)

  expect_s3_class(df, "data.frame")
  expect_gt(nrow(df), 0)
  expect_true(all(spr_cols %in% names(df)))
  expect_true(all(c(
    "comprehensive_csi", "additional_targeted_atsi", "targeted_tsi"
  ) %in% names(df)))

  # District/state file -> school columns are filled with the district sentinel.
  expect_true(all(df$school_id == "999"))
  expect_type(df$comprehensive_csi, "double")
})

test_that("fetch_spr_essa_status_counts statewide totals match the raw file", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  st <- fetch_spr_essa_status_counts(2025) %>%
    dplyr::filter(is_state)

  expect_equal(nrow(st), 1)
  # Pinned from ESSAAccountabilityStatusCounts, statewide row (SY2024-25):
  expect_equal(st$comprehensive_csi, 99)
  expect_equal(st$additional_targeted_atsi, 65)
  expect_equal(st$targeted_tsi, 7)
})
