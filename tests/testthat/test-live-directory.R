skip_if_no_live_tests()


districts <- get_district_directory()
schools <- get_school_directory()

test_that("get_district_directory works", {

  expect_s3_class(districts, 'data.frame')
  # The Homeroom district download is a whole-state register. A zero-row or
  # near-empty frame means the request was refused, not that NJ shrank.
  expect_gt(nrow(districts), 500)
  expect_true(all(c("county_id", "district_id", "cds_code") %in% names(districts)))
  expect_false(any(is.na(districts$district_id)))

})

test_that("get_school_directory works", {

  expect_s3_class(schools, 'data.frame')
  expect_gt(nrow(schools), 2000)
  expect_true(all(c("county_id", "district_id", "school_id", "cds_code") %in%
                    names(schools)))
  expect_false(any(is.na(schools$school_id)))

})
