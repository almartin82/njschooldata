# NOTE: As of 2024, NJ DOE has restructured their special education data website.
# Historical data (2003-2019) is no longer available at the original URLs.
# Data prior to 2014 requires an OPRA request.
# New data uses a different URL structure at /education/specialed/monitor/ideapublicdata/

test_that("fetch_sped returns expected structure for 2024 data", {
  skip_if_offline()

  # Test current data year
  result <- tryCatch(
    fetch_sped(2024),
    error = function(e) NULL
  )


  skip_if(is.null(result), "SPED data URL not accessible")

  expect_s3_class(result, 'data.frame')
  expected_cols <- c("end_year", "county_name", "district_id", "district_name",
                     "gened_num", "sped_num", "sped_rate")
  expect_true(all(expected_cols %in% names(result)))
})

test_that("fetch_sped validates end_year parameter", {
  expect_error(fetch_sped(1990), "not a valid")
  expect_error(fetch_sped(2030), "not a valid")
})

test_that("fetch_sped validates level parameter", {
  expect_error(fetch_sped(2025, level = "school"), "level")
})

test_that("build_sped_url switches to the 2025 consolidated naming", {
  # 2025+ uses the consolidated IDEA-618 public reporting workbook.
  url_25 <- build_sped_url(2025)
  expect_match(url_25, "2025_618data/", fixed = TRUE)
  expect_match(url_25, "2025IDEA618PublicReporting_ClassificationRates\\.xlsx$")
  # Pre-2025 uses the older DistrictWide_ClassificationRate naming in the
  # prior-year-labeled folder.
  url_24 <- build_sped_url(2024)
  expect_match(url_24, "2023_618data/DistrictWide_ClassificationRate_2324_public\\.xlsx$")
})

test_that("get_raw_sped(level='state') is rejected before 2025", {
  expect_error(
    get_raw_sped(2024, level = "state"),
    "only available for end_year >= 2025"
  )
})

test_that("standardize_sped_disability_category maps NJ labels + rollup", {
  input <- c(
    "Autism", "Other Health Impairment", "Specific Learning Disability",
    "Emotional Regulation Impairment", "Preschool Child with a Disability",
    "Auditory Impairment", "Statewide Total"
  )
  expected <- c(
    "autism", "other_health_impairment", "specific_learning_disability",
    "emotional_regulation_impairment", "preschool_disability",
    "auditory_impairment", "all_disabilities"
  )
  expect_equal(standardize_sped_disability_category(input), expected)
})

test_that("tidy_sped_state_disability reshapes a State Rates frame", {
  # Minimal in-memory fixture mirroring the cleaned 2025 'State Rates' sheet
  # (post clean_sped_names): rates are decimals, with a sentinel row.
  df <- tibble::tibble(
    disability_category = c("Autism", "Visual Impairment",
                            "Statewide Total", "end of worksheet"),
    sped_num = c("31715", "324", "242001", NA),
    sped_rate = c("0.0227", "0.0002", "0.1735", NA),
    end_year = 2025L
  )
  out <- tidy_sped_state_disability(df, 2025L)
  expect_setequal(
    out$disability_category,
    c("autism", "visual_impairment", "all_disabilities")
  )
  expect_true(all(out$is_state))
  expect_equal(out$n_students[out$disability_category == "autism"], 31715)
  # decimal rate scaled to 0-100 percent
  expect_equal(out$sped_rate[out$disability_category == "autism"], 2.27)
  # sentinel row dropped
  expect_false(any(out$disability_category == "end of worksheet"))
})


# ------------------------------------------------------------------
# Network tests: 2025 consolidated workbook (district + state)
# ------------------------------------------------------------------

test_that("fetch_sped(2025) district returns the classification schema", {
  skip_if_offline()
  result <- tryCatch(fetch_sped(2025), error = function(e) NULL)
  skip_if(is.null(result), "SPED 2025 workbook not accessible")

  expected_cols <- c("end_year", "county_id", "county_name", "district_id",
                     "district_name", "gened_num", "sped_num", "sped_rate")
  expect_true(all(expected_cols %in% names(result)))
  expect_true(nrow(result) > 0)
  expect_equal(unique(result$end_year), 2025)
  # counts/rates parsed to numeric, leading zeros preserved on ids
  expect_true(is.numeric(result$gened_num))
  expect_true(is.numeric(result$sped_num))
  expect_true(is.numeric(result$sped_rate))
  expect_true(any(grepl("^0", result$district_id)))
})

test_that("fetch_sped(2025, level='state') gives child count by disability", {
  skip_if_offline()
  s <- tryCatch(fetch_sped(2025, level = "state"), error = function(e) NULL)
  skip_if(is.null(s), "SPED 2025 workbook not accessible")

  expect_true(all(c("end_year", "is_state", "disability_category",
                    "n_students", "sped_rate", "suppressed") %in% names(s)))
  expect_true(all(s$is_state))
  # Standardized IDEA categories present (NJ uses auditory_impairment +
  # emotional_regulation_impairment in place of the federal labels).
  expect_true(all(c("autism", "specific_learning_disability",
                    "other_health_impairment", "all_disabilities") %in%
                    s$disability_category))
  # No raw NJ labels leak through.
  expect_false(any(c("Autism", "Statewide Total") %in% s$disability_category))

  # Fidelity: the 13 disability categories sum exactly to the rollup total.
  rollup <- s$n_students[s$disability_category == "all_disabilities"]
  parts <- sum(s$n_students[s$disability_category != "all_disabilities"],
               na.rm = TRUE)
  expect_equal(parts, rollup)

  # Suppressed flag matches NA counts (none expected at state level, but the
  # invariant must hold).
  expect_equal(s$suppressed, is.na(s$n_students))
})

