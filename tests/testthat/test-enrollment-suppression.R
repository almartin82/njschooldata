test_that("a censored percentage is NA, never a midpoint", {
  # NJ DOE writes ">95" instead of a value when a share exceeds 95 percent.
  # The token is a statement that the value was withheld. It must not become
  # a number.
  expect_true(is.na(enr_pct_published_value(">95")))
  expect_false(identical(enr_pct_published_value(">95"), 97.5))

  # Whitespace and a trailing percent sign around the token change nothing.
  expect_true(is.na(enr_pct_published_value(" >95 ")))
  expect_true(is.na(enr_pct_published_value(">95%")))
})

test_that("published percentages pass through exactly", {
  expect_equal(enr_pct_published_value("12.4"), 12.4)
  expect_equal(enr_pct_published_value("100"), 100)
  expect_equal(enr_pct_published_value("95"), 95)
  expect_equal(enr_pct_published_value(" 7.5 "), 7.5)
  expect_equal(enr_pct_published_value("12.4%"), 12.4)
})

test_that("a real published zero survives; a blank does not become zero", {
  expect_equal(enr_pct_published_value("0"), 0)
  expect_equal(enr_pct_published_value("0.0"), 0)

  expect_true(is.na(enr_pct_published_value("")))
  expect_true(is.na(enr_pct_published_value(NA_character_)))
  expect_true(is.na(enr_pct_published_value("*")))
  expect_true(is.na(enr_pct_published_value("N")))
})

test_that("a vector mixes published and censored cells without contaminating either", {
  observed <- enr_pct_published_value(c("12.4", ">95", "0", "", "88"))

  expect_equal(observed[1], 12.4)
  expect_true(is.na(observed[2]))
  expect_equal(observed[3], 0)
  expect_true(is.na(observed[4]))
  expect_equal(observed[5], 88)

  # No warning: the censoring token is recognised before coercion, not left to
  # as.numeric() to turn into NA by accident.
  expect_silent(enr_pct_published_value(c("12.4", ">95")))
})

test_that("a count derived from a censored percentage is unknown, not invented", {
  # These populations are published ONLY as percentages, so the count is
  # pct / 100 * total. When the percentage is censored the count is unknown.
  total <- c(1000, 1000)
  counts <- enr_pct_published_value(c("12.4", ">95")) / 100 * total

  expect_equal(counts[1], 124)
  expect_true(is.na(counts[2]))

  # The specific number the old code produced, so this test names what it is
  # guarding against: ">95" was rewritten to "97.5" and multiplied out to 975.
  expect_false(identical(counts[2], 975))
})

test_that("the midpoint substitution has not returned to the enrollment fetcher", {
  # Gate, not a style check. From 2020 until 2026-08 get_raw_enr() rewrote
  # ">95" to "97.5" and multiplied it by Total Enrollment, publishing an
  # invented headcount for free lunch, reduced lunch, English learners,
  # migrant, military and homeless students. Missing data stays missing.
  source_path <- test_path("..", "..", "R", "fetch_enrollment.R")
  skip_if_not(file.exists(source_path), "package source not available")

  source_text <- readLines(source_path, warn = FALSE)
  substitution <- grepl("97\\.5", source_text) & grepl(">95", source_text)

  expect_equal(
    sum(substitution), 0,
    info = paste(
      "R/fetch_enrollment.R substitutes a value for the >95 censoring token at:",
      paste(which(substitution), collapse = ", ")
    )
  )
})
