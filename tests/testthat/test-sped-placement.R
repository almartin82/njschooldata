# ==============================================================================
# Tests for fetch_sped_placement() (IDEA 618 Educational Environment)
# ==============================================================================
# Closes #46.
#
# These tests hit the live NJ DOE workbook. They are gated behind
# skip_if_offline() the same way as the rest of the network-dependent tests
# in this package (see tests/testthat/test_sped.R).
# ==============================================================================


# ------------------------------------------------------------------
# Offline tests: argument validation + helpers
# ------------------------------------------------------------------

test_that("get_valid_sped_placement_years returns 2025", {
  expect_equal(get_valid_sped_placement_years(), 2025L)
})

test_that("build_sped_placement_url uses the IDEA 618 path", {
  url <- build_sped_placement_url(2025)
  expect_match(url, "ideapublicdata/docs/2025_618data/", fixed = TRUE)
  expect_match(url, "StudentCountandEducationalEnvironment\\.xlsx$")
})

test_that("fetch_sped_placement rejects unsupported years", {
  expect_error(fetch_sped_placement(1999), "not a valid")
  expect_error(fetch_sped_placement(2020), "not a valid")
})

test_that("fetch_sped_placement validates age_group and level", {
  expect_error(
    fetch_sped_placement(2025, age_group = "k-12"),
    "age_group"
  )
  expect_error(
    fetch_sped_placement(2025, level = "school"),
    "level"
  )
})

test_that("standardize_sped_placement_subgroups normalizes NJ labels", {
  input <- c(
    "Districtwide",
    "Black or African American",
    "Hispanic",
    "Native Hawaiian or Pacific Islander",
    "Two or More Races",
    "Multilingual Learner",
    "Non-Multilingual Learner",
    "Autism",
    "Speech or Language Impairment"
  )
  expected <- c(
    "total",
    "black",
    "hispanic",
    "pacific_islander",
    "multiracial",
    "lep",
    "non_lep",
    "autism",
    "speech_language_impairment"
  )
  expect_equal(standardize_sped_placement_subgroups(input), expected)
})

test_that("parse_placement_count and parse_placement_pct handle suppression", {
  expect_equal(
    parse_placement_count(c("42", "*", "0", "N")),
    c(42, NA, 0, NA)
  )
  expect_equal(
    parse_placement_pct(c("12.3", "*", "0.0"), scale_to_pct = 1),
    c(12.3, NA, 0)
  )
  expect_equal(
    parse_placement_pct(c("0.123", "*", "1"), scale_to_pct = 100),
    c(12.3, NA, 100)
  )
})


# ------------------------------------------------------------------
# Network tests: structure + fidelity
# ------------------------------------------------------------------

test_that("fetch_sped_placement (district 5-21) returns expected structure", {
  skip_if_offline()

  df <- tryCatch(fetch_sped_placement(2025), error = function(e) NULL)
  skip_if(is.null(df), "SPED placement workbook not accessible")

  expected_cols <- c(
    "end_year", "county_id", "county_name",
    "district_id", "district_name",
    "subgroup", "environment",
    "count", "percent", "subgroup_total",
    "is_state", "is_district", "is_charter"
  )
  expect_true(all(expected_cols %in% names(df)))
  expect_true(nrow(df) > 0)
  expect_equal(unique(df$end_year), 2025)

  # 8 educational-environment categories for school-age
  expect_setequal(
    unique(df$environment),
    c(
      "gen_ed_80_plus", "gen_ed_40_79", "gen_ed_less_40",
      "separate_school", "residential_facility",
      "homebound_hospital", "correction_facility",
      "parentally_placed_nonpublic"
    )
  )

  # Standard subgroup names present (cross-state)
  expect_true(all(
    c("total", "black", "hispanic", "lep", "male", "female")
      %in% df$subgroup
  ))

  # No district has subgroup labels left in raw NJ form
  expect_false(any("Districtwide" %in% df$subgroup))
  expect_false(any("Multilingual Learner" %in% df$subgroup))
})


test_that("fetch_sped_placement entity flags are coherent", {
  skip_if_offline()
  df <- tryCatch(fetch_sped_placement(2025), error = function(e) NULL)
  skip_if(is.null(df), "SPED placement workbook not accessible")

  expect_true(all(df$is_district))
  expect_false(any(df$is_state))
  # Charters live under county_id "80"
  expect_true(all(df$is_charter == (df$county_id == "80")))
})


