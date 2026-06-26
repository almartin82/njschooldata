# ==============================================================================
# Tests for fetch_restraint_seclusion()
# ==============================================================================
#
# Live-network tests for the NJ DOE standalone DARS school-level Restraint &
# Seclusion workbooks. Pinned values are verified by hand against the published
# workbooks at:
#   https://www.nj.gov/education/vandv/annualreport/dars/
#     2022_23RestraintAndSeclusionSchoolLevelDatabase.xlsx        (end_year 2023)
#     2023_24RestraintAndSeclusionSchoolLevelDatabasePublic.xlsx  (end_year 2024)
#
# Data sheet: "Restraints and Seclusions" (2nd sheet), real header row 12
# (skip = 11). 27 published columns, ~46k rows (school x student group).
#
# Verified anchor cells (read directly from the downloaded workbooks):
#   2023 Absecon Public Schools (district 0010) / Emma C Attales (school 050),
#     "Schoolwide": any=1, restraint=1, seclusion=0.
#   2024 same school, "School Total": any=0, restraint=0, seclusion=0.
#   2023 Gloucester County Special Services (1774) / Bankbridge Regional (015),
#     "Schoolwide": any=158, restraint=157, seclusion=21.
#   2024 same school, "School Total": any=113, restraint=112, seclusion=12.
#   2023 Absecon Emma C Attales "Asian": any cell is "<5" -> must be NA.
#   2024 Brigantine (0570) / Brigantine Community (300) "Asian": "<5" -> NA.
# ==============================================================================

rs_id_flag_cols <- c(
  "end_year",
  "county_id", "county_name",
  "district_id", "district_name",
  "school_id", "school_name",
  "student_group", "subgroup", "grade_level",
  "is_state", "is_county", "is_district", "is_school",
  "is_charter", "is_charter_sector", "is_allpublic"
)

