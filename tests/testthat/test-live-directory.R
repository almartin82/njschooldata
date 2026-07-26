skip_if_no_live_tests()


districts <- get_district_directory()
schools <- get_school_directory()

test_that("get_district_directory works", {
  
  expect_s3_class(districts, 'data.frame')

})

test_that("get_school_directory works", {
  
  expect_s3_class(schools, 'data.frame')
  
})
