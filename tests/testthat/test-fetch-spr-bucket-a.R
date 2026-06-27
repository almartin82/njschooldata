# ==============================================================================
# Tests for SPR "Bucket A" assessment / graduation detail fetchers
# ==============================================================================
#
# Live-network tests for sheets first published in (or, for
# FederalGraduationRates, expanded by) the redesigned SY2024-25 SPR databases:
#   fetch_spr_proficiency_by_test()  (ELAPerformanceByTest / MathPerformancebyTest)
#   fetch_spr_science_grade()        (NJSLASciencebyGradeTrends)
#   fetch_spr_elp_progress()         (ProgressTowardELP)
#   fetch_spr_grad_cohort()          (GraduationCohortProfile)
#   fetch_spr_fed_grad()             (FederalGraduationRates, 2021-2025)
#
# Pinned values verified against the NJ DOE SPR workbooks at:
#   https://www.nj.gov/education/sprreports/download/DataFiles/
#
# ==============================================================================

spr_a_cols <- c(
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
# Argument validation / coverage gates (no network)
# ==============================================================================

test_that("Bucket A fetchers gate at their real first available year", {
  # elp_progress stays 2025-only (the legacy sheet is a different metric).
  expect_error(fetch_spr_elp_progress(2024), ">= 2025")
  # proficiency_by_test: 2017-2019 and 2022-2025; COVID years 2020/2021 error.
  expect_error(fetch_spr_proficiency_by_test(2020), "2017-2019 and")
  expect_error(fetch_spr_proficiency_by_test(2021), "2017-2019 and")
  expect_error(fetch_spr_proficiency_by_test(2016), "2017-2019 and")
  # science_grade: 2019 and 2021-2025; 2020 COVID and 2017-2018 (NJASK) error.
  expect_error(fetch_spr_science_grade(2020), "2019 and")
  expect_error(fetch_spr_science_grade(2018), "2019 and")
  # grad_cohort: 2020+ (cohort-profile sheets); error before 2020.
  expect_error(fetch_spr_grad_cohort(2019), "end_year >= 2020")
  # FederalGraduationRates exists from SY2020-21; error before that.
  expect_error(fetch_spr_fed_grad(2020), "end_year >= 2021")
  # subject must be ela/math.
  expect_error(fetch_spr_proficiency_by_test(2025, subject = "science"),
               "subject must be one of")
})

test_that("normalize_grade_test maps pre-redesign labels to the 2025 form", {
  expect_equal(
    normalize_grade_test(c("Grade 03", "Grade 08", "Grade 10",
                           "ALG01", "ALG02", "GEO01")),
    c("Grade 3", "Grade 8", "Grade 10", "Algebra I", "Algebra II", "Geometry")
  )
})


# ==============================================================================
# fetch_spr_proficiency_by_test()
# ==============================================================================

test_that("fetch_spr_proficiency_by_test returns expected structure", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  df <- fetch_spr_proficiency_by_test(2025, subject = "ela")
  expect_s3_class(df, "data.frame")
  expect_gt(nrow(df), 0)
  expect_true(all(spr_a_cols %in% names(df)))
  expect_true(all(c("subject", "grade_test", "subgroup", "valid_scores",
                    "mean_scaled_score", "proficiency_rate",
                    "level_1", "level_5") %in% names(df)))
  expect_equal(unique(df$subject), "ELA")
  # Filtered to the requested academic year.
  expect_equal(unique(df$school_year[!is.na(df$school_year)]), "2024-25")
  expect_type(df$proficiency_rate, "double")
})

test_that("fetch_spr_proficiency_by_test matches published statewide cells", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  # ELA Grade 4, All Students, statewide (SY2024-25 District workbook).
  ela <- fetch_spr_proficiency_by_test(2025, subject = "ela", level = "district")
  ref <- ela %>%
    dplyr::filter(is_state, grade_test == "Grade 4",
                  subgroup == "total population")
  expect_equal(nrow(ref), 1)
  expect_equal(ref$proficiency_rate, 53.5)
  expect_equal(ref$valid_scores, 93574)

  # Math Algebra I is a high-school end-of-course test variant exposed only by
  # this by-test sheet (not by fetch_parcc()).
  math <- fetch_spr_proficiency_by_test(2025, subject = "math", level = "district")
  alg <- math %>%
    dplyr::filter(is_state, grade_test == "Algebra I",
                  subgroup == "total population")
  expect_equal(alg$proficiency_rate, 38.1)
  expect_true("Algebra I" %in% math$grade_test)
  expect_true("Geometry" %in% math$grade_test)
})


