context("report_card functions")

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
  expect_equal(length(many_rc), 6)
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
                c("county_code", "district_code", "school_code",
                  "end_year", "grade_level", "n_enrolled",
                  "county_name",  "district_name", "school_name"))
   expect_setequal(enr_many %>%
                      pull(grade_level) %>%
                      unique(),
                   c("01", "02", "03", "04", "05", "06", "07", "08",
                     "09", "10", "11", "12", "PK", "KG", "TOTAL", 
                     NA_character_))
   
   expect_equal(enr_many %>%
                   filter(district_code == "3570",
                          school_code == "999",
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
               85.3)
  
  expect_equal(matric_17 %>%
                 filter(district_code == '3570',
                        school_code == '055',
                        subgroup == 'Total Population') %>%
                 pull(enroll_4yr),
               93.6)
})

test_that("enrich_grad_count joins correct years", {
  matric_12 <- extract_rc_college_matric(list(rc_2012))
  
  expect_error(matric_12 %>%
                 enrich_grad_count())
  
  
  matric_13 <- extract_rc_college_matric(list(rc_2013))
  
  matric_counts_13 <- matric_13 %>%
    enrich_grad_count()
  
  expect_equal(matric_counts_13 %>%
                 pull(gc_year) %>%
                 unique(),
               unique(matric_counts_13$end_year) - 1)
  
  expect_equal(matric_counts_13 %>%
                 filter(district_code == '3570',
                        school_code == '055',
                        subgroup == 'total population') %>%
                 pull(graduated_count),
               167)
  
  
  matric_17 <- extract_rc_college_matric(list(rc_2017))
  
  matric_counts_17 <- matric_17 %>%
    enrich_grad_count()
  
  expect_equal(matric_counts_17 %>%
                 pull(gc_year) %>%
                 unique(),
               unique(matric_counts_17$end_year))
})

test_that("enrich_grad_count joins correct subgroup", {

  matric_13 <- extract_rc_college_matric(list(rc_2013))
  
  gc_12 <- fetch_grad_count(2012)
  
  matric_counts_13 <- matric_13 %>%
    enrich_grad_count()
  
  expect_equal(matric_counts_13 %>%
                 filter(district_code == '3570',
                        school_code == '055',
                        subgroup == 'black') %>%
                 pull(graduated_count),
               62)
  
  expect_equal(matric_counts_13 %>%
                 filter(district_code == '3570',
                        school_code == '055',
                        subgroup == 'economically disadvantaged') %>%
                 pull(graduated_count),
               128)
})


test_that("enrich_matric_counts gets both 12/16 mo", {
  
  matric_18 <- extract_rc_college_matric(list(rc_2018))
  matric_18_12mo <- extract_rc_college_matric(list(rc_2018),
                                              type = '12 month')
  
  expect_false(identical(matric_18, matric_18_12mo))
  
  
  matric_18_counts <- enrich_matric_counts(matric_18)
  matric_18_counts_12mo <- enrich_matric_counts(matric_18_12mo)
  
  expect_false(identical(matric_18_counts, matric_18_counts_12mo))
})