context("report_card functions")

rc <- get_one_rc_database(2015)
many_rc <- get_rc_databases(2012:2017)
all_rc <- get_rc_databases(2003:2017)

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
})


test_that("extract_rc_college_matric pulls longitudinal matriculation data", {
  df <- extract_rc_college_matric(many_rc)
  expect_is(df, 'tbl_df')
})