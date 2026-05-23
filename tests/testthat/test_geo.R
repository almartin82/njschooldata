
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
  
  
  nwk_no_ward <- enr_all %>%
    filter(district_id == '3570', is_school) %>%
    enrich_school_latlong %>%
    enrich_school_city_ward %>%
    select(school_id, school_name, address, lat, lng, ward) %>%
    unique() %>%
    filter(is.na(ward)) %>%
    nrow
  
  expect_equal(nwk_no_ward, 0)
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
  testthat::expect_s3_class(enr_2019_enriched, 'data.frame')
})


test_that("ward_enr_aggs correctly aggregates newark enrollment data by ward", {
  enr_2019_wards <- ward_enr_aggs(enr_2019)
  testthat::expect_s3_class(enr_2019_wards, 'data.frame')
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
   
      expect_s3_class(gr9_11_2018_mat, 'data.frame')
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


# LIVE smoke test: the tidygeocoder cascade used by enrich_school_latlong()
# (use_cache = FALSE) returns real coordinates for a known NJ address. This
# hits a live geocoding service, so it is skipped on CRAN and when offline.
test_that("tidygeocoder cascade geocodes a known NJ address to plausible coords", {
  skip_on_cran()
  skip_if_offline()
  skip_if_not_installed("tidygeocoder")

  # NJ DOE building: 100 Riverview Plaza, Trenton, NJ 08625
  geo <- tidygeocoder::geo_combine(
    queries = list(list(method = "census"), list(method = "osm")),
    global_params = list(address = "address"),
    address = "100 Riverview Plaza, Trenton, NJ 08625 USA",
    lat = "lat",
    long = "long"
  )

  expect_true(all(c("address", "lat", "long") %in% names(geo)))
  expect_equal(nrow(geo), 1)
  # Plausible NJ bounding box: lat ~38.9-41.4, lng ~ -75.6 to -73.9
  expect_true(!is.na(geo$lat) && geo$lat >= 38.9 && geo$lat <= 41.4)
  expect_true(!is.na(geo$long) && geo$long >= -75.6 && geo$long <= -73.9)
})


