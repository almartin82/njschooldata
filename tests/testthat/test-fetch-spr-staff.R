# ==============================================================================
# Tests for Expanded Staff Sheet Fetchers
# ==============================================================================
#
# Live-network tests for the redesigned 2024-25 SPR staff sheets:
#   fetch_spr_admin_experience()
#   fetch_spr_staff_counts()
#   fetch_spr_staff_demo_subject()
#   fetch_spr_staff_education()
#   fetch_spr_staff_retention()
#   fetch_spr_teacher_exp_subject()
#   fetch_spr_educator_equity()   (District/State database only; no CDS)
#
# Pinned values verified against the NJ DOE 2024-25 SPR workbooks at:
#   https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/
# Reference school: Absecon (county 01, district 0010), Emma C Attales (school
# 050), SY2024-25.
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

local_big_download_timeout <- function(seconds = 600, env = parent.frame()) {
  old <- getOption("timeout")
  options(timeout = seconds)
  withr::defer(options(timeout = old), envir = env)
  invisible(old)
}

ref_emma <- function(df) {
  dplyr::filter(df, county_id == "01", district_id == "0010", school_id == "050")
}


# ==============================================================================
# Argument validation (no network)
# ==============================================================================

# These sheets are genuinely new in (or materially restructured for) the
# 2024-25 redesign, so their fetchers stay gated at end_year >= 2025.
test_that("redesign-only staff fetchers error (no fabrication) for pre-2025", {
  expect_error(fetch_spr_admin_experience(2024), "end_year >= 2025")
  expect_error(fetch_spr_staff_demo_subject(2024), "end_year >= 2025")
  expect_error(fetch_spr_teacher_exp_subject(2024), "end_year >= 2025")
  expect_error(fetch_spr_educator_equity(2024), "end_year >= 2025")
})

# These sheets exist in earlier databases, so their fetchers were extended
# backward. They error only below each sheet's real first year.
test_that("backfilled staff fetchers error only below their real floor", {
  # StaffCounts first appears in SY2020-21.
  expect_error(fetch_spr_staff_counts(2020), "end_year >= 2021")
  # TeachersAdminsLevelOfEducation: SY2016-17 uses a different layout.
  expect_error(fetch_spr_staff_education(2017), "end_year >= 2018")
  # Retention is district-granularity before 2025; school-level is 2025+.
  expect_error(fetch_spr_staff_retention(2024), "level = 'district'")
  expect_error(fetch_spr_staff_retention(2017, level = "district"),
               "end_year >= 2018")
})


# ==============================================================================
# fetch_spr_admin_experience()
# ==============================================================================

test_that("fetch_spr_admin_experience returns numeric measures and keeps CDS", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_spr_admin_experience(2025)

  expect_true(all(spr_cols %in% names(df)))
  expect_true(all(c(
    "admin_count_school", "admin_count_state",
    "average_years_exp_in_public_schools_school",
    "percentage_admins_with_4_or_more_years_exp_school"
  ) %in% names(df)))
  # CDS identifiers stay character (a "count" name match must not coerce them).
  expect_type(df$county_id, "character")
  expect_type(df$admin_count_school, "double")

  ref <- ref_emma(df)
  expect_equal(nrow(ref), 1)
  # Pinned: Emma C Attales admin count 1, 25 avg years exp, 100% with 4+ years.
  expect_equal(ref$admin_count_school, 1)
  expect_equal(ref$average_years_exp_in_public_schools_school, 25)
  expect_equal(ref$percentage_admins_with_4_or_more_years_exp_school, 100)
})


# ==============================================================================
# fetch_spr_staff_counts()
# ==============================================================================

test_that("fetch_spr_staff_counts coerces counts and NA-fills missing", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_spr_staff_counts(2025)

  expect_true(all(spr_cols %in% names(df)))
  expect_true(all(c(
    "staff_category", "school_total_staff",
    "district_total_staff_members", "state_total_staff_members"
  ) %in% names(df)))
  expect_type(df$state_total_staff_members, "double")

  ref <- ref_emma(df)
  # Pinned: Emma C Attales has 1 administrator.
  expect_equal(
    ref$school_total_staff[ref$staff_category == "Administrators"], 1
  )
  # A role with no school-level value reads "There is no data..." -> NA.
  expect_true(is.na(
    ref$school_total_staff[ref$staff_category == "Child Study Team Members"]
  ))
})


# ==============================================================================
# fetch_spr_staff_demo_subject()
# ==============================================================================

test_that("fetch_spr_staff_demo_subject preserves privacy ranges as character", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_spr_staff_demo_subject(2025)

  expect_true(all(spr_cols %in% names(df)))
  expect_true(all(c("subject_area", "teacher_count", "two_or_more_races",
                    "white", "female", "male") %in% names(df)))

  # teacher_count is numeric; composition columns stay character.
  expect_type(df$teacher_count, "double")
  expect_type(df$white, "character")
  expect_type(df$female, "character")

  # Gender columns carry privacy-protected ranges that must be preserved.
  gender_vals <- df$female[!is.na(df$female)]
  expect_true(any(grepl("[0-9]-[0-9]|<=|>=|≤|≥|<|>", gender_vals)))

  ref <- ref_emma(df) %>% dplyr::filter(subject_area == "All Teachers")
  expect_equal(ref$teacher_count, 37)
  # Pinned exact percent preserved verbatim (not coerced).
  expect_equal(ref$white, "91.9%")
})


# ==============================================================================
# fetch_spr_staff_education()
# ==============================================================================

