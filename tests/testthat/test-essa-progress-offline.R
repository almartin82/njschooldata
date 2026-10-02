# Structural examples for analysis only; these are not source data or fixtures
# of published NJ DOE accountability results.
essa_analysis_rows <- function() {
  data.frame(
    county_id = c("01", "01", "03"),
    county_name = c("County A", "County A", "County B"),
    district_id = c("0010", "0020", "0010"),
    district_name = c("District A", "District B", "District C"),
    school_id = "010",
    school_name = c("School A", "School B", "School C"),
    category_of_identification = c(
      "Comprehensive Support", "No Identification", "Targeted Support"
    ),
    stringsAsFactors = FALSE
  )
}

test_that("ESSA progress keeps repeated local school codes independent", {
  first <- essa_analysis_rows()
  second <- first[c(3, 1, 2), ]
  second$category_of_identification <- c(
    "Targeted Support", "Targeted Support", "Comprehensive Support"
  )
  after_gap <- first[1, ]
  after_gap$category_of_identification <- "No Identification"

  result <- track_essa_progress_over_time(list(
    "2026" = after_gap, "2024" = second, "2023" = first
  ))
  history <- result$longitudinal

  expect_equal(result$summary$n_schools_tracked, 3L)
  expect_equal(history$status_change[history$end_year == 2023], rep("First Year", 3))
  expect_equal(history$status_change[history$end_year == 2024],
               c("Improvement", "Decline", "Stable"))
  expect_equal(history$status_change[history$end_year == 2026], "Insufficient Data")
  expect_equal(result$summary$n_improvements, 1L)
  expect_equal(result$summary$n_declines, 1L)
  expect_equal(result$summary$n_years, 3L)
  expect_setequal(names(history), c(
    "end_year", "county_id", "district_id", "school_id", "school_name",
    "category_of_identification", "focus_level", "status_change"
  ))

  expected <- data.frame(
    from_status = c("Comprehensive Support", "No Support", "Targeted Support"),
    to_status = c("Targeted Support", "Comprehensive Support", "Targeted Support"),
    n_schools = 1L,
    pct_schools = 100
  )
  expect_equal(as.data.frame(result$transitions), expected)
})

test_that("a single two-year ESSA improvement retains its prior status", {
  first <- essa_analysis_rows()[1, ]
  second <- first
  second$category_of_identification <- "Targeted Support"
  result <- track_essa_progress_over_time(list("2023" = first, "2024" = second))
  expect_equal(result$summary$n_improvements, 1L)
  expect_equal(as.data.frame(result$transitions), data.frame(
    from_status = "Comprehensive Support", to_status = "Targeted Support",
    n_schools = 1L, pct_schools = 100
  ))
})

test_that("focus-school filtering uses the requested year", {
  first <- essa_analysis_rows()[1, ]
  first$end_year <- 2023
  second <- first
  second$end_year <- 2024
  combined <- rbind(first, second)
  expect_equal(identify_focus_schools(combined, end_year = 2023)$end_year, 2023)
  expect_equal(identify_focus_schools(combined, end_year = "2024")$end_year, 2024)
  expect_warning(absent <- identify_focus_schools(combined, end_year = 2025),
                 "No focus schools")
  expect_equal(nrow(absent), 0L)
})

test_that("ESSA progress rejects ambiguous school-year observations", {
  duplicated_school <- essa_analysis_rows()[c(1, 1), ]
  expect_error(
    track_essa_progress_over_time(list("2024" = duplicated_school)),
    "one row per county_id, district_id, school_id and end_year"
  )
  expect_error(
    track_essa_progress_over_time(list("2024" = duplicated_school)),
    "Duplicate: 01/0010/010/2024"
  )
  district_rows <- duplicated_school
  district_rows$school_id <- "999"
  expect_error(
    track_essa_progress_over_time(list("2024" = district_rows)),
    "Supply school-level fetch_essa_status"
  )
})

test_that("ESSA histories resume consecutive transitions after a year gap", {
  first <- tibble::as_tibble(essa_analysis_rows()[1, ])
  first$end_year <- 2023
  first$is_school <- TRUE
  first$is_district <- FALSE
  after_gap <- first
  after_gap$end_year <- 2025
  after_gap$category_of_identification <- "Targeted Support"
  next_year <- after_gap
  next_year$end_year <- 2026
  next_year$category_of_identification <- "No Identification"
  result <- track_essa_progress_over_time(list(
    "2023" = first, "2025" = after_gap, "2026" = next_year
  ))
  expect_equal(result$longitudinal$status_change,
               c("First Year", "Insufficient Data", "Improvement"))
  expect_equal(as.data.frame(result$transitions), data.frame(
    from_status = "Targeted Support", to_status = "No Support",
    n_schools = 1L, pct_schools = 100
  ))
})

test_that("focus-school year filtering fails for ambiguous or absent years", {
  rows <- essa_analysis_rows()
  expect_error(identify_focus_schools(rows, end_year = 2023), "end_year")
  rows$end_year <- 2023
  expect_error(identify_focus_schools(rows, end_year = c(2023, 2024)),
               "end_year must be a single school year")
})
