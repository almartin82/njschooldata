context("test msgp functions")

sgp16 <- get_and_process_msgp(2016)
sgp17 <- get_and_process_msgp(2017)
sgp18 <- get_and_process_msgp(2018)
# should we test fetch_msgp() ?
sgp19 <- get_and_process_msgp(2019)

test_that("sgp works with 2016 data", {
  expect_is(sgp16, 'tbl_df')
  expect_is(sgp16, 'data.frame')
  expect_equal(
    names(sgp16),
    c("county_id", "district_id", "school_id",
      "end_year", "subject", "grade", "subgroup", "median_sgp", 
      "is_district", "is_school"))
    
    expect_length(sgp16 %>% 
                    filter(is_district) %>%
                    group_by(district_id, subject) %>%
                    filter(n() > 1) %>%
                    pull(median_sgp),
                  0)
})


test_that("sgp works with 2017 data", {
  expect_is(sgp17, 'tbl_df')
  expect_is(sgp17, 'data.frame')
  expect_equal(
    names(sgp17),
    c("county_id", "district_id", "school_id",
      "end_year", "subject", "grade", "subgroup", "median_sgp", 
      "is_district", "is_school")
  )
})


test_that("sgp works with 2018 data", {
  expect_is(sgp18, 'tbl_df')
  expect_is(sgp18, 'data.frame')
  expect_equal(
    names(sgp18),
    c("county_id", "district_id", "school_id", 
      "end_year", "subject", "grade", "subgroup", "median_sgp", 
      "is_district", "is_school")
  )
})


test_that("sgp works with 2019 data", {
   expect_is(sgp19, 'tbl_df')
   expect_is(sgp19, 'data.frame')
   expect_equal(
      names(sgp19),
      c("county_id", "district_id", "school_id", 
        "end_year", "subject", "grade", "subgroup", "median_sgp", 
        "is_district", "is_school")
   )
})

test_that("ground truth value checks on 2019 sgp data", {
   newark_sgp_19 <- sgp19 %>%
      filter(district_id == '3570',
             school_id == '270',
             !is_district) 
   
   expect_is(newark_sgp_19, 'data.frame')
   
   expect_equal(newark_sgp_19 %>% 
                   filter(subgroup == "total population",
                          subject == "ela",
                          grade == "TOTAL") %>% 
                   pull(median_sgp), 
                "38.5")
   
   expect_equal(newark_sgp_19 %>% 
                   filter(subgroup == "economically disadvantaged",
                          subject == "ela") %>% 
                   pull(median_sgp), 
                "38.5")
   
   expect_equal(newark_sgp_19 %>% 
                   filter(subgroup == "male",
                          subject == "ela") %>% 
                   pull(median_sgp), 
                NA_character_)
   
   expect_equal(newark_sgp_19 %>%
                   filter(subgroup == "homeless",
                          subject == "math") %>%
                   pull(median_sgp),
                NA_character_)
   
   expect_equal(newark_sgp_19 %>%
                   filter(grade == "Grade 4",
                          subject == "math") %>%
                   pull(median_sgp),
                "46")
})