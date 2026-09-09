skip_if_no_live_tests()


sgp16 <- get_and_process_msgp(2016)
sgp17 <- get_and_process_msgp(2017)
sgp18 <- get_and_process_msgp(2018)
# should we test fetch_msgp() ?
sgp19 <- get_and_process_msgp(2019)

test_that("sgp works with 2016 data", {
  expect_is(sgp16, 'tbl_df')
  expect_s3_class(sgp16, 'data.frame')
  expect_equal(
    names(sgp16),
    c("county_id", "district_id", "school_id",
      "end_year", "subject", "grade", "subgroup", "median_sgp",
      "is_district", "is_school", "is_charter")
  )
  
  expect_length(sgp16 %>%
                  filter(is_district) %>%
                  group_by(district_id, subject) %>%
                  filter(n() > 1) %>%
                  pull(median_sgp),
                  0)
  
  expect_length(sgp16 %>%
                  filter(district_id == '3570',
                         is_district) %>%
                  pull(median_sgp), 
                2)
})


test_that("sgp works with 2017 data", {
  expect_is(sgp17, 'tbl_df')
  expect_s3_class(sgp17, 'data.frame')
  expect_equal(
    names(sgp17),
    c("county_id", "district_id", "school_id",
      "end_year", "subject", "grade", "subgroup", "median_sgp",
      "is_district", "is_school", "is_charter")
  )
})


test_that("sgp works with 2018 data", {
  expect_is(sgp18, 'tbl_df')
  expect_s3_class(sgp18, 'data.frame')
  expect_equal(
    names(sgp18),
    c("county_id", "district_id", "school_id",
      "end_year", "subject", "grade", "subgroup", "median_sgp",
      "is_district", "is_school", "is_charter")
  )
})


test_that("sgp works with 2019 data", {
   expect_is(sgp19, 'tbl_df')
   expect_s3_class(sgp19, 'data.frame')
   expect_equal(
      names(sgp19),
      c("county_id", "district_id", "school_id",
        "end_year", "subject", "grade", "subgroup", "median_sgp",
        "is_district", "is_school", "is_charter")
   )
})

test_that("ground truth value checks on 2019 sgp data", {
   newark_sgp_19 <- sgp19 %>%
      filter(district_id == '3570',
             school_id == '270',
             !is_district) 
   
   expect_s3_class(newark_sgp_19, 'data.frame')
   
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

test_that("the statewide 2017 row reports the published StateMedian", {
  # NJ DOE's District/State workbook stamps the statewide row's CountyCode with
  # the literal word "State" and leaves DistrictMedian blank on it, so the value
  # lives in StateMedian. The casing of that literal drifts by workbook: the
  # 2016-2017 Database_DistrictStateDetail.xlsx spells it "STATE", the 2017-2018
  # and 2018-2019 ones spell it "State".
  #
  # Read directly out of that workbook (sheet StudentGrowth, header on row 1;
  # column A CountyCode, C StudentGroup, D Subject, E DistrictMedian,
  # F StateMedian). The 20 statewide rows are 11802:11821, all with A = "STATE"
  # and E blank:
  #
  #   A11814 "STATE"  C11814 "Statewide"                   D11814 "ELA"   F11814 50.00
  #   A11815 "STATE"  C11815 "Statewide"                   D11815 "Math"  F11815 50.00
  #   A11804 "STATE"  C11804 "Asian, Native Hawaiian, ..." D11804 "ELA"   F11804 60.00
  #   A11816 "STATE"  C11816 "Students with Disabilities"  D11816 "ELA"   F11816 41.00
  state_17 <- sgp17 %>%
    filter(toupper(trimws(county_id)) == 'STATE', grade == 'TOTAL')

  expect_equal(nrow(state_17), 20)
  expect_equal(sum(is.na(state_17$median_sgp)), 0)

  expect_equal(
    state_17 %>%
      filter(subgroup == 'total population', subject == 'ela') %>%
      pull(median_sgp),
    "50.00"
  )
  expect_equal(
    state_17 %>%
      filter(subgroup == 'total population', subject == 'math') %>%
      pull(median_sgp),
    "50.00"
  )
  expect_equal(
    state_17 %>%
      filter(subgroup == 'asian', subject == 'ela') %>%
      pull(median_sgp),
    "60.00"
  )
  expect_equal(
    state_17 %>%
      filter(subgroup == 'students with disabilities', subject == 'ela') %>%
      pull(median_sgp),
    "41.00"
  )
})


test_that("the statewide 2018 row is unaffected by the casing fix", {
  # 2017-2018 Database_DistrictStateDetail.xlsx spells the literal "State", so
  # these rows already resolved before the case-insensitive match and must be
  # untouched by it.
  state_18 <- sgp18 %>%
    filter(toupper(trimws(county_id)) == 'STATE', grade == 'TOTAL')

  expect_equal(nrow(state_18), 20)
  expect_equal(sum(is.na(state_18$median_sgp)), 0)
  expect_equal(
    state_18 %>%
      filter(subgroup == 'total population', subject == 'ela') %>%
      pull(median_sgp),
    "50.0"
  )
})
