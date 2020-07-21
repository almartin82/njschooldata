context("test special pop enr")

sp16 <- fetch_reportcard_special_pop(2016)
sp17 <- fetch_reportcard_special_pop(2017)
sp18 <- fetch_reportcard_special_pop(2018)
sp19 <- fetch_reportcard_special_pop(2019)

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


test_that("special pop works with 2018 data", {
   expect_is(sp18, 'tbl_df')
   expect_is(sp18, 'data.frame')
   expect_equal(
      names(sp18),
      c("county_id", 
        "district_id",
        "school_id", "school_name", 
        "end_year", 
        "subgroup", "percent",
        "is_district", "is_school"
      )
   )
})


test_that("special pop works with 2019 data", {
   expect_is(sp19, 'tbl_df')
   expect_is(sp19, 'data.frame')
   expect_equal(
      names(sp19),
      c("county_id", 
        "district_id",
        "school_id", "school_name", 
        "end_year", 
        "subgroup", "percent",
        "is_district", "is_school"
      )
   )
})


test_that("ground truth value checks on 2018 special populations data", {
   newark_sp_18 <- sp18 %>%
      filter(district_id == '3570',
             school_id == '270',
             !is_district) 
   
   expect_is(newark_sp_18, 'data.frame')

   }
)


test_that("ground truth value checks on 2019 special populations data", {
   newark_sp_19 <- sp19 %>%
      filter(district_id == '3570',
             school_id == '270',
             !is_district) 
   
   expect_is(newark_sp_19, 'data.frame')
   
   expect_equal(newark_sp_19 %>% 
                   filter(subgroup == "Female") %>% 
                   pull(percent), 
                45.5)
   
   expect_equal(newark_sp_19 %>% 
                   filter(subgroup == "Male") %>% 
                   pull(percent), 
                54.5)
   
   expect_equal(newark_sp_19 %>% 
                   filter(subgroup == "Economically Disadvantaged") %>% 
                   pull(percent), 
                78.6)
   
   expect_equal(newark_sp_19 %>% 
                   filter(subgroup == "IEP") %>% 
                   pull(percent),
                29.2)
   
   expect_equal(newark_sp_19 %>% 
                   filter(subgroup == "Foster Care") %>% 
                   pull(percent), 
                1.3)
   
   expect_equal(newark_sp_19 %>% 
                   filter(subgroup == "Migrant") %>% 
                   pull(percent), 
                0)
   }
)


test_that("ground truth value checks on 2016 special populations data", {
   newark_sp_16 <- sp16 %>%
      filter(district_id == '3570',
             school_id == '270',
             !is_district) 
   
   expect_is(newark_sp_16, 'data.frame')
   
   expect_equal(newark_sp_16 %>% 
                   filter(subgroup == "IEP") %>% 
                   pull(percent), 
                27)
   
   expect_equal(newark_sp_16 %>% 
                   filter(subgroup == "Male") %>% 
                   pull(percent), 
                52)
   
   expect_equal(newark_sp_16 %>% 
                   filter(subgroup == "Economically Disadvantaged") %>% 
                   pull(percent), 
                81)
   
   expect_equal(newark_sp_16 %>% 
                   filter(subgroup == "Female") %>% 
                   pull(percent), 
                48)

})