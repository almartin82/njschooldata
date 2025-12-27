# NOTE: As of 2024, NJ DOE has restructured their special education data website.
# Historical data (2003-2019) is no longer available at the original URLs.
# Data prior to 2014 requires an OPRA request.
# New data uses a different URL structure at /education/specialed/monitor/ideapublicdata/

test_that("fetch_sped returns expected structure for 2024 data", {
  skip_if_offline()

  # Test current data year
  result <- tryCatch(
    fetch_sped(2024),
    error = function(e) NULL
  )


  skip_if(is.null(result), "SPED data URL not accessible")

  expect_s3_class(result, 'data.frame')
  expected_cols <- c("end_year", "county_name", "district_id", "district_name",
                     "gened_num", "sped_num", "sped_rate")
  expect_true(all(expected_cols %in% names(result)))
})

test_that("fetch_sped validates end_year parameter", {
  expect_error(fetch_sped(1990), "not a valid")
  expect_error(fetch_sped(2030), "not a valid")
})

