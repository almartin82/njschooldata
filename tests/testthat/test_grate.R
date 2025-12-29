
grad_rate_cols <- c(
  "end_year",
  "county_id", "county_name",
  "district_id", "district_name",
  "school_id", "school_name",
  "subgroup",
  "grad_rate",
  "cohort_count", "graduated_count",
  "methodology",
  "is_state", "is_county", "is_district", "is_school",
  "is_charter", "is_charter_sector", "is_allpublic"
)


## 4 year
test_that('fetch_grad_rate works with 4 year', {
   ex0 <- fetch_grad_rate(2012, '4 year')
   ex1 <- fetch_grad_rate(2013, '4 year')
   ex2 <- fetch_grad_rate(2014, '4 year')
   ex3 <- fetch_grad_rate(2015, '4 year')
   ex4 <- fetch_grad_rate(2016, '4 year')
   ex5 <- fetch_grad_rate(2017, '4 year')
   ex6 <- fetch_grad_rate(2018, '4 year')
   ex7 <- fetch_grad_rate(2019, '4 year')
   ex8 <- fetch_grad_rate(2020, '4 year')

   expect_s3_class(ex0, 'data.frame')
   expect_s3_class(ex1, 'data.frame')
   expect_s3_class(ex2, 'data.frame')
   expect_s3_class(ex3, 'data.frame')
   expect_s3_class(ex4, 'data.frame')
   expect_s3_class(ex5, 'data.frame')
   expect_s3_class(ex6, 'data.frame')
   expect_s3_class(ex7, 'data.frame')
   expect_s3_class(ex8, 'data.frame')
})

test_that('fetch_grad_rate all years', {

   expect_error(fetch_grad_rate(2010))
   expect_error(fetch_grad_rate(2011))
   #grr12 <- fetch_grad_rate(2011)
   grr13 <- fetch_grad_rate(2012)
   grr14 <- fetch_grad_rate(2013)
   grr15 <- fetch_grad_rate(2014)
   grr16 <- fetch_grad_rate(2015)
   grr17 <- fetch_grad_rate(2016)
   grr18 <- fetch_grad_rate(2017)
   grr19 <- fetch_grad_rate(2018)
   grr20 <- fetch_grad_rate(2019)
   grr20 <- fetch_grad_rate(2020)
   grr21 <- fetch_grad_rate(2021)
   grr22 <- fetch_grad_rate(2022)
   grr23 <- fetch_grad_rate(2023)
   grr24 <- fetch_grad_rate(2024)
   expect_error(fetch_grad_rate(2025))

})

test_that('fetch grate works with 2015 data', {
  ex <- fetch_grad_rate(2015)
  expect_s3_class(ex, 'data.frame')
  expect_equal(sum(ex$graduated_count, na.rm = TRUE), 674621)
  expect_equal(names(ex), grad_rate_cols)
})


test_that('fetch grate works with 2018 data', {
  ex <- fetch_grad_rate(2018)
  expect_s3_class(ex, 'data.frame')
  expect_equal(sum(ex$graduated_count, na.rm = TRUE), 996902)
  expect_equal(names(ex), grad_rate_cols)
})

test_that("ground truth values on 2019 grate", {
   ex <- fetch_grad_rate(2019)
   expect_s3_class(ex, "data.frame")
   expect_equal(names(ex), grad_rate_cols)

   expect_equal(filter(ex,
                       district_id == '3570',
                       school_id == '030',
                       subgroup == 'black') %>%
                   pull(grad_rate), .744)

   expect_equal(filter(ex,
                       district_id == '3570',
                       school_id == '030',
                       subgroup == 'white') %>%
                   pull(grad_rate), NA_real_)

   expect_equal(filter(ex,
                       district_id == '3570',
                       school_id == '030',
                       subgroup == 'students with disability') %>%
                   pull(grad_rate), .594)
})


