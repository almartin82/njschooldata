# Tests for PARCC/NJSLA assessment data across all supported years
# Verifies URL patterns, state record normalization, and data processing

# ==============================================================================
# URL Pattern Tests - Verify each year's URL format works
# ==============================================================================

test_that("2015 PARCC URL pattern works (parcc subdirectory)", {
  # 2015 uses: /1415/parcc/ELA03.xlsx
  p <- fetch_parcc(2015, 3, "ela", tidy = TRUE)
  expect_s3_class(p, "data.frame")
  expect_gt(nrow(p), 20000)
})

test_that("2016-2018 PARCC URL pattern works (spring subdirectory)", {
  # 2016-2018 uses: /1617/spring/ELA03.xlsx
  p <- tryCatch(
    fetch_parcc(2017, 3, "ela", tidy = TRUE),
    error = function(e) {
      skip(paste("Network error fetching 2017 data:", e$message))
    }
  )
  expect_s3_class(p, "data.frame")
  expect_gt(nrow(p), 20000)
})

test_that("2019 NJSLA URL pattern works (spaces in filename)", {

  # 2019 uses: ELA03%20NJSLA%20DATA%202018-19.xlsx (spaces encoded)
  p <- fetch_parcc(2019, 3, "ela", tidy = TRUE)
  expect_s3_class(p, "data.frame")
  expect_gt(nrow(p), 20000)
})

test_that("2022 NJSLA URL pattern works (underscores in filename)", {
  # 2022 uses: ELA03_NJSLA_DATA_2021-22.xlsx (underscores)
  p <- fetch_parcc(2022, 3, "ela", tidy = TRUE)
  expect_s3_class(p, "data.frame")
  expect_gt(nrow(p), 20000)
})

test_that("2023 NJSLA URL pattern works", {
  p <- fetch_parcc(2023, 3, "ela", tidy = TRUE)
  expect_s3_class(p, "data.frame")
  expect_gt(nrow(p), 20000)
})

test_that("2024 NJSLA URL pattern works", {
  p <- fetch_parcc(2024, 3, "ela", tidy = TRUE)
  expect_s3_class(p, "data.frame")
  expect_gt(nrow(p), 20000)
})

# ==============================================================================
# State Record Normalization Tests
# Verify state records are normalized to county_id="99", district_id="9999"
# ==============================================================================

test_that("2015 PARCC state records normalized (raw uses 'STATE')", {
  # Raw data has county_code="STATE", should be normalized to "99"
  p <- fetch_parcc(2015, 3, "ela", tidy = TRUE)

  # State records should exist with county_id="99"
  state_rows <- p[p$county_id == "99", ]
  expect_gt(nrow(state_rows), 0)

  # Verify is_state flag is TRUE for these

  expect_true(all(state_rows$is_state))

  # State records should have district_id="9999" and school_id="999"
  expect_true(all(state_rows$district_id == "9999"))
  expect_true(all(state_rows$school_id == "999"))

  # Should have total_population subgroup
  expect_true("total_population" %in% state_rows$subgroup)
})

test_that("2019 NJSLA state records normalized (raw uses 'State')", {
  # Raw data has county_code="State" (title case), should be normalized to "99"
  p <- fetch_parcc(2019, 3, "ela", tidy = TRUE)

  state_rows <- p[p$county_id == "99", ]
  expect_gt(nrow(state_rows), 0)
  expect_true(all(state_rows$is_state))
  expect_true(all(state_rows$district_id == "9999"))
  expect_true(all(state_rows$school_id == "999"))
  expect_true("total_population" %in% state_rows$subgroup)
})

test_that("2022 NJSLA state records normalized", {
  p <- fetch_parcc(2022, 3, "ela", tidy = TRUE)

  state_rows <- p[p$county_id == "99", ]
  expect_gt(nrow(state_rows), 0)
  expect_true(all(state_rows$is_state))
  expect_true(all(state_rows$district_id == "9999"))
  expect_true(all(state_rows$school_id == "999"))
  expect_true("total_population" %in% state_rows$subgroup)
})

test_that("2024 NJSLA state records normalized", {
  p <- fetch_parcc(2024, 3, "ela", tidy = TRUE)

  state_rows <- p[p$county_id == "99", ]
  expect_gt(nrow(state_rows), 0)
  expect_true(all(state_rows$is_state))
  expect_true(all(state_rows$district_id == "9999"))
  expect_true(all(state_rows$school_id == "999"))
  expect_true("total_population" %in% state_rows$subgroup)
})

# ==============================================================================
# Proficiency Value Tests
# Verify state-level proficiency rates match expected values from raw data
# ==============================================================================

test_that("2015 state proficiency values match raw data", {
  # Raw data: L4=38.6, L5=4.9, Total=43.5
  p <- fetch_parcc(2015, 3, "ela", tidy = TRUE)
  state_total <- p[p$county_id == "99" & p$subgroup == "total_population", ]

  expect_equal(nrow(state_total), 1)
  expect_equal(state_total$pct_l4, 38.6)
  expect_equal(state_total$pct_l5, 4.9)
  expect_equal(state_total$proficient_above, 43.5)
})

