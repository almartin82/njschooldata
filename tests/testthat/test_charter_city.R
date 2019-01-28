context("functions in charter.R")

test_that("id_charter_hosts correctly handles enrollment data", {
  
  enr_2017 <- fetch_enr(2017)
  enr_2017_host <- id_charter_hosts(enr_2017)
  expect_is(enr_2017_host, "data.frame")
  expect_equal(nrow(enr_2017_host), 1)
  
})
