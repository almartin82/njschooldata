# ==============================================================================
# Typology Guard Tests
# ==============================================================================
#
# Structural validation tests that catch common data quality issues:
# - Division by zero in percentage calculations
# - Percentage scale consistency (0-1 vs 0-100)
# - Column type correctness
# - Subgroup/grade value set validation
# - Zero vs NA distinction
# - No duplicate rows
# - Row count minimums
#
# These tests guard against regressions in data processing logic.
#
# ==============================================================================

# -- Percentage division-by-zero guards (enrollment) ---------------------------

test_that("enrollment tidy pct has no Inf from division by zero", {
  skip_on_cran()
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # pct = n_students / row_total; if row_total is 0, pct becomes Inf
  valid_pct <- enr$pct[!is.na(enr$pct)]
  expect_false(any(is.infinite(valid_pct)),
    info = "Inf in pct column (likely division by zero)")
  expect_false(any(is.nan(valid_pct)),
    info = "NaN in pct column")
})

test_that("enrollment tidy pct is in 0-1 range (not 0-100)", {
  skip_on_cran()
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # pct should be 0-1 scale (proportion), not 0-100 scale (percentage)
  valid_pct <- enr$pct[!is.na(enr$pct)]
  expect_true(all(valid_pct >= 0),
    info = "Negative pct values found")
  expect_true(all(valid_pct <= 1.01),
    info = "pct values > 1 found (wrong scale?)")
})


# -- Percentage scale consistency (graduation) ---------------------------------

test_that("graduation rate is in 0-1 scale (not 0-100)", {
  skip_on_cran()
  skip_if_offline()

  gr <- fetch_grad_rate(2024)

  valid_rates <- gr$grad_rate[!is.na(gr$grad_rate)]
  expect_true(all(valid_rates >= 0),
    info = "Negative grad_rate values found")
  expect_true(all(valid_rates <= 1.0),
    info = "grad_rate > 1 found (probably 0-100 scale instead of 0-1)")
})

test_that("PARCC proficiency is in 0-100 scale (not 0-1)", {
  skip_on_cran()
  skip_if_offline()

  p <- fetch_parcc(2024, 4, "ela")

  valid_prof <- p$proficient_above[!is.na(p$proficient_above)]
  # PARCC uses 0-100 percentage scale
  expect_true(all(valid_prof >= 0),
    info = "Negative proficient_above values found")
  # Allow 0.5% tolerance for rounding (e.g., 43.8 + 56.3 = 100.1)
  expect_true(all(valid_prof <= 100.5),
    info = "proficient_above > 100.5 found")

  # Should have some values above 1 (confirming it's not 0-1 scale)
  expect_true(max(valid_prof) > 1,
    info = "All proficient_above <= 1, might be wrong scale")
})


# -- Column type correctness (enrollment) --------------------------------------

test_that("enrollment wide format column types are correct", {
  skip_on_cran()
  skip_if_offline()

  enr <- fetch_enr(2024, use_cache = TRUE)

  # Character columns
  char_cols <- c("county_id", "county_name", "district_id", "district_name",
                 "school_id", "school_name", "CDS_Code")
  for (col in char_cols) {
    if (col %in% names(enr)) {
      expect_true(is.character(enr[[col]]),
        info = paste(col, "should be character, is", class(enr[[col]])))
    }
  }

  # Numeric columns
  num_cols <- c("row_total", "end_year")
  for (col in num_cols) {
    if (col %in% names(enr)) {
      expect_true(is.numeric(enr[[col]]),
        info = paste(col, "should be numeric, is", class(enr[[col]])))
    }
  }

  # Grade level should be character
  expect_true(is.character(enr$grade_level),
    info = "grade_level should be character")
})

test_that("enrollment tidy format column types are correct", {
  skip_on_cran()
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  expect_true(is.character(enr$subgroup),
    info = "subgroup should be character")
  expect_true(is.numeric(enr$n_students),
    info = "n_students should be numeric")
  expect_true(is.numeric(enr$pct),
    info = "pct should be numeric")
  expect_true(is.logical(enr$is_state),
    info = "is_state should be logical")
  expect_true(is.logical(enr$is_district),
    info = "is_district should be logical")
  expect_true(is.logical(enr$is_school),
    info = "is_school should be logical")
  expect_true(is.logical(enr$is_charter),
    info = "is_charter should be logical")
})


