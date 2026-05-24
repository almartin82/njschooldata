# ==============================================================================
# Tests for Student Growth Percentile (SGP) Fetcher
# ==============================================================================
#
# Live-network tests for fetch_sgp(), which reads NJ median Student Growth
# Percentile (mSGP) data from the redesigned 2024-25 SPR databases.
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
# default 60s download timeout for the duration of the calling test so the
# large-file fetches do not trip a transient timeout. Restores on test exit.
local_big_download_timeout <- function(seconds = 600, env = parent.frame()) {
  old <- getOption("timeout")
  options(timeout = seconds)
  withr::defer(options(timeout = old), envir = env)
  invisible(old)
}


# ==============================================================================
# Argument validation (no network)
# ==============================================================================

test_that("fetch_sgp rejects invalid type", {
  expect_error(
    fetch_sgp(2025, type = "nonsense"),
    "type must be one of"
  )
})

test_that("fetch_sgp gates each type at its real first year (no fabrication)", {
  # COVID gap: NJ produced no SGP for SY2019-20..SY2021-22 (any type).
  expect_error(fetch_sgp(2020, type = "trends"), "COVID")
  expect_error(fetch_sgp(2021, type = "by_grade"), "COVID")
  expect_error(fetch_sgp(2022, type = "by_performance_level"), "COVID")
  # trends omits SY2016-17 (the sheet has no county/district name columns).
  expect_error(fetch_sgp(2017, type = "trends"), "end_year >= 2018")
  # by_grade omits SY2016-17 (the sheet has no county/district name columns).
  expect_error(fetch_sgp(2017, type = "by_grade"), "end_year >= 2018")
  # by_performance_level before 2023 is a different statistic (growth-band
  # percentage distribution by PARCC level), not a median SGP.
  expect_error(
    fetch_sgp(2019, type = "by_performance_level"),
    "different statistic"
  )
})


# ==============================================================================
# type = "trends" (StudentGrowthTrends)
# ==============================================================================

test_that("fetch_sgp trends returns expected structure (school)", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_sgp(2025, type = "trends")

  expect_s3_class(df, "data.frame")
  expect_gt(nrow(df), 0)
  expect_true(all(spr_cols %in% names(df)))
  expect_true(all(c(
    "subgroup",
    "ela_median_sgp", "ela_median_sgp_category",
    "ela_median_sgp_state", "ela_median_sgp_state_category",
    "math_median_sgp", "math_median_sgp_category",
    "math_median_sgp_state", "math_median_sgp_state_category"
  ) %in% names(df)))

  # Subgroup labels are standardized via clean_spr_subgroups()
  expect_true("total population" %in% df$subgroup)

  # mSGP value columns are numeric and in the 1-99 percentile range (or NA)
  expect_type(df$ela_median_sgp, "double")
  vals <- df$ela_median_sgp[!is.na(df$ela_median_sgp)]
  expect_true(all(vals >= 1 & vals <= 99))
})

test_that("fetch_sgp trends district level flags state and district rows", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_sgp(2025, level = "district", type = "trends")

  expect_true(all(df$school_id == "999"))
  expect_true(any(df$is_state))
  expect_true(any(df$is_district))
})

test_that("fetch_sgp trends values match the raw NJ DOE file", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_sgp(2025, type = "trends")

  ref <- df %>%
    dplyr::filter(
      county_id == "01", district_id == "0010", school_id == "050",
      subgroup == "total population"
    )

  expect_equal(nrow(ref), 1)
  # Pinned from StudentGrowthTrends, SchoolYear 2024-25, All Students:
  #   ELA_..._School = 55, Math_..._School = 61, ELA_..._State = 50
  expect_equal(ref$ela_median_sgp, 55)
  expect_equal(ref$math_median_sgp, 61)
  expect_equal(ref$ela_median_sgp_state, 50)
})


# ==============================================================================
# type = "by_grade" (StudentGrowthbyGrade)
# ==============================================================================

test_that("fetch_sgp by_grade returns expected structure", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_sgp(2025, type = "by_grade")

  expect_s3_class(df, "data.frame")
  expect_gt(nrow(df), 0)
  expect_true(all(spr_cols %in% names(df)))
  expect_true(all(c("subject", "grade", "median_sgp", "median_sgp_category") %in% names(df)))

  expect_true(all(c("ELA", "Math") %in% df$subject))
  expect_type(df$median_sgp, "double")
})

test_that("fetch_sgp by_grade preserves half-point medians from the raw file", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_sgp(2025, type = "by_grade")

  ref <- df %>%
    dplyr::filter(
      county_id == "01", district_id == "0010", school_id == "050",
      subject == "ELA", grade == "Grade 6"
    )

  expect_equal(nrow(ref), 1)
  # Pinned: Emma C Attales ELA Grade 6 mSGP = 58.5 (half-point preserved)
  expect_equal(ref$median_sgp, 58.5)
})


# ==============================================================================
# type = "by_performance_level" (StudentGrowthByPerformLevel)
# ==============================================================================

