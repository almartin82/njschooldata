context('grate')

grad_rate_cols <- c(
  "end_year",
  "county_id", "county_name",
  "district_id", "district_name",
  "school_id", "school_name",
  "subgroup",
  "grad_rate",
  "cohort_count", "graduated_count",
  "methodology",
  "is_state", "is_county", "is_district", "is_school",
  "is_charter", "is_charter_sector", "is_allpublic"
)


## 4 year
test_that('fetch_grad_rate works with 4 year', {
   ex0 <- fetch_grad_rate(2012, '4 year')
   ex1 <- fetch_grad_rate(2013, '4 year')
   ex2 <- fetch_grad_rate(2014, '4 year')
   ex3 <- fetch_grad_rate(2015, '4 year')
   ex4 <- fetch_grad_rate(2016, '4 year')
   ex5 <- fetch_grad_rate(2017, '4 year')
   ex6 <- fetch_grad_rate(2018, '4 year')
   ex7 <- fetch_grad_rate(2019, '4 year')
   ex8 <- fetch_grad_rate(2020, '4 year')

   expect_is(ex0, 'data.frame')
   expect_is(ex1, 'data.frame')
   expect_is(ex2, 'data.frame')
   expect_is(ex3, 'data.frame')
   expect_is(ex4, 'data.frame')
   expect_is(ex5, 'data.frame')
   expect_is(ex6, 'data.frame')
   expect_is(ex7, 'data.frame')
   expect_is(ex8, 'data.frame')
})

test_that('fetch_grad_rate all years', {

   expect_error(fetch_grad_rate(2010))
   expect_error(fetch_grad_rate(2011))
   #grr12 <- fetch_grad_rate(2011)
   grr13 <- fetch_grad_rate(2012)
   grr14 <- fetch_grad_rate(2013)
   grr15 <- fetch_grad_rate(2014)
   grr16 <- fetch_grad_rate(2015)
   grr17 <- fetch_grad_rate(2016)
   grr18 <- fetch_grad_rate(2017)
   grr19 <- fetch_grad_rate(2018)
   grr20 <- fetch_grad_rate(2019)
   grr20 <- fetch_grad_rate(2020)
   expect_error(fetch_grad_rate(2021))

})

test_that('fetch grate works with 2015 data', {
  ex <- fetch_grad_rate(2015)
  expect_is(ex, 'data.frame')
  expect_equal(sum(ex$graduated_count, na.rm = TRUE), 674621)
  expect_equal(names(ex), grad_rate_cols)
})


test_that('fetch grate works with 2018 data', {
  ex <- fetch_grad_rate(2018)
  expect_is(ex, 'data.frame')
  expect_equal(sum(ex$graduated_count, na.rm = TRUE), 996902)
  expect_equal(names(ex), grad_rate_cols)
})

test_that("ground truth values on 2019 grate", {
   ex <- fetch_grad_rate(2019)
   expect_is(ex, "data.frame")
   expect_equal(names(ex), grad_rate_cols)

   expect_equal(filter(ex,
                       district_id == '3570',
                       school_id == '030',
                       subgroup == 'black') %>%
                   pull(grad_rate), .744)

   expect_equal(filter(ex,
                       district_id == '3570',
                       school_id == '030',
                       subgroup == 'white') %>%
                   pull(grad_rate), NA_real_)

   expect_equal(filter(ex,
                       district_id == '3570',
                       school_id == '030',
                       subgroup == 'students with disability') %>%
                   pull(grad_rate), .594)
})


test_that("ground truth values on 2020 grate", {
  ex <- fetch_grad_rate(2020)
  expect_is(ex, "data.frame")
  expect_equal(names(ex), grad_rate_cols)

  expect_equal(filter(ex,
                      district_id == '3570',
                      school_id == '030',
                      subgroup == 'black') %>%
                 pull(grad_rate), 0.754)

  expect_equal(filter(ex,
                      district_id == '3570',
                      school_id == '030',
                      subgroup == 'white') %>%
                 pull(grad_rate), NA_real_)

  expect_equal(filter(ex,
                      district_id == '3570',
                      school_id == '030',
                      subgroup == 'students with disability') %>%
                 pull(grad_rate), 0.672)
})


