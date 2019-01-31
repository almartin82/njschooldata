context("functions in enr")

#post-NJSMART
test_that("get_raw_enr correctly grabs the 2015 enrollment file", {
  ex_2015 <- get_raw_enr(2015)

  expect_equal(nrow(ex_2015), 26223)
  expect_equal(ncol(ex_2015), 28)
  expect_equal(sum(ex_2015$ROW_TOTAL, na.rm = TRUE), 10954804)
})


test_that("get_raw_enr correctly grabs the 2011 enrollment file", {
  ex_2011 <- get_raw_enr(2011)

  expect_equal(nrow(ex_2011), 25891)
  expect_equal(ncol(ex_2011), 27)
  expect_equal(sum(ex_2011$ROW_TOTAL, na.rm = TRUE), 10871910)
})


#pre-NJSMART
test_that("get_raw_enr correctly grabs the 2010 enrollment file", {
  ex_2010 <- get_raw_enr(2010)

  expect_equal(nrow(ex_2010), 29599)
  expect_equal(ncol(ex_2010), 29)
  expect_equal(sum(ex_2010$ROW_TOTAL, na.rm = TRUE), 11084504)
})


test_that("get_raw_enr correctly grabs the 2001 enrollment file", {
  ex_2001 <- get_raw_enr(2001)

  expect_equal(nrow(ex_2001), 28447)
  expect_equal(ncol(ex_2001), 20)
  expect_equal(sum(ex_2001$ROWTOTAL, na.rm = TRUE), 10522596)
})


test_that("fetch_enr correctly grabs the 2012 enrollment file", {
  fetch_2009 <- fetch_enr(2009)

  expect_equal(nrow(fetch_2009), 29491)
  expect_equal(ncol(fetch_2009), 29)
  expect_equal(sum(as.numeric(fetch_2009$row_total), na.rm = TRUE), 11034082)
})


test_that("fetch_enr handles the 2016-17 enrollment file", {
  fetch_2017 <- fetch_enr(2017)

  expect_equal(nrow(fetch_2009), 26470)
  expect_equal(ncol(fetch_2009), 26)
})


test_that("fetch_enr handles the 2017-18 enrollment file", {
  fetch_2018 <- fetch_enr(2018)

  expect_is(fetch_2018, 'data.frame')
  expect_equal(nrow(fetch_2009), 26470)
  expect_equal(ncol(fetch_2009), 26)
})


test_that("all enrollment data can be pulled", {
  enr_all <- map_df(
    c(1999:2018),
    fetch_enr
  )

  expect_is(enr_all, 'data.frame')
  expect_equal(nrow(enr_all), 558627)
  expect_equal(ncol(enr_all), 33)
})


test_that("enr aggs correctly calculates known 2018 data", {
  ex_2018 <- get_raw_enr(2018) %>%
    clean_enr_names() %>%
    split_enr_cols() %>%
    clean_enr_data() %>%
    enr_aggs()
  
  attales <- ex_2018 %>% filter(CDS_Code == '010010050') 
  
  expect_equal(attales[attales$grade_level == '05', ]$row_total, 91)
  expect_equal(attales[attales$grade_level == '06', ]$row_total, 93)
  expect_equal(attales[attales$grade_level == '07', ]$row_total, 82)
  expect_equal(attales[attales$grade_level == '08', ]$row_total, 107)
  
  expect_equal(attales[attales$program_code == 'UG', ]$row_total, 8)
  expect_equal(attales[attales$program_code == '55', ]$row_total, 381)
  
  # new gender aggs
  expect_equal(attales[attales$program_code == '05', ]$male, 43)
  expect_equal(attales[attales$program_code == '05', ]$female, 48)
  
  # new race aggs
  expect_equal(attales[attales$program_code == '05', ]$white, 51)
  expect_equal(attales[attales$program_code == '05', ]$black, 19)
  expect_equal(attales[attales$program_code == '05', ]$hispanic, 11)
  expect_equal(attales[attales$program_code == '05', ]$asian, 6)
  expect_equal(attales[attales$program_code == '05', ]$native_american, 0)
  expect_equal(attales[attales$program_code == '05', ]$pacific_islander, 0)
  expect_equal(attales[attales$program_code == '05', ]$multiracial, 4)
})


test_that("fetch_enr works with tidy=TRUE argument", {
  enr_2018_tidy <- fetch_enr(2018, tidy=TRUE)
  expect_is(enr_2018_tidy, 'data.frame')
  # sample_n(enr_2018_tidy, 10) %>% print.AsIs()
})