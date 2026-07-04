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


test_that("annotate_metric attaches row-wise metadata for long finance output", {
  df <- tibble::tibble(
    metric = c("per_pupil_total", "revenue_state"),
    value = c(25000, 1000000)
  )

  annotated <- annotate_metric(df)

  expect_equal(names(df), names(annotated)[seq_along(names(df))])
  expect_equal(annotated$polarity, c("neutral", "neutral"))
  expect_equal(annotated$unit, c("dollars", "dollars"))
  expect_equal(annotated$is_rate, c(FALSE, FALSE))
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
