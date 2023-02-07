context("functions in directory.R")

districts <- get_district_directory()
schools <- get_school_directory()

test_that("get_district_directory works", {
  
  expect_is(districts, 'data.frame')

})

test_that("get_school_directory works", {
  
  expect_is(districts, 'data.frame')
  
})
