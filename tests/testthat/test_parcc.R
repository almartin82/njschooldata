context("parcc functions")

test_that("get_raw_parcc gets data file", {
  
  p <- get_raw_parcc(2015, 4, 'ela')
  expect_equal(dim(p), c(22248, 18))
  
  expect_error(fetch_parcc(2015, 10, 'math'))
  
})


test_that("fetch_parcc gets data file", {
  
  p <- fetch_parcc(2015, 4, 'math')
  expect_equal(dim(p), c(22324, 34))
  
  p <- fetch_parcc(2015, 'GEO', 'math')
  expect_equal(dim(p), c(12625, 34))
  
})


test_that("fetch_parcc processes data file", {
  
  p <- fetch_parcc(2015, 8, 'ela', tidy = FALSE)
  expect_equal(colnames(p)[4], "grade")
  
  p <- fetch_parcc(2015, 4, 'math', tidy = TRUE)
  expect_equal(dim(p), c(22324, 34))
  expect_true("black" %in% p$subgroup)
  expect_false("GENDER" %in% p$subgroup)
  
})


test_that("fetch_parcc processes 2016-17 data file", {
  
  p <- fetch_parcc(2017, 8, 'ela', tidy = FALSE)
  expect_equal(colnames(p)[3], "test_name")
  
  p <- fetch_parcc(2017, 4, 'math', tidy = TRUE)
  expect_equal(dim(p), c(25557, 34))
  expect_true("black" %in% p$subgroup)
  expect_false("GENDER" %in% p$subgroup)
  
})


test_that("calculate_agg_parcc_prof on one year", {
  math_k11_2018 <- calculate_agg_parcc_prof(
    end_year = 2018,
    subj = 'math',
    k8 = FALSE
  )
  expect_is(math_k11_2018, 'data.frame')
  expect_equal(ncol(math_k11_2018), 37)
  expect_equal(nrow(math_k11_2018), 47629)
})


test_that("calculate_agg_parcc_prof, 4 years", {
  
  math_parcc_multi <- map_df(
    c(2015:2018),
    ~calculate_agg_parcc_prof(.x, subj = 'math', k8=FALSE)
  )
  expect_is(math_parcc_multi, 'data.frame')
  
  expect_equal(ncol(math_parcc_multi), 37)
  expect_equal(nrow(math_parcc_multi), 47629)
})
