# Tests for input validation module

test_that("validate_end_year rejects non-numeric values", {
  expect_error(
    validate_end_year("2024", "enrollment"),
    "must be a single numeric"
  )

  expect_error(
    validate_end_year(c(2023, 2024), "enrollment"),
    "must be a single numeric"
  )
})

test_that("validate_end_year rejects non-integer values", {
  expect_error(
    validate_end_year(2024.5, "enrollment"),
    "must be an integer"
  )
})

test_that("validate_end_year rejects years outside valid range", {
  expect_error(
    validate_end_year(1990, "enrollment"),
    "not valid for enrollment"
  )

  expect_error(
    validate_end_year(2030, "enrollment"),
    "not valid for enrollment"
  )
})

test_that("validate_end_year accepts valid years", {
  expect_silent(validate_end_year(2024, "enrollment"))
  expect_silent(validate_end_year(1999, "enrollment"))
  expect_silent(validate_end_year(2019, "parcc"))
})

test_that("validate_end_year rejects COVID year for PARCC", {
  expect_error(
    validate_end_year(2020, "parcc"),
    "COVID-19"
  )
})

test_that("validate_end_year provides helpful error messages", {
  err <- tryCatch(
    validate_end_year(1990, "enrollment"),
    error = function(e) e
  )

  expect_match(err$message, "Valid years")
  expect_match(err$message, "1999")  # Should mention valid range
})

test_that("get_valid_years returns correct years", {
  enr_years <- get_valid_years("enrollment")
  expect_equal(min(enr_years), 1999)
  expect_equal(max(enr_years), 2025)

  parcc_years <- get_valid_years("parcc")
  expect_false(2020 %in% parcc_years)  # COVID year excluded
  expect_true(2019 %in% parcc_years)
  expect_true(2021 %in% parcc_years)
})

test_that("get_valid_years errors on unknown data type", {
  expect_error(
    get_valid_years("unknown"),
    "Unknown data type"
  )
})

test_that("validate_grade accepts valid grades for NJASK", {
  expect_silent(validate_grade(4, "njask", 2010))
  expect_silent(validate_grade(8, "njask", 2010))
})

test_that("validate_grade rejects invalid grades for NJASK", {
  expect_error(
    validate_grade(2, "njask", 2010),
    "not valid for njask"
  )

  # Grade 8 wasn't NJASK before 2008 (was GEPA)
  expect_error(
    validate_grade(8, "njask", 2006),
    "not valid for njask"
  )
})

test_that("validate_grade handles PARCC course codes", {
  expect_silent(validate_grade("ALG1", "parcc", 2023))
  expect_silent(validate_grade("GEO", "parcc", 2023))
  expect_silent(validate_grade("ALG2", "parcc", 2023))
})

test_that("get_valid_grades returns correct grades", {
  # NJASK 2010
  njask_grades <- get_valid_grades("njask", 2010)
  expect_equal(njask_grades, 3:8)

  # PARCC/NJSLA
  parcc_grades <- get_valid_grades("parcc", 2023)
  expect_true("ALG1" %in% parcc_grades)
  expect_true(8 %in% parcc_grades)
})

test_that("validate_subject accepts valid subjects", {
  expect_silent(validate_subject("ela"))
  expect_silent(validate_subject("math"))
  expect_silent(validate_subject("ELA"))
  expect_silent(validate_subject("Math"))
})
test_that("validate_subject rejects invalid subjects", {
  expect_error(
    validate_subject("science"),
    "not valid"
  )
})

test_that("validate_methodology accepts valid values", {
  expect_silent(validate_methodology("4 year"))
  expect_silent(validate_methodology("5 year"))
})

test_that("validate_methodology rejects invalid values", {
  expect_error(
    validate_methodology("6 year"),
    "not valid"
  )
})

test_that("validate_methodology checks 5-year availability", {
  expect_error(
    validate_methodology("5 year", end_year = 2011),
    "not available before 2012"
  )

  expect_silent(validate_methodology("5 year", end_year = 2012))
})

test_that("validate_logical accepts TRUE and FALSE", {
  expect_silent(validate_logical(TRUE, "tidy"))
  expect_silent(validate_logical(FALSE, "tidy"))
})

test_that("validate_logical rejects non-logical values", {
  expect_error(
    validate_logical("true", "tidy"),
    "must be TRUE or FALSE"
  )

  expect_error(
    validate_logical(1, "tidy"),
    "must be TRUE or FALSE"
  )

  expect_error(
    validate_logical(NA, "tidy"),
    "must be TRUE or FALSE"
  )
})

test_that("validate_parcc_call validates all parameters", {
  # Valid call
  expect_silent(validate_parcc_call(2023, 4, "math"))
  expect_silent(validate_parcc_call(2023, "ALG1", "math"))

  # Invalid year
  expect_error(
    validate_parcc_call(2020, 4, "math"),
    "COVID"
  )

  # Invalid grade for math (grade 10 only for ELA)
  expect_error(
    validate_parcc_call(2023, 10, "math"),
    "not valid"
  )

  # Course with wrong subject
  expect_error(
    validate_parcc_call(2023, "ALG1", "ela"),
    "only available for math"
  )
})
