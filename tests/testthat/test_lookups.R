
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


test_that("comparing schools with the same id across districts", {
  
  newark <- filter(enr_several, district_id %in% c('3570')) %>%
    friendly_school_names()
  
  jerseycity <- filter(enr_several, district_id %in% c('2390')) %>%
    friendly_school_names()
  
  both <- filter(enr_several, district_id %in% c('3570', '2390')) %>%
    friendly_school_names()
  
  expect_equal(length(both), length(newark) + length(jerseycity))
})
