context("functions in enr")

#post-NJSMART
test_that("get_raw_enr correctly grabs the 2015 enrollment file", {
  ex_2015 <- get_raw_enr(2015)
  
  expect_equal(nrow(ex_2015), 26215)
  expect_equal(ncol(ex_2015), 27)
  expect_equal(sum(ex_2015$ROW_TOTAL, na.rm = TRUE), 10952060)
  
})


test_that("get_raw_enr correctly grabs the 2011 enrollment file", {
  ex_2011 <- get_raw_enr(2011)
  
  expect_equal(nrow(ex_2011), 25891)
  expect_equal(ncol(ex_2011), 26)
  expect_equal(sum(ex_2011$ROW_TOTAL, na.rm = TRUE), 10871910)
  
})

#pre-NJSMART

test_that("get_raw_enr correctly grabs the 2010 enrollment file", {
  ex_2010 <- get_raw_enr(2010)
  
  expect_equal(nrow(ex_2010), 29599)
  expect_equal(ncol(ex_2010), 28)
  expect_equal(sum(ex_2010$ROW_TOTAL, na.rm = TRUE), 11084504)
  
})

test_that("get_raw_enr correctly grabs the 2001 enrollment file", {
  ex_2001 <- get_raw_enr(2001)
  
  expect_equal(nrow(ex_2001), 28447)
  expect_equal(ncol(ex_2001), 19)
  expect_equal(sum(ex_2001$ROWTOTAL, na.rm = TRUE), 10522596)
  
})
