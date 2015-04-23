context("functions in enr")


test_that("get_raw_enr correctly grabs the 2015 enrollment file", {
  ex_2015 <- get_raw_enr(2015)
  
  expect_equal(nrow(ex_2015), 26215)
  expect_equal(ncol(ex_2015), 27)
  expect_equal(sum(ex_2015$ROW_TOTAL, na.rm = TRUE), 10952060)
  
})


test_that("get_raw_enr correctly grabs the 2012 enrollment file", {
  ex_2012 <- get_raw_enr(2012)
  
  expect_equal(nrow(ex_2012), 26128)
  expect_equal(ncol(ex_2012), 27)
  expect_equal(sum(ex_2012$ROW_TOTAL, na.rm = TRUE), 10911972)
  
})

