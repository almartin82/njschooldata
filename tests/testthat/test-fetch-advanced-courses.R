# ==============================================================================
# Tests for fetch_advanced_course_access()
#   type = "courses_offered" | "participation_by_group" | "sle"
# ==============================================================================
#
# Live-network tests against the NJ DOE School Performance Report (SPR) workbooks.
# Pinned values were read by hand from the published cells (cell references in the
# comments). Anchor entity (stable across years): Atlantic City High School,
#   county_id "01", district_id "0110", school_id "010".
#
# COURSES OFFERED (APIBCoursesOffered 2017-2024 / ABIBCoursesOffered 2025),
#   AC HS "AP Biology":
#     2017 enrolled=42 tested=42; 2018 enrolled=26 tested=25;
#     2024 enrolled=4 tested=4;   2025 enrolled=28 tested=26.
#   STATE (District workbook, is_state) "AP Biology" 2024: enrolled=9044 tested=7917.
#
# PARTICIPATION BY GROUP (APIBDualEnrPartByStudentGrp 2021-2024 /
#   AP_IB_Dual_PartStudentGroup 2025; absent 2017-2020), AC HS "total population":
#     2021 apib=24.5 dual=0.9 state_apib=35.7 state_dual=22.3
#     2024 apib=17.4 dual=0.0 state_apib=35.9 state_dual=26.9
#     2025 apib=17.7 dual=30.6 state_apib=37.5 state_dual=30.0 (school_year 2024-25)
#   STATE (District workbook, is_state) "total population" 2024:
#     apib_pct_state=35.9 dual_pct_state=26.9 (entity columns are NA on the
#     legacy is_state row; the statewide value lives in the *_pct_state column).
#
# SLE PARTICIPATION (CTE_SLEParticipation 2017-2023 / SLE_Participation 2024-2025),
#   AC HS:
#     2017 sle=1.9 state=2.5; 2018 sle=2.3 state=3.3; 2023 sle=3.3 state=2.6;
#     2024 sle=5.5 state=4.6; 2025 sle=0.9 state=5.5.
#   STATE (District workbook, is_state) 2024: sle_pct_state=4.6.
# ==============================================================================

