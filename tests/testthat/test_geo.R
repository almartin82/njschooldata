context("functions in geo.R")

enr_2019 <- fetch_enr(2019, tidy=TRUE)

#post-NJSMART
test_that("ward_enr_aggs correctly labels newark 2018-19 enrollment data", {
  enr_2019_enriched <- enr_2019 %>%
    enrich_school_latlong %>%
    enrich_school_city_ward
  testthat::expect_is(enr_2019_enriched, 'data.frame')
})


test_that("ward_enr_aggs correctly aggregates newark enrollment data by ward", {
  enr_2019_wards <- ward_enr_aggs(enr_2019)
  testthat::expect_is(enr_2019_wards, 'data.frame')
})



# PARCC
parcc_ela_8_2019 <- fetch_parcc(end_year = 2019, grade_or_subj = 8,
                          subj = 'ela', tidy = T)

parcc_mat_6_2018 <- fetch_parcc(end_year = 2018, grade_or_subj = 6,
                                subj = 'math', tidy = T)

test_that("ward_parcc_aggs correctly aggregates newark parcc data by ward" , {
   parcc_ela_8_2019 %>%
      ward_parcc_aggs() %>%
      testthat::expect_is('data.frame')
})


test_that("ground truth values for parcc 2018 ward aggregations", {
   parcc_mat_6_2018_ward <- parcc_mat_6_2018 %>%
      ward_parcc_aggs()
   
   expect_equal(parcc_mat_6_2018_ward %>%
                   filter(district_id == "3570 CENTRAL",
                          subgroup == "black") %>%
                   pull(number_of_valid_scores),
               193)
   
   expect_equal(parcc_mat_6_2018_ward %>%
                   filter(district_name == "Newark City EAST",
                          subgroup == "lep_current_former") %>%
                   pull(num_l5),
               7)
   })

test_that("ground truth values for parcc 2019 ward aggregations", {
   parcc_ela8_19_ward <- parcc_ela_8_2019 %>%
      ward_parcc_aggs()

   expect_equal(parcc_ela8_19_ward %>%
                   filter(subgroup == "special_education",
                          district_name == "Newark City CENTRAL") %>%
                   pull(number_of_valid_scale_scores),
                54)

   expect_equal(parcc_ela8_19_ward %>%
                   filter(subgroup == "lep_current",
                          district_name == "Newark City EAST") %>%
                   pull(scale_score_mean) %>%
                   round(1),
                725.2)
})

test_that("grade aggregates work w/ ward aggregation", {
   gr9_11_2018_mat <- calculate_agg_parcc_prof(end_year = 2018,
                            subj = 'math',
                            gradespan = '9-11')
   
   gr9_11_2018_mat_ward <- gr9_11_2018_mat %>%
      ward_parcc_aggs() %>%
      bind_rows(gr9_11_2018_mat)

   # ward aggregate present
   expect_equal(sum(c("Newark City EAST", 
               "Garfield City") %in%
                gr9_11_2018_mat_ward$district_name), 
             2)
   
   # did not bind ward aggregates in calculate_agg_parcc_prof
   expect_equal(gr9_11_2018_mat_ward %>%
                   distinct(.keep_all = T) %>%
                   dim(),
                dim(gr9_11_2018_mat_ward))
})
