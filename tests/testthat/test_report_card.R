
rc <- get_one_rc_database(2015)
many_rc <- get_rc_databases(2012:2019)
all_rc <- many_rc

# rc_2003 <- get_one_rc_database(2003)
# rc_2004 <- get_one_rc_database(2004)
rc_2012 <- get_one_rc_database(2012)
rc_2013 <- get_one_rc_database(2013)
rc_2014 <- get_one_rc_database(2014)
rc_2015 <- get_one_rc_database(2015)
rc_2016 <- get_one_rc_database(2016)
rc_2017 <- get_one_rc_database(2017)
rc_2018 <- get_one_rc_database(2018)
rc_2019 <- get_one_rc_database(2019)

test_that("get_raw_rc_database returns list of data frames", {
  
  expect_is(rc, 'list')
  expect_equal(length(rc), 25)
  expect_equal(
    names(rc),
    c("sch_header", "lang", "enrollment", "esea_waiver", "parcc_ela", 
      "parcc_math", "parcc_state_avg", "njask_science", "biology", 
      "naep", "ap_ib", "ap_ib_sum", "participation_pct_sat_psat_act", 
      "sat_avg", "sat_1550", "algebra", "chronic_absenteeism", "graduation", 
      "graduation_pathways", "post_sec", "dropout", 
      "visual_arts", "cte_sle_dual_enr", "sgp", "school_climate"
    )
  )
})


test_that("get_raw_rc_database returns list of data frames", {
  expect_is(many_rc, 'list')
  expect_equal(length(many_rc), 8)
})

test_that("extract_rc_SAT pulls longitudinal SAT data", {
  df <- extract_rc_SAT(many_rc)
  expect_is(df, 'tbl_df')
  
  df <- extract_rc_SAT(all_rc)
  expect_is(df, 'tbl_df')
})


test_that("extract_rc_college_matric pulls longitudinal matriculation data", {
  df <- extract_rc_college_matric(many_rc)
  expect_is(df, 'tbl_df')
  
  expect_equal(df %>%
                 pull(end_year) %>%
                 unique(),
               2012:2019)
  
  df <- extract_rc_college_matric(all_rc)
  expect_is(df, 'tbl_df')
})


test_that("extract_rc_ap pulls longitudinal Advanced Placement data", {
  df <- extract_rc_AP(many_rc)
  expect_is(df, 'tbl_df')
  
  df <- extract_rc_AP(all_rc)
  expect_is(df, 'tbl_df')
})


test_that("extract_rc_cds finds the county district school name for every year", {
  
  df <- extract_rc_cds(many_rc)
  expect_is(df, 'tbl_df')
  expect_named(
    df, 
    c("county_code", "district_code", "school_code", "county_name", 
      "district_name", "school_name", "end_year")
  )
  
  df <- extract_rc_cds(all_rc)
  expect_is(df, 'tbl_df')
  expect_named(
    df, 
    c("county_code", "district_code", "school_code", "county_name", 
      "district_name", "school_name", "end_year")
  )
  
})


test_that("extract_rc_enrollment pulls longitudinal enrollment data", {
   enr_many <- extract_rc_enrollment(many_rc)
   
   expect_is(enr_many, 'tbl_df')
   expect_named(enr_many,
                c("county_id", "district_id", "school_id",
                  "end_year", "grade_level", "n_enrolled",
                  "county_name",  "district_name"))
   expect_setequal(enr_many %>%
                      pull(grade_level) %>%
                      unique(),
                   c("01", "02", "03", "04", "05", "06", "07", "08",
                     "09", "10", "11", "12", "PK", "KG", "TOTAL", 
                     NA_character_))
   
   expect_equal(enr_many %>%
                   filter(district_id == "3570",
                          school_id == "999",
                          grade_level == "TOTAL",
                          end_year == 2019) %>%
                   pull(n_enrolled),
                "41510")
}) 


test_that("extract_rc_college_matric ground truth values", {
  matric_12 <- extract_rc_college_matric(list(rc_2012))
  
  expect_equal(matric_12 %>%
                 filter(district_code == '3570',
                        school_code == '055', 
                        subgroup == 'Economically Disadvantaged Students') %>%
                 pull(enroll_4yr),
               84.2)
  
  matric_17 <- extract_rc_college_matric(list(rc_2017))
  
  expect_equal(matric_17 %>%
                 filter(district_code == '3570',
                        school_code == '055',
                        subgroup == 'Total Population') %>%
                 pull(enroll_any),
               67.2)
  
  expect_equal(matric_17 %>%
                 filter(district_code == '3570',
                        school_code == '055',
                        subgroup == 'Total Population') %>%
                 pull(enroll_4yr),
               87.4)
})

