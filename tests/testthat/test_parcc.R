context("parcc functions")

test_that("get_raw_parcc gets data file", {
  
  p <- get_raw_parcc(2015, 4, 'ela')
  expect_equal(dim(p), c(22248, 18))
  
  expect_error(fetch_parcc(2015, 10, 'math'))
  
})


test_that("fetch_parcc gets data file", {
  
  p <- fetch_parcc(2015, 4, 'math')
  expect_equal(dim(p), c(22324, 22))
  
  p <- fetch_parcc(2015, 'GEO', 'math')
  expect_equal(dim(p), c(12625, 22))
  
})


test_that("fetch_parcc processes data file", {
  
  p <- fetch_parcc(2015, 8, 'ela', tidy = FALSE)
  expect_equal(colnames(p)[3], "district_code")
  
  p <- fetch_parcc(2015, 4, 'math', tidy = TRUE)
  expect_equal(dim(p), c(22324, 22))
  expect_true("black" %in% p$subgroup)
  expect_false("GENDER" %in% p$subgroup)
  
})

