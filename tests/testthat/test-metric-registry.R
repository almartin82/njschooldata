test_that("metric registry has valid required metadata", {
  registry <- load_metric_registry()

  expect_named(
    registry,
    c(
      "domain", "metric", "label", "unit", "polarity", "is_rate",
      "denominator_metric", "era_break_set", "notes"
    )
  )
  expect_gt(nrow(registry), 0)
  expect_equal(anyDuplicated(registry$metric), 0)
  expect_true(all(registry$polarity %in% c(
    "higher_is_better", "lower_is_better", "neutral"
  )))
  expect_false(any(is.na(registry$label) | registry$label == ""))
  expect_false(any(is.na(registry$unit) | registry$unit == ""))
  expect_type(registry$is_rate, "logical")
})


test_that("finance metrics emitted by fetch_finance are registered", {
  registry <- load_metric_registry()
  finance_metrics <- get(".finance_metrics", envir = asNamespace("njschooldata"))

  missing <- setdiff(finance_metrics, registry$metric)
  expect_length(missing, 0)
})


test_that("course metrics emitted by fetch_courses are registered", {
  registry <- load_metric_registry()
  course_metrics <- c(
    "students_enrolled", "students_tested",
    "apib_coursework_school", "apib_coursework_state",
    "apib_exam_school", "apib_exam_state",
    "ap3_ib4_school", "ap3_ib4_state",
    "dual_enrollment_school", "dual_enrollment_state",
    "apib_pct_school", "apib_pct_district", "apib_pct_state",
    "dual_pct_school", "dual_pct_district", "dual_pct_state",
    "sle_pct_school", "sle_pct_district", "sle_pct_state",
    "cte_participants", "cte_concentrators",
    "state_cte_participants", "state_cte_concentrators",
    "earned_one_credential", "credentials_earned",
    "students_participating", "pct_participating",
    "apprenticeship_count", "apprenticeship_8_year_total",
    "sat_participation", "act_participation", "psat_participation",
    "sat_participation_state", "act_participation_state",
    "psat_participation_state",
    "college_exam_avg_score_school",
    "college_exam_avg_score_district",
    "college_exam_avg_score_state",
    "college_exam_benchmark_school",
    "college_exam_benchmark_district",
    "college_exam_benchmark_state"
  )

  missing <- setdiff(course_metrics, registry$metric)
  expect_length(missing, 0)
})


test_that("annotate_metric attaches row-wise metadata for long finance output", {
  df <- tibble::tibble(
    metric = c("per_pupil_total", "revenue_state"),
    value = c(25000, 1000000)
  )

  annotated <- annotate_metric(df)

  expect_equal(names(df), names(annotated)[seq_along(names(df))])
  expect_equal(annotated$polarity, c("neutral", "neutral"))
  expect_equal(annotated$unit, c("dollars", "dollars"))
  expect_equal(annotated$is_rate, c(TRUE, FALSE))
})


test_that("favorable percentile flips lower-is-better and preserves higher-is-better", {
  df <- tibble::tibble(
    district_id = c("A", "B", "C"),
    discipline_rate = c(10, 20, 30),
    grad_rate = c(70, 80, 90)
  )

  lower_ranked <- df %>%
    add_favorable_percentile_rank("discipline_rate")

  expect_equal(
    lower_ranked$discipline_rate_favorable_percentile,
    c(100, 66.7, 33.3)
  )

  higher_ranked <- df %>%
    add_favorable_percentile_rank("grad_rate")

  expect_equal(
    higher_ranked$grad_rate_favorable_percentile,
    c(33.3, 66.7, 100)
  )
})