test_that("ground truth values on 2020 grate", {
  ex <- fetch_grad_rate(2020)
  expect_s3_class(ex, "data.frame")
  expect_equal(names(ex), grad_rate_cols)

  expect_equal(filter(ex,
                      district_id == '3570',
                      school_id == '030',
                      subgroup == 'black') %>%
                 pull(grad_rate), 0.754)

  expect_equal(filter(ex,
                      district_id == '3570',
                      school_id == '030',
                      subgroup == 'white') %>%
                 pull(grad_rate), NA_real_)

  expect_equal(filter(ex,
                      district_id == '3570',
                      school_id == '030',
                      subgroup == 'students with disability') %>%
                 pull(grad_rate), 0.672)
})


## 5 year
test_that('five year window is in more recent data', {
   ex <- fetch_grad_rate(2017, '5 year')
   expect_s3_class(ex, 'data.frame')
   expect_equal(names(ex), grad_rate_cols)
})


test_that('get_raw_grate works with 5 year', {
  ex0 <- get_grad_rate(2012, '5 year')
  ex1 <- get_grad_rate(2013, '5 year')
  ex2 <- get_grad_rate(2014, '5 year')
  ex3 <- get_grad_rate(2015, '5 year')
  ex4 <- get_grad_rate(2016, '5 year')
  ex5 <- get_grad_rate(2017, '5 year')
  ex6 <- get_grad_rate(2018, '5 year')
  ex7 <- get_grad_rate(2019, '5 year')

  expect_s3_class(ex0, 'data.frame')
  expect_s3_class(ex1, 'data.frame')
  expect_s3_class(ex2, 'data.frame')
  expect_s3_class(ex3, 'data.frame')
  expect_s3_class(ex4, 'data.frame')
  expect_s3_class(ex5, 'data.frame')
  expect_s3_class(ex6, 'data.frame')
})


test_that('fetch_grad_rate works with 5 year', {
  ex0 <- fetch_grad_rate(2012, '5 year')
  ex1 <- fetch_grad_rate(2013, '5 year')
  ex2 <- fetch_grad_rate(2014, '5 year')
  ex3 <- fetch_grad_rate(2015, '5 year')
  ex4 <- fetch_grad_rate(2016, '5 year')
  ex5 <- fetch_grad_rate(2017, '5 year')
  ex6 <- fetch_grad_rate(2018, '5 year')

  expect_s3_class(ex0, 'data.frame')
  expect_s3_class(ex1, 'data.frame')
  expect_s3_class(ex2, 'data.frame')
  expect_s3_class(ex3, 'data.frame')
  expect_s3_class(ex4, 'data.frame')
  expect_s3_class(ex5, 'data.frame')
  expect_s3_class(ex6, 'data.frame')
})


test_that("ground truth values on 2018 5y grate", {
   ex <- fetch_grad_rate(2018, '5 year')
   expect_s3_class(ex, "data.frame")

   expect_equal(filter(ex,
                       district_id == '3570',
                       school_id == '888') %>%
                   pull(grad_rate), .765)

   expect_equal(filter(ex,
                       district_id == '3570',
                       school_id == '030') %>%
                   pull(grad_rate), .798)

   expect_equal(filter(ex,
                       district_id == '3570',
                       school_id == '307') %>%
                   pull(grad_rate), NA_real_)
})




# grad count
test_that('fetch_grad_count all years', {
  # it doesn't look like 2011 file has any counts in the raw file
  # to pull out
  expect_error(fetch_grad_count(2011))
  gr13 <- fetch_grad_count(2012)
  gr14 <- fetch_grad_count(2013)
  gr15 <- fetch_grad_count(2014)
  gr16 <- fetch_grad_count(2015)
  gr17 <- fetch_grad_count(2016)
  gr18 <- fetch_grad_count(2017)
  gr19 <- fetch_grad_count(2018)
  gr20 <- fetch_grad_count(2019)
  gr21 <- fetch_grad_count(2020)
  gr22 <- fetch_grad_count(2021)
  gr23 <- fetch_grad_count(2022)
  gr24 <- fetch_grad_count(2023)
  gr25 <- fetch_grad_count(2024)
  expect_error(fetch_grad_count(2025))
})

