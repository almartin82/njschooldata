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

test_that("ward_parcc_aggs correctly aggregates newark parcc data by ward" , {
   parcc_ela_8_2019 %>%
      ward_parcc_aggs() %>%
      testthat::expect_is('data.frame')
})

test_that("ground truth values for parcc ward aggregations", {
   parcc_ela8_19_ward <- parcc_ela_8_2019 %>%
      ward_parcc_aggs()
   
   expect_equal(parcc_ela8_19_ward %>%
                   filter(subgroup == "special_education",
                          district_name == "Newark City CENTRAL") %>%
                   pull(number_of_valid_scale_scores),
                54)
   
   expect_equal(parcc_ela8_19_ward %>%
                   filter(subgroup == "asian",
                          district_name == "Newark City NORTH") %>%
                   pull(n_schools),
                2)
   
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
      expect_is('data.frame')
})