# -- Column type correctness (graduation) --------------------------------------

test_that("graduation rate column types are correct", {
  skip_on_cran()
  skip_if_offline()

  gr <- fetch_grad_rate(2024)

  expect_true(is.numeric(gr$grad_rate),
    info = "grad_rate should be numeric")
  expect_true(is.numeric(gr$cohort_count),
    info = "cohort_count should be numeric")
  expect_true(is.numeric(gr$graduated_count),
    info = "graduated_count should be numeric")
  expect_true(is.character(gr$subgroup),
    info = "subgroup should be character")
  expect_true(is.character(gr$methodology),
    info = "methodology should be character")
  expect_true(is.logical(gr$is_state),
    info = "is_state should be logical")
})


# -- Column type correctness (assessment) --------------------------------------

test_that("PARCC column types are correct", {
  skip_on_cran()
  skip_if_offline()

  p <- fetch_parcc(2024, 4, "ela")

  expect_true(is.numeric(p$pct_l1), info = "pct_l1 should be numeric")
  expect_true(is.numeric(p$pct_l2), info = "pct_l2 should be numeric")
  expect_true(is.numeric(p$pct_l3), info = "pct_l3 should be numeric")
  expect_true(is.numeric(p$pct_l4), info = "pct_l4 should be numeric")
  expect_true(is.numeric(p$pct_l5), info = "pct_l5 should be numeric")
  expect_true(is.numeric(p$proficient_above), info = "proficient_above should be numeric")
  expect_true(is.numeric(p$number_enrolled), info = "number_enrolled should be numeric")
  expect_true(is.numeric(p$scale_score_mean), info = "scale_score_mean should be numeric")
  expect_true(is.character(p$subgroup), info = "subgroup should be character")
  expect_true(is.logical(p$is_state), info = "is_state should be logical")
})


# -- Row count minimum tests ---------------------------------------------------

test_that("enrollment has enough rows to be plausible", {
  skip_on_cran()
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # NJ has ~600 districts and ~2,500 schools. Tidy format multiplies by
  # subgroups and grade levels. Should have at minimum 50k rows.
  expect_true(nrow(enr) > 50000,
    info = "Enrollment has too few rows to be plausible")
})

test_that("PARCC has enough rows to be plausible", {
  skip_on_cran()
  skip_if_offline()

  p <- fetch_parcc(2024, 4, "ela")

  # NJ has ~2,500 schools * ~16 subgroups = ~40,000 rows at minimum
  # In practice, many subgroups are suppressed so we see ~25,000
  expect_true(nrow(p) > 10000,
    info = "PARCC has too few rows to be plausible")
})

test_that("graduation rate has enough rows to be plausible", {
  skip_on_cran()
  skip_if_offline()

  gr <- fetch_grad_rate(2024)

  # NJ has ~500 high schools * ~17 subgroups = ~8,500+ rows
  expect_true(nrow(gr) > 5000,
    info = "Graduation rate has too few rows to be plausible")
})


# -- Subgroup value set validation (enrollment) --------------------------------

test_that("enrollment subgroups match expected canonical set", {
  skip_on_cran()
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  actual_subgroups <- sort(unique(enr$subgroup))

  # These are the expected subgroups per CLAUDE.md valid filter values
  expected_subgroups <- sort(c(
    "total_enrollment", "male", "female",
    "white", "black", "hispanic", "asian",
    "native_american", "pacific_islander", "multiracial",
    "free_lunch", "reduced_lunch", "free_reduced_lunch",
    "lep", "migrant"
  ))

  expect_equal(actual_subgroups, expected_subgroups,
    info = paste(
      "Subgroup mismatch.\nActual:", paste(actual_subgroups, collapse = ", "),
      "\nExpected:", paste(expected_subgroups, collapse = ", ")
    ))
})

