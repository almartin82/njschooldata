# ==============================================================================
# Tests for fetch_police_notifications() and fetch_hib_investigations()
# ==============================================================================
#
# Live-network tests for SPR PoliceNotifications and HIBInvestigations sheets.
# Both sheets exist in NJ DOE SPR databases for end_year 2018-2025 in both the
# School (Database_SchoolDetail.xlsx) and District/State
# (Database_DistrictStateDetail.xlsx) workbooks. They are absent from the
# SY2016-17 (end_year 2017) databases.
#
# Pinned values are verified against the published NJ DOE SPR workbooks at:
#   https://www.nj.gov/education/sprreports/download/DataFiles/
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
local_big_download_timeout <- function(seconds = 1200, env = parent.frame()) {
  old <- getOption("timeout")
  options(timeout = seconds)
  withr::defer(options(timeout = old), envir = env)
  invisible(old)
}


# ==============================================================================
# Argument validation (no network)
# ==============================================================================

test_that("fetch_police_notifications rejects pre-2018 years", {
  # PoliceNotifications sheet is absent from the SY2016-17 SPR databases.
  expect_error(fetch_police_notifications(2017), "end_year >= 2018")
})

test_that("fetch_hib_investigations rejects pre-2018 years", {
  # HIBInvestigations sheet is absent from the SY2016-17 SPR databases.
  expect_error(fetch_hib_investigations(2017), "end_year >= 2018")
})

test_that("fetch_police_notifications rejects invalid level", {
  expect_error(
    fetch_police_notifications(2024, level = "invalid"),
    "level must be one of 'school' or 'district'"
  )
})

test_that("fetch_hib_investigations rejects invalid level", {
  expect_error(
    fetch_hib_investigations(2024, level = "invalid"),
    "level must be one of 'school' or 'district'"
  )
})


# ==============================================================================
# fetch_police_notifications() — structure / schema
# ==============================================================================

test_that("fetch_police_notifications returns expected structure (district, 2024)", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_police_notifications(2024, level = "district")

  expect_s3_class(df, "data.frame")
  expect_gt(nrow(df), 0)
  expect_true(all(spr_cols %in% names(df)))

  # The six standardized incident-category columns (legacy + redesign harmonized).
  expect_true(all(c(
    "violence", "weapons", "vandalism", "substances", "hib", "other_incidents"
  ) %in% names(df)))

  # Counts must be numeric (suppression -> NA, real counts preserved).
  expect_type(df$violence, "double")
  expect_type(df$weapons, "double")
  expect_type(df$vandalism, "double")
  expect_type(df$substances, "double")
  expect_type(df$hib, "double")
  expect_type(df$other_incidents, "double")

  # No negative counts.
  for (col in c("violence", "weapons", "vandalism", "substances", "hib",
                "other_incidents")) {
    vals <- df[[col]][!is.na(df[[col]])]
    expect_true(all(vals >= 0), info = paste("negative values in", col))
  }
})

test_that("fetch_police_notifications district file has state, county, and district rows", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_police_notifications(2024, level = "district")

  # Exactly one state aggregate row.
  expect_equal(sum(df$is_state), 1)
  # Many district rows.
  expect_gt(sum(df$is_district), 100)
  # District file: school_id is always "999" (the District-Total sentinel).
  expect_true(all(df$school_id == "999"))
})

test_that("fetch_police_notifications district state row equals sum of district rows", {
  # Sanity: in the District/State workbook the State aggregate equals the
  # statewide sum of district-level counts. Pinned to violence (the largest
  # category) for a tight aggregation check.
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_police_notifications(2024, level = "district")

  state_violence <- df$violence[df$is_state]
  district_sum <- sum(df$violence[df$is_district], na.rm = TRUE)

  expect_equal(state_violence, district_sum)
})

test_that("fetch_police_notifications 2025 harmonizes 'hib' column from redesign", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_police_notifications(2025, level = "district")

  expect_true("hib" %in% names(df))
  # The legacy long name must not leak through.
  expect_false("harassment_intimidation_bullying_hib" %in% names(df))
  # 2025 sheet carries a school_year column; it should be preserved.
  expect_true("school_year" %in% names(df))
})

test_that("fetch_police_notifications 2018 (legacy) harmonizes 'hib' column", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_police_notifications(2018, level = "district")

  # Legacy column 'harassment_intimidation_bullying_hib' must be renamed to 'hib'.
  expect_true("hib" %in% names(df))
  expect_false("harassment_intimidation_bullying_hib" %in% names(df))
})

