context("test sped functions")

all_end_years <- c(2003:2019)

test_that("get raw sped works across all years", {
  
  raw_sped_list <- map(
    all_end_years, ~get_raw_sped(.x)
  )
  expect_is(raw_sped_list, 'list')
})



test_that("fetch sped works across all years", {
  
  fetch_sped_df <- map_df(
    all_end_years, ~fetch_sped(.x)
  )
  expect_is(fetch_sped_df, 'tbl_df')
})



test_that("raw sped returns county names and ids correctly", {
  
  target_years <- c(2003:2008)

  missing_ids <- map_df(
    target_years, ~fetch_sped(.x)
  )

  
})
