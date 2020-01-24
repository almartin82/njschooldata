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