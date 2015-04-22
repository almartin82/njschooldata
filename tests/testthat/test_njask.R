context("functions in njask.R")


test_that("get_raw_njask correctly grabs the 2014 6th grade NJASK", {
  ex <- get_raw_njask(2014, 6)

  expect_equal(nrow(ex), 881)
  expect_equal(ncol(ex), 551)
  expect_equal(sum(ex$TOTAL_POPULATION_Number_Enrolled_ELA, na.rm = TRUE), 307136)
  
})
