# ==============================================================================
# Tests for Graduation Pathways, Home-Language Enrollment, and NAEP Fetchers
# ==============================================================================
#
# Live-network tests for the redesigned 2024-25 SPR sheets:
#   fetch_spr_grad_pathways()
#   fetch_spr_home_language()
#   fetch_spr_naep()    (District/State database only; no CDS breakdown)
#
# Pinned values verified against the NJ DOE 2024-25 SPR workbooks at:
#   https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/
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

test_that("grad-pathways/home-language/NAEP error (no fabrication) for pre-2025", {
  expect_error(fetch_spr_grad_pathways(2024), "end_year >= 2025")
  expect_error(fetch_spr_home_language(2023), "end_year >= 2025")
  expect_error(fetch_spr_naep(2020), "end_year >= 2025")
})


# ==============================================================================
# fetch_spr_grad_pathways()
# ==============================================================================

test_that("fetch_spr_grad_pathways returns expected structure", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_spr_grad_pathways(2025)

  expect_s3_class(df, "data.frame")
  expect_gt(nrow(df), 0)
  expect_true(all(spr_cols %in% names(df)))
  expect_true(all(c(
    "subject", "statewide_assessment", "substitute_competency_test",
    "portfolio_appeals", "alternate_requirements_in_iep"
  ) %in% names(df)))

  expect_true(all(c("ELA", "Math") %in% df$subject))
  # Pathway percentages are numeric on a 0-100 scale.
  expect_type(df$statewide_assessment, "double")
  vals <- df$statewide_assessment[!is.na(df$statewide_assessment)]
  expect_true(all(vals >= 0 & vals <= 100))
})

test_that("fetch_spr_grad_pathways values match the raw NJ DOE file", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  ref <- fetch_spr_grad_pathways(2025) %>%
    dplyr::filter(
      county_id == "01", district_id == "0110", school_id == "010",
      subject == "ELA"
    )

  expect_equal(nrow(ref), 1)
  # Pinned from GraduationPathways, Atlantic City High School, ELA, SY2024-25:
  expect_equal(ref$statewide_assessment, 59.7)
  expect_equal(ref$substitute_competency_test, 3.2)
  expect_equal(ref$portfolio_appeals, 20.9)
  expect_equal(ref$alternate_requirements_in_iep, 16.0)
})


# ==============================================================================
# fetch_spr_home_language()
# ==============================================================================

test_that("fetch_spr_home_language returns expected structure", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_spr_home_language(2025)

  expect_s3_class(df, "data.frame")
  expect_gt(nrow(df), 0)
  expect_true(all(spr_cols %in% names(df)))
  expect_true(all(c("home_language", "percent_of_students") %in% names(df)))

  expect_true("English" %in% df$home_language)
  expect_type(df$percent_of_students, "double")
})

test_that("fetch_spr_home_language values match the raw NJ DOE file", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  ref <- fetch_spr_home_language(2025) %>%
    dplyr::filter(county_id == "01", district_id == "0010", school_id == "050")

  # Pinned from EnrollmentByHomeLanguage, Emma C Attales, SY2024-25:
  expect_equal(ref$percent_of_students[ref$home_language == "English"], 76.1)
  expect_equal(ref$percent_of_students[ref$home_language == "Spanish"], 17.1)
})


# ==============================================================================
# fetch_spr_naep()
# ==============================================================================

test_that("fetch_spr_naep returns the state/national summary structure", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_spr_naep(2025)

  expect_s3_class(df, "data.frame")
  expect_gt(nrow(df), 0)
  # NAEP has no CDS identifiers; it is a state/national summary table.
  expect_true(all(c(
    "end_year", "test_year", "state_nation", "subject", "grade",
    "student_group", "below_basic", "basic", "proficient", "advanced"
  ) %in% names(df)))
  expect_false("county_id" %in% names(df))

  expect_true(all(c("New Jersey", "Nation") %in% df$state_nation))
  # test_year is the NAEP administration year (integer); sentinels are dropped.
  expect_type(df$test_year, "integer")
  expect_false(any(is.na(df$test_year)))
  expect_type(df$proficient, "double")
})

test_that("fetch_spr_naep values match the raw NJ DOE file", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  g4math <- fetch_spr_naep(2025) %>%
    dplyr::filter(
      test_year == 2024, subject == "Mathematics", grade == "4",
      student_group == "All Students"
    )

  nj <- g4math %>% dplyr::filter(state_nation == "New Jersey")
  nation <- g4math %>% dplyr::filter(state_nation == "Nation")

  expect_equal(nrow(nj), 1)
  expect_equal(nrow(nation), 1)
  # Pinned from NAEP, 2024 administration, Grade 4 Mathematics, All Students:
  expect_equal(nj$proficient, 33)
  expect_equal(nation$below_basic, 24)
})