# ==============================================================================
# fetch_spr_science_grade()
# ==============================================================================

test_that("fetch_spr_science_grade returns expected structure and cells", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  sci <- fetch_spr_science_grade(2025, level = "district")
  expect_true(all(spr_a_cols %in% names(sci)))
  expect_true(all(c("grade", "grade_level", "level_1_percentage",
                    "level_4_percentage") %in% names(sci)))
  # NJSLA science is given at grades 5, 8, 11 -> normalized two-digit labels.
  expect_setequal(unique(sci$grade_level), c("05", "08", "11"))
  expect_equal(unique(sci$school_year[!is.na(sci$school_year)]), "2024-25")

  ref <- sci %>%
    dplyr::filter(is_state, grade_level == "05", subgroup == "total population")
  expect_equal(nrow(ref), 1)
  expect_equal(ref$level_1_percentage, 30.6)
  expect_equal(ref$level_4_percentage, 7.9)
})


# ==============================================================================
# fetch_spr_elp_progress()
# ==============================================================================

test_that("fetch_spr_elp_progress returns one progress rate per entity", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  elp <- fetch_spr_elp_progress(2025, level = "district")
  expect_true(all(spr_a_cols %in% names(elp)))
  expect_true("progress_toward_elp" %in% names(elp))
  # No subgroup/grade breakdown.
  expect_false("subgroup" %in% names(elp))
  expect_equal(unique(elp$school_year[!is.na(elp$school_year)]), "2024-25")

  state <- elp %>% dplyr::filter(is_state)
  expect_equal(nrow(state), 1)
  expect_equal(state$progress_toward_elp, 30.1)
})


# ==============================================================================
# fetch_spr_grad_cohort()
# ==============================================================================

test_that("fetch_spr_grad_cohort exposes 4/5/6-year cohorts", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  gc <- fetch_spr_grad_cohort(2025, level = "district")
  expect_true(all(spr_a_cols %in% names(gc)))
  expect_true(all(c("cohort_type", "subgroup", "graduated", "continuing",
                    "non_continuing", "persisting") %in% names(gc)))
  expect_setequal(unique(gc$cohort_type), c("4-Year", "5-Year", "6-Year"))

  ref <- gc %>%
    dplyr::filter(is_state, cohort_type == "4-Year",
                  subgroup == "total population")
  expect_equal(nrow(ref), 1)
  expect_equal(ref$graduated, 91.8)
  # Persistence (graduated + continuing) is published only for the 6-Year
  # cohort; the 4-Year row's "n/a" must coerce to NA, never a guessed number.
  expect_true(is.na(ref$persisting))
})


# ==============================================================================
# fetch_spr_fed_grad()
# ==============================================================================

test_that("fetch_spr_fed_grad reshapes 2025 redesign layout (long by cohort)", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  fg <- fetch_spr_fed_grad(2025, level = "district")
  expect_true(all(spr_a_cols %in% names(fg)))
  expect_true(all(c("subgroup", "cohort_years", "cohort_label",
                    "graduation_rate_federal") %in% names(fg)))
  expect_setequal(unique(fg$cohort_years), c(4, 5, 6))

  ref <- fg %>%
    dplyr::filter(is_state, subgroup == "total population", cohort_years == 4)
  expect_equal(nrow(ref), 1)
  expect_equal(ref$graduation_rate_federal, 88.9)
  expect_equal(ref$cohort_label, "Cohort 2025")
})

test_that("fetch_spr_fed_grad harmonizes the pre-redesign (2022) layout", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  fg <- fetch_spr_fed_grad(2022, level = "district")
  # 2021-2023 carry only the 4- and 5-year cohorts (no 6-year yet).
  expect_setequal(unique(fg$cohort_years), c(4, 5))

  # Statewide 4-year federal rate is stored in the state_* column on the State
  # row in the legacy layout.
  state <- fg %>%
    dplyr::filter(is_state, subgroup == "total population", cohort_years == 4)
  expect_equal(state$graduation_rate_federal, 85.2)
  expect_equal(state$cohort_label, "Cohort 2022")

  # An ordinary district takes its own x_* value, never the statewide column.
  ac <- fg %>%
    dplyr::filter(is_district, district_id == "0110",
                  subgroup == "total population", cohort_years == 4)
  expect_equal(ac$graduation_rate_federal, 66.5)
})


