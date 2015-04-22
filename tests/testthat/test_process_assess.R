context("functions in process_assess.R")

#constants
processed_2014 <- get_raw_njask(2014, 6) %>% 
  process_nj_assess(layout=layout_njask)


test_that("process_njask correctly handles the 2014 6th grade NJASK", {

  expect_equal(nrow(processed_2014), 881)
  expect_equal(ncol(processed_2014), 551)
  expect_equal(
    sum(processed_2014$TOTAL_POPULATION_LANGUAGE_ARTS_Proficient_Percentage, na.rm = TRUE), 
    47685.3, tolerance = 0.01
  )
  
})