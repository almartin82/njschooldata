context('grate')

grate_cols <- c(
  "county_id", "county_name", "district_id", "district_name", 
  "school_id", "school_name", "group", "grad_rate", "cohort_count", 
  "graduated_count", "methodology", "time_window", "grad_cohort", 
  "year_reported"
)

test_that('fetch grate works properly', {
  ex <- fetch_grate(2015)
  expect_is(ex, 'data.frame')
  expect_equal(sum(ex$graduated_count, na.rm = TRUE), 674621)
  expect_equal(names(ex), grate_cols)
})


test_that('fetch grate works with more recent data', {
  ex <- fetch_grate(2018)
  expect_is(ex, 'data.frame')
  expect_equal(sum(ex$graduated_count, na.rm = TRUE), 996902)
  expect_equal(names(ex), grate_cols)
})


test_that('five year window is in more recent data', {
  ex <- fetch_grate(2017, '5 year')
  expect_is(ex, 'data.frame')
  expect_equal(sum(ex$graduated_count, na.rm = TRUE), 996902)
  expect_equal(names(ex), grate_cols)
})


test_that('get_raw_grate works with 5 year', {
  ex0 <- get_raw_grate(2012, '5 year')
  ex1 <- get_raw_grate(2013, '5 year')
  ex2 <- get_raw_grate(2014, '5 year')
  ex3 <- get_raw_grate(2015, '5 year')
  ex4 <- get_raw_grate(2016, '5 year')
  ex5 <- get_raw_grate(2017, '5 year')
  
  expect_is(ex0, 'data.frame')
  expect_is(ex1, 'data.frame')
  expect_is(ex2, 'data.frame')
  expect_is(ex3, 'data.frame')
  expect_is(ex4, 'data.frame')
  expect_is(ex5, 'data.frame')
})


test_that('fetch_grate works with 5 year', {
  ex0 <- fetch_grate(2012, '5 year')
  ex1 <- fetch_grate(2013, '5 year')
  ex2 <- fetch_grate(2014, '5 year')
  ex3 <- fetch_grate(2015, '5 year')
  ex4 <- fetch_grate(2016, '5 year')
  ex5 <- fetch_grate(2017, '5 year')
  
  expect_is(ex0, 'data.frame')
  expect_is(ex1, 'data.frame')
  expect_is(ex2, 'data.frame')
  expect_is(ex3, 'data.frame')
  expect_is(ex4, 'data.frame')
  expect_is(ex5, 'data.frame')
})