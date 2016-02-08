context("parcc functions")

testthat("get_raw_parcc gets data file", {
  
  p <- get_raw_parcc(2015, 4, 'ela')
  expect_equal(dim(p), c(22248, 18))
})

testthat("fetch_parcc gets and processes data file", {
  
  p <- fetch_parcc(2015, 4, 'math')
  expect_equal(dim(p), c(22324, 22))
  
  p <- fetch_parcc(2015, 4, 'math', tidy = TRUE)
  expect_equal(dim(p), c(22324, 22))
})