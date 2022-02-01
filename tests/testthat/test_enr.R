context("functions in enr")

#post-NJSMART
test_that("get_raw_enr correctly grabs the 2015 enrollment file", {
  ex_2015 <- get_raw_enr(2015)

  expect_equal(nrow(ex_2015), 26223)
  expect_equal(ncol(ex_2015), 28)
  expect_equal(sum(ex_2015$ROW_TOTAL, na.rm = TRUE), 10954804)
})


test_that("get_raw_enr correctly grabs the 2011 enrollment file", {
  ex_2011 <- get_raw_enr(2011)

  expect_equal(nrow(ex_2011), 25891)
  expect_equal(ncol(ex_2011), 27)
  expect_equal(sum(ex_2011$ROW_TOTAL, na.rm = TRUE), 10871910)
})


#pre-NJSMART
test_that("get_raw_enr correctly grabs the 2010 enrollment file", {
  ex_2010 <- get_raw_enr(2010)

  expect_equal(nrow(ex_2010), 29599)
  expect_equal(ncol(ex_2010), 29)
  expect_equal(sum(ex_2010$ROW_TOTAL, na.rm = TRUE), 11084504)
})


test_that("get_raw_enr correctly grabs the 2001 enrollment file", {
  ex_2001 <- get_raw_enr(2001)

  expect_equal(nrow(ex_2001), 28447)
  expect_equal(ncol(ex_2001), 20)
  expect_equal(sum(ex_2001$ROWTOTAL, na.rm = TRUE), 10522596)
})


test_that("fetch_enr correctly grabs the 2012 enrollment file", {
  fetch_2009 <- fetch_enr(2009)

  expect_equal(nrow(fetch_2009), 29491)
  expect_equal(ncol(fetch_2009), 39)
  expect_equal(sum(as.numeric(fetch_2009$row_total), na.rm = TRUE), 35628697)
})


test_that("fetch_enr handles the 2016-17 enrollment file", {
  fetch_2017 <- fetch_enr(2017)

  expect_is(fetch_2017, 'data.frame')
  expect_equal(nrow(fetch_2017), 26467)
  expect_equal(ncol(fetch_2017), 39)
})


test_that("fetch_enr handles the 2017-18 enrollment file", {
  fetch_2018 <- fetch_enr(2018)

  expect_is(fetch_2018, 'data.frame')
  expect_equal(nrow(fetch_2018), 26484)
  expect_equal(ncol(fetch_2018), 39)
})


test_that("fetch_enr handles the 2017-18 enrollment file, tidy TRUE", {
  fetch_2018 <- fetch_enr(2018, TRUE)
  
  expect_is(fetch_2018, 'data.frame')
  expect_equal(fetch_2018 %>%
               filter(subgroup == "free_reduced_lunch") %>%
               nrow(), 
            3217)  
  expect_lte(fetch_2018 %>%
                  filter(grade_level == "TOTAL") %>%
                  nrow(), 6e5)
  
  expect_equal(nrow(fetch_2018), 651701)
  expect_equal(ncol(fetch_2018), 21)
})


test_that("fetch_enr handles the 2018-19 enrollment file", {
  fetch_2019 <- fetch_enr(2019)
  
  expect_is(fetch_2019, 'data.frame')
  
  expect_equal(nrow(fetch_2019), 26506)
  expect_equal(ncol(fetch_2019), 39)
})

test_that("fetch_enr handles the 2018-19 enrollment file, tidy = TRUE", {
  fetch_2019 <- fetch_enr(2019, TRUE)
  
  expect_is(fetch_2019, 'data.frame')
  expect_equal(nrow(fetch_2019), 652214)
  expect_equal(ncol(fetch_2019), 21)
})


test_that("all enrollment data can be pulled", {
  enr_all <- map_df(
    c(1999:2018),
    fetch_enr
  )

  expect_is(enr_all, 'data.frame')
  expect_equal(nrow(enr_all), 559791)
  expect_equal(ncol(enr_all), 42)
})


