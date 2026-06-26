# ==============================================================================
# Tests for fetch_school_day() and fetch_device_ratios()
# ==============================================================================
#
# Live-network tests for the SPR SchoolDay and DeviceRatios sheets (school
# workbook only). Pinned values are verified by hand against the published NJ
# DOE SPR workbooks at:
#   https://www.nj.gov/education/sprreports/download/DataFiles/
#
# Anchor entity (stable across years): Atlantic City High School,
#   county_id "01", district_id "0110", school_id "010".
#   SchoolDay length_of_day reads "6 Hrs[.] 25 Mins[.]" (= 385 minutes) in
#   every year 2017-2025; instruction_full_time reads "5 Hrs. 40 Mins."
#   (= 340 min) for 2017-2023 and "6 Hrs. 5 Mins." (= 365 min) for 2024-2025.
#   DeviceRatios reads "1:1" (2018-2024) / "1" (2025) -> 1 student per device.
# ==============================================================================

spr_id_flag_cols <- c(
  "end_year",
  "county_id", "county_name",
  "district_id", "district_name",
  "school_id", "school_name",
  "is_state", "is_county", "is_district", "is_school",
  "is_charter", "is_charter_sector", "is_allpublic"
)

local_big_download_timeout <- function(seconds = 1200, env = parent.frame()) {
  old <- getOption("timeout")
  options(timeout = seconds)
  withr::defer(options(timeout = old), envir = env)
  invisible(old)
}


# ==============================================================================
# Argument validation (no network)
# ==============================================================================

test_that("fetch_school_day rejects non-school level", {
  expect_error(fetch_school_day(2024, level = "district"), "school-level only")
})

test_that("fetch_school_day rejects pre-2017 years", {
  expect_error(fetch_school_day(2016), "end_year >= 2017")
})

test_that("fetch_device_ratios rejects non-school level", {
  expect_error(fetch_device_ratios(2024, level = "district"), "school-level only")
})

test_that("fetch_device_ratios rejects years where the sheet is absent", {
  # SY2016-17 (2017) and SY2019-20 (2020) have no DeviceRatios sheet.
  expect_error(fetch_device_ratios(2017), "absent")
  expect_error(fetch_device_ratios(2020), "absent")
})


# ==============================================================================
# Value parsers (pure, no network)
# ==============================================================================

test_that("parse_duration_to_minutes handles published formats", {
  expect_equal(parse_duration_to_minutes("6 Hrs. 25 Mins."), 385)
  expect_equal(parse_duration_to_minutes("6 Hrs 25 Mins"), 385)   # legacy (no dots)
  expect_equal(parse_duration_to_minutes("5 Hrs. 40 Mins."), 340)
  expect_equal(parse_duration_to_minutes("6 Hrs. 5 Mins."), 365)
  expect_equal(parse_duration_to_minutes("4 Hrs. 0 Mins."), 240)
  # Non-duration values become NA, never a fabricated 0.
  expect_true(is.na(parse_duration_to_minutes("n/a")))
  expect_true(is.na(parse_duration_to_minutes("n/a - applies only to high schools")))
  expect_true(is.na(parse_duration_to_minutes(NA_character_)))
  # Vectorized
  expect_equal(
    parse_duration_to_minutes(c("6 Hrs. 25 Mins.", "n/a")),
    c(385, NA_real_)
  )
})

test_that("parse_device_ratio handles published formats", {
  expect_equal(parse_device_ratio("1:1"), 1)
  expect_equal(parse_device_ratio("2.6:1"), 2.6)
  expect_equal(parse_device_ratio("1.1:1"), 1.1)
  expect_equal(parse_device_ratio("1"), 1)      # 2025 bare-number form
  expect_equal(parse_device_ratio("1.1"), 1.1)
  expect_true(is.na(parse_device_ratio("No devices reported")))
  expect_true(is.na(parse_device_ratio("n/a")))
  expect_true(is.na(parse_device_ratio(NA_character_)))
})


# ==============================================================================
# fetch_school_day(): structure + per-year raw fidelity
# ==============================================================================

test_that("fetch_school_day returns expected structure", {
  local_big_download_timeout()
  df <- fetch_school_day(2024)
  expect_s3_class(df, "data.frame")
  expect_true(all(spr_id_flag_cols %in% names(df)))
  expect_true(all(c(
    "typical_start_time", "typical_end_time",
    "length_of_day", "length_of_day_minutes",
    "instruction_full_time", "instruction_full_time_minutes",
    "instruction_shared_time", "instruction_shared_time_minutes"
  ) %in% names(df)))
  # Derived minutes are numeric.
  expect_type(df$length_of_day_minutes, "double")
})