# ==============================================================================
# Suppression -> NA (no fabrication)
# ==============================================================================

test_that("Bucket A value coercion maps suppression text to NA, keeps real 0", {
  # spr_value_numeric underlies every Bucket A value column.
  expect_true(is.na(spr_value_numeric("n/a")))
  expect_true(is.na(spr_value_numeric("Fewer than 10 students in the cohort.")))
  expect_true(is.na(spr_value_numeric("*")))
  expect_equal(spr_value_numeric("0"), 0)
  expect_equal(spr_value_numeric("53.5%"), 53.5)
  expect_equal(spr_value_numeric("93,574"), 93574)
})


# ==============================================================================
# Pre-redesign backfill years (verified against the legacy workbooks)
# ==============================================================================

test_that("fetch_spr_grad_cohort backfills the pre-redesign cohort sheets", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  # 2024 reads the three separate NYr sheets and stacks them.
  gc24 <- fetch_spr_grad_cohort(2024, level = "district")
  expect_setequal(unique(gc24$cohort_type), c("4-Year", "5-Year", "6-Year"))
  state4 <- gc24 %>%
    dplyr::filter(is_state, cohort_type == "4-Year",
                  subgroup == "total population")
  expect_equal(state4$graduated, 91.3)
  # A real district takes its own value, never the statewide column.
  ac <- gc24 %>%
    dplyr::filter(is_district, district_id == "0110", cohort_type == "4-Year",
                  subgroup == "total population")
  expect_equal(ac$graduated, 81.9)

  # 2020 has only the 4- and 5-year cohorts (no 6-year sheet yet).
  gc20 <- fetch_spr_grad_cohort(2020, level = "district")
  expect_setequal(unique(gc20$cohort_type), c("4-Year", "5-Year"))
  expect_equal(
    (gc20 %>% dplyr::filter(is_state, cohort_type == "4-Year",
                            subgroup == "total population"))$graduated,
    91.0
  )
})

test_that("fetch_spr_proficiency_by_test backfills both pre-redesign eras", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  # 2022-2024 era (grade_subject + percent_testers_met_or_exceeded).
  m24 <- fetch_spr_proficiency_by_test(2024, subject = "math", level = "district")
  expect_true(all(c("Algebra I", "Geometry", "Algebra II", "Grade 3") %in%
                    m24$grade_test))
  alg <- m24 %>%
    dplyr::filter(is_state, grade_test == "Algebra I",
                  subgroup == "total population")
  expect_equal(alg$proficiency_rate, 40)

  # 2017-2019 era (grade + met_exceed).
  m19 <- fetch_spr_proficiency_by_test(2019, subject = "math", level = "district")
  expect_true("Algebra I" %in% m19$grade_test)
  expect_false("school_year" %in% names(m19))  # no trend column pre-2025
  alg19 <- m19 %>%
    dplyr::filter(is_state, grade_test == "Algebra I",
                  subgroup == "total population")
  expect_equal(alg19$proficiency_rate, 42)
})

test_that("fetch_spr_science_grade backfills NJSLA science to 2019", {
  skip_on_cran()
  skip_if_offline()
  local_big_download_timeout()

  # 2022-2024 era (percent_level entity / performance_level_perc state).
  s24 <- fetch_spr_science_grade(2024, level = "district")
  expect_setequal(unique(s24$grade_level), c("05", "08", "11"))
  ref24 <- s24 %>%
    dplyr::filter(is_state, grade_level == "05", subgroup == "total population")
  expect_equal(ref24$level_4_percentage, 6)

  # 2019 era (NJSLAScienceTable, level_1..4 direct).
  s19 <- fetch_spr_science_grade(2019, level = "district")
  ref19 <- s19 %>%
    dplyr::filter(is_state, grade_level == "05", subgroup == "total population")
  expect_equal(ref19$level_4_percentage, 7)
})