test_that("2019 state proficiency values match raw data", {
  # Raw data: L4=42.8, L5=7.4, Total=50.2
  p <- fetch_parcc(2019, 3, "ela", tidy = TRUE)
  state_total <- p[p$county_id == "99" & p$subgroup == "total_population", ]

  expect_equal(nrow(state_total), 1)
  expect_equal(state_total$pct_l4, 42.8)
  expect_equal(state_total$pct_l5, 7.4)
  expect_equal(state_total$proficient_above, 50.2)
})

test_that("2022 state proficiency values match raw data", {
  # Raw data: L4=36.2, L5=6.2, Total=42.4
  p <- fetch_parcc(2022, 3, "ela", tidy = TRUE)
  state_total <- p[p$county_id == "99" & p$subgroup == "total_population", ]

  expect_equal(nrow(state_total), 1)
  expect_equal(state_total$pct_l4, 36.2)
  expect_equal(state_total$pct_l5, 6.2)
  expect_equal(state_total$proficient_above, 42.4)
})

test_that("2024 state proficiency values match raw data", {
  # Raw data: L4=37.2, L5=6.4, Total=43.6
  p <- fetch_parcc(2024, 3, "ela", tidy = TRUE)
  state_total <- p[p$county_id == "99" & p$subgroup == "total_population", ]

  expect_equal(nrow(state_total), 1)
  expect_equal(state_total$pct_l4, 37.2)
  expect_equal(state_total$pct_l5, 6.4)
  expect_equal(state_total$proficient_above, 43.6)
})

# ==============================================================================
# Garbage Row Filtering Tests
# Verify footer/note rows from Excel are filtered out
# ==============================================================================

test_that("garbage rows are filtered from 2015 data", {
  p <- fetch_parcc(2015, 3, "ela", tidy = TRUE)

  # Should not contain any rows with "suppressed" or "end of" in county_id
  garbage_rows <- grepl("suppressed|end of", p$county_id, ignore.case = TRUE)
  expect_equal(sum(garbage_rows), 0)

  # All county_ids should be valid codes (2-digit numbers or "DFG" for DFG aggregates)
  valid_county <- grepl("^[0-9]{2}$", p$county_id) | p$county_id == "DFG"
  expect_true(all(valid_county))
})

test_that("garbage rows are filtered from 2022 data", {
  p <- fetch_parcc(2022, 3, "ela", tidy = TRUE)

  garbage_rows <- grepl("suppressed|end of", p$county_id, ignore.case = TRUE)
  expect_equal(sum(garbage_rows), 0)

  valid_county <- grepl("^[0-9]{2}$", p$county_id)
  expect_true(all(valid_county))
})

test_that("garbage rows are filtered from 2024 data", {
  p <- fetch_parcc(2024, 3, "ela", tidy = TRUE)

  garbage_rows <- grepl("suppressed|end of", p$county_id, ignore.case = TRUE)
  expect_equal(sum(garbage_rows), 0)

  valid_county <- grepl("^[0-9]{2}$", p$county_id)
  expect_true(all(valid_county))
})

# ==============================================================================
# Subgroup Tidying Tests
# Verify subgroup names are standardized
# ==============================================================================

test_that("2015 subgroups are tidied (uppercase to standard)", {
  # Raw data has: "ALL STUDENTS", "WHITE", "AFRICAN AMERICAN", etc.
  p <- fetch_parcc(2015, 3, "ela", tidy = TRUE)

  expect_true("total_population" %in% p$subgroup)
  expect_true("white" %in% p$subgroup)
  expect_true("black" %in% p$subgroup)
  expect_true("hispanic" %in% p$subgroup)
  expect_true("asian" %in% p$subgroup)

  # Should NOT have uppercase versions
  expect_false("ALL STUDENTS" %in% p$subgroup)
  expect_false("WHITE" %in% p$subgroup)
  expect_false("AFRICAN AMERICAN" %in% p$subgroup)
})

test_that("2022 subgroups are tidied (title case to standard)", {
  # Raw data has: "All Students", "White", "African American", etc.
  p <- fetch_parcc(2022, 3, "ela", tidy = TRUE)

  expect_true("total_population" %in% p$subgroup)
  expect_true("white" %in% p$subgroup)
  expect_true("black" %in% p$subgroup)
  expect_true("hispanic" %in% p$subgroup)
  expect_true("asian" %in% p$subgroup)

  # Should NOT have title case versions
  expect_false("All Students" %in% p$subgroup)
  expect_false("White" %in% p$subgroup)
  expect_false("African American" %in% p$subgroup)
})

# ==============================================================================
# Year Coverage Tests
# Verify fetch_all_parcc excludes 2020 (COVID) and 2021 (Start Strong only)
# ==============================================================================

test_that("fetch_all_parcc excludes 2020 and 2021", {
  # This test is slow - only run if specifically requested
  skip_on_cran()
  skip_if_not(Sys.getenv("TEST_ALL_YEARS") == "true")

  all_parcc <- fetch_all_parcc()

  years_in_data <- unique(all_parcc$testing_year)

  # Should NOT include 2020 (COVID) or 2021 (Start Strong only)
  expect_false(2020 %in% years_in_data)
  expect_false(2021 %in% years_in_data)

  # Should include all other years
  expect_true(2015 %in% years_in_data)
  expect_true(2019 %in% years_in_data)
  expect_true(2022 %in% years_in_data)
  expect_true(2024 %in% years_in_data)
})
