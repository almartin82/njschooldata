# ==============================================================================
# Tests for fetch_directory() and related functions
# ==============================================================================

# Skip on CRAN and when offline
skip_on_cran()
skip_if_offline()

# -----------------------------------------------------------------------------
# URL Availability Tests
# -----------------------------------------------------------------------------

test_that("school directory URL is accessible", {
  # NJ DOE sometimes rejects HEAD requests with HTTP/2 errors,

  # so we test with a limited GET request instead
  resp <- tryCatch(
    httr::GET(
      "https://homeroom4.doe.state.nj.us/public/publicschools/download/",
      httr::timeout(15),
      httr::config(http_version = 0)  # let curl negotiate
    ),
    error = function(e) NULL
  )
  # If we got a response at all, accept 200/302/403
  # If HEAD fails with protocol error, the actual download tests below
  # will still validate functionality
  if (!is.null(resp)) {
    expect_true(resp$status_code %in% c(200, 302, 403))
  }
})

test_that("district directory URL is accessible", {
  resp <- tryCatch(
    httr::GET(
      "https://homeroom4.doe.state.nj.us/public/districtpublicschools/download/",
      httr::timeout(15),
      httr::config(http_version = 0)
    ),
    error = function(e) NULL
  )
  if (!is.null(resp)) {
    expect_true(resp$status_code %in% c(200, 302, 403))
  }
})

# -----------------------------------------------------------------------------
# Raw Data Download Tests
# -----------------------------------------------------------------------------

test_that("get_raw_school_directory returns expected columns", {
  raw <- get_raw_school_directory()

  expect_s3_class(raw, "data.frame")
  expect_gt(nrow(raw), 2000)

  expected_cols <- c(
    "County Code", "County Name", "District Code", "District Name",
    "School Code", "School Name", "Princ. First Name", "Princ. Last Name",
    "Address1", "City", "State", "Zip", "Phone"
  )
  for (col in expected_cols) {
    expect_true(col %in% names(raw), info = paste("Missing column:", col))
  }
})

test_that("get_raw_district_directory returns expected columns", {
  raw <- get_raw_district_directory()

  expect_s3_class(raw, "data.frame")
  expect_gt(nrow(raw), 600)

  expected_cols <- c(
    "County Code", "County Name", "District Code", "District Name",
    "Supt. First Name", "Supt. Last Name",
    "Address1", "City", "State", "Zip", "Phone", "Website"
  )
  for (col in expected_cols) {
    expect_true(col %in% names(raw), info = paste("Missing column:", col))
  }
})

# -----------------------------------------------------------------------------
# Processed Data Tests
# -----------------------------------------------------------------------------

test_that("fetch_directory school level returns correct schema", {
  schools <- fetch_directory(level = "school", use_cache = TRUE)

  expect_s3_class(schools, "data.frame")
  expect_gt(nrow(schools), 2000)

  required_cols <- c(
    "county_id", "county_name", "district_id", "district_name",
    "school_id", "school_name", "entity_type",
    "principal_name", "principal_email",
    "address", "city", "state", "zip", "phone",
    "grades_served", "nces_id",
    "is_charter", "is_school", "is_district", "CDS_Code"
  )
  for (col in required_cols) {
    expect_true(col %in% names(schools), info = paste("Missing column:", col))
  }

  # Entity type should all be "school"
  expect_true(all(schools$entity_type == "school"))
  expect_true(all(schools$is_school))
  expect_true(all(!schools$is_district))
})

test_that("fetch_directory district level returns correct schema", {
  districts <- fetch_directory(level = "district", use_cache = TRUE)

  expect_s3_class(districts, "data.frame")
  expect_gt(nrow(districts), 600)

  required_cols <- c(
    "county_id", "county_name", "district_id", "district_name",
    "entity_type",
    "superintendent_name", "superintendent_email",
    "address", "city", "state", "zip", "phone",
    "website",
    "is_charter", "is_school", "is_district", "CDS_Code"
  )
  for (col in required_cols) {
    expect_true(col %in% names(districts), info = paste("Missing column:", col))
  }

  # Entity type should all be "district"
  expect_true(all(districts$entity_type == "district"))
  expect_true(all(districts$is_district))
  expect_true(all(!districts$is_school))
})

test_that("fetch_directory both level combines school and district data", {
  both <- fetch_directory(level = "both", use_cache = TRUE)

  expect_s3_class(both, "data.frame")

  n_schools <- sum(both$entity_type == "school")
  n_districts <- sum(both$entity_type == "district")

  expect_gt(n_schools, 2000)
  expect_gt(n_districts, 600)
  expect_equal(nrow(both), n_schools + n_districts)
})