test_that("enrich_matric_counts joins correct years", {
  matric_12 <- extract_rc_college_matric(list(rc_2012))
  
  expect_error(matric_12 %>%
                 enrich_grad_count())
  
  
  gcount_12 <- fetch_grad_count(2012)
  matric_13 <- extract_rc_college_matric(list(rc_2013))
  
  matric_counts_13 <- matric_13 %>%
    enrich_matric_counts()
  
  
  expect_equal(matric_counts_13 %>%
                 filter(district_id == '3570',
                        school_id == '055',
                        subgroup == 'total population') %>%
                 pull(graduated_count),
               gcount_12 %>%
                 filter(district_id == '3570',
                        school_id == '055',
                        subgroup == 'total population') %>%
                 pull(graduated_count))

  
  
  matric_18 <- extract_rc_college_matric(list(rc_2018))
  matric_18_12mo <- extract_rc_college_matric(list(rc_2018),
                                              type = "12 month")
  gcount_17 <- fetch_grad_count(2017)
  gcount_18 <- fetch_grad_count(2018)
  
  matric_counts_18 <- matric_18 %>%
    enrich_matric_counts()
  matric_counts_18_12mo <- matric_18_12mo %>%
    enrich_matric_counts(type = "12 month")
  
  expect_equal(matric_counts_18 %>%
                 filter(district_id == '3570',
                        school_id == '055',
                        subgroup == 'total population') %>%
                 pull(graduated_count),
               gcount_17 %>%
                 filter(district_id == '3570',
                        school_id == '055',
                        subgroup == 'total population') %>%
                 pull(graduated_count))
  
  expect_equal(matric_counts_18_12mo %>%
                 filter(district_id == '3570',
                        school_id == '055',
                        subgroup == 'total population') %>%
                 pull(graduated_count),
               gcount_18 %>%
                 filter(district_id == '3570',
                        school_id == '055',
                        subgroup == 'total population') %>%
                 pull(graduated_count))
})

test_that("enrich_grad_count joins correct subgroup", {

  matric_13 <- extract_rc_college_matric(list(rc_2013))
  
  gcount_12 <- fetch_grad_count(2012)
  
  matric_counts_13 <- matric_13 %>%
    enrich_matric_counts()
  
  expect_equal(matric_counts_13 %>%
                 filter(district_id == '3570',
                        school_id == '055',
                        subgroup == 'black') %>%
                 pull(graduated_count),
               gcount_12 %>%
                 filter(district_id == '3570',
                        school_id == '055',
                        subgroup == 'black') %>%
                 pull(graduated_count))
  
  expect_equal(matric_counts_13 %>%
                 filter(district_id == '3570',
                        school_id == '055',
                        subgroup == 'economically disadvantaged') %>%
                 pull(graduated_count),
               gcount_12 %>%
                 filter(district_id == '3570',
                        school_id == '055',
                        subgroup == 'economically disadvantaged') %>%
                 pull(graduated_count))
})




test_that("enrich_matric_counts enriches multiple yrs", {
  matric_1819 <- extract_rc_college_matric(list(rc_2018, rc_2019))
  
  matric_counts_18 <- rc_2018 %>%
    list() %>%
    extract_rc_college_matric() %>%
    enrich_matric_counts()
  
  matric_counts_17 <- rc_2017 %>%
    list() %>%
    extract_rc_college_matric() %>%
    enrich_matric_counts()
  
  matric_counts_1819 <- matric_1819 %>%
    enrich_matric_counts()
  
  expect_equal(matric_counts_1819 %>%
                 filter(end_year == 2019,
                        district_id == '3570',
                        school_id == '055',
                        subgroup == 'black') %>%
                 pull(graduated_count),
               gcount_18 %>% 
                 filter(district_id == '3570',
                        school_id == '055',
                        subgroup == 'black') %>%
                 pull(graduated_count))
  

  expect_equal(matric_counts_1819 %>%
                 filter(end_year == 2018,
                        district_id == '3570',
                        school_id == '055',
                        subgroup == 'hispanic') %>%
                 pull(graduated_count),
               gcount_17 %>% 
                 filter(district_id == '3570',
                        school_id == '055',
                        subgroup == 'hispanic') %>%
                 pull(graduated_count))
})


test_that("district_matric_aggs aggregates correctly", {
  
  matric_counts_16 <- rc_2016 %>%
    list() %>%
    extract_rc_college_matric() %>%
    enrich_matric_counts()
  
  # just making sure there aren't any district level outcomes here!
  expect_equal(matric_counts_16 %>%
                 filter(school_id == '999') %>%
                 nrow(),
               0)
  
  dists_16 <- district_matric_aggs(matric_counts_16)
  
  expect_equal(dists_16 %>%
               pull(district_id) %>%
               unique() %>%
               length(),
             matric_counts_16 %>%
               pull(district_id) %>%
               unique() %>%
               length())
  
  
  expect_equal(dists_16 %>%
                 filter(district_id == '3710',
                        subgroup == 'total population') %>%
                 pull(enroll_any_count),
               529)
  
  expect_equal(dists_16 %>%
                 filter(district_id == '3710',
                        subgroup == 'total population') %>%
                 pull(enroll_2yr),
               5.5)
})

