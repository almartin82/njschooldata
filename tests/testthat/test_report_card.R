context("report_card functions")

rc <- get_one_rc_database(2015)
many_rc <- get_rc_databases(2012:2019)
all_rc <- many_rc

# rc_2003 <- get_one_rc_database(2003)
# rc_2004 <- get_one_rc_database(2004)
rc_2016 <- get_one_rc_database(2016)
rc_2017 <- get_one_rc_database(2017)
rc_2018 <- get_one_rc_database(2018)

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