
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


test_that("fetch_enr correctly grabs the 2009 enrollment file", {
  fetch_2009 <- fetch_enr(2009)

  expect_equal(nrow(fetch_2009), 29491)
  expect_equal(ncol(fetch_2009), 39)
  # Verified against raw NJ DOE source file: enrollment_0809.zip -> STAT_ENR.CSV
  expect_equal(sum(as.numeric(fetch_2009$row_total), na.rm = TRUE), 11034082)
})


test_that("fetch_enr handles the 2016-17 enrollment file", {
  fetch_2017 <- fetch_enr(2017)

  expect_s3_class(fetch_2017, 'data.frame')
  expect_equal(nrow(fetch_2017), 26467)
  expect_equal(ncol(fetch_2017), 39)
})


test_that("fetch_enr handles the 2017-18 enrollment file", {
  fetch_2018 <- fetch_enr(2018)

  expect_s3_class(fetch_2018, 'data.frame')
  expect_equal(nrow(fetch_2018), 26484)
  expect_equal(ncol(fetch_2018), 39)
})


test_that("fetch_enr handles the 2017-18 enrollment file, tidy TRUE", {
  fetch_2018 <- fetch_enr(2018, TRUE)
  
  expect_s3_class(fetch_2018, 'data.frame')
  expect_equal(fetch_2018 %>%
               filter(subgroup == "free_reduced_lunch") %>%
               nrow(), 
            3217)  
  expect_lte(fetch_2018 %>%
                  filter(grade_level == "TOTAL") %>%
                  nrow(), 6e5)
  
  expect_equal(nrow(fetch_2018), 651701)
  expect_equal(ncol(fetch_2018), 22)  # includes is_charter column
})


test_that("fetch_enr handles the 2018-19 enrollment file", {
  fetch_2019 <- fetch_enr(2019)
  
  expect_s3_class(fetch_2019, 'data.frame')
  
  expect_equal(nrow(fetch_2019), 26506)
  expect_equal(ncol(fetch_2019), 39)
})

test_that("fetch_enr handles the 2018-19 enrollment file, tidy = TRUE", {
  fetch_2019 <- fetch_enr(2019, TRUE)
  
  expect_s3_class(fetch_2019, 'data.frame')
  expect_equal(nrow(fetch_2019), 652214)
  expect_equal(ncol(fetch_2019), 22)  # includes is_charter column
})


test_that("all enrollment data can be pulled", {
  enr_all <- map_df(
    c(2000:2022),
    fetch_enr
  )

  expect_s3_class(enr_all, 'data.frame')
  expect_equal(nrow(enr_all), 727779)
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
  expect_s3_class(enr_2018_untidy, 'data.frame')
  
  enr_2018_tidy <- fetch_enr(2018, tidy=TRUE)
  expect_s3_class(enr_2018_tidy, 'data.frame')
})


test_that("fetch_enr tidy FALSE works across many years", {
  enr_years <- c(1999:2018)
  enr_df <- map_df(enr_years, ~fetch_enr(.x, tidy=FALSE))
  expect_s3_class(enr_df, 'data.frame')
})


test_that("fetch_enr tidy TRUE works across many years", {
  enr_years <- c(1999:2018)
  enr_df <- map_df(enr_years, ~fetch_enr(.x, tidy=TRUE))
  expect_s3_class(enr_df, 'data.frame')
})