test_that("fetch_spr_staff_education returns numeric degree shares", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_spr_staff_education(2025)

  expect_true(all(c("teachers_admins", "bachelors", "masters", "doctoral")
                  %in% names(df)))
  expect_type(df$masters, "double")

  ref <- ref_emma(df)
  # Pinned: Emma C Attales teachers 45.9% Master's, 2.7% Doctoral.
  expect_equal(ref$masters[ref$teachers_admins == "Teachers"], 45.9)
  expect_equal(ref$doctoral[ref$teachers_admins == "Teachers"], 2.7)
  # The administrator Bachelor's note is non-numeric -> NA.
  expect_true(is.na(ref$bachelors[ref$teachers_admins == "Administrators"]))
})


# ==============================================================================
# fetch_spr_staff_retention()
# ==============================================================================

test_that("fetch_spr_staff_retention returns numeric retention rates", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_spr_staff_retention(2025)

  expect_true(all(c("teachers_admins", "retention_pct_district",
                    "retention_pct_state") %in% names(df)))
  expect_type(df$retention_pct_district, "double")

  ref <- ref_emma(df)
  # Pinned: Emma C Attales teacher retention 86.6% (district), 90.1% (state).
  expect_equal(ref$retention_pct_district[ref$teachers_admins == "Teachers"], 86.6)
  expect_equal(ref$retention_pct_state[ref$teachers_admins == "Teachers"], 90.1)
})


# ==============================================================================
# fetch_spr_teacher_exp_subject()
# ==============================================================================

test_that("fetch_spr_teacher_exp_subject returns numeric experience shares", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_spr_teacher_exp_subject(2025)

  expect_true(all(c("subject_area", "teacher_count", "fourormoreyearsexp",
                    "bachelors", "masters", "doctoral") %in% names(df)))
  expect_type(df$fourormoreyearsexp, "double")

  ref <- ref_emma(df) %>% dplyr::filter(subject_area == "All Teachers")
  expect_equal(ref$teacher_count, 37)
  # Pinned: 91.9% of Emma C Attales teachers have 4+ years of experience.
  expect_equal(ref$fourormoreyearsexp, 91.9)
})


# ==============================================================================
# fetch_spr_educator_equity()
# ==============================================================================

test_that("fetch_spr_educator_equity returns the statewide summary (no CDS)", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_spr_educator_equity(2025)

  expect_s3_class(df, "data.frame")
  expect_gt(nrow(df), 0)
  expect_true(all(c("end_year", "school_year", "category", "classes_included",
                    "all_students") %in% names(df)))
  # Statewide summary table -> no CDS identifiers.
  expect_false("county_id" %in% names(df))
  expect_type(df$all_students, "double")

  oof <- df %>%
    dplyr::filter(grepl("out-of-field", category, ignore.case = TRUE),
                  classes_included == "Core Classes")
  expect_equal(nrow(oof), 1)
  # Pinned: 5.69% of students taught by an out-of-field teacher (core classes).
  expect_equal(oof$all_students, 0.0569)
})


# ==============================================================================
# Backfill to earlier years (pre-redesign databases)
# ==============================================================================
#
# Values pinned against the NJ DOE SY2023-24 SPR workbooks:
#   https://www.nj.gov/education/sprreports/download/DataFiles/2023-2024/
# Reference school: Absecon (county 01, district 0010), Emma C Attales
# (school 050). Note retention is district-granularity before 2025.
# ==============================================================================

test_that("fetch_spr_staff_counts backfills to SY2020-21 with matching values", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_spr_staff_counts(2024)
  expect_true(all(spr_cols %in% names(df)))
  expect_true("staff_category" %in% names(df))

  ref <- ref_emma(df)
  # Pinned: Emma C Attales has 1 administrator and 37 teachers in SY2023-24.
  expect_equal(ref$school_total_staff[ref$staff_category == "Administrators"], 1)
  expect_equal(ref$school_total_staff[ref$staff_category == "Teachers"], 37)
  # A role with no school-level value reads "N" -> NA.
  expect_true(is.na(
    ref$school_total_staff[ref$staff_category == "Child Study Team Members"]
  ))

  # The sheet first appears in SY2020-21.
  expect_gt(nrow(fetch_spr_staff_counts(2021, level = "district")), 0)
})

test_that("fetch_spr_staff_education backfills via TeachersAdminsLevelOfEducation", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_spr_staff_education(2024)
  expect_true(all(c("teachers_admins", "bachelors", "masters", "doctoral")
                  %in% names(df)))
  expect_type(df$masters, "double")

  ref <- ref_emma(df)
  # Pinned: Emma C Attales teachers 56.8% Bachelor's, 40.5% Master's,
  # 2.7% Doctoral in SY2023-24.
  expect_equal(ref$bachelors[ref$teachers_admins == "Teachers"], 56.8)
  expect_equal(ref$masters[ref$teachers_admins == "Teachers"], 40.5)
  expect_equal(ref$doctoral[ref$teachers_admins == "Teachers"], 2.7)
  # The legacy "Admin" label is normalized to "Administrators".
  expect_true("Administrators" %in% df$teachers_admins)
  expect_false("Admin" %in% df$teachers_admins)
})

test_that("fetch_spr_staff_retention backfills at district level", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_spr_staff_retention(2024, level = "district")
  expect_true(all(c("teachers_admins", "retention_pct_district",
                    "retention_pct_state") %in% names(df)))
  expect_type(df$retention_pct_district, "double")

  ref <- dplyr::filter(df, county_id == "01", district_id == "0010")
  # Pinned: Absecon teacher retention 93.5% (district), 89.5% (state) in SY2023-24.
  expect_equal(ref$retention_pct_district[ref$teachers_admins == "Teachers"], 93.5)
  expect_equal(ref$retention_pct_state[ref$teachers_admins == "Teachers"], 89.5)
})
