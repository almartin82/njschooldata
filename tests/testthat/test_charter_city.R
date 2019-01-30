context("functions in charter.R")

test_that("id_charter_hosts correctly handles enrollment data", {
  
  enr_2017 <- fetch_enr(2017)
  enr_2017_host <- id_charter_hosts(enr_2017)
  expect_is(enr_2017_host, "data.frame")
  expect_equal(nrow(enr_2017), nrow(enr_2017_host))
})


test_that("id_charter_hosts finds host cities for all charters", {
  
  enr_2018 <- fetch_enr(2018)

  # look at all county = charters and make sure that none have null host_district_id
  charter_enr_2018 <- enr_2018 %>% filter(county_id == '80')
  charter_enr_2018_host <- id_charter_hosts(charter_enr_2018)
  
  expect_equal(nrow(charter_enr_2018), nrow(charter_enr_2018_host))
  expect_is(enr_2018_host, "data.frame")
  expect_equal(charter_enr_2018_host$host_district_id %>% is.na() %>% sum(), 0)
  
  charter_enr_2018_host %>%
    filter(is.na(host_district_id))
  
  
  
})
