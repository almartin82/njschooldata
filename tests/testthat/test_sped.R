
all_end_years <- c(2003:2019)

test_that("get raw sped works across all years", {
  
  raw_sped_list <- map(
    all_end_years, ~get_raw_sped(.x)
  )
  expect_is(raw_sped_list, 'list')
})


test_that("fetch sped works across all years", {
  
  fetch_sped_df <- map(
    all_end_years, ~fetch_sped(.x)
  )
  expect_is(fetch_sped_df, 'list')
})


test_that("raw sped returns county names and ids correctly", {
  
  target_years <- c(2003:2008)
  
  missing_ids <- map_df(
    target_years, ~fetch_sped(.x)
  )
  expect_is(fetch_sped_df, 'tbl_df')
})


test_that("fetch sped works across all years and binds into dataframe", {
  
  fetch_sped_df <- map_df(
    all_end_years, ~fetch_sped(.x)
  )
  expect_is(fetch_sped_df, 'tbl_df')
})


test_that("ground truth numbers on end year 2011 SPED data", {
  
  ex_file = fetch_sped(2011)

  atlantic_city = ex_file %>%
    filter(district_id == '0110')
  expect_equal(atlantic_city$gened_num, 6821)
  expect_equal(atlantic_city$sped_num, 1017)
  expect_equal(atlantic_city$sped_rate, 14.90984, tolerance = .0001)

  eo = ex_file %>%
    filter(district_id == '6410')
  expect_equal(eo$gened_num, 470)
  expect_equal(eo$sped_num, 0)
  expect_equal(eo$sped_rate, 0, tolerance = .0001)
})

