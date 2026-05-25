# ==============================================================================
# Unit tests for parse_rank() (no network)
# ==============================================================================
#
# Through ~2015 a TGES rank is a plain integer ("34").  From 2019 on NJ DOE
# encodes it as "rank|out_of" ("33|57").  parse_rank() must keep the rank integer
# in both eras and turn missing markers ("N.R.", "N.A.", blanks) into NA.
# ==============================================================================

pr <- function(x) njschooldata:::parse_rank(x)


test_that("plain integer ranks pass through unchanged", {
  expect_identical(pr("1"), 1L)
  expect_identical(pr("7"), 7L)
  expect_identical(pr("34"), 34L)
  expect_identical(pr("57"), 57L)
  expect_identical(pr("100"), 100L)
  expect_identical(pr("700"), 700L)
})

test_that("the rank|out_of format keeps the rank, drops the denominator", {
  expect_identical(pr("33|57"), 33L)
  expect_identical(pr("1|99"), 1L)
  expect_identical(pr("7|7"), 7L)
  expect_identical(pr("24|56"), 24L)
  expect_identical(pr("700|700"), 700L)
  expect_identical(pr("12|73"), 12L)
})

test_that("Not Reported / Not Applicable markers become NA", {
  expect_true(is.na(pr("N.R.")))
  expect_true(is.na(pr("N.A.")))
  expect_true(is.na(pr("NR")))
  expect_true(is.na(pr("NA")))
  expect_true(is.na(pr("*")))
  expect_true(is.na(pr("-")))
})

test_that("blanks and NA input become NA", {
  expect_true(is.na(pr("")))
  expect_true(is.na(pr("   ")))
  expect_true(is.na(pr(NA)))
  expect_true(is.na(pr(NA_character_)))
})

test_that("parse_rank is vectorized and preserves length and order", {
  expect_identical(pr(c("12|50", "N.A.", "7")), c(12L, NA, 7L))
  expect_identical(pr(c("1", "2", "3", "4")), 1:4)
  expect_length(pr(c("1", "2", "3")), 3L)
  expect_length(pr(character(0)), 0L)
  expect_identical(pr(c("33|57", "N.R.", "9", "", "1|2")),
                   c(33L, NA, 9L, NA, 1L))
})

test_that("parse_rank always returns an integer vector", {
  expect_type(pr("5"), "integer")
  expect_type(pr("5|9"), "integer")
  expect_type(pr("N.R."), "integer")
  expect_type(pr(c("1", "2|3", "N.A.")), "integer")
  expect_type(pr(character(0)), "integer")
})

test_that("numeric input is coerced to integer", {
  expect_identical(pr(34), 34L)
  expect_identical(pr(c(1, 2, 3)), 1:3)
})

test_that("only the segment before the first pipe is used", {
  expect_identical(pr("5|10|15"), 5L)
  expect_identical(pr("42|"), 42L)
})

test_that("leading/trailing pipe content does not leak into the rank", {
  expect_identical(pr("8|123"), 8L)
  expect_false(identical(pr("8|123"), 8123L))
})
