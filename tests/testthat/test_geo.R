context("functions in geo.R")

enr_2019 <- fetch_enr(2019, tidy=TRUE)

test_that("enrich geo functions cover all newark schools", {
  enr_all <- map_df(
    c(1999:2019),
    ~fetch_enr(end_year=.x, tidy=TRUE)
  ) 
  
  nwk_no_geocode <- enr_all %>%
    filter(district_id == '3570', is_school) %>%
    enrich_school_latlong %>%
    select(end_year, school_id, school_name, address, lat, lng) %>%
    unique %>%
    filter(is.na(lat)) %>%
    nrow
  
  expect_equal(nwk_no_geocode, 0)
})

test_that("enrich_school_latlong gets all newark schools w/ address 2019", {
  nwk_19 <- enr_2019 %>%
    filter(district_id == '3570') %>%
    enrich_school_latlong %>%
    select(school_id, school_name, address, lat, lng) %>%
    unique
    
    expect_equal(sum(is.na(nwk_19$address)),
                 sum(is.na(nwk_19$lat)))
    
    nwk_19_ward <- enr_2019 %>%
      filter(district_id == '3570') %>%
      enrich_school_latlong %>%
      enrich_school_city_ward %>%
      select(school_id, school_name, address, lat, lng, ward) %>%
      unique
    
    expect_equal(sum(is.na(nwk_19_ward$address)),
                 sum(is.na(nwk_19_ward$ward)))
}) 


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
                   pull(schools) %>%
                   str_count(","), # one comma = two schools; 
                1)
   
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
   
      expect_is(gr9_11_2018_mat, 'data.frame')
})



# GRAD RATE
grate_2019 <- fetch_grad_rate(2019)
grate_2018_5y <- fetch_grad_rate(2018, '5 year')

test_that("aggregates correctly newark grad rate data by ward" , {
   grate_2019 %>%
      ward_grate_aggs() %>%
      testthat::expect_is('data.frame')
   
   grate_2018_5y %>%
      ward_grate_aggs() %>%
      testthat::expect_is('data.frame')
})


test_that("ground truth values for grate ward aggregations", {
   grate_19_ward <- grate_2019 %>%
      ward_grate_aggs()
   
   expect_equal(grate_19_ward %>%
                   filter(district_id == "3570 SOUTH",
                          subgroup == "total population") %>%
                   pull(graduated_count),
                384)
   
   expect_equal(grate_19_ward %>%
                   filter(district_id == "3570 EAST",
                          subgroup == "limited english proficiency") %>%
                   pull(grad_rate),
                .827)
   
   expect_equal(grate_19_ward %>%
                   filter(district_id == "3570 WEST",
                          subgroup == "white") %>%
                   pull(grad_rate),
                NA_real_)
})



### GRAD COUNT
gcount_2019 <- fetch_grad_count(2019)

test_that("aggregates correctly newark grad count data by ward" , {
   gcount_2019 %>%
      ward_gcount_aggs() %>%
      testthat::expect_is('data.frame')
})

test_that("ground truth values for gcount ward aggregations", {
   gcount_19_ward <- gcount_2019 %>%
      ward_gcount_aggs()
   
   expect_equal(gcount_19_ward %>%
                   filter(district_id == "3570 CENTRAL",
                          subgroup == "total population") %>%
                   pull(graduated_count),
                1100)
   
   expect_equal(gcount_19_ward %>%
                   filter(district_id == "3570 EAST",
                          subgroup == "limited english proficiency") %>%
                   pull(cohort_count),
                139)
   
   expect_equal(gcount_19_ward %>%
                   filter(district_id == "3570 WEST",
                          subgroup == "white") %>%
                   pull(cohort_count),
                0)
})


### postsecondary matriculation
matric_19 <- 2019 %>%
  get_one_rc_database() %>%
  list() %>%
  extract_rc_college_matric() %>%
  enrich_matric_counts()

test_that("aggregates correctly newark postsec matric data by ward" , {
  matric_19 %>%
    ward_matric_aggs() %>%
    testthat::expect_is('data.frame')
})

test_that("ground truth values for gcount ward aggregations", {
  matric_19_ward <- matric_19 %>%
    ward_matric_aggs()
  
  expect_equal(matric_19_ward %>%
                 filter(district_id == "3570 SOUTH",
                        subgroup == "total population") %>%
                 pull(enroll_any),
               50.3)
  
  # some discrepancy here -- reason for concern?
  expect_lte(matric_19_ward %>%
                 filter(district_id == "3570 EAST",
                        subgroup == "limited english proficiency") %>%
                 pull(enroll_4yr) - 20.7,
               1)
  
  expect_equal(matric_19_ward %>%
                 filter(district_id == "3570 WEST",
                        subgroup == "white") %>%
                 pull(enroll_2yr_count),
               numeric(0))
})


