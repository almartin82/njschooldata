# Tests for slugify_district()

# ==============================================================================
# Pure logic tests (no network)
# ==============================================================================

test_that("slugify_district strips 'Public Schools' suffix", {
  expect_equal(slugify_district("Providence Public Schools"), "providence")
})

test_that("slugify_district strips 'School District' suffix", {
  expect_equal(slugify_district("Dallas Independent School District"), "dallas")
})

test_that("slugify_district strips 'ISD' suffix", {
  expect_equal(slugify_district("Austin ISD"), "austin")
})

test_that("slugify_district strips 'USD' suffix", {
  expect_equal(slugify_district("Wichita USD"), "wichita")
})

test_that("slugify_district handles multi-word names", {
  expect_equal(slugify_district("Little Rock School District"), "little-rock")
  expect_equal(slugify_district("Salt Lake City School District"), "salt-lake-city")
})

test_that("slugify_district lowercases", {
  expect_equal(slugify_district("PROVIDENCE"), "providence")
  expect_equal(slugify_district("Providence"), "providence")
})

test_that("slugify_district removes punctuation", {
  expect_equal(slugify_district("St. Paul Public Schools"), "st-paul")
})

test_that("slugify_district handles already-clean names", {
  expect_equal(slugify_district("Barrington"), "barrington")
})

test_that("slugify_district vectorized", {
  result <- slugify_district(c("Providence Public Schools", "Cranston"))
  expect_equal(result, c("providence", "cranston"))
})

test_that("slugify_district strips trailing hyphens", {
  # "Unified" gets stripped, leaving potential trailing hyphen
  expect_false(grepl("-$", slugify_district("San Diego Unified")))
})

test_that("slugify_district backwards compatible without district_id", {
  expect_equal(slugify_district("Providence Public Schools"), "providence")
  expect_equal(
    slugify_district(c("Cranston", "Warwick")),
    c("cranston", "warwick")
  )
})

test_that("slugify_district resolves collisions with district_id", {
  result <- slugify_district(
    c("Liberty", "Liberty"),
    c("1234", "5678")
  )
  expect_equal(result, c("liberty-1234", "liberty-5678"))
})

test_that("slugify_district only appends id to duplicates", {
  result <- slugify_district(
    c("Springfield", "Liberty", "Liberty"),
    c("0001", "1234", "5678")
  )
  expect_equal(result[1], "springfield")
  expect_equal(result[2], "liberty-1234")
  expect_equal(result[3], "liberty-5678")
})

test_that("slugify_district falls back to full name when stripping empties slug", {
  # "Community ISD" would strip to empty; fallback preserves original
  expect_equal(slugify_district("Community ISD"), "community-isd")
  expect_equal(slugify_district("County School District"), "county-school-district")
})

test_that("slugify_district ignores district_id when no collisions", {
  result <- slugify_district(
    c("Providence", "Cranston"),
    c("28", "07")
  )
  expect_equal(result, c("providence", "cranston"))
})

# ==============================================================================
# Integration: uniqueness from fetch_directory()
# ==============================================================================

test_that("slugify_district produces unique slugs for all directory districts", {
  skip_on_cran()

  dir <- fetch_directory(level = "district")
  districts <- unique(dir[, c("district_name", "district_id")])
  districts <- districts[
    is.na(districts$district_name) == FALSE &
    is.na(districts$district_id) == FALSE,
  ]

  slugs <- slugify_district(districts$district_name, districts$district_id)

  expect_true(all(!is.na(slugs)), info = "No slug should be NA")
  expect_true(all(nchar(slugs) > 0), info = "No slug should be empty")

  dupes <- slugs[duplicated(slugs)]
  if (length(dupes) > 0) {
    colliding <- districts$district_name[slugs %in% dupes]
    fail(paste0(
      length(dupes), " collision(s):\n",
      paste(colliding, "->", slugify_district(colliding), collapse = "\n")
    ))
  }
  expect_equal(length(unique(slugs)), length(slugs))

  blocklist <- c("", "the", "of", "and", "state", "education")
  expect_true(!any(slugs %in% blocklist))
})

# ==============================================================================
# Integration: uniqueness from fetch_enr()
# ==============================================================================

test_that("slugify_district produces unique slugs for all enrollment districts", {
  skip_on_cran()

  enr <- fetch_enr(2024, tidy = TRUE)
  districts <- unique(enr[enr$is_district == TRUE, c("district_name", "district_id")])
  districts <- districts[!is.na(districts$district_name), ]

  slugs <- slugify_district(districts$district_name, districts$district_id)

  expect_true(all(!is.na(slugs)), info = "No slug should be NA")
  expect_true(all(nchar(slugs) > 0), info = "No slug should be empty")
  expect_equal(length(unique(slugs)), length(slugs))
})