test_that("fetch_school_day matches verified source cells every year 2017-2025", {
  local_big_download_timeout()
  # Atlantic City HS (0110/010): length_of_day = 385 min in every year.
  # instruction_full_time = 340 min (2017-2023) then 365 min (2024-2025).
  expected_ift <- function(yr) if (yr >= 2024) 365 else 340
  for (yr in 2017:2025) {
    df <- fetch_school_day(yr)
    row <- df[df$district_id == "0110" & df$school_id == "010", ]
    expect_equal(nrow(row), 1, info = paste("year", yr))
    expect_match(row$length_of_day, "6 Hrs.* 25 Mins", info = paste("year", yr))
    expect_equal(row$length_of_day_minutes, 385, info = paste("year", yr))
    expect_equal(row$instruction_full_time_minutes, expected_ift(yr),
                 info = paste("year", yr))
  }
})

test_that("fetch_school_day minutes are sane and Newark is present each year", {
  local_big_download_timeout()
  for (yr in c(2018, 2021, 2024, 2025)) {
    df <- fetch_school_day(yr)
    schools <- df[df$is_school, ]
    # Parse-error guard: no negative / absurd day lengths. Real published
    # values span ~170-720 min (e.g. Union City Hudson Elementary reports a
    # "12 Hrs 0 Mins" full-day program = 720 min), so the band is wide enough
    # to admit genuine outliers while still catching a broken parse.
    lod <- schools$length_of_day_minutes[!is.na(schools$length_of_day_minutes)]
    expect_true(all(lod >= 60 & lod <= 900), info = paste("year", yr))
    # Newark (district 3570) present.
    expect_true(any(df$district_id == "3570"), info = paste("year", yr))
    # Row count in an established band (NJ has ~2,500 schools reporting).
    expect_true(nrow(schools) > 2000 && nrow(schools) < 3000,
                info = paste("year", yr))
  }
})

test_that("fetch_school_day preserves the published string (tidy<->raw fidelity)", {
  local_big_download_timeout()
  raw <- fetch_spr_data("SchoolDay", 2024)
  tidy <- fetch_school_day(2024)
  key <- function(d) paste(d$district_id, d$school_id)
  m <- match(key(tidy), key(raw))
  expect_equal(tidy$length_of_day, raw$length_of_day[m])
  expect_equal(tidy$instruction_full_time, raw$instruction_full_time[m])
})


# ==============================================================================
# fetch_device_ratios(): structure + per-year raw fidelity
# ==============================================================================

test_that("fetch_device_ratios returns expected structure", {
  local_big_download_timeout()
  df <- fetch_device_ratios(2024)
  expect_s3_class(df, "data.frame")
  expect_true(all(spr_id_flag_cols %in% names(df)))
  expect_true(all(c("student_device_ratio", "students_per_device") %in% names(df)))
  expect_type(df$students_per_device, "double")
})

test_that("fetch_device_ratios matches verified source cells every covered year", {
  local_big_download_timeout()
  # Atlantic City HS (0110/010) reads 1:1 (-> 1 student per device) every year.
  for (yr in c(2018, 2019, 2021, 2022, 2023, 2024, 2025)) {
    df <- fetch_device_ratios(yr)
    row <- df[df$district_id == "0110" & df$school_id == "010", ]
    expect_equal(nrow(row), 1, info = paste("year", yr))
    expect_equal(row$students_per_device, 1, info = paste("year", yr))
  }
})

test_that("fetch_device_ratios values are sane and Newark present each year", {
  local_big_download_timeout()
  for (yr in c(2018, 2021, 2024, 2025)) {
    df <- fetch_device_ratios(yr)
    spd <- df$students_per_device[!is.na(df$students_per_device)]
    # Parse-error guard: students-per-device is strictly positive and finite.
    # Real published values run from 1:1 up to a few hundred:1 (e.g. Jackson
    # Township's Sylvia Rosenauer Elementary reported 265:1 in 2024), so the
    # upper bound is generous - it catches a broken parse, not real scarcity.
    expect_true(all(spd > 0 & is.finite(spd)), info = paste("year", yr))
    expect_true(all(spd < 1000), info = paste("year", yr))
    expect_true(any(df$district_id == "3570"), info = paste("year", yr))
  }
})

test_that("fetch_device_ratios preserves the published string (tidy<->raw fidelity)", {
  local_big_download_timeout()
  raw <- fetch_spr_data("DeviceRatios", 2023)  # legacy ratio-string layout
  tidy <- fetch_device_ratios(2023)
  key <- function(d) paste(d$district_id, d$school_id)
  m <- match(key(tidy), key(raw))
  expect_equal(tidy$student_device_ratio, raw$student_device_ratio[m])
})