test_that("enrollment subgroups do NOT contain non-standard names", {
  skip_on_cran()
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  subgroups <- unique(enr$subgroup)

  # These non-standard names should never appear in tidy enrollment
  bad_names <- c(
    "econ_disadv", "special_ed", "el", "ell", "english_learner",
    "american_indian", "two_or_more", "frl", "low_income",
    "total", "Total", "ALL"
  )
  for (bad in bad_names) {
    expect_false(bad %in% subgroups,
      info = paste("Non-standard subgroup name found:", bad))
  }
})


# -- Grade value set validation (enrollment) -----------------------------------

test_that("enrollment grade levels match expected set", {
  skip_on_cran()
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  grade_levels <- sort(unique(enr$grade_level))

  expected_grades <- sort(c(
    "PK", "K", "01", "02", "03", "04", "05",
    "06", "07", "08", "09", "10", "11", "12",
    "TOTAL"
  ))

  expect_equal(grade_levels, expected_grades,
    info = paste(
      "Grade level mismatch.\nActual:", paste(grade_levels, collapse = ", "),
      "\nExpected:", paste(expected_grades, collapse = ", ")
    ))
})

test_that("enrollment grade normalization: KF/KH -> K, PF/PH -> PK", {
  skip_on_cran()
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  grade_levels <- unique(enr$grade_level)

  # Raw codes should NOT appear (normalized to K and PK)
  expect_false("KF" %in% grade_levels, info = "KF not normalized to K")
  expect_false("KH" %in% grade_levels, info = "KH not normalized to K")
  expect_false("PF" %in% grade_levels, info = "PF not normalized to PK")
  expect_false("PH" %in% grade_levels, info = "PH not normalized to PK")
  expect_false("KG" %in% grade_levels, info = "KG not normalized to K")

  # Normalized codes should appear
  expect_true("K" %in% grade_levels, info = "K missing after normalization")
  expect_true("PK" %in% grade_levels, info = "PK missing after normalization")
})


# -- Grade value set validation (wide enrollment) ------------------------------

test_that("enrollment wide grade levels are uppercase", {
  skip_on_cran()
  skip_if_offline()

  enr <- fetch_enr(2024, use_cache = TRUE)

  grade_levels <- unique(enr$grade_level)
  for (gl in grade_levels) {
    expect_equal(gl, toupper(gl),
      info = paste("Grade level not uppercase:", gl))
  }
})


# -- Zero vs NA distinction (enrollment) ---------------------------------------

test_that("enrollment n_students uses 0, not NA, for real zeros", {
  skip_on_cran()
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # State-level total enrollment should never be NA
  state_total <- enr %>%
    dplyr::filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL")
  expect_false(is.na(state_total$n_students),
    info = "State total enrollment should not be NA")
  expect_true(state_total$n_students > 0,
    info = "State total enrollment should be > 0")
})

test_that("enrollment row_total (wide) is never NA for real data rows", {
  skip_on_cran()
  skip_if_offline()

  enr <- fetch_enr(2024, use_cache = TRUE)

  # Filter to TOTAL grade rows, excluding "End of worksheet" garbage rows
  # that NJ DOE includes at the bottom of their Excel files
  totals <- enr %>%
    dplyr::filter(grade_level == "TOTAL", county_id != "End of worksheet")

  # row_total should always have a value for real total rows
  na_count <- sum(is.na(totals$row_total))
  expect_equal(na_count, 0,
    info = paste(na_count, "rows with NA row_total at TOTAL grade level"))
})


# -- No duplicate rows --------------------------------------------------------

test_that("enrollment tidy has no exact duplicate rows for named programs", {
  skip_on_cran()
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # The tidy enrollment pipeline creates some rows with program_code=NA and
  # grade_level=NA for special population subgroups (free_lunch, lep, etc.)
  # which share the same total_enrollment. These are a known data structure
  # artifact. We check rows WITH a defined program_code for true duplicates.
  named_programs <- enr %>% dplyr::filter(!is.na(program_code))
  n_dupes <- nrow(named_programs) - nrow(dplyr::distinct(named_programs))
  expect_equal(n_dupes, 0,
    info = paste(n_dupes, "exact duplicate rows found in tidy enrollment (named programs)"))
})

