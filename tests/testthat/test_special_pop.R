context("test special pop enr")

sp17 <- fetch_reportcard_special_pop(2017)
sp18 <- fetch_reportcard_special_pop(2018)


test_that("special pop works with 2017 data", {
  expect_is(sp17, 'tbl_df')
  expect_is(sp17, 'data.frame')
  expect_equal(
    names(sp17),
    c("county_id", 
      "district_id",
      "school_id", "school_name", 
      "end_year", 
      "subgroup", "percent",
      "is_district", "is_school"
    )
  )
})
