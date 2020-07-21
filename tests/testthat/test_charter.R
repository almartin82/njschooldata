context("functions in charter.R")

test_that("id_charter_hosts correctly handles enrollment data", {
  
  enr_2017 <- fetch_enr(2017)
  enr_2017_host <- id_charter_hosts(enr_2017)
  expect_is(enr_2017_host, "data.frame")
  expect_equal(nrow(enr_2017), nrow(enr_2017_host))
})


test_that("id_charter_hosts finds host cities for all charters, 2018 enr", {
  
  enr_2018 <- fetch_enr(2018, tidy=TRUE)

  # look at all county = charters and make sure that none have null host_district_id
  charter_enr_2018 <- enr_2018 %>% 
    filter(county_id == '80' & !district_id=='9999')
  charter_enr_2018_host <- id_charter_hosts(charter_enr_2018)
  
  expect_equal(nrow(charter_enr_2018), nrow(charter_enr_2018_host))
  expect_is(charter_enr_2018_host, "data.frame")
  expect_equal(charter_enr_2018_host$host_district_id %>% is.na() %>% sum(), 0)
})


test_that("id_charter_hosts finds host cities for all charters, 2017 enr", {
  
  enr_2017 <- fetch_enr(2017)
  
  # look at all county = charters and make sure that none have null host_district_id
  charter_enr_2017 <- enr_2017 %>% 
    filter(county_id == '80' & !district_id=='9999')
  charter_enr_2017_host <- id_charter_hosts(charter_enr_2017)
  
  expect_equal(nrow(charter_enr_2017), nrow(charter_enr_2017_host))
  expect_is(charter_enr_2017_host, "data.frame")
  expect_equal(charter_enr_2017_host$host_district_id %>% is.na() %>% sum(), 0)
})


test_that("id_charter_hosts finds host cities for all charters, 2016 enr", {
  
  enr_2016 <- fetch_enr(2016)
  
  # look at all county = charters and make sure that none have null host_district_id
  charter_enr_2016 <- enr_2016 %>% 
    filter(county_id == '80' & !district_id=='9999')
  charter_enr_2016_host <- id_charter_hosts(charter_enr_2016)
  
  expect_equal(nrow(charter_enr_2016), nrow(charter_enr_2016_host))
  expect_is(charter_enr_2016_host, "data.frame")
  expect_equal(charter_enr_2016_host$host_district_id %>% is.na() %>% sum(), 0)
})


test_that("id_charter_hosts, 2018 parcc math 3", {
  
  parcc_math3_18 <- fetch_parcc(end_year = 2018, grade = 3, subj = 'math')
  
  # look at all county = charters and make sure that none have null host_district_id
  charter_parcc_math3_18 <- parcc_math3_18 %>% 
    filter(county_id=='80' & !district_id=='9999')
  charter_parcc_math3_18_host <- id_charter_hosts(charter_parcc_math3_18)
  
  expect_equal(nrow(charter_parcc_math3_18), nrow(charter_parcc_math3_18_host))
  expect_is(charter_parcc_math3_18_host, "data.frame")
  expect_equal(charter_parcc_math3_18_host$host_district_id %>% is.na() %>% sum(), 0)
})


test_that("id_charter_hosts, 2018 parcc ela 5", {
  
  parcc_ela5_18 <- fetch_parcc(end_year = 2018, grade = 5, subj = 'ela')
  
  # look at all county = charters and make sure that none have null host_district_id
  charter_parcc_ela5_18 <- parcc_ela5_18 %>% 
    filter(county_id == '80' & !district_id=='9999')
  charter_parcc_ela5_18_host <- id_charter_hosts(charter_parcc_ela5_18)
  
  expect_equal(nrow(charter_parcc_ela5_18), nrow(charter_parcc_ela5_18_host))
  expect_is(charter_parcc_ela5_18_host, "data.frame")
  expect_equal(charter_parcc_ela5_18_host$host_district_id %>% is.na() %>% sum(), 0)
})


test_that("id_charter_hosts, 2018 parcc ALG1 math", {
  
  parcc_alg1_18 <- fetch_parcc(end_year = 2018, grade = 'ALG1', subj = 'math')
  
  # look at all county = charters and make sure that none have null host_district_id
  charter_parcc_alg1_18 <- parcc_alg1_18 %>% 
    filter(county_id == '80' & !district_id=='9999')
  charter_parcc_alg1_18_host <- id_charter_hosts(charter_parcc_alg1_18)
  
  expect_equal(nrow(charter_parcc_alg1_18), nrow(charter_parcc_alg1_18_host))
  expect_is(charter_parcc_alg1_18_host, "data.frame")
  expect_equal(charter_parcc_alg1_18_host$host_district_id %>% is.na() %>% sum(), 0)
})