test_that("fetch_police_notifications pinned values match NJ DOE workbook (2024)", {
  # Pinned against PoliceNotifications, District/State workbook SY2023-24, Atlantic
  # City School District (county 01, district 0110), district-total row.
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_police_notifications(2024, level = "district") %>%
    dplyr::filter(county_id == "01", district_id == "0110", is_district)

  expect_equal(nrow(df), 1)
  expect_equal(df$violence, 13)
  expect_equal(df$weapons, 6)
  expect_equal(df$vandalism, 2)
})


# ==============================================================================
# fetch_hib_investigations() — structure / schema
# ==============================================================================

test_that("fetch_hib_investigations returns expected structure (district, 2024)", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_hib_investigations(2024, level = "district")

  expect_s3_class(df, "data.frame")
  expect_gt(nrow(df), 0)
  expect_true(all(spr_cols %in% names(df)))

  # The four HIB-specific columns.
  expect_true(all(c(
    "hib_nature", "hib_alleged", "hib_confirmed", "total_hib_investigations"
  ) %in% names(df)))

  # Count columns must be numeric.
  expect_type(df$hib_alleged, "double")
  expect_type(df$hib_confirmed, "double")
  expect_type(df$total_hib_investigations, "double")

  # No negative counts.
  for (col in c("hib_alleged", "hib_confirmed", "total_hib_investigations")) {
    vals <- df[[col]][!is.na(df[[col]])]
    expect_true(all(vals >= 0), info = paste("negative values in", col))
  }
})

test_that("fetch_hib_investigations exposes the 8 HIB nature categories", {
  # HIBInvestigations is long-format: one row per (entity x hib_nature). The
  # canonical eight nature categories are the same across every year.
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_hib_investigations(2024, level = "district")

  expected_natures <- c(
    "Ancestry", "Disability", "Gender", "No Identified Nature", "Other",
    "Race", "Religion", "Sexual Orientation"
  )
  expect_setequal(unique(df$hib_nature), expected_natures)
})

test_that("fetch_hib_investigations district state rows approximately sum the district rows", {
  # Sanity: state-level total_hib_investigations per nature should be very close
  # to the sum of district-level rows for the same nature. NJ DOE's state
  # aggregate occasionally diverges from the bottom-up sum by a handful of
  # incidents (likely small-cell suppression or late-arriving counts), so this
  # asserts agreement within 1% rather than exact equality.
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_hib_investigations(2024, level = "district")

  state_by_nature <- df %>%
    dplyr::filter(is_state) %>%
    dplyr::select(hib_nature, state_total = total_hib_investigations)
  dist_sum <- df %>%
    dplyr::filter(is_district) %>%
    dplyr::group_by(hib_nature) %>%
    dplyr::summarise(district_sum = sum(total_hib_investigations, na.rm = TRUE),
                     .groups = "drop")
  joined <- dplyr::inner_join(state_by_nature, dist_sum, by = "hib_nature")

  expect_equal(nrow(joined), 8)
  # Absolute and relative agreement (within 1% of the state total).
  rel_diff <- abs(joined$state_total - joined$district_sum) /
    pmax(joined$state_total, 1)
  expect_true(all(rel_diff < 0.01),
              info = sprintf("max rel diff: %.4f", max(rel_diff)))
})

test_that("fetch_hib_investigations 2025 preserves school_year column", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_hib_investigations(2025, level = "district")

  expect_true("school_year" %in% names(df))
  expect_true(all(df$school_year == "2024-25"))
})


# ==============================================================================
# Multi-year smoke tests (district level only — school DB is 350+ MB)
# ==============================================================================

test_that("fetch_police_notifications works across the supported year range", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  for (yr in c(2018, 2019, 2024, 2025)) {
    df <- fetch_police_notifications(yr, level = "district")
    expect_s3_class(df, "data.frame")
    expect_gt(nrow(df), 0)
    expect_true(all(spr_cols %in% names(df)))
    expect_true("hib" %in% names(df))
    expect_true(all(df$end_year == yr))
  }
})

test_that("fetch_hib_investigations works across the supported year range", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  for (yr in c(2018, 2019, 2024, 2025)) {
    df <- fetch_hib_investigations(yr, level = "district")
    expect_s3_class(df, "data.frame")
    expect_gt(nrow(df), 0)
    expect_true(all(spr_cols %in% names(df)))
    expect_true(all(c("hib_nature", "hib_alleged", "hib_confirmed",
                      "total_hib_investigations") %in% names(df)))
    expect_true(all(df$end_year == yr))
  }
})
