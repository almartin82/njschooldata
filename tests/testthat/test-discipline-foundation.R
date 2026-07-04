test_that("discipline enrollment denominator joins total enrollment by CDS and year", {
  discipline <- tibble::tibble(
    end_year = c(2024, 2024, 2024),
    county_id = c("01", "01", "02"),
    district_id = c("0010", "0010", "9999"),
    school_id = c("050", "051", "999"),
    value = c(1, 2, 3)
  )

  enrollment <- tibble::tibble(
    end_year = 2024,
    county_id = c("01", "01", "01", "02"),
    district_id = c("0010", "0010", "0010", "9999"),
    school_id = c("050", "050", "051", "999"),
    program_code = c("55", "01", "55", "55"),
    grade_level = c("TOTAL", "01", "TOTAL", "TOTAL"),
    subgroup = c("total_enrollment", "total_enrollment", "white", "total_enrollment"),
    n_students = c(500, 40, 250, 1000)
  )

  out <- attach_discipline_enrollment_denominator(
    discipline,
    enrollment = enrollment
  )

  expect_equal(names(out)[seq_along(names(discipline))], names(discipline))
  expect_equal(out$n_students, c(500, NA, 1000))
})

test_that("discipline row value status preserves suppression before coercion", {
  raw <- tibble::tibble(
    violence = c("0", "<5", NA, "N/A"),
    weapons = c("3", "0", "", "N/A")
  )

  status <- discipline_row_value_status(raw, c("violence", "weapons"))

  expect_equal(
    as.character(status),
    c("actual", "suppressed", "not_published", "not_applicable")
  )
})

test_that("discipline fetchers expose additive foundation arguments", {
  expect_false(formals(fetch_disciplinary_removals)$with_status)
  expect_false(formals(fetch_disciplinary_removals)$with_denominator)
  expect_false(formals(fetch_disciplinary_removals)$with_subgroup_std)

  expect_false(formals(fetch_violence_vandalism_hib)$with_status)
  expect_false(formals(fetch_violence_vandalism_hib)$with_denominator)

  expect_false(formals(fetch_police_notifications)$with_status)
  expect_false(formals(fetch_police_notifications)$with_denominator)

  expect_false(formals(fetch_restraint_seclusion)$with_status)
  expect_false(formals(fetch_restraint_seclusion)$with_denominator)
  expect_false(formals(fetch_restraint_seclusion)$with_subgroup_std)
})