test_that("enrollment tidy has unique rows per entity-program-grade-subgroup", {
  skip_on_cran()
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # Each CDS_Code + program_code + grade_level + subgroup combination
  # should be unique. The key insight is that program_code distinguishes
  # half-day vs full-day K and PK programs.
  # Exclude "End of worksheet" garbage rows from NJ DOE Excel files
  dupes <- enr %>%
    dplyr::filter(!is.na(program_code), county_id != "End of worksheet") %>%
    dplyr::count(CDS_Code, program_code, grade_level, subgroup) %>%
    dplyr::filter(n > 1)

  expect_equal(nrow(dupes), 0,
    info = paste(nrow(dupes), "duplicate entity-program-grade-subgroup combos found"))
})

test_that("PARCC has no duplicate rows per entity-subgroup", {
  skip_on_cran()
  skip_if_offline()

  p <- fetch_parcc(2024, 4, "ela")

  # Each county_id + district_id + school_id + subgroup combination should be unique
  dupes <- p %>%
    dplyr::count(county_id, district_id, school_id, subgroup) %>%
    dplyr::filter(n > 1)

  expect_equal(nrow(dupes), 0,
    info = paste(nrow(dupes), "duplicate entity-subgroup combos in PARCC"))
})

test_that("graduation rate has no duplicate rows per entity-subgroup", {
  skip_on_cran()
  skip_if_offline()

  gr <- fetch_grad_rate(2024)

  dupes <- gr %>%
    dplyr::count(county_id, district_id, school_id, subgroup) %>%
    dplyr::filter(n > 1)

  expect_equal(nrow(dupes), 0,
    info = paste(nrow(dupes), "duplicate entity-subgroup combos in grad rate"))
})


# -- CDS_Code format validation -----------------------------------------------

test_that("enrollment CDS_Code has consistent 9-char format for real data", {
  skip_on_cran()
  skip_if_offline()

  enr <- fetch_enr(2024, use_cache = TRUE)

  # Exclude "End of worksheet" garbage rows from NJ DOE Excel files
  real_data <- enr %>% dplyr::filter(county_id != "End of worksheet")

  # CDS_Code should be county_id + district_id + school_id = 2+4+3 = 9 chars
  cds_lengths <- nchar(real_data$CDS_Code)
  expect_true(all(cds_lengths == 9),
    info = paste("CDS_Code not 9 chars. Lengths found:",
                 paste(unique(cds_lengths), collapse = ", ")))
})

test_that("enrollment county_id is zero-padded to 2 digits for real data", {
  skip_on_cran()
  skip_if_offline()

  enr <- fetch_enr(2024, use_cache = TRUE)

  # Exclude "End of worksheet" garbage rows
  real_data <- enr %>% dplyr::filter(county_id != "End of worksheet")

  county_lengths <- nchar(real_data$county_id)
  expect_true(all(county_lengths == 2),
    info = "county_id not consistently 2 chars")
})

test_that("enrollment district_id is zero-padded to 4 digits", {
  skip_on_cran()
  skip_if_offline()

  enr <- fetch_enr(2024, use_cache = TRUE)

  district_lengths <- nchar(enr$district_id)
  expect_true(all(district_lengths == 4),
    info = "district_id not consistently 4 chars")
})

test_that("enrollment school_id is zero-padded to 3 digits", {
  skip_on_cran()
  skip_if_offline()

  enr <- fetch_enr(2024, use_cache = TRUE)

  school_lengths <- nchar(enr$school_id)
  expect_true(all(school_lengths == 3),
    info = "school_id not consistently 3 chars")
})


# -- Entity flag consistency ---------------------------------------------------

test_that("enrollment charter schools are in county 80", {
  skip_on_cran()
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  charters <- enr %>% dplyr::filter(is_charter)
  if (nrow(charters) > 0) {
    expect_true(all(charters$county_id == "80"),
      info = "Charter schools should have county_id 80")
  }
})

