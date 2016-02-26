context("functions in gepa.R")

#constant
ex_2007 <- get_raw_gepa(2007)
fetch_06 <- fetch_gepa(2006)


test_that("get_raw_gepa correctly grabs the 2007 GEPA", {

  expect_equal(nrow(ex_2007), 1224)
  expect_equal(ncol(ex_2007), 486)
  expect_equal(sum(ex_2007$TOTAL_POPULATION_Number_Enrolled, na.rm = TRUE), 403444)
  
})


test_that("fetch_gepa correctly grabs the 2006 GEPA", {
  
  expect_equal(nrow(fetch_06), 1232)
  expect_equal(ncol(fetch_06), 461)
  expect_equal(sum(fetch_06$TOTAL_POPULATION_Number_Enrolled, na.rm = TRUE), 544595)
  expect_equal(
    sum(fetch_06$TOTAL_POPULATION_LANGUAGE_ARTS_Proficient_Percentage, na.rm = TRUE), 
    78817.1, tolerance = 0.01
  )
  
})