test_that("ground truth values on 2019 grad count", {
   ex <- fetch_grad_count(2019)
   expect_s3_class(ex, "data.frame")

   expect_equal(filter(ex,
                       district_id == '3570',
                       school_id == '999',
                       subgroup == "female") %>%
                   pull(graduated_count), 1085)

   expect_equal(filter(ex,
                       district_id == '3570',
                       school_id == '030',
                       subgroup == "economically disadvantaged") %>%
                   pull(cohort_count), 179)

   expect_equal(filter(ex,
                       district_id == '3570',
                       school_id == '307',
                       subgroup == "white") %>%
                   pull(cohort_count), NA_real_)
})


test_that("grad counts correctly enriched", {
  grate_19 <- fetch_grad_rate(2019)

  ex <- enrich_grad_count(grate_19, 2019)

  ex_row <- ex %>%
    filter(district_id == '3570',
           school_id == '055',
           subgroup == 'total population')

  expect_equal(pull(ex_row, graduated_count.x),
               pull(ex_row, graduated_count.y))
  })


test_that("2020-2024 graduation data includes cohort counts", {
  # 2020 was previously missing counts but NJ DOE updated file format
  grate_2024 <- fetch_grad_rate(2024)

  # Check that cohort_count and graduated_count are populated
  non_na_cohort <- sum(!is.na(grate_2024$cohort_count))
  expect_gt(non_na_cohort, 5000)  # Should have >5000 non-NA values

  non_na_graduated <- sum(!is.na(grate_2024$graduated_count))
  expect_gt(non_na_graduated, 5000)
})


test_that("charter sector aggregation works for 2020-2024", {
  grate_2024 <- fetch_grad_rate(2024)

  # Test charter sector aggs
  sector <- charter_sector_grate_aggs(grate_2024)

  # Newark should be present
  newark_sector <- sector %>%
    filter(district_id == "3570C", subgroup == "total")

  expect_equal(nrow(newark_sector), 1)
  expect_true(!is.na(newark_sector$grad_rate))
  expect_true(newark_sector$cohort_count > 0)
  expect_true(newark_sector$is_charter_sector)
})


test_that("allpublic aggregation works for 2020-2024", {
  grate_2024 <- fetch_grad_rate(2024)

  # Test allpublic aggs
  allpublic <- allpublic_grate_aggs(grate_2024)

  # Newark should be present
  newark_all <- allpublic %>%
    filter(district_id == "3570A", subgroup == "total")

  expect_equal(nrow(newark_all), 1)
  expect_true(!is.na(newark_all$grad_rate))
  expect_true(newark_all$cohort_count > 0)
  expect_true(newark_all$is_allpublic)

  # All public should have more students than charter sector only
  sector <- charter_sector_grate_aggs(grate_2024)
  newark_sector <- sector %>% filter(district_id == "3570C", subgroup == "total")
  expect_gt(newark_all$cohort_count, newark_sector$cohort_count)
})


# =============================================================================
# 6-Year Graduation Rate Tests
# =============================================================================

grad_rate_6yr_cols <- c(
  "end_year",
  "county_id", "county_name",
  "district_id", "district_name",
  "school_id", "school_name",
  "subgroup",
  "grad_rate_6yr", "continuing_rate", "non_continuing_rate", "persistence_rate",
  "methodology",
  "is_state", "is_county", "is_district", "is_school",
  "is_charter", "is_charter_sector", "is_allpublic"
)

