context("functions in hspa.R")

#constant
ex_2014 <- get_raw_hspa(2014)
fetch_07 <- fetch_hspa(2007)


test_that("get_raw_hspa correctly grabs the 2014 HSPA", {

  expect_equal(nrow(ex_2014), 371)
  expect_equal(ncol(ex_2014), 559)
  expect_equal(sum(ex_2014$TOTAL_POPULATION_Number_Enrolled_LAL, na.rm = TRUE), 256136)
  
})


test_that("fetch_njask correctly grabs the 2007 HSPA", {
  
  expect_equal(nrow(fetch_07), 681)
  expect_equal(ncol(fetch_07), 527)
  expect_equal(sum(fetch_07$TOTAL_POPULATION_Number_Enrolled_LAL, na.rm = TRUE), 380702)
  expect_equal(
    sum(fetch_07$TOTAL_POPULATION_LANGUAGE_ARTS_Proficient_Percentage, na.rm = TRUE), 
     44984.6, tolerance = 0.01
  )
  
})