test_that("enr aggs correctly calculates known 2018 data", {
  ex_2018 <- get_raw_enr(2018) %>%
    clean_enr_names() %>%
    split_enr_cols() %>%
    clean_enr_data() %>%
    enr_aggs()
  
  attales <- ex_2018 %>% filter(CDS_Code == '010010050') 
  
  expect_equal(attales[attales$grade_level == '05', ]$row_total, 91)
  expect_equal(attales[attales$grade_level == '06', ]$row_total, 93)
  expect_equal(attales[attales$grade_level == '07', ]$row_total, 82)
  expect_equal(attales[attales$grade_level == '08', ]$row_total, 107)
  
  expect_equal(attales[attales$program_code == 'UG', ]$row_total, 8)
  expect_equal(attales[attales$program_code == '55', ]$row_total, 381)
  
  # new gender aggs
  expect_equal(attales[attales$program_code == '05', ]$male, 43)
  expect_equal(attales[attales$program_code == '05', ]$female, 48)
  
  # new race aggs
  expect_equal(attales[attales$program_code == '05', ]$white, 51)
  expect_equal(attales[attales$program_code == '05', ]$black, 19)
  expect_equal(attales[attales$program_code == '05', ]$hispanic, 11)
  expect_equal(attales[attales$program_code == '05', ]$asian, 6)
  expect_equal(attales[attales$program_code == '05', ]$native_american, 0)
  expect_equal(attales[attales$program_code == '05', ]$pacific_islander, 0)
  expect_equal(attales[attales$program_code == '05', ]$multiracial, 4)
})


test_that("fetch_enr works with tidy=TRUE argument", {
  enr_2018_untidy <- fetch_enr(2018, tidy=FALSE)
  expect_is(enr_2018_untidy, 'data.frame')
  
  enr_2018_tidy <- fetch_enr(2018, tidy=TRUE)
  expect_is(enr_2018_tidy, 'data.frame')
})


test_that("fetch_enr tidy FALSE works across many years", {
  enr_years <- c(1999:2018)
  enr_df <- map_df(enr_years, ~fetch_enr(.x, tidy=FALSE))
  expect_is(enr_df, 'data.frame')
})


test_that("fetch_enr tidy TRUE works across many years", {
  enr_years <- c(1999:2018)
  enr_df <- map_df(enr_years, ~fetch_enr(.x, tidy=TRUE))
  expect_is(enr_df, 'data.frame')
})


test_that("hand test fetch_enr numbers", {
  enr_2018_tidy <- fetch_enr(2018, tidy=TRUE)
  expect_is(enr_2018_tidy, 'data.frame')
  
  nps_2018 <- enr_2018_tidy %>%
    filter(district_id == '3570' & is_district)
  nps_2018_total <- nps_2018 %>% filter(subgroup == 'total_enrollment')
  
  expect_equal(
    nps_2018_total %>% filter(grade_level=='PK') %>% pull(n_students),
    1963
  )
  expect_equal(
    nps_2018_total %>% filter(grade_level=='K') %>% pull(n_students),
    2450
  )
  expect_equal(
    nps_2018_total %>% filter(grade_level=='01') %>% pull(n_students),
    2588
  )
  expect_equal(
    nps_2018_total %>% filter(grade_level=='02') %>% pull(n_students),
    2640
  )
  expect_equal(
    nps_2018_total %>% filter(grade_level=='03') %>% pull(n_students),
    2683
  )
  expect_equal(
    nps_2018_total %>% filter(grade_level=='04') %>% pull(n_students),
    2652
  )
  expect_equal(
    nps_2018_total %>% filter(grade_level=='05') %>% pull(n_students),
    2597
  )
  expect_equal(
    nps_2018_total %>% filter(grade_level=='06') %>% pull(n_students),
    2530
  )
  expect_equal(
    nps_2018_total %>% filter(grade_level=='07') %>% pull(n_students),
    2255
  )
  expect_equal(
    nps_2018_total %>% filter(grade_level=='08') %>% pull(n_students),
    2514
  )
  expect_equal(
    nps_2018_total %>% filter(grade_level=='09') %>% pull(n_students),
    2007
  )
  expect_equal(
    nps_2018_total %>% filter(grade_level=='10') %>% pull(n_students),
    2128
  )
  expect_equal(
    nps_2018_total %>% filter(grade_level=='11') %>% pull(n_students),
    2116
  )
  expect_equal(
    nps_2018_total %>% filter(grade_level=='12') %>% pull(n_students),
    1995
  )
})


