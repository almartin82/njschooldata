# ==============================================================================
# Tests for the redesigned (2024-25) Seal-of-Biliteracy fetchers
#   fetch_biliteracy_summary(), fetch_biliteracy_trends(),
#   fetch_biliteracy_by_group()
# ==============================================================================
#
# Live-network tests against the NJ DOE SPR 2024-25 workbooks. The three sheets
# exist ONLY in end_year 2025 (verified with readxl::excel_sheets on the cached
# 2024 vs 2025 workbooks - they are absent 2017-2024). Pinned values were read
# by hand from the published cells.
#
# Anchor entity: Atlantic City High School, county_id "01", district_id "0110",
# school_id "010" (SPR School workbook, 2025):
#   SealofBiliteracy_Summary row:
#     total_seals_earned = 30, numberof_languages = 6,
#     unique_students_earning_seals = 30, unique pct = "6.8%",
#     multilingual_learners_earning_seals = 23, ML pct = "11.5%"
#   SealofBiliteracy_Trends rows (school_year -> total_seals_earned):
#     2020-21 -> "0", 2021-22 -> "Fewer than 5 seals" (-> NA), 2022-23 -> "0",
#     2023-24 -> "14", 2024-25 -> "30"
#   SealofBiliteracy_StudentGroup "total population" row:
#     students_earning_seal_pct_school = "6.8%",
#     students_earning_seal_pct_district = "6.8%",
#     students_earning_seal_pct_state = "11.1%"
#
# STATE anchor (SPR District workbook, 2025, is_state row):
#   Summary: total_seals_earned = "12,644" (-> 12644), numberof_languages = 61,
#     unique pct = "11.1%", ML pct = "26.7%"
#   Trends: 2020-21 -> "4,953" (-> 4953), 2024-25 -> "12,644" (-> 12644)
#
# DISTRICT anchor (SPR District workbook, 2025): Newark (3570),
#   StudentGroup "total population" students_earning_seal_pct_district = "15.4%",
#   students_earning_seal_pct_state = "11.1%".
# ==============================================================================