# charter enrollment aggs
test_that("charter sector aggs, 2018 enrollment data", {
  
  enr_2018 <- fetch_enr(2018, tidy=TRUE)
  ch_aggs_2018 <- charter_sector_enr_aggs(enr_2018)
  expect_is(ch_aggs_2018, "data.frame")
  expect_equal(nrow(ch_aggs_2018), 8420)
})


test_that("charter sector aggs, 2017-18 enrollment data", {
  
  enr_1718 <- map_df(c(2017:2018),~fetch_enr(.x, tidy=TRUE))
  ch_aggs_1718 <- charter_sector_enr_aggs(enr_1718)
  expect_is(ch_aggs_1718, "data.frame")
  expect_equal(nrow(ch_aggs_1718), 16500)
})

test_that("charter sector aggs, ALL enrollment data", {
  enr_years <- c(1999:2018)
  enr_df <- map_df(enr_years, ~fetch_enr(.x, tidy=TRUE))
  ch_aggs_ <- charter_sector_enr_aggs(enr_df)
  expect_is(enr_df, 'data.frame')
})


test_that("all public aggs, 2017-18 enrollment data", {
  
  enr_1718 <- map_df(c(2017:2018), ~fetch_enr(.x, tidy=TRUE))
  all_public_aggs_1718 <- allpublic_enr_aggs(enr_1718)
  expect_is(all_public_aggs_1718 , "data.frame")
  expect_equal(nrow(all_public_aggs_1718), 16500)
})


# charter PARCC aggs
test_that("charter sector parcc aggs, 2018", {
  
  p_math4_2018 <- fetch_parcc(2018, 4, 'math', TRUE)
  ch_aggs_math4_2018 <- charter_sector_parcc_aggs(p_math4_2018)
  expect_is(ch_aggs_math4_2018, "data.frame")
  expect_equal(nrow(ch_aggs_math4_2018), 339)
})

test_that("allpublic parcc aggs, 2018", {
  
  p_math4_2018 <- fetch_parcc(2018, 4, 'math', TRUE)
  allpublic_aggs_math4_2018 <- allpublic_parcc_aggs(p_math4_2018)
  expect_is(allpublic_aggs_math4_2018, "data.frame")
  expect_equal(nrow(allpublic_aggs_math4_2018), 339)
})


test_that("charter sector grate aggs, 2018", {
  
  grate_2018 <- fetch_grad_rate(2018)
  ch_aggs_grate_2018 <- charter_sector_grate_aggs(grate_2018)
  expect_is(ch_aggs_grate_2018, "data.frame")
  
  expect_equal(nrow(ch_aggs_grate_2018), 180)
})


test_that("allpublic grate aggs, 2018", {
  grate_2018 <- fetch_grad_rate(2018)
  allpublic_aggs_grate_2018 <- allpublic_grate_aggs(grate_2018)
  expect_is(allpublic_aggs_grate_2018, "data.frame")
  
  expect_equal(nrow(allpublic_aggs_grate_2018), 180)
})


test_that("charter sector gcount aggs, 2018", {
  
  gcount_2018 <- fetch_grad_count(2018)
  ch_aggs_gcount_2018 <- charter_sector_gcount_aggs(gcount_2018)
  expect_is(ch_aggs_gcount_2018, "data.frame")
  
  expect_equal(nrow(ch_aggs_gcount_2018), 180)
})


test_that("allpublic gcount aggs, 2018", {
  gcount_2018 <- fetch_grad_count(2018)
  allpublic_aggs_gcount_2018 <- allpublic_gcount_aggs(gcount_2018)
  expect_is(allpublic_aggs_gcount_2018, "data.frame")
  
  expect_equal(nrow(allpublic_aggs_gcount_2018), 180)
})

test_that("special populations data is enriched w/ enrollment, 2018", {
  sp_18_enr <- fetch_reportcard_special_pop(2018) %>%
    enrich_rc_enrollment()
  
  expect_equal(sp_18_enr %>%
                 filter(district_id == '3570',
                        school_id == '220',
                        subgroup == 'Economically Disadvantaged') %>%
                 pull(n_students),
               428)
})

test_that("charter sector special populations aggregates, 2017", {
  sp_17 <- fetch_reportcard_special_pop(2017)
  
  sp_charter_17 <- charter_sector_spec_pop_aggs(sp_17)
  
  expect_is(sp_charter_17,
            "data.frame")
  
  expect_equal(sp_charter_17 %>%
                 filter(subgroup == "Economically Disadvantaged",
                        district_id == "0110C") %>%
                 pull(percent),
               97.2)
})


test_that("all public special populations aggregates, 2017", {
  sp_17 <- fetch_reportcard_special_pop(2017)
  
  sp_allpub_17 <- allpublic_spec_pop_aggs(sp_17)
  
  expect_is(sp_allpub_17,
            "data.frame")
  
  expect_equal(sp_allpub_17 %>%
                 filter(subgroup == "Female",
                        district_id == "0110A") %>%
                 pull(percent),
               49.3)
})

