# The staff analysis helpers resolve each input column to exactly one
# column; an ambiguous input stops instead of the first regex hit winning.

ratio_input <- function() {
  tibble::tibble(
    county_id = "01", district_id = "0110", school_id = "010",
    student_enrollment = c(1000, 600),
    number_teachers = c(40, 50),
    pct_teachers_certified = c(98, 99)
  )
}

test_that("two teacher columns stop instead of the first being used", {
  expect_error(calc_student_staff_ratio(ratio_input(), ratio_type = "teachers"),
               "Cannot tell which column holds teachers staff")
})

test_that("naming the column resolves the ambiguity exactly", {
  out <- calc_student_staff_ratio(ratio_input(), ratio_type = "teachers",
                                  staff_col = "number_teachers")
  expect_equal(out$student_staff_ratio, c(25, 12))
  expect_error(calc_student_staff_ratio(ratio_input(), ratio_type = "teachers",
                                        staff_col = "teachers"),
               "is not a column")
})

test_that("two category columns stop in the diversity helper", {
  df <- tibble::tibble(
    county_id = "01", district_id = "0110",
    subgroup = c("white", "black"), demographic_group = c("race", "race"),
    number_staff = c(3, 1)
  )
  expect_error(calc_staff_diversity_metrics(df), "Cannot tell which column holds demographic category")
  out <- calc_staff_diversity_metrics(df, category_col = "subgroup")
  expect_equal(unique(out$racial_diversity_score), 1 - (0.75^2 + 0.25^2))
})