test_that("enrollment state rows have county_id 99 and district_id 9999", {
  skip_on_cran()
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  state_rows <- enr %>% dplyr::filter(is_state)
  expect_true(nrow(state_rows) > 0,
    info = "No state rows found")
  expect_true(all(state_rows$county_id == "99"),
    info = "State rows should have county_id 99")
  expect_true(all(state_rows$district_id == "9999"),
    info = "State rows should have district_id 9999")
})

test_that("enrollment district rows have school_id 999", {
  skip_on_cran()
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # Districts (non-state) should have school_id 999
  district_rows <- enr %>% dplyr::filter(is_district, !is_state)
  if (nrow(district_rows) > 0) {
    expect_true(all(district_rows$school_id == "999"),
      info = "District rows should have school_id 999")
  }
})


# -- Assessment performance level consistency ----------------------------------

test_that("PARCC ELA/Math has 5 performance levels", {
  skip_on_cran()
  skip_if_offline()

  p <- fetch_parcc(2024, 4, "ela")

  # ELA/Math should have all 5 levels (some NA due to suppression)
  expect_true("pct_l5" %in% names(p), info = "pct_l5 missing for ELA")

  # At least some rows should have non-NA pct_l5
  expect_true(any(!is.na(p$pct_l5)),
    info = "All pct_l5 values are NA for ELA (should have data)")
})

test_that("PARCC Science has 4 performance levels (pct_l5 always NA)", {
  skip_on_cran()
  skip_if_offline()

  p <- fetch_parcc(2024, 8, "science")

  # Science has only 4 levels
  expect_true(all(is.na(p$pct_l5)),
    info = "Science should have pct_l5 = NA (only 4 levels)")
})

test_that("NJGPA has 2 performance levels (pct_l3/l4/l5 always NA)", {
  skip_on_cran()
  skip_if_offline()

  njgpa <- fetch_njgpa(2024, "ela")

  expect_true(all(is.na(njgpa$pct_l3)), info = "NJGPA should have pct_l3 = NA")
  expect_true(all(is.na(njgpa$pct_l4)), info = "NJGPA should have pct_l4 = NA")
  expect_true(all(is.na(njgpa$pct_l5)), info = "NJGPA should have pct_l5 = NA")
})


# -- Validation function tests ------------------------------------------------

test_that("validate_end_year rejects invalid enrollment years", {
  expect_error(validate_end_year(1990, "enrollment"))
  expect_error(validate_end_year(2030, "enrollment"))
  expect_error(validate_end_year("abc", "enrollment"))
  expect_error(validate_end_year(c(2020, 2021), "enrollment"))
})

test_that("validate_end_year accepts valid enrollment years", {
  expect_true(validate_end_year(2000, "enrollment"))
  expect_true(validate_end_year(2024, "enrollment"))
})

test_that("validate_end_year rejects COVID year for PARCC", {
  expect_error(validate_end_year(2020, "parcc"))
})

test_that("validate_end_year accepts valid PARCC years", {
  expect_true(validate_end_year(2015, "parcc"))
  expect_true(validate_end_year(2024, "parcc"))
})

test_that("get_valid_years returns correct years for each data type", {
  enr_years <- get_valid_years("enrollment")
  expect_equal(min(enr_years), 2000)
  expect_equal(max(enr_years), 2025)

  parcc_years <- get_valid_years("parcc")
  expect_false(2020 %in% parcc_years, info = "2020 should be excluded from PARCC")
  expect_true(2015 %in% parcc_years)
  expect_true(2024 %in% parcc_years)

  grate_years <- get_valid_years("grad_rate")
  expect_equal(min(grate_years), 2011)
  expect_equal(max(grate_years), 2024)
})

test_that("get_valid_grades returns expected grades", {
  # NJASK
  expect_equal(get_valid_grades("njask", 2010), 3:8)
  expect_equal(get_valid_grades("njask", 2006), 3:7)
  expect_equal(get_valid_grades("njask", 2004), c(3, 4))

  # PARCC post-2019
  parcc_grades <- get_valid_grades("parcc", 2024)
  expect_true(3 %in% parcc_grades)
  expect_true(10 %in% parcc_grades)
  expect_true("ALG1" %in% parcc_grades)
})