test_that("hand test fetch_enr numbers", {
  enr_2018_tidy <- fetch_enr(2018, tidy=TRUE)
  expect_s3_class(enr_2018_tidy, 'data.frame')
  
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
  expect_s3_class(aggs_2018, 'data.frame')
  
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


test_that("2021 makes sense", {
  enr_2021 <- fetch_enr(2021, tidy = TRUE)

  # Verified against raw NJ DOE source: enrollment_2021.xlsx District sheet
  expect_equal(filter(enr_2021,
                      district_id == '3570',
                      school_id == '999',
                      grade_level == "TOTAL",
                      subgroup == "total_enrollment") %>%
                 pull(n_students),
               40085)

  expect_equal(filter(enr_2021,
                      district_id == '3570',
                      school_id == '303',
                      grade_level == "01",
                      subgroup == "total_enrollment") %>%
                 pull(n_students),
               82)

  expect_equal(filter(enr_2021,
                      district_id == '3570',
                      school_id == '004',
                      program_code == "55",
                      subgroup == "migrant") %>%
                 pull(n_students),
               0)
})


test_that("2022 makes sense", {
  enr_2022 <- fetch_enr(2022, tidy = TRUE)
  
  expect_equal(filter(enr_2022,
                      district_id == '3570',
                      school_id == '999',
                      grade_level == "TOTAL",
                      subgroup == "total_enrollment") %>%
                 pull(n_students),
               40607)
  
  expect_equal(filter(enr_2022,
                      district_id == '3570',
                      school_id == '303',
                      grade_level == "01",
                      subgroup == "total_enrollment") %>%
                 pull(n_students),
               84)
  
  expect_equal(filter(enr_2022,
                      district_id == '3570',
                      school_id == '004',
                      program_code == "55",
                      subgroup == "migrant") %>%
                 pull(n_students),
               0)
})


test_that("1999-2000 works again", {
  ex <- fetch_enr(2000)
  expect_s3_class(ex, 'data.frame')
  
})


test_that("2020 works again", {
  ex <- fetch_enr(2020)
  expect_s3_class(ex, 'data.frame')

})


test_that("princeton data looks reasonable", {

  ex_fetch <- fetch_enr(2000)

  ex <- fetch_enr(2000, tidy=TRUE)
  ex_agg <- enr_grade_aggs(ex)
  ex_all <- bind_rows(ex, ex_agg)

  expect_s3_class(ex_all, 'data.frame')

  ex_raw <- get_raw_enr(end_year = 2000)

  filtered_fetch <- ex_fetch %>%
    filter(CDS_Code == '214255999') %>%
    filter(
      grade_level == 'TOTAL'
    )

  filtered_tidy <- ex_all %>%
    filter(CDS_Code == '214255999') %>%
    filter(
      grade_level == 'TOTAL' &
      subgroup == 'total_enrollment'
    )

  filtered_raw <- ex_raw %>%
    filter(
      COUNTY == '21-MERCER' &
        DISTRICT == '4255-PRINCETON REGIONAL' &
        SCHOOL == '999-DISTRICT TOTAL'
    ) %>%
    filter(
      PROG_NAME == 'Total'
    )

  filtered_fetch %>% print.AsIs()
  filtered_tidy %>% print.AsIs()
  filtered_raw %>% print.AsIs()

  expect_equal(filtered_fetch$row_total, 3164.5)
  expect_equal(filtered_tidy$n_students, 3164.5)
  expect_equal(filtered_fetch$row_total, 3164.5)

})


test_that("2007 princeton data looks reasonable", {
  
  ex_fetch <- fetch_enr(2007)
  
  ex <- fetch_enr(2007, tidy=TRUE)
  ex_agg <- enr_grade_aggs(ex)
  ex_all <- bind_rows(ex, ex_agg)
  
  expect_s3_class(ex_all, 'data.frame')
  
  ex_raw <- get_raw_enr(end_year = 2007)
  
  filtered_fetch <- ex_fetch %>%
    filter(CDS_Code == '214255999') %>%
    filter(
      grade_level == 'TOTAL'
    )
  
  filtered_tidy <- ex_all %>%
    filter(CDS_Code == '214255999') %>%
    filter(
      grade_level == 'TOTAL' &
        subgroup == 'total_enrollment'
    )
  
  filtered_raw <- ex_raw %>%
    filter(
      COUNTY == '21-MERCER' &
        DISTRICT == '4255-PRINCETON REGIONAL' &
        SCHOOL == '999-DISTRICT TOTAL'
    ) %>%
    filter(
      PROG_NAME == 'Total'
    )
  
  filtered_fetch %>% print.AsIs()
  filtered_tidy %>% print.AsIs()
  filtered_raw %>% print.AsIs()

  # Verified against raw NJ DOE source file: enrollment_0607.zip -> STAT_ENR.CSV
  # Princeton Regional 2007 ROWTOTAL = 4262 (not 3164.5 which was the 2000 value)
  expect_equal(filtered_fetch$row_total, 4262)
  expect_equal(filtered_tidy$n_students, 4262)
  expect_equal(filtered_fetch$row_total, 4262)

})


test_that("look at all enr data to see if there are parsing problems", {

  all_years <- c(2000:2022)

  for (i in all_years) {
    enr_output <- fetch_enr(i)
    expect_s3_class(enr_output, 'data.frame')
  }
  # Note: tidyselect deprecation warnings are expected and not checked here
})


test_that("2020+ data includes racial subgroups when tidy = TRUE", {
  
  ex_2020 <- get_raw_enr(2020) %>%
    filter(`District Code` == '4255') %>%
    filter(Grade == 'All Grades') %>%
    filter(`School Code` == '999')
  
  ex_tidy <- fetch_enr(2020, tidy=TRUE) %>%
    filter(district_id == '4255') %>%
    filter(subgroup == 'asian') %>%
    filter(school_id == '999')

  expect_equal(ex_tidy$n_students, ex_2020$Asian)
  expect_equal(ex_tidy$program_name, 'Total')
})


# NOTE: 1999 enrollment data was removed from NJ DOE website.
# Valid enrollment years are now 2000-2025.


test_that("2024-25 enrollment data fetches correctly", {
  enr_2025 <- fetch_enr(2025, tidy = TRUE)

  # Newark total enrollment (verified against raw Excel file)
  newark_total <- filter(enr_2025,
                         district_id == '3570',
                         school_id == '999',
                         grade_level == "TOTAL",
                         subgroup == "total_enrollment") %>%
    pull(n_students)
  expect_equal(newark_total, 43980)

  # Newark racial subgroups
  expect_equal(filter(enr_2025,
                      district_id == '3570',
                      school_id == '999',
                      subgroup == "black") %>%
                 pull(n_students),
               13906)

  expect_equal(filter(enr_2025,
                      district_id == '3570',
                      school_id == '999',
                      subgroup == "hispanic") %>%
                 pull(n_students),
               26384)

  expect_equal(filter(enr_2025,
                      district_id == '3570',
                      school_id == '999',
                      subgroup == "white") %>%
                 pull(n_students),
               2880)

  # Jersey City verification
  expect_equal(filter(enr_2025,
                      district_id == '2390',
                      school_id == '999',
                      grade_level == "TOTAL",
                      subgroup == "total_enrollment") %>%
                 pull(n_students),
               25692)

  expect_equal(filter(enr_2025,
                      district_id == '2390',
                      school_id == '999',
                      subgroup == "asian") %>%
                 pull(n_students),
               4663)

  # Princeton verification
  expect_equal(filter(enr_2025,
                      district_id == '4255',
                      school_id == '999',
                      grade_level == "TOTAL",
                      subgroup == "total_enrollment") %>%
                 pull(n_students),
               3787)

  expect_equal(filter(enr_2025,
                      district_id == '4255',
                      school_id == '999',
                      subgroup == "asian") %>%
                 pull(n_students),
               970)
})


test_that("2023-24 enrollment data fetches correctly", {
  enr_2024 <- fetch_enr(2024, tidy = TRUE)

  # Basic structure tests
  expect_s3_class(enr_2024, 'data.frame')
  expect_true(nrow(enr_2024) > 100000)  # Should have many rows
  expect_true("district_id" %in% names(enr_2024))
  expect_true("subgroup" %in% names(enr_2024))
  expect_true("n_students" %in% names(enr_2024))

  # Check Newark is present
  newark_exists <- filter(enr_2024,
                          district_id == '3570',
                          school_id == '999',
                          subgroup == "total_enrollment") %>%
    nrow()
  expect_true(newark_exists > 0)
})


test_that("2024-25 charter schools have correct enrollment", {
  enr_2025 <- fetch_enr(2025, tidy = TRUE)

  # North Star Academy Charter School (7320) - one of Newark's largest charters
  north_star <- filter(enr_2025,
                       district_id == '7320',
                       school_id == '999',
                       grade_level == "TOTAL",
                       subgroup == "total_enrollment") %>%
    pull(n_students)
  expect_true(north_star > 2000)  # Known to be a large charter

  # TEAM Academy Charter School (7325) - another large Newark charter
  team <- filter(enr_2025,
                 district_id == '7325',
                 school_id == '999',
                 grade_level == "TOTAL",
                 subgroup == "total_enrollment") %>%
    pull(n_students)
  expect_true(team > 1000)  # Known to be a large charter
})


test_that("2024-25 enrollment has expected grade levels", {
  enr_2025 <- fetch_enr(2025, tidy = TRUE)

  # Check Newark has expected grade levels
  newark_grades <- filter(enr_2025,
                          district_id == '3570',
                          school_id == '999',
                          subgroup == "total_enrollment") %>%
    pull(grade_level) %>%
    unique()

  # Should have Pre-K through 12 plus TOTAL
  expect_true("TOTAL" %in% newark_grades)
  expect_true("01" %in% newark_grades | "1" %in% newark_grades)  # First grade
  expect_true("12" %in% newark_grades)  # Twelfth grade
})


test_that("2024-25 enrollment has all racial subgroups", {
  enr_2025 <- fetch_enr(2025, tidy = TRUE)

  # Check Newark has all expected racial subgroups
  newark_subgroups <- filter(enr_2025,
                             district_id == '3570',
                             school_id == '999') %>%
    pull(subgroup) %>%
    unique()

  expect_true("black" %in% newark_subgroups)
  expect_true("hispanic" %in% newark_subgroups)
  expect_true("white" %in% newark_subgroups)
  expect_true("asian" %in% newark_subgroups)
  expect_true("multiracial" %in% newark_subgroups)
  expect_true("total_enrollment" %in% newark_subgroups)
})


test_that("historical enrollment data (2000-2010) still works", {
  # Test year 2005 - middle of old format era
  enr_2005 <- fetch_enr(2005, tidy = TRUE)

  expect_s3_class(enr_2005, 'data.frame')
  expect_true(nrow(enr_2005) > 10000)

  # Check Newark exists in 2005
  newark_2005 <- filter(enr_2005,
                        district_id == '3570') %>%
    nrow()
  expect_true(newark_2005 > 0)
})
