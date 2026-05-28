# =============================================================================
# Issue #98 + #70: PARCC aggregate provenance columns
#
#   #98 -> parcc_aggregate_calcs() should report which test(s) were combined,
#          via `tests = collapse_agg_names(test_name)`.
#   #70 -> parcc_aggregate_calcs() should report how many schools were combined,
#          mirroring n_charter_rows, via `n_schools = n_distinct(school_name)`.
#
# The data frames below are TEST-ONLY logic fixtures. Every number is chosen by
# hand purely to exercise the aggregation MATH and the new provenance columns.
# They are NOT real NJ DOE figures, are never written to data/ or
# inst/extdata/, and must not be presented as actual assessment results.
# =============================================================================

test_that("parcc_aggregate_calcs reports tests and n_schools and rolls up counts (#98, #70)", {
  # TEST-ONLY fixture (not real NJ data): a single district with two schools.
  # School A is a 3-8 school -> 2 math grade rows (03, 04).
  # School B is a high school -> 1 math course row (ALG1).
  # All rows share test_name = "math". This mirrors the real grouped input that
  # calculate_agg_parcc_prof() feeds in: one row per (school, grade/course),
  # with grade NOT a grouping key so grades roll up into one span row.
  test_df <- tibble::tibble(
    district_name = rep("TEST DISTRICT", 3),
    school_name = c("School A", "School A", "School B"),
    test_name = rep("math", 3),
    grade = c("03", "04", "ALG1"),
    is_charter = c(FALSE, FALSE, FALSE),
    number_enrolled = c(100, 110, 90),
    number_not_tested = c(5, 4, 6),
    number_of_valid_scale_scores = c(100, 100, 100),
    scale_score_mean = c(740, 750, 760),
    # Performance-level percentages sum to 100 within each row.
    pct_l1 = c(10, 10, 10),
    pct_l2 = c(20, 20, 20),
    pct_l3 = c(30, 30, 30),
    pct_l4 = c(25, 25, 25),
    pct_l5 = c(15, 15, 15)
  ) %>%
    parcc_perf_level_counts()

  result <- test_df %>%
    dplyr::group_by(district_name) %>%
    parcc_aggregate_calcs() %>%
    dplyr::ungroup()

  # One aggregate row for the single district group.
  expect_equal(nrow(result), 1)

  # ---- #98: tests column ----
  # All three input rows are test_name "math", so it collapses to a single name.
  expect_true("tests" %in% names(result))
  expect_equal(result$tests, "math")

  # ---- #70: n_schools column ----
  # Two distinct schools (A, B) across three rows. n_distinct, not n(): if this
  # used n() it would return 3 (one per grade/course row), overcounting.
  expect_true("n_schools" %in% names(result))
  expect_equal(result$n_schools, 2L)

  # Sanity check that the existing schools-string collapsing still works:
  # School A appears in 2 rows, School B in 1.
  expect_equal(result$schools, "School A (2), School B (1)")

  # ---- enrollment / not-tested / valid-score sums roll up correctly ----
  expect_equal(result$number_enrolled, 100 + 110 + 90)
  expect_equal(result$number_not_tested, 5 + 4 + 6)
  expect_equal(result$number_of_valid_scale_scores, 100 + 100 + 100)

  # ---- performance-level counts roll up correctly ----
  # Each row has 100 valid scores, so num_lX = pct_lX per row; summed over 3 rows.
  expect_equal(result$num_l1, 3 * 10)
  expect_equal(result$num_l2, 3 * 20)
  expect_equal(result$num_l3, 3 * 30)
  expect_equal(result$num_l4, 3 * 25)
  expect_equal(result$num_l5, 3 * 15)

  # ---- recomputed percentages off the rolled-up counts ----
  # 300 valid scores total; e.g. num_l1 = 30 -> pct_l1 = 10.0
  expect_equal(result$pct_l1, 10.0)
  expect_equal(result$pct_l4, 25.0)
  expect_equal(result$pct_l5, 15.0)
  # proficient_above = (num_l4 + num_l5) / valid * 100 = (75 + 45) / 300 * 100
  expect_equal(result$proficient_above, 40.0)

  # ---- enrollment-weighted scale score mean ----
  # weighted by valid scores (equal weights here): mean(740, 750, 760) = 750
  expect_equal(result$scale_score_mean, 750)
})