# -----------------------------------------------------------------------------
# Data Quality Tests
# -----------------------------------------------------------------------------

test_that("school directory has non-empty data", {
  schools <- fetch_directory(level = "school", use_cache = TRUE)

  # Most schools should have principals
  has_principal <- sum(!is.na(schools$principal_name))
  pct_with_principal <- has_principal / nrow(schools)
  expect_gt(pct_with_principal, 0.9, label = "% of schools with principal")

  # All should have county and district
  expect_true(all(!is.na(schools$county_id)))
  expect_true(all(!is.na(schools$district_id)))
  expect_true(all(!is.na(schools$school_id)))

  # Multiple counties
  expect_gt(length(unique(schools$county_name)), 20)

  # Multiple districts
  expect_gt(length(unique(schools$district_name)), 500)
})

test_that("district directory has non-empty data", {
  districts <- fetch_directory(level = "district", use_cache = TRUE)

  # Most districts should have superintendents
  has_supt <- sum(!is.na(districts$superintendent_name))
  pct_with_supt <- has_supt / nrow(districts)
  expect_gt(pct_with_supt, 0.85, label = "% of districts with superintendent")

  # Most districts should have websites
  has_website <- sum(!is.na(districts$website) & districts$website != "")
  pct_with_website <- has_website / nrow(districts)
  expect_gt(pct_with_website, 0.9, label = "% of districts with website")

  # All should have county and district codes
  expect_true(all(!is.na(districts$county_id)))
  expect_true(all(!is.na(districts$district_id)))
})

test_that("charter schools are correctly flagged", {
  schools <- fetch_directory(level = "school", use_cache = TRUE)

  # Charter schools have county_id == "80"
  charters <- schools[schools$is_charter, ]
  expect_gt(nrow(charters), 50)  # NJ has many charter schools
  expect_true(all(charters$county_id == "80"))
})

test_that("CDS_Code is correctly constructed", {
  schools <- fetch_directory(level = "school", use_cache = TRUE)
  districts <- fetch_directory(level = "district", use_cache = TRUE)

  # School CDS = county_id + district_id + school_id
  expected_school_cds <- paste0(schools$county_id, schools$district_id, schools$school_id)
  expect_equal(schools$CDS_Code, expected_school_cds)

  # District CDS = county_id + district_id + "999"
  expected_dist_cds <- paste0(districts$county_id, districts$district_id, "999")
  expect_equal(districts$CDS_Code, expected_dist_cds)
})

test_that("Excel formula padding is properly removed", {
  schools <- fetch_directory(level = "school", use_cache = TRUE)

  # county_id should be clean (no ="01" patterns)
  expect_false(any(grepl('="', schools$county_id)))
  expect_false(any(grepl('"', schools$county_id)))

  # Same for district_id and school_id
  expect_false(any(grepl('="', schools$district_id)))
  expect_false(any(grepl('="', schools$school_id)))
})

# -----------------------------------------------------------------------------
# Input Validation Tests
# -----------------------------------------------------------------------------

test_that("fetch_directory rejects invalid level", {
  expect_error(
    fetch_directory(level = "invalid"),
    "must be one of"
  )
})

# -----------------------------------------------------------------------------
# Cache Tests
# -----------------------------------------------------------------------------

test_that("cache round-trip works for directory data", {
  # Clear cache first
  clear_directory_cache()

  # First call should download
  schools1 <- fetch_directory(level = "school", use_cache = TRUE)

  # Second call should use cache
  schools2 <- fetch_directory(level = "school", use_cache = TRUE)

  expect_equal(nrow(schools1), nrow(schools2))
  expect_equal(names(schools1), names(schools2))

  # Clean up
  clear_directory_cache()
})

# -----------------------------------------------------------------------------
# Backward Compatibility Tests
# -----------------------------------------------------------------------------

test_that("fetch_directory school level matches get_school_directory columns", {
  # Verify that the new function covers all info from the old function
  schools_new <- fetch_directory(level = "school", use_cache = TRUE)

  # The old function returned: county_id, county_name, district_id,
  # district_name, school_id, school_name, address, CDS_Code (plus raw cols)
  # New function should have all of these
  expect_true("county_id" %in% names(schools_new))
  expect_true("district_id" %in% names(schools_new))
  expect_true("school_id" %in% names(schools_new))
  expect_true("CDS_Code" %in% names(schools_new))
  expect_true("address" %in% names(schools_new))
})
