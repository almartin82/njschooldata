context("functions in lookups.R")

enr_several <- map_df(
  c(2017:2018),
  fetch_enr, tidy=TRUE
)
friendly_names <- friendly_district_names(enr_several)

test_that("friendly_district_names makes friendly names", {
  
  expect_equal(
    head(friendly_names),
    c("Absecon City", "Academy Charter High School", "Academy For Urban Leadership Charter School", 
      "Achieve Community Charter School", "Alexandria Twp", "Allamuchy Twp"
    )
  )
})


test_that("district_name_to_id correctly identifies the friendly names", {
  
  back_to_id <- district_name_to_id(friendly_names[1:5], enr_several)
  expect_equal(
    back_to_id[1:5],
    c("6010", "0010", "0020", "6032", "6110")
  )
})


test_that("Newark's Dayton St. School exists", {
  enr_several <- map_df(
    c(2011:2014),
    fetch_enr, tidy=TRUE
  )
  
  nwk_schools <- enr_several %>%
    filter(district_id == '3570') %>%
    friendly_school_names()
  
  expect_true(sum(str_detect(nwk_schools, "Dayton")) == 1)
  expect_true(sum(str_detect(nwk_schools, "PESHINE")) == 1)
  
  
  expect_equal(
    c("600", "370") %in%
      school_name_to_id(c("Dayton Street School", "PESHINE AVE"), df = enr_several) %>%
      sum(),
    2
  )
})