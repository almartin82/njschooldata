context("parcc functions")

test_that("get_raw_parcc gets data file", {
  
  p <- get_raw_parcc(2015, 4, 'ela')
  expect_equal(dim(p), c(22248, 18))
  
  expect_error(fetch_parcc(2015, 10, 'math'))
  
})


test_that("fetch_parcc gets data file", {
  
  p <- fetch_parcc(2015, 4, 'math')
  expect_equal(dim(p), c(22324, 35))
  
  p <- fetch_parcc(2015, 'GEO', 'math')
  expect_equal(dim(p), c(12625, 35))
  
})


test_that("fetch_parcc processes data file", {
  
  p <- fetch_parcc(2015, 8, 'ela', tidy = FALSE)
  expect_equal(colnames(p)[4], "grade")
  
  p <- fetch_parcc(2015, 4, 'math', tidy = TRUE)
  expect_equal(dim(p), c(22324, 35))
  expect_true("black" %in% p$subgroup)
  expect_false("GENDER" %in% p$subgroup)
  
})


test_that("fetch_parcc processes 2016-17 data file", {
  
  p <- fetch_parcc(2017, 8, 'ela', tidy = FALSE)
  expect_equal(colnames(p)[3], "test_name")
  
  p <- fetch_parcc(2017, 4, 'math', tidy = TRUE)
  expect_equal(dim(p), c(25557, 35))
  expect_true("black" %in% p$subgroup)
  expect_false("GENDER" %in% p$subgroup)
  
})


test_that("calculate_agg_parcc_prof all grades", {
  math_311_2018 <- calculate_agg_parcc_prof(
    end_year = 2018,
    subj = 'math',
    gradespan = '3-11'
  )
  expect_is(math_311_2018, 'data.frame')
})


test_that("calculate_agg_parcc_prof 3-8", {
  math_38_2018 <- calculate_agg_parcc_prof(
    end_year = 2018,
    subj = 'math',
    gradespan = '3-8'
  )
  expect_is(math_38_2018, 'data.frame')
})


test_that("calculate_agg_parcc_prof 9-11", {
  math_911_2018 <- calculate_agg_parcc_prof(
    end_year = 2018,
    subj = 'math',
    gradespan = '9-11'
  )
  expect_is(math_911_2018, 'data.frame')
})


test_that("works with 2018-19 SLA data", {
  sla_2019 <- fetch_parcc(end_year = 2019, grade_or_subj = 4, 'ela', TRUE)
  expect_is(sla_2019, 'data.frame')
  
  sla_2019 <- fetch_parcc(end_year = 2019, grade_or_subj = 'ALG1', 'math', TRUE)
  expect_is(sla_2019, 'data.frame')
  
  sla_2019 <- fetch_parcc(end_year = 2019, grade_or_subj = 'GEO', 'math', TRUE)
  expect_is(sla_2019, 'data.frame')

  sla_2019 <- fetch_parcc(end_year = 2019, grade_or_subj = 'ALG2', 'math', TRUE)
  expect_is(sla_2019, 'data.frame')
})


test_that("fetch_all_parcc works", {
  all_parcc <- fetch_all_parcc()
  expect_is(sla_2019, 'data.frame')
})