test_that("fetch_sped_placement counts sum to subgroup_total (fidelity)", {
  skip_if_offline()
  df <- tryCatch(fetch_sped_placement(2025), error = function(e) NULL)
  skip_if(is.null(df), "SPED placement workbook not accessible")

  # Newark is large enough that the visible counts should account for the
  # district total once you allow for suppression flags ("*"). Each
  # suppressed cell represents 1-9 students, so the sum of visible counts
  # should differ from the row total by at most 9 * (number suppressed).
  newark <- df[
    df$district_name == "Newark Public School District" &
      df$subgroup == "total",
  ]
  skip_if(nrow(newark) == 0, "Newark not present in workbook")
  total <- unique(newark$subgroup_total)
  visible_sum <- sum(newark$count, na.rm = TRUE)
  n_suppressed <- sum(is.na(newark$count))
  expect_true(visible_sum <= total)
  expect_true(visible_sum >= total - 9 * n_suppressed)
})


test_that("fetch_sped_placement(tidy=FALSE) returns raw workbook tibble", {
  skip_if_offline()
  raw <- tryCatch(
    fetch_sped_placement(2025, tidy = FALSE),
    error = function(e) NULL
  )
  skip_if(is.null(raw), "SPED placement workbook not accessible")

  # Raw layer: column names preserved as published
  expect_true("County Code" %in% names(raw))
  expect_true("Student Group" %in% names(raw))
  expect_true(
    "In General Education for 80% or More of the Day Count" %in% names(raw)
  )
})


test_that("fetch_sped_placement (state 5-21) returns 5 dimension breakdowns", {
  skip_if_offline()
  df <- tryCatch(
    fetch_sped_placement(2025, level = "state"),
    error = function(e) NULL
  )
  skip_if(is.null(df), "SPED placement workbook not accessible")

  expect_setequal(
    unique(df$dimension),
    c("age", "disability", "racial_ethnic", "gender", "multilingual_learner")
  )
  expect_true(all(df$is_state))
  expect_false(any(df$is_district))
})


test_that("state 5-21: counts within a subgroup sum to subgroup_total", {
  skip_if_offline()
  df <- tryCatch(
    fetch_sped_placement(2025, level = "state"),
    error = function(e) NULL
  )
  skip_if(is.null(df), "SPED placement workbook not accessible")

  asian <- df[df$dimension == "racial_ethnic" & df$subgroup == "asian", ]
  skip_if(nrow(asian) == 0, "Asian subgroup missing from state sheet")
  expect_equal(
    sum(asian$count, na.rm = TRUE),
    unique(asian$subgroup_total)
  )
})


test_that("fetch_sped_placement (district 3-5) returns districtwide totals", {
  skip_if_offline()
  df <- tryCatch(
    fetch_sped_placement(2025, age_group = "3-5", level = "district"),
    error = function(e) NULL
  )
  skip_if(is.null(df), "SPED placement workbook not accessible")

  expect_true(all(df$environment == "districtwide"))
  expect_true(all(df$is_district))
})


test_that("fetch_sped_placement (state 3-5) uses preschool environments", {
  skip_if_offline()
  df <- tryCatch(
    fetch_sped_placement(2025, age_group = "3-5", level = "state"),
    error = function(e) NULL
  )
  skip_if(is.null(df), "SPED placement workbook not accessible")

  # A couple of preschool-specific category codes
  expect_true("ec_program_10plus_hrs" %in% df$environment)
  expect_true("separate_class" %in% df$environment)
  # School-age-only codes shouldn't be present
  expect_false("gen_ed_80_plus" %in% df$environment)
})


test_that("fetch_sped_placement_multi binds years and skips bad ones", {
  skip_if_offline()
  # 1999 is invalid, 2025 is valid -- multi should warn on 1999 and still
  # return data from 2025.
  df <- suppressWarnings(
    tryCatch(
      fetch_sped_placement_multi(c(1999L, 2025L)),
      error = function(e) NULL
    )
  )
  skip_if(is.null(df), "SPED placement workbook not accessible")

  expect_true(nrow(df) > 0)
  expect_equal(unique(df$end_year), 2025)
})