test_that("fetch_6yr_grad_rate works for all valid years", {
  # 6-year data is available 2021-2024
  ex21 <- fetch_6yr_grad_rate(2021)
  ex22 <- fetch_6yr_grad_rate(2022)
  ex23 <- fetch_6yr_grad_rate(2023)
  ex24 <- fetch_6yr_grad_rate(2024)

  expect_s3_class(ex21, "data.frame")
  expect_s3_class(ex22, "data.frame")
  expect_s3_class(ex23, "data.frame")
  expect_s3_class(ex24, "data.frame")

  expect_equal(names(ex24), grad_rate_6yr_cols)
})

test_that("fetch_6yr_grad_rate returns error for invalid years", {
  expect_error(fetch_6yr_grad_rate(2020),
               "6-year graduation rate data is available for years: 2021, 2022, 2023, 2024")
  expect_error(fetch_6yr_grad_rate(2019))
  expect_error(fetch_6yr_grad_rate(2025))
})

test_that("fetch_6yr_grad_rate works with school level", {
  ex <- fetch_6yr_grad_rate(2024, level = "school")

  expect_s3_class(ex, "data.frame")
  expect_equal(names(ex), grad_rate_6yr_cols)
  expect_true(any(ex$is_school))

  # School file should have actual school names
  school_rows <- ex %>% filter(is_school)
  expect_true(all(school_rows$school_name != "District Total"))
})

test_that("fetch_6yr_grad_rate works with district level", {
  ex <- fetch_6yr_grad_rate(2024, level = "district")

  expect_s3_class(ex, "data.frame")
  expect_equal(names(ex), grad_rate_6yr_cols)

  # All rows should be district-level
  expect_true(all(ex$school_id == "999"))
  expect_true(all(ex$is_district | ex$is_state | ex$is_county))
})

test_that("ground truth values for 6-year 2024 school data", {
  ex <- fetch_6yr_grad_rate(2024, level = "school")

  # Atlantic City High School - Schoolwide (from sample data we tested)
  atlantic_city <- ex %>%
    filter(district_name == "Atlantic City School District",
           school_name == "Atlantic City High School",
           subgroup == "total population")

  expect_equal(nrow(atlantic_city), 1)
  expect_equal(atlantic_city$grad_rate_6yr, 79.4)
  # persistence_rate is only available in 2024+
  expect_equal(atlantic_city$persistence_rate, 80.3)
})

test_that("6-year 2021-2023 data has NA persistence_rate", {
  # persistence_rate column was added in 2024
  ex <- fetch_6yr_grad_rate(2023)
  expect_true(all(is.na(ex$persistence_rate)))
})

test_that("6-year graduation subgroups are cleaned correctly", {
  ex <- fetch_6yr_grad_rate(2024)

  subgroups <- unique(ex$subgroup)

  # Check that standard names are used
  expect_true("total population" %in% subgroups)
  expect_true("black" %in% subgroups)
  expect_true("economically disadvantaged" %in% subgroups)
  expect_true("students with disability" %in% subgroups)

  # Check that original names are NOT present
  expect_false("Schoolwide" %in% subgroups)
  expect_false("Black or African American" %in% subgroups)
  expect_false("Economically Disadvantaged Students" %in% subgroups)
})

test_that("6-year graduation rate aggregation flags are correct", {
  ex <- fetch_6yr_grad_rate(2024, level = "school")

  # Schools should have is_school = TRUE
  school_rows <- ex %>% filter(!school_id %in% c("888", "997", "999"))
  expect_true(all(school_rows$is_school))
  expect_true(all(!school_rows$is_district))

  # Charter schools should be flagged
  charter_rows <- ex %>% filter(county_id == "80")
  expect_true(all(charter_rows$is_charter))
})

test_that("fetch_all_6yr_grad_rate returns combined data", {
  # This test can be slow, so just check structure
  ex <- fetch_all_6yr_grad_rate(level = "school")

  expect_s3_class(ex, "data.frame")
  expect_equal(names(ex), grad_rate_6yr_cols)

  # Should have data from multiple years
  years_present <- unique(ex$end_year)
  expect_true(length(years_present) >= 2)
  expect_true(all(years_present %in% c(2021, 2022, 2023, 2024)))
})
