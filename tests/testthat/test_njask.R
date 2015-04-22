context("functions in njask.R")

#constant
ex_2014 <- get_raw_njask(2014, 6)
processed_2014 <- process_njask(ex_2014)
fetch_07g3 <- fetch_njask(2007, 3)

test_that("get_raw_njask correctly grabs the 2014 6th grade NJASK", {

  expect_equal(nrow(ex_2014), 881)
  expect_equal(ncol(ex_2014), 551)
  expect_equal(sum(ex_2014$TOTAL_POPULATION_Number_Enrolled_ELA, na.rm = TRUE), 307136)
  
})


test_that("process_njask correctly handles the 2014 6th grade NJASK", {

  expect_equal(nrow(processed_2014), 881)
  expect_equal(ncol(processed_2014), 551)
  expect_equal(
    sum(processed_2014$TOTAL_POPULATION_LANGUAGE_ARTS_Proficient_Percentage, na.rm = TRUE), 
    47685.3, tolerance = 0.01
  )
  
})


test_that("fetch_njask correctly grabs the 2007 g3 NJASK", {
  
  expect_equal(nrow(fetch_07g3), 1944)
  expect_equal(ncol(fetch_07g3), 487)
  expect_equal(sum(fetch_07g3$TOTAL_POPULATION_Number_Enrolled, na.rm = TRUE), 388423)
  expect_equal(
    sum(fetch_07g3$TOTAL_POPULATION_LANGUAGE_ARTS_Proficient_Percentage, na.rm = TRUE), 
     143124.5, tolerance = 0.01
  )
  
})
