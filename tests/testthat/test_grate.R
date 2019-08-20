context('grate')

grad_rate_cols <- c(
  "end_year",
  "county_id", "county_name", 
  "district_id", "district_name", 
  "school_id", "school_name",
  "group", 
  "grad_rate", 
  "cohort_count", "graduated_count", 
  "methodology"
)

test_that('fetch grate works properly', {
  ex <- fetch_grad_rate(2015)
  expect_is(ex, 'data.frame')
  expect_equal(sum(ex$graduated_count, na.rm = TRUE), 674621)
  expect_equal(names(ex), grad_rate_cols)
})


test_that('fetch grate works with more recent data', {
  ex <- fetch_grad_rate(2018)
  expect_is(ex, 'data.frame')
  expect_equal(sum(ex$graduated_count, na.rm = TRUE), 996902)
  expect_equal(names(ex), grad_rate_cols)
})


test_that('five year window is in more recent data', {
  ex <- fetch_grad_rate(2017, '5 year')
  expect_is(ex, 'data.frame')
  expect_equal(names(ex), grad_rate_cols)
})


test_that('get_raw_grate works with 5 year', {
  ex0 <- get_grad_rate(2012, '5 year')
  ex1 <- get_grad_rate(2013, '5 year')
  ex2 <- get_grad_rate(2014, '5 year')
  ex3 <- get_grad_rate(2015, '5 year')
  ex4 <- get_grad_rate(2016, '5 year')
  ex5 <- get_grad_rate(2017, '5 year')
  
  expect_is(ex0, 'data.frame')
  expect_is(ex1, 'data.frame')
  expect_is(ex2, 'data.frame')
  expect_is(ex3, 'data.frame')
  expect_is(ex4, 'data.frame')
  expect_is(ex5, 'data.frame')
})


test_that('fetch_grad_rate works with 5 year', {
  ex0 <- fetch_grad_rate(2012, '5 year')
  ex1 <- fetch_grad_rate(2013, '5 year')
  ex2 <- fetch_grad_rate(2014, '5 year')
  ex3 <- fetch_grad_rate(2015, '5 year')
  ex4 <- fetch_grad_rate(2016, '5 year')
  ex5 <- fetch_grad_rate(2017, '5 year')
  
  expect_is(ex0, 'data.frame')
  expect_is(ex1, 'data.frame')
  expect_is(ex2, 'data.frame')
  expect_is(ex3, 'data.frame')
  expect_is(ex4, 'data.frame')
  expect_is(ex5, 'data.frame')
})


test_that('fetch_grad_rate works with 4 year', {
  ex0 <- fetch_grad_rate(2012, '4 year')
  ex1 <- fetch_grad_rate(2013, '4 year')
  ex2 <- fetch_grad_rate(2014, '4 year')
  ex3 <- fetch_grad_rate(2015, '4 year')
  ex4 <- fetch_grad_rate(2016, '4 year')
  ex5 <- fetch_grad_rate(2017, '4 year')
  ex6 <- fetch_grad_rate(2018, '4 year')
  
  expect_is(ex0, 'data.frame')
  expect_is(ex1, 'data.frame')
  expect_is(ex2, 'data.frame')
  expect_is(ex3, 'data.frame')
  expect_is(ex4, 'data.frame')
  expect_is(ex5, 'data.frame')
  expect_is(ex6, 'data.frame')
  
})


test_that('fetch_grad_count all years', {
  
  gr00 <- fetch_grad_count(1999)
  gr01 <- fetch_grad_count(2000)
  gr02 <- fetch_grad_count(2001)
  gr03 <- fetch_grad_count(2002)
  gr04 <- fetch_grad_count(2003)
  gr05 <- fetch_grad_count(2004)
  gr06 <- fetch_grad_count(2005)
  gr07 <- fetch_grad_count(2006)
  gr08 <- fetch_grad_count(2007)
  gr09 <- fetch_grad_count(2008)
  gr10 <- fetch_grad_count(2009)
  gr11 <- fetch_grad_count(2010)
  gr12 <- fetch_grad_count(2011)
  gr13 <- fetch_grad_count(2012)
  gr14 <- fetch_grad_count(2013)
  gr15 <- fetch_grad_count(2014)
  gr16 <- fetch_grad_count(2015)
  gr17 <- fetch_grad_count(2016)
  gr18 <- fetch_grad_count(2017)
  gr19 <- fetch_grad_count(2018)
  expect_error(fetch_grad_count(2019))
  
})



test_that('fetch_grad_rate all years', {
  
  expect_error(fetch_grad_rate(2010))
  grr12 <- fetch_grad_rate(2011)
  grr13 <- fetch_grad_rate(2012)
  grr14 <- fetch_grad_rate(2013)
  grr15 <- fetch_grad_rate(2014)
  grr16 <- fetch_grad_rate(2015)
  grr17 <- fetch_grad_rate(2016)
  grr18 <- fetch_grad_rate(2017)
  grr19 <- fetch_grad_rate(2018)
  expect_error(fetch_grad_rate(2019))
  
})