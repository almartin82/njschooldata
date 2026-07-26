test_that("absence subgroup and tidy contracts are offline", {
  input <- c(
    "total population", "economically disadvantaged", "black",
    "limited english proficiency", "students with disabilities"
  )
  expect_identical(
    standardize_absence_subgroups(input),
    c("total", "econ_disadv", "black", "lep", "special_ed")
  )

  out <- tidy_absence(data.frame(
    end_year = 2024L,
    subgroup = input,
    chronically_absent_rate = c(10, 20, 12, 18, 22)
  ))
  expect_identical(out$subgroup, c(
    "total", "econ_disadv", "black", "lep", "special_ed"
  ))
})

test_that("absence validation fails before any source request", {
  expect_error(fetch_absence(2024, type = "invalid"), "type must be one of")
  expect_error(fetch_absence(2024, type = "ESSA"), "type must be one of")
})