test_that("fetch_sgp by_performance_level returns expected structure", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_sgp(2025, type = "by_performance_level")

  expect_s3_class(df, "data.frame")
  expect_gt(nrow(df), 0)
  expect_true(all(spr_cols %in% names(df)))
  expect_true(all(c("subject", "njsla_performance_level", "median_sgp", "median_sgp_category") %in% names(df)))

  # NJSLA performance levels run 1-5
  expect_true(any(grepl("Performance Level", df$njsla_performance_level)))
})


# ==============================================================================
# Pre-2025 backfill (legacy StudentGrowthByGrade / StudentGrowthByPerformLevel)
# ==============================================================================
#
# Pinned against the NJ DOE District/State workbooks; reference district is
# Absecon (county 01, district 0010). by_grade is backfilled to 2018, 2019,
# 2023, 2024; by_performance_level to 2023, 2024.

test_that("fetch_sgp by_grade backfill matches the raw legacy file (2024)", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_sgp(2024, level = "district", type = "by_grade")

  expect_true(all(c(
    "subject", "grade", "median_sgp", "median_sgp_category"
  ) %in% names(df)))
  expect_true(all(c("ELA", "Math") %in% df$subject))

  ref <- df %>%
    dplyr::filter(district_id == "0010", subject == "ELA", grade == "Grade 6")
  expect_equal(nrow(ref), 1)
  # Pinned from StudentGrowthByGrade SY2023-24: mSGP 74.5, Level "High".
  expect_equal(ref$median_sgp, 74.5)
  expect_equal(ref$median_sgp_category, "High")
})

test_that("fetch_sgp by_grade has no growth category before 2023", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_sgp(2019, level = "district", type = "by_grade")

  # The 2018-19 sheet carries no Level column; category is NA, medians are real.
  expect_true(all(is.na(df$median_sgp_category)))
  expect_true(any(!is.na(df$median_sgp)))
})

test_that("fetch_sgp by_performance_level backfill matches the raw file (2024)", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_sgp(2024, level = "district", type = "by_performance_level")

  ref <- df %>%
    dplyr::filter(
      district_id == "0010", subject == "ELA",
      njsla_performance_level == "Performance Level 1"
    )
  expect_equal(nrow(ref), 1)
  # Pinned from StudentGrowthByPerformLevel SY2023-24: mSGP 54, Level "Typical".
  expect_equal(ref$median_sgp, 54)
  expect_equal(ref$median_sgp_category, "Typical")
})

test_that("fetch_sgp by_performance_level normalizes the level label (2023)", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_sgp(2023, level = "district", type = "by_performance_level")
  expect_true(all(grepl("Performance Level", unique(df$njsla_performance_level))))
})


# ==============================================================================
# Pre-2025 trends backfill (legacy StudentGrowth subgroup sheet)
# ==============================================================================
#
# trends is backfilled to 2018, 2019, 2023, 2024. Legacy sheets carry MetTarget
# (preserved in ela/math_met_target) and have NA *_category. The school file
# mislabels its subgroup column "SchoolYear"; the reshaper handles it.

test_that("fetch_sgp trends backfill matches the raw file, district (2024)", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_sgp(2024, level = "district", type = "trends")

  expect_true(all(c(
    "subgroup",
    "ela_median_sgp", "ela_median_sgp_state", "ela_met_target",
    "math_median_sgp", "math_median_sgp_state", "math_met_target"
  ) %in% names(df)))
  # Legacy years predate the growth-category labels.
  expect_true(all(is.na(df$ela_median_sgp_category)))

  ref <- df %>%
    dplyr::filter(district_id == "0010", subgroup == "total population")
  expect_equal(nrow(ref), 1)  # one row per entity per subgroup (ELA/Math pivoted)
  # Pinned from StudentGrowth SY2023-24, Districtwide:
  expect_equal(ref$ela_median_sgp, 55)
  expect_equal(ref$ela_median_sgp_state, 50)
  expect_equal(ref$ela_met_target, "Met Standard")
})

test_that("fetch_sgp trends backfill keeps school subgroups (mislabeled column)", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_sgp(2024, level = "school", type = "trends")

  # The school sheet's subgroup column is mislabeled "SchoolYear"; the reshaper
  # recovers the full subgroup breakdown rather than collapsing to total.
  expect_gt(length(unique(df$subgroup)), 5)

  ref <- df %>%
    dplyr::filter(
      county_id == "01", district_id == "0010", school_id == "050",
      subgroup == "total population"
    )
  expect_equal(nrow(ref), 1)
  # Entity median is the school's own (SchoolMedian = 59 for Emma C Attales ELA).
  expect_equal(ref$ela_median_sgp, 59)
  expect_equal(ref$ela_median_sgp_state, 50)
})

test_that("fetch_sgp trends backfill matches the raw file, district (2019)", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_sgp(2019, level = "district", type = "trends")

  ref <- df %>%
    dplyr::filter(district_id == "0010", subgroup == "total population")
  expect_equal(nrow(ref), 1)
  # Pinned from StudentGrowth SY2018-19, Districtwide ELA: 39 / state 50 / Not Met.
  expect_equal(ref$ela_median_sgp, 39)
  expect_equal(ref$ela_met_target, "Not Met")
})