test_that("hand test fetch_enr numbers", {
  enr_2007_tidy <- fetch_enr(2007, tidy=TRUE)
  nps_2007 <- enr_2007_tidy %>%
    filter(district_id == '3570' & is_district)
  nps_2007_total <- nps_2007 %>% filter(subgroup == 'total_enrollment')
  
  expect_equal(
    nps_2007_total %>% filter(grade_level=='PK' & program_code=='1') %>% pull(n_students),
    652
  )
  expect_equal(
    nps_2007_total %>% filter(grade_level=='K') %>% pull(n_students),
    3210
  )
  expect_equal(
    nps_2007_total %>% filter(grade_level=='01') %>% pull(n_students),
    3188
  )
  expect_equal(
    nps_2007_total %>% filter(grade_level=='02') %>% pull(n_students),
    3099
  )
  expect_equal(
    nps_2007_total %>% filter(grade_level=='03') %>% pull(n_students),
    3185
  )
  expect_equal(
    nps_2007_total %>% filter(grade_level=='04') %>% pull(n_students),
    2886
  )
  expect_equal(
    nps_2007_total %>% filter(grade_level=='05') %>% pull(n_students),
    2568
  )
  expect_equal(
    nps_2007_total %>% filter(grade_level=='06') %>% pull(n_students),
    2606
  )
  expect_equal(
    nps_2007_total %>% filter(grade_level=='07') %>% pull(n_students),
    2694
  )
  expect_equal(
    nps_2007_total %>% filter(grade_level=='08') %>% pull(n_students),
    2592
  )
  expect_equal(
    nps_2007_total %>% filter(grade_level=='09') %>% pull(n_students),
    2813
  )
  expect_equal(
    nps_2007_total %>% filter(grade_level=='10') %>% pull(n_students),
    2842
  )
  expect_equal(
    nps_2007_total %>% filter(grade_level=='11') %>% pull(n_students),
    2669
  )
  expect_equal(
    nps_2007_total %>% filter(grade_level=='12') %>% pull(n_students),
    2257
  )
})


test_that("enr_grade_aggs works", {
  ex_2018 <- fetch_enr(2018, TRUE)
  aggs_2018 <- enr_grade_aggs(ex_2018)
  expect_is(aggs_2018, 'data.frame')
  
  camden_es_k12 <- aggs_2018 %>% 
    filter(district_id == '3570' & school_id == '310' & grade_level=='K12')
  camden_es_k8 <- aggs_2018 %>% 
    filter(district_id == '3570' & school_id == '310' & grade_level=='K8')
  expect_equal(camden_es_k8$n_students, camden_es_k12$n_students)
  
  expect_gte(
    aggs_2018 %>%
      filter(district_id == '3570',
             school_id == '020',
             grade_level == 'K12UG',
             subgroup == 'total_enrollment') %>%
      pull(n_students),
    aggs_2018 %>%
      filter(district_id == '3570',
             school_id == '020',
             grade_level == 'K12',
             subgroup == 'total_enrollment') %>%
      pull(n_students)
    )
  
})

test_that("frl group exists", {
  enr_19 <- fetch_enr(2019, TRUE)
  
  expect_gt(enr_19 %>%
              filter(district_id == '3570',
                     school_id == '999',
                     subgroup == "free_lunch") %>%
              pull(pct),
            0)
  
  expect_gt(enr_19 %>%
              filter(district_id == '3570',
                     school_id == '999',
                     subgroup == "free_reduced_lunch") %>%
              pull(pct), 
            0)
})


test_that("refactor 2010 test", {
  
  enr_2010 <- get_raw_enr(2010)
  
  expect_equal(dim(enr_2010)[1], 29599)
  expect_equal(dim(enr_2010)[2], 29)
  expect_equal(sum(enr_2010$ROW_TOTAL), 11084504)
  
})


test_that("2020 isn't terribly wrong", {
  enr_2020 <- fetch_enr(2020, tidy = TRUE)
  
  expect_equal(filter(enr_2020,
                      district_id == '3570',
                      school_id == '999',
                      grade_level == "TOTAL",
                      subgroup == "total_enrollment") %>%
                 pull(n_students),
               36676)
  
  
  expect_equal(filter(enr_2020,
                      district_id == '3570',
                      school_id == '303',
                      grade_level == "01",
                      subgroup == "total_enrollment") %>%
                 pull(n_students),
               91)
  
  
  expect_equal(filter(enr_2020,
                      district_id == '3570',
                      school_id == '004',
                      program_code == "55",
                      subgroup == "migrant") %>%
                 pull(n_students),
               0)
  
  
  
})
