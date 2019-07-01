context("assessment peer percentiles")

test_that("parcc peer percentile works with 2017 math data", {
  p <- fetch_parcc(2017, 4, 'math', tidy = TRUE)
  
  p_sch <- p %>% filter(is_school)
  p_sch_ile <- assessment_peer_percentile(p_sch)
  
  expect_is(p_sch_ile, 'data.frame')
  expect_is(p_sch_ile, 'tbl_df')
  
  p_sch_ile %>%
    filter(subgroup == 'total_population') -> foo3
})