bili_id_flag_cols <- c(
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

test_that("redesigned biliteracy fetchers reject non-2025 years", {
  expect_error(fetch_biliteracy_summary(2024), "end_year 2025 only")
  expect_error(fetch_biliteracy_trends(2017), "end_year 2025 only")
  expect_error(fetch_biliteracy_by_group(2026), "end_year 2025 only")
})

test_that("redesigned biliteracy fetchers reject bad level", {
  expect_error(fetch_biliteracy_summary(2025, level = "state"),
               "level must be")
  expect_error(fetch_biliteracy_trends(2025, level = "campus"),
               "level must be")
  expect_error(fetch_biliteracy_by_group(2025, level = "foo"),
               "level must be")
})


# ==============================================================================
# fetch_biliteracy_summary()
# ==============================================================================

test_that("fetch_biliteracy_summary returns expected structure", {
  local_big_download_timeout()
  df <- fetch_biliteracy_summary(2025)
  expect_s3_class(df, "data.frame")
  expect_true(all(bili_id_flag_cols %in% names(df)))
  expect_true(all(c(
    "school_year",
    "total_seals_earned", "numberof_languages",
    "unique_students_earning_seals", "unique_students_earning_seals_pct",
    "multilingual_learners_earning_seals",
    "multilingual_learners_earning_seals_pct"
  ) %in% names(df)))
  expect_type(df$total_seals_earned, "double")
  expect_type(df$unique_students_earning_seals_pct, "double")
})

test_that("fetch_biliteracy_summary matches verified Atlantic City HS cells", {
  local_big_download_timeout()
  df <- fetch_biliteracy_summary(2025)            # school level
  row <- df[df$district_id == "0110" & df$school_id == "010", ]
  expect_equal(nrow(row), 1)
  expect_equal(row$total_seals_earned, 30)                      # cell "30"
  expect_equal(row$numberof_languages, 6)                       # cell "6"
  expect_equal(row$unique_students_earning_seals, 30)           # cell "30"
  expect_equal(row$unique_students_earning_seals_pct, 6.8, tolerance = 0.1)  # "6.8%"
  expect_equal(row$multilingual_learners_earning_seals, 23)     # cell "23"
  expect_equal(row$multilingual_learners_earning_seals_pct, 11.5,
               tolerance = 0.1)                                 # "11.5%"
})

test_that("fetch_biliteracy_summary matches the verified STATE totals", {
  local_big_download_timeout()
  df <- fetch_biliteracy_summary(2025, level = "district")
  st <- df[df$is_state, ]
  expect_equal(nrow(st), 1)
  expect_equal(st$total_seals_earned, 12644)                    # cell "12,644"
  expect_equal(st$numberof_languages, 61)                       # cell "61"
  expect_equal(st$unique_students_earning_seals_pct, 11.1, tolerance = 0.1)  # "11.1%"
  expect_equal(st$multilingual_learners_earning_seals_pct, 26.7,
               tolerance = 0.1)                                 # "26.7%"
})

test_that("fetch_biliteracy_summary coerces ML text-bleed to NA, not a number", {
  local_big_download_timeout()
  df <- fetch_biliteracy_summary(2025)
  raw <- fetch_spr_data("SealofBiliteracy_Summary", 2025)
  # Rows whose published ML cell is the suppression / text-bleed note must be NA.
  bleed <- grepl("less than 10|Fewer than 5",
                 raw$multilingual_learners_earning_seals)
  expect_true(any(bleed))   # such rows exist in the published file
  key <- function(d) paste(d$district_id, d$school_id)
  m <- match(key(raw[bleed, ]), key(df))
  expect_true(all(is.na(df$multilingual_learners_earning_seals[m])))
})

test_that("fetch_biliteracy_summary values are sane and Newark present", {
  local_big_download_timeout()
  df <- fetch_biliteracy_summary(2025)
  # Percentages in [0, 100].
  for (col in c("unique_students_earning_seals_pct",
                "multilingual_learners_earning_seals_pct")) {
    v <- df[[col]][!is.na(df[[col]])]
    expect_true(all(v >= 0 & v <= 100), info = col)
  }
  # Counts non-negative.
  cnt <- df$total_seals_earned[!is.na(df$total_seals_earned)]
  expect_true(all(cnt >= 0))
  # Newark present.
  expect_true(any(df$district_id == "3570"))
})


# ==============================================================================
# fetch_biliteracy_trends()
# ==============================================================================

test_that("fetch_biliteracy_trends returns expected structure", {
  local_big_download_timeout()
  df <- fetch_biliteracy_trends(2025)
  expect_s3_class(df, "data.frame")
  expect_true(all(bili_id_flag_cols %in% names(df)))
  expect_true(all(c("school_year", "total_seals_earned") %in% names(df)))
  expect_type(df$total_seals_earned, "double")
})

test_that("fetch_biliteracy_trends carries exactly 5 distinct school years", {
  local_big_download_timeout()
  df <- fetch_biliteracy_trends(2025)
  yrs <- sort(unique(df$school_year))
  expect_equal(yrs, c("2020-21", "2021-22", "2022-23", "2023-24", "2024-25"))
  # One row per (entity, school_year).
  dup <- df[df$is_school | df$is_district | df$is_state, ]
  counts <- table(paste(dup$district_id, dup$school_id, dup$school_year))
  expect_true(all(counts == 1))
})

test_that("fetch_biliteracy_trends matches verified Atlantic City HS cells", {
  local_big_download_timeout()
  df <- fetch_biliteracy_trends(2025)
  row <- df[df$district_id == "0110" & df$school_id == "010", ]
  expect_equal(nrow(row), 5)
  got <- setNames(row$total_seals_earned, row$school_year)
  expect_equal(unname(got["2020-21"]), 0)         # cell "0" stays 0
  expect_true(is.na(got["2021-22"]))              # "Fewer than 5 seals" -> NA
  expect_equal(unname(got["2022-23"]), 0)         # cell "0"
  expect_equal(unname(got["2023-24"]), 14)        # cell "14"
  expect_equal(unname(got["2024-25"]), 30)        # cell "30"
})

test_that("fetch_biliteracy_trends matches the verified STATE trend", {
  local_big_download_timeout()
  df <- fetch_biliteracy_trends(2025, level = "district")
  st <- df[df$is_state, ]
  got <- setNames(st$total_seals_earned, st$school_year)
  expect_equal(unname(got["2020-21"]), 4953)      # cell "4,953"
  expect_equal(unname(got["2024-25"]), 12644)     # cell "12,644"
  # State seal total in a plausible band established from the published data.
  expect_true(all(st$total_seals_earned > 1000 & st$total_seals_earned < 30000))
})


# ==============================================================================
# fetch_biliteracy_by_group()
# ==============================================================================

test_that("fetch_biliteracy_by_group returns expected structure", {
  local_big_download_timeout()
  df <- fetch_biliteracy_by_group(2025)
  expect_s3_class(df, "data.frame")
  expect_true(all(bili_id_flag_cols %in% names(df)))
  expect_true(all(c(
    "subgroup",
    "students_earning_seal_pct_school",
    "students_earning_seal_pct_district",
    "students_earning_seal_pct_state"
  ) %in% names(df)))
  expect_type(df$students_earning_seal_pct_school, "double")
  # Subgroup labels are normalized (clean_spr_subgroups).
  expect_true("total population" %in% df$subgroup)
})

test_that("fetch_biliteracy_by_group matches verified Atlantic City HS rate", {
  local_big_download_timeout()
  df <- fetch_biliteracy_by_group(2025)
  row <- df[df$district_id == "0110" & df$school_id == "010" &
              df$subgroup == "total population", ]
  expect_equal(nrow(row), 1)
  expect_equal(row$students_earning_seal_pct_school, 6.8, tolerance = 0.1)
  expect_equal(row$students_earning_seal_pct_district, 6.8, tolerance = 0.1)
  expect_equal(row$students_earning_seal_pct_state, 11.1, tolerance = 0.1)
})

test_that("fetch_biliteracy_by_group matches verified DISTRICT (Newark) rate", {
  local_big_download_timeout()
  # District workbook: there is no _pct_school column at district level.
  df <- fetch_biliteracy_by_group(2025, level = "district")
  expect_false("students_earning_seal_pct_school" %in% names(df))
  row <- df[df$district_id == "3570" & df$subgroup == "total population", ]
  expect_equal(nrow(row), 1)
  expect_equal(row$students_earning_seal_pct_district, 15.4, tolerance = 0.1)
  expect_equal(row$students_earning_seal_pct_state, 11.1, tolerance = 0.1)
})

test_that("fetch_biliteracy_by_group coerces <10-enrollment suppression to NA", {
  local_big_download_timeout()
  df <- fetch_biliteracy_by_group(2025)
  raw <- fetch_spr_data("SealofBiliteracy_StudentGroup", 2025)
  supp <- grepl("Enrollment for the group is <10|Fewer than 5 students",
                raw$students_earning_seal_pct_school)
  expect_true(any(supp))   # suppression rows exist in the published file
  # Every suppressed cell must be NA, never a fabricated number.
  expect_true(all(is.na(spr_value_numeric(
    raw$students_earning_seal_pct_school[supp]
  ))))
})

test_that("fetch_biliteracy_by_group rates are sane percentages", {
  local_big_download_timeout()
  df <- fetch_biliteracy_by_group(2025)
  # Rates are non-negative. The upper band is generous (<= 200) on purpose: NJ
  # publishes a genuine seal-earning rate above 100% for at least one group
  # (Kingsway Regional HS, LEP, "109.1%") because the rate is seals earned over
  # a 12th-grade-style denominator, not over the group's own enrollment. That is
  # a real published cell, not a parse error, so it must pass through unclipped.
  for (col in c("students_earning_seal_pct_school",
                "students_earning_seal_pct_district",
                "students_earning_seal_pct_state")) {
    v <- df[[col]][!is.na(df[[col]])]
    expect_true(all(v >= 0 & v <= 200), info = col)
  }
  # The state-rate column never exceeds a sane biliteracy share.
  vst <- df$students_earning_seal_pct_state[!is.na(df$students_earning_seal_pct_state)]
  expect_true(all(vst >= 0 & vst <= 100))
  expect_true(any(df$district_id == "3570"))
})


# ==============================================================================
# tidy <-> raw fidelity: published strings preserved through coercion
# ==============================================================================

test_that("biliteracy coercion preserves published numbers exactly", {
  local_big_download_timeout()
  raw <- fetch_spr_data("SealofBiliteracy_Summary", 2025)
  tidy <- fetch_biliteracy_summary(2025)
  key <- function(d) paste(d$district_id, d$school_id)
  m <- match(key(tidy), key(raw))
  # Where the raw cell is a clean integer string, the coerced value equals it.
  raw_seals <- suppressWarnings(as.numeric(
    gsub(",", "", raw$total_seals_earned[m])
  ))
  expect_equal(tidy$total_seals_earned, raw_seals)
})