adv_id_flag_cols <- c(
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

ac_hs <- function(df) df[df$district_id == "0110" & df$school_id == "010", ]


# ==============================================================================
# Argument validation (no network)
# ==============================================================================

test_that("fetch_advanced_course_access rejects a bad type", {
  expect_error(fetch_advanced_course_access(2024, type = "ap_scores"))
})

test_that("fetch_advanced_course_access rejects a bad level", {
  expect_error(
    fetch_advanced_course_access(2024, type = "courses_offered", level = "state"),
    "level must be"
  )
  expect_error(
    fetch_advanced_course_access(2024, type = "sle", level = "campus"),
    "level must be"
  )
})

test_that("participation_by_group rejects years where the sheet is absent", {
  # APIBDualEnrPartByStudentGrp is absent from the 2017-2020 SPR databases.
  expect_error(
    fetch_advanced_course_access(2020, type = "participation_by_group"),
    "end_year >= 2021"
  )
  expect_error(
    fetch_advanced_course_access(2017, type = "participation_by_group"),
    "end_year >= 2021"
  )
})

test_that("courses_offered and sle reject pre-2017 years", {
  expect_error(
    fetch_advanced_course_access(2016, type = "courses_offered"),
    "end_year >= 2017"
  )
  expect_error(
    fetch_advanced_course_access(2016, type = "sle"),
    "end_year >= 2017"
  )
})


# ==============================================================================
# courses_offered
# ==============================================================================

test_that("courses_offered returns expected structure", {
  local_big_download_timeout()
  df <- fetch_advanced_course_access(2024, type = "courses_offered")
  expect_s3_class(df, "data.frame")
  expect_true(all(adv_id_flag_cols %in% names(df)))
  expect_true(all(c("course_name", "students_enrolled", "students_tested") %in%
                    names(df)))
  expect_type(df$students_enrolled, "double")
  expect_type(df$students_tested, "double")
})

test_that("courses_offered matches verified Atlantic City HS cells", {
  local_big_download_timeout()
  expected <- list(
    "2017" = c(42, 42), "2018" = c(26, 25),
    "2024" = c(4, 4),   "2025" = c(28, 26)
  )
  for (yr in names(expected)) {
    df <- fetch_advanced_course_access(as.integer(yr), type = "courses_offered")
    row <- ac_hs(df)
    row <- row[grepl("^AP Biology$", row$course_name), ]
    expect_equal(nrow(row), 1, info = paste("year", yr))
    expect_equal(row$students_enrolled, expected[[yr]][1], info = paste("year", yr))
    expect_equal(row$students_tested, expected[[yr]][2], info = paste("year", yr))
  }
})

test_that("courses_offered matches the verified STATE cell", {
  local_big_download_timeout()
  df <- fetch_advanced_course_access(2024, type = "courses_offered",
                                     level = "district")
  st <- df[df$is_state & grepl("^AP Biology$", df$course_name), ]
  expect_equal(nrow(st), 1)
  expect_equal(st$students_enrolled, 9044)   # cell "9044"
  expect_equal(st$students_tested, 7917)     # cell "7917"
})

test_that("courses_offered covers AC HS AP Biology every year 2017-2025", {
  local_big_download_timeout()
  for (yr in 2017:2025) {
    df <- fetch_advanced_course_access(yr, type = "courses_offered")
    row <- ac_hs(df)
    row <- row[grepl("^AP Biology$", row$course_name), ]
    expect_equal(nrow(row), 1, info = paste("year", yr))
    expect_false(is.na(row$students_enrolled), info = paste("year", yr))
  }
})

test_that("courses_offered counts are sane and Newark present", {
  local_big_download_timeout()
  for (yr in c(2018, 2021, 2024, 2025)) {
    df <- fetch_advanced_course_access(yr, type = "courses_offered")
    enr <- df$students_enrolled[!is.na(df$students_enrolled)]
    tst <- df$students_tested[!is.na(df$students_tested)]
    expect_true(all(enr >= 0), info = paste("year", yr))
    expect_true(all(tst >= 0), info = paste("year", yr))
    expect_true(any(df$district_id == "3570"), info = paste("year", yr))  # Newark
    # NJ has thousands of school-by-course rows.
    expect_true(nrow(df) > 3000, info = paste("year", yr))
  }
})

test_that("courses_offered preserves published counts (tidy<->raw fidelity)", {
  local_big_download_timeout()
  raw <- fetch_spr_data("APIBCoursesOffered", 2024)
  tidy <- fetch_advanced_course_access(2024, type = "courses_offered")
  key <- function(d) paste(d$district_id, d$school_id, d$course_name)
  m <- match(key(tidy), key(raw))
  expect_equal(tidy$students_enrolled,
               spr_value_numeric(raw$student_enroll_count[m]))
  expect_equal(tidy$students_tested,
               spr_value_numeric(raw$student_tested_count[m]))
})


# ==============================================================================
# participation_by_group
# ==============================================================================

test_that("participation_by_group returns expected structure", {
  local_big_download_timeout()
  df <- fetch_advanced_course_access(2024, type = "participation_by_group")
  expect_s3_class(df, "data.frame")
  expect_true(all(adv_id_flag_cols %in% names(df)))
  expect_true(all(c("subgroup", "apib_pct_school", "apib_pct_state",
                    "dual_pct_school", "dual_pct_state") %in% names(df)))
  expect_type(df$apib_pct_school, "double")
  expect_type(df$dual_pct_state, "double")
  expect_true("total population" %in% df$subgroup)
})

test_that("participation_by_group matches verified Atlantic City HS cells", {
  local_big_download_timeout()
  # year -> c(apib_school, dual_school, apib_state, dual_state)
  expected <- list(
    "2021" = c(24.5, 0.9, 35.7, 22.3),
    "2024" = c(17.4, 0.0, 35.9, 26.9),
    "2025" = c(17.7, 30.6, 37.5, 30.0)
  )
  for (yr in names(expected)) {
    df <- fetch_advanced_course_access(as.integer(yr),
                                       type = "participation_by_group")
    row <- ac_hs(df)
    row <- row[row$subgroup == "total population", ]
    expect_equal(nrow(row), 1, info = paste("year", yr))
    e <- expected[[yr]]
    expect_equal(row$apib_pct_school, e[1], tolerance = 0.1, info = paste("year", yr))
    expect_equal(row$dual_pct_school, e[2], tolerance = 0.1, info = paste("year", yr))
    expect_equal(row$apib_pct_state,  e[3], tolerance = 0.1, info = paste("year", yr))
    expect_equal(row$dual_pct_state,  e[4], tolerance = 0.1, info = paste("year", yr))
  }
})

test_that("participation_by_group matches the verified STATE rate", {
  local_big_download_timeout()
  df <- fetch_advanced_course_access(2024, type = "participation_by_group",
                                     level = "district")
  st <- df[df$is_state & df$subgroup == "total population", ]
  expect_equal(nrow(st), 1)
  # The legacy is_state row carries the statewide rate in the *_pct_state column.
  expect_equal(st$apib_pct_state, 35.9, tolerance = 0.1)
  expect_equal(st$dual_pct_state, 26.9, tolerance = 0.1)
})

test_that("participation_by_group covers AC HS every year 2021-2025", {
  local_big_download_timeout()
  for (yr in 2021:2025) {
    df <- fetch_advanced_course_access(yr, type = "participation_by_group")
    row <- ac_hs(df)
    row <- row[row$subgroup == "total population", ]
    expect_equal(nrow(row), 1, info = paste("year", yr))
  }
})

test_that("participation_by_group 2025 collapses to ONE school year per row", {
  local_big_download_timeout()
  # The 2025 sheet is a multi-year trend table; filter_spr_to_year() must keep
  # only SY2024-25, yielding one row per (entity, subgroup).
  df <- fetch_advanced_course_access(2025, type = "participation_by_group")
  expect_equal(unique(df$school_year), "2024-25")
  key <- paste(df$county_id, df$district_id, df$school_id, df$subgroup)
  expect_true(max(table(key)) == 1)
  # 2025 adds the district-level columns.
  expect_true(all(c("apib_pct_district", "dual_pct_district") %in% names(df)))
})

test_that("fetch_courses normalizes 2025 advanced access with subgroup status", {
  local_big_download_timeout()
  df <- fetch_courses("advanced_access", 2025, with_status = TRUE)
  row <- df[
    df$district_id == "0110" &
      df$school_id == "010" &
      df$subgroup == "total population" &
      df$metric == "apib_pct_school",
  ]

  expect_equal(nrow(row), 1)
  expect_equal(row$subgroup_std, "total_enrollment")
  expect_equal(row$value, 17.7, tolerance = 0.1)
  expect_equal(as.character(row$value_status), "actual")
})

test_that("fetch_courses normalizes 2025 courses offered from the renamed sheet", {
  local_big_download_timeout()
  df <- fetch_courses("courses_offered", 2025, with_status = TRUE)
  row <- df[
    df$district_id == "0110" &
      df$school_id == "010" &
      df$course_name == "AP Biology" &
      df$metric == "students_enrolled",
  ]

  expect_equal(nrow(row), 1)
  expect_equal(row$value, 28)
  expect_equal(as.character(row$value_status), "actual")
})

test_that("participation_by_group coerces no-data text to NA, not a number", {
  local_big_download_timeout()
  raw <- fetch_spr_data("AP_IB_Dual_PartStudentGroup", 2025)
  raw <- filter_spr_to_year(raw, 2025)
  bleed <- grepl("no data available", raw$apib_enrolled_school, ignore.case = TRUE)
  expect_true(any(bleed))   # such rows exist in the published file
  # Every such cell must coerce to NA, never a fabricated number.
  expect_true(all(is.na(spr_value_numeric(raw$apib_enrolled_school[bleed]))))
})

test_that("participation_by_group rates are sane and Newark present", {
  local_big_download_timeout()
  for (yr in c(2021, 2024, 2025)) {
    df <- fetch_advanced_course_access(yr, type = "participation_by_group")
    for (col in intersect(
      c("apib_pct_school", "apib_pct_district", "apib_pct_state",
        "dual_pct_school", "dual_pct_district", "dual_pct_state"),
      names(df))) {
      v <- df[[col]][!is.na(df[[col]])]
      expect_true(all(v >= 0 & v <= 100), info = paste(yr, col))
    }
    expect_true(any(df$district_id == "3570"), info = paste("year", yr))  # Newark
  }
})

test_that("participation_by_group preserves published rates (tidy<->raw)", {
  local_big_download_timeout()
  raw <- fetch_spr_data("APIBDualEnrPartByStudentGrp", 2024)
  tidy <- fetch_advanced_course_access(2024, type = "participation_by_group")
  key <- function(d) paste(d$district_id, d$school_id, d$subgroup)
  m <- match(key(tidy), key(raw))
  expect_equal(tidy$apib_pct_school,
               spr_value_numeric(raw$percent_enrolled_in_one_or_more_apor_ibcourse[m]))
})


# ==============================================================================
# sle
# ==============================================================================

test_that("sle returns expected structure", {
  local_big_download_timeout()
  df <- fetch_advanced_course_access(2024, type = "sle")
  expect_s3_class(df, "data.frame")
  expect_true(all(adv_id_flag_cols %in% names(df)))
  expect_true(all(c("sle_pct_school", "sle_pct_state") %in% names(df)))
  expect_type(df$sle_pct_school, "double")
  expect_type(df$sle_pct_state, "double")
})

test_that("sle matches verified Atlantic City HS cells", {
  local_big_download_timeout()
  # year -> c(sle_pct_school, sle_pct_state)
  expected <- list(
    "2017" = c(1.9, 2.5), "2018" = c(2.3, 3.3), "2023" = c(3.3, 2.6),
    "2024" = c(5.5, 4.6), "2025" = c(0.9, 5.5)
  )
  for (yr in names(expected)) {
    df <- fetch_advanced_course_access(as.integer(yr), type = "sle")
    row <- ac_hs(df)
    expect_equal(nrow(row), 1, info = paste("year", yr))
    expect_equal(row$sle_pct_school, expected[[yr]][1], tolerance = 0.1,
                 info = paste("year", yr))
    expect_equal(row$sle_pct_state, expected[[yr]][2], tolerance = 0.1,
                 info = paste("year", yr))
  }
})

test_that("sle matches the verified STATE rate", {
  local_big_download_timeout()
  df <- fetch_advanced_course_access(2024, type = "sle", level = "district")
  st <- df[df$is_state, ]
  expect_equal(nrow(st), 1)
  expect_equal(st$sle_pct_state, 4.6, tolerance = 0.1)
  # District workbook carries the entity rate as sle_pct_district, not _school.
  expect_false("sle_pct_school" %in% names(df))
  expect_true("sle_pct_district" %in% names(df))
})

test_that("sle covers AC HS every year 2017-2025", {
  local_big_download_timeout()
  for (yr in 2017:2025) {
    df <- fetch_advanced_course_access(yr, type = "sle")
    row <- ac_hs(df)
    expect_equal(nrow(row), 1, info = paste("year", yr))
    expect_false(is.na(row$sle_pct_school), info = paste("year", yr))
  }
})

test_that("sle rates are sane and Newark present", {
  local_big_download_timeout()
  for (yr in c(2018, 2023, 2024, 2025)) {
    df <- fetch_advanced_course_access(yr, type = "sle")
    for (col in intersect(c("sle_pct_school", "sle_pct_district",
                            "sle_pct_state"), names(df))) {
      v <- df[[col]][!is.na(df[[col]])]
      expect_true(all(v >= 0 & v <= 100), info = paste(yr, col))
    }
    expect_true(any(df$district_id == "3570"), info = paste("year", yr))  # Newark
  }
})

test_that("sle preserves published rates (tidy<->raw fidelity)", {
  local_big_download_timeout()
  raw <- fetch_spr_data("CTE_SLEParticipation", 2023)   # legacy layout
  tidy <- fetch_advanced_course_access(2023, type = "sle")
  key <- function(d) paste(d$district_id, d$school_id)
  m <- match(key(tidy), key(raw))
  expect_equal(tidy$sle_pct_school, spr_value_numeric(raw$sleschool[m]))
})