rs_value_cols <- c(
  "any_restraint_seclusion_count", "any_restraint_seclusion_pct",
  "restraint_count", "restraint_pct",
  "restraint_physical_count", "restraint_physical_pct",
  "restraint_mechanical_count", "restraint_mechanical_pct",
  "restraint_both_phys_mech_count", "restraint_both_phys_mech_pct",
  "seclusion_count", "seclusion_pct",
  "both_restraint_seclusion_count", "both_restraint_seclusion_pct",
  "both_physical_restraint_count", "both_physical_restraint_pct",
  "both_mechanical_restraint_count", "both_mechanical_restraint_pct",
  "both_phys_mech_restraint_count", "both_phys_mech_restraint_pct"
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

test_that("fetch_restraint_seclusion rejects non-school level", {
  expect_error(fetch_restraint_seclusion(2024, level = "district"),
               "school-level only")
})

test_that("fetch_restraint_seclusion rejects unsupported years", {
  expect_error(fetch_restraint_seclusion(2022), "2023.*2024")
  expect_error(fetch_restraint_seclusion(2025), "2023.*2024")
  expect_error(fetch_restraint_seclusion(2019), "2023.*2024")
})


# ==============================================================================
# Suppression coercion (pure, no network) -- the load-bearing data-integrity test
# ==============================================================================

test_that("rs_value_numeric maps masked cells to NA, never the digit 5", {
  # "<5" is a RANGE for 1-4 students -- it must become NA, NOT 5.
  expect_true(is.na(rs_value_numeric("<5")))
  expect_true(is.na(rs_value_numeric("<5.00")))
  expect_true(is.na(rs_value_numeric("<10")))
  expect_true(is.na(rs_value_numeric("*")))
  expect_true(is.na(rs_value_numeric("")))
  # Real numbers (including a genuine 0) pass through unchanged.
  expect_equal(rs_value_numeric("0"), 0)
  expect_equal(rs_value_numeric("5"), 5)
  expect_equal(rs_value_numeric("158"), 158)
  expect_equal(rs_value_numeric("1,234"), 1234)
  # Vectorized: the "<5" element is NA, not 5.
  out <- rs_value_numeric(c("<5", "1", "*", "0", "12"))
  expect_equal(out, c(NA, 1, NA, 0, 12))
})

test_that("rs_split_student_group normalizes the DARS labels", {
  sp <- rs_split_student_group(c(
    "Schoolwide", "School Total", "Grade Preschool", "Grade Kindergarten",
    "Grade 3", "Black or African-American", "Students with disabilities"
  ))
  expect_equal(sp$subgroup, c(
    "total population", "total population", "total population",
    "total population", "total population", "black",
    "students with disabilities"
  ))
  expect_equal(sp$grade_level, c(
    "TOTAL", "TOTAL", "PK", "K", "03", "TOTAL", "TOTAL"
  ))
})


# ==============================================================================
# Structure
# ==============================================================================

test_that("fetch_restraint_seclusion returns expected structure", {
  local_big_download_timeout()
  df <- fetch_restraint_seclusion(2024)
  expect_s3_class(df, "data.frame")
  expect_true(all(rs_id_flag_cols %in% names(df)))
  expect_true(all(rs_value_cols %in% names(df)))
  # School-only source: every row is a school, no aggregates.
  expect_true(all(df$is_school))
  expect_false(any(df$is_state | df$is_county | df$is_district))
  # Value columns are numeric.
  expect_type(df$any_restraint_seclusion_count, "double")
})


# ==============================================================================
# Raw-fidelity anchors (counts EXACT) -- both years + a large-count anchor
# ==============================================================================

test_that("fetch_restraint_seclusion matches verified 2023 source cells", {
  local_big_download_timeout()
  df <- fetch_restraint_seclusion(2023)

  # Absecon / Emma C Attales, "Schoolwide".
  a <- df[df$district_id == "0010" & df$school_id == "050" &
            df$subgroup == "total population" & df$grade_level == "TOTAL", ]
  expect_equal(nrow(a), 1)
  expect_equal(a$any_restraint_seclusion_count, 1)
  expect_equal(a$restraint_count, 1)
  expect_equal(a$seclusion_count, 0)

  # Large-count anchor: Bankbridge Regional School (Gloucester Co Special Svcs).
  big <- df[df$district_id == "1774" & df$school_id == "015" &
              df$subgroup == "total population" & df$grade_level == "TOTAL", ]
  expect_equal(nrow(big), 1)
  expect_equal(big$any_restraint_seclusion_count, 158)
  expect_equal(big$restraint_count, 157)
  expect_equal(big$seclusion_count, 21)
})

test_that("fetch_restraint_seclusion matches verified 2024 source cells", {
  local_big_download_timeout()
  df <- fetch_restraint_seclusion(2024)

  # Absecon / Emma C Attales, "School Total" (the 2023-24 total label).
  a <- df[df$district_id == "0010" & df$school_id == "050" &
            df$subgroup == "total population" & df$grade_level == "TOTAL", ]
  expect_equal(nrow(a), 1)
  expect_equal(a$any_restraint_seclusion_count, 0)
  expect_equal(a$restraint_count, 0)
  expect_equal(a$seclusion_count, 0)

  # Large-count anchor: Bankbridge Regional School.
  big <- df[df$district_id == "1774" & df$school_id == "015" &
              df$subgroup == "total population" & df$grade_level == "TOTAL", ]
  expect_equal(nrow(big), 1)
  expect_equal(big$any_restraint_seclusion_count, 113)
  expect_equal(big$restraint_count, 112)
  expect_equal(big$seclusion_count, 12)
})


# ==============================================================================
# Suppression: a known "<5" cell must be NA (not 5)
# ==============================================================================

test_that("fetch_restraint_seclusion suppresses '<5' cells to NA", {
  local_big_download_timeout()

  # 2023 Absecon / Emma C Attales "Asian": published any-count is "<5" -> NA.
  df23 <- fetch_restraint_seclusion(2023)
  s23 <- df23[df23$district_id == "0010" & df23$school_id == "050" &
                df23$subgroup == "asian", ]
  expect_equal(nrow(s23), 1)
  expect_true(is.na(s23$any_restraint_seclusion_count))
  expect_false(isTRUE(s23$any_restraint_seclusion_count == 5))

  # 2024 Brigantine / Brigantine Community School "Asian": "<5" -> NA.
  df24 <- fetch_restraint_seclusion(2024)
  s24 <- df24[df24$district_id == "0570" & df24$school_id == "300" &
                df24$subgroup == "asian", ]
  expect_equal(nrow(s24), 1)
  expect_true(is.na(s24$any_restraint_seclusion_count))
})


# ==============================================================================
# Subgroup / grade split correctness on real data
# ==============================================================================

test_that("fetch_restraint_seclusion splits subgroup and grade correctly", {
  local_big_download_timeout()
  df <- fetch_restraint_seclusion(2024)

  # Grade Kindergarten rows -> grade_level "K", subgroup "total population".
  gk <- df[df$student_group == "Grade Kindergarten", ]
  expect_true(nrow(gk) > 0)
  expect_true(all(gk$grade_level == "K"))
  expect_true(all(gk$subgroup == "total population"))

  # Black-or-African-American rows -> subgroup "black", grade_level "TOTAL".
  bk <- df[df$student_group == "Black or African-American", ]
  expect_true(nrow(bk) > 0)
  expect_true(all(bk$subgroup == "black"))
  expect_true(all(bk$grade_level == "TOTAL"))

  # Grade Preschool -> "PK".
  pk <- df[df$student_group == "Grade Preschool", ]
  expect_true(nrow(pk) > 0)
  expect_true(all(pk$grade_level == "PK"))
})


# ==============================================================================
# Sanity: one row per (school, student_group); counts sane; Newark present
# ==============================================================================

test_that("fetch_restraint_seclusion is one row per (school, student_group)", {
  local_big_download_timeout()
  for (yr in c(2023, 2024)) {
    df <- fetch_restraint_seclusion(yr)
    dups <- df %>%
      dplyr::count(district_id, school_id, student_group) %>%
      dplyr::filter(n > 1)
    expect_equal(nrow(dups), 0, info = paste("year", yr))
  }
})

test_that("fetch_restraint_seclusion counts are sane and Newark is present", {
  local_big_download_timeout()
  for (yr in c(2023, 2024)) {
    df <- fetch_restraint_seclusion(yr)

    # Newark (district 3570) present.
    expect_true(any(df$district_id == "3570"), info = paste("year", yr))

    # Row count in an established band (~46k school x student-group rows).
    expect_true(nrow(df) > 40000 && nrow(df) < 50000, info = paste("year", yr))

    # Counts are non-negative and integer-valued where not NA.
    cc <- df$any_restraint_seclusion_count
    cc <- cc[!is.na(cc)]
    expect_true(all(cc >= 0), info = paste("year", yr))
    expect_true(all(cc == floor(cc)), info = paste("year", yr))
  }
})
