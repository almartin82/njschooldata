context("test msgp functions")

sgp16 <- get_and_process_msgp(2016)
sgp17 <- get_and_process_msgp(2017)
sgp18 <- get_and_process_msgp(2018)

test_that("sgp works with 2016 data", {
  expect_is(sgp16, 'tbl_df')
  expect_is(sgp16, 'data.frame')
  expect_equal(
    names(sgp16),
    c("county_code", "district_code", "school_code",
      "end_year", "subject", "grade", "subgroup", "median_sgp", 
      "is_district", "is_school")
  )
})


test_that("sgp works with 2017 data", {
  expect_is(sgp17, 'tbl_df')
  expect_is(sgp17, 'data.frame')
  expect_equal(
    names(sgp17),
    c("county_code", "district_code", "school_code",
      "end_year", "subject", "grade", "subgroup", "median_sgp", 
      "is_district", "is_school")
  )
})


test_that("sgp works with 2018 data", {
  expect_is(sgp18, 'tbl_df')
  expect_is(sgp18, 'data.frame')
  expect_equal(
    names(sgp18),
    c("county_code", "district_code", "school_code", 
      "end_year", "subject", "grade", "subgroup", "median_sgp", 
      "is_district", "is_school")
  )
})