## 5 year
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
  ex6 <- get_grad_rate(2018, '5 year')
  ex7 <- get_grad_rate(2019, '5 year')

  expect_is(ex0, 'data.frame')
  expect_is(ex1, 'data.frame')
  expect_is(ex2, 'data.frame')
  expect_is(ex3, 'data.frame')
  expect_is(ex4, 'data.frame')
  expect_is(ex5, 'data.frame')
  expect_is(ex6, 'data.frame')
})


test_that('fetch_grad_rate works with 5 year', {
  ex0 <- fetch_grad_rate(2012, '5 year')
  ex1 <- fetch_grad_rate(2013, '5 year')
  ex2 <- fetch_grad_rate(2014, '5 year')
  ex3 <- fetch_grad_rate(2015, '5 year')
  ex4 <- fetch_grad_rate(2016, '5 year')
  ex5 <- fetch_grad_rate(2017, '5 year')
  ex6 <- fetch_grad_rate(2018, '5 year')

  expect_is(ex0, 'data.frame')
  expect_is(ex1, 'data.frame')
  expect_is(ex2, 'data.frame')
  expect_is(ex3, 'data.frame')
  expect_is(ex4, 'data.frame')
  expect_is(ex5, 'data.frame')
  expect_is(ex6, 'data.frame')
})


test_that("ground truth values on 2018 5y grate", {
   ex <- fetch_grad_rate(2018, '5 year')
   expect_is(ex, "data.frame")

   expect_equal(filter(ex,
                       district_id == '3570',
                       school_id == '888') %>%
                   pull(grad_rate), .765)

   expect_equal(filter(ex,
                       district_id == '3570',
                       school_id == '030') %>%
                   pull(grad_rate), .798)

   expect_equal(filter(ex,
                       district_id == '3570',
                       school_id == '307') %>%
                   pull(grad_rate), NA_real_)
})




# grad count
test_that('fetch_grad_count all years', {
  # it doesn't look like 2011 file has any counts in the raw file
  # to pull out
  expect_error(fetch_grad_count(2011))
  gr13 <- fetch_grad_count(2012)
  gr14 <- fetch_grad_count(2013)
  gr15 <- fetch_grad_count(2014)
  gr16 <- fetch_grad_count(2015)
  gr17 <- fetch_grad_count(2016)
  gr18 <- fetch_grad_count(2017)
  gr19 <- fetch_grad_count(2018)
  gr20 <- fetch_grad_count(2019)
  expect_error(fetch_grad_count(2020))
})

test_that("ground truth values on 2019 grad count", {
   ex <- fetch_grad_count(2019)
   expect_is(ex, "data.frame")

   expect_equal(filter(ex,
                       district_id == '3570',
                       school_id == '999',
                       subgroup == "female") %>%
                   pull(graduated_count), 1085)

   expect_equal(filter(ex,
                       district_id == '3570',
                       school_id == '030',
                       subgroup == "economically disadvantaged") %>%
                   pull(cohort_count), 179)

   expect_equal(filter(ex,
                       district_id == '3570',
                       school_id == '307',
                       subgroup == "white") %>%
                   pull(cohort_count), NA_real_)
})


test_that("grad counts correctly enriched", {
  grate_19 <- fetch_grad_rate(2019)

  ex <- enrich_grad_count(grate_19, 2019)

  ex_row <- ex %>%
    filter(district_id == '3570',
           school_id == '055',
           subgroup == 'total population')

  expect_equal(pull(ex_row, graduated_count.x),
               pull(ex_row, graduated_count.y))
  

  grate_20 <- fetch_grad_rate(2020)
  ex2 <- enrich_grad_count(grate_20, 2020)
  
  ex_row <- ex %>%
    filter(district_id == '3570',
           school_id == '055',
           subgroup == 'total population')
  
  expect_equal(pull(ex_row, graduated_count.x),
               pull(ex_row, graduated_count.y))
  
})