test_that("parcc_aggregate_calcs tests column lists multiple tests with counts when subjects mix (#98)", {
  # TEST-ONLY fixture (not real NJ data): a single school with one math row and
  # two ela rows, to confirm `tests` enumerates each distinct test_name with its
  # count when an aggregate genuinely spans more than one assessment.
  test_df <- tibble::tibble(
    district_name = rep("TEST DISTRICT", 3),
    school_name = rep("School A", 3),
    test_name = c("math", "ela", "ela"),
    grade = c("03", "03", "04"),
    is_charter = rep(FALSE, 3),
    number_enrolled = rep(100, 3),
    number_not_tested = rep(0, 3),
    number_of_valid_scale_scores = rep(100, 3),
    scale_score_mean = rep(750, 3),
    pct_l1 = rep(20, 3),
    pct_l2 = rep(20, 3),
    pct_l3 = rep(20, 3),
    pct_l4 = rep(20, 3),
    pct_l5 = rep(20, 3)
  ) %>%
    parcc_perf_level_counts()

  result <- test_df %>%
    dplyr::group_by(district_name) %>%
    parcc_aggregate_calcs() %>%
    dplyr::ungroup()

  # ela appears in 2 rows, math in 1; collapse_agg_names sorts by frequency desc.
  expect_equal(result$tests, "ela (2), math (1)")
  # Single school across all three rows.
  expect_equal(result$n_schools, 1L)
})


test_that("parcc_aggregate_calcs n_charter_rows is unchanged by new columns (#70 mirrors #69)", {
  # TEST-ONLY fixture (not real NJ data): mix of charter and non-charter rows to
  # confirm n_charter_rows (the #69 pattern n_schools is modeled on) still counts
  # flagged input rows, independent of the new n_schools distinct-school count.
  test_df <- tibble::tibble(
    district_name = rep("TEST DISTRICT", 4),
    school_name = c("Charter A", "Charter A", "Charter B", "District School"),
    test_name = rep("math", 4),
    grade = c("03", "04", "03", "03"),
    is_charter = c(TRUE, TRUE, TRUE, FALSE),
    number_enrolled = rep(100, 4),
    number_not_tested = rep(0, 4),
    number_of_valid_scale_scores = rep(100, 4),
    scale_score_mean = rep(750, 4),
    pct_l1 = rep(20, 4),
    pct_l2 = rep(20, 4),
    pct_l3 = rep(20, 4),
    pct_l4 = rep(20, 4),
    pct_l5 = rep(20, 4)
  ) %>%
    parcc_perf_level_counts()

  result <- test_df %>%
    dplyr::group_by(district_name) %>%
    parcc_aggregate_calcs() %>%
    dplyr::ungroup()

  # 3 charter-flagged input rows.
  expect_equal(result$n_charter_rows, 3L)
  # 3 distinct schools (Charter A counted once despite 2 rows).
  expect_equal(result$n_schools, 3L)
})


test_that("calculate_agg_parcc_prof carries tests and n_schools through to output (#98, #70)", {
  # Integration test against live NJ DOE data; skips offline or if unavailable.
  skip_if_offline()

  agg <- tryCatch(
    calculate_agg_parcc_prof(end_year = 2023, subj = "math", gradespan = "3-11"),
    error = function(e) NULL
  )
  skip_if(is.null(agg), "PARCC data URL not accessible")

  expect_true(all(c("tests", "n_schools") %in% names(agg)))

  # gradespan label applied after aggregation; grades genuinely rolled up.
  expect_true(all(agg$grade == "3-11"))
  # single subject in, so tests collapses to "math" on every row.
  expect_true(all(agg$tests == "math"))

  # n_schools is a non-negative count.
  expect_true(all(agg$n_schools >= 0))

  # A school-level row aggregates only that school -> exactly one distinct
  # school name in its input rows.
  school_rows <- agg %>% dplyr::filter(is_school)
  if (nrow(school_rows) > 0) {
    expect_true(all(school_rows$n_schools == 1))
  }

  # NJ DOE district/state rows are themselves pre-aggregated summary rows that
  # carry no school name (school_name is NA), so n_distinct(school_name) is 1
  # for those groups. n_schools counts distinct school NAMES among the grouped
  # input rows -- not the universe of schools in NJ -- so district- and
  # state-level aggregates correctly report 1.
  district_rows <- agg %>% dplyr::filter(is_district)
  if (nrow(district_rows) > 0) {
    expect_true(all(district_rows$n_schools == 1))
  }
  state_total <- agg %>%
    dplyr::filter(is_state, subgroup == "total_population")
  if (nrow(state_total) > 0) {
    expect_equal(unique(state_total$n_schools), 1L)
  }
})
