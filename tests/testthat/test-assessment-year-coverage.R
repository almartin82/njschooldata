# ==============================================================================
# Assessment (PARCC/NJSLA) Year Coverage Tests
# ==============================================================================
#
# Exhaustive per-year tests for NJ PARCC/NJSLA assessment data.
# PARCC ran 2015-2018, NJSLA 2019+. 2020 cancelled (COVID), 2021 not available
# (Start Strong pilot only). Valid years: 2015-2019, 2022-2024.
#
# Pinned state proficiency values verified against NJ DOE Excel files at:
# https://www.nj.gov/education/assessment/results/reports/
#
# ==============================================================================

# -- Grade 4 ELA state proficiency (pinned per year) ---------------------------
# Using Grade 4 ELA as the canonical benchmark because it is stable and
# has the largest sample size (all 4th graders take ELA).

parcc_ela_g4_pins <- list(
  # Pinned: state proficient_above for Grade 4 ELA, subgroup=total_population
  # Source: NJ DOE PARCC/NJSLA data files (ELA04 sheets)
  list(year = 2015, assess_name = "PARCC", state_prof = 51.1, state_enrolled = 100203),
  list(year = 2016, assess_name = "PARCC", state_prof = 53.5, state_enrolled = 101013),
  list(year = 2017, assess_name = "PARCC", state_prof = 55.9, state_enrolled = 103051),
  list(year = 2018, assess_name = "PARCC", state_prof = 58.0, state_enrolled = 101659),
  list(year = 2019, assess_name = "NJSLA", state_prof = 57.4, state_enrolled = 100780),
  list(year = 2022, assess_name = "NJSLA", state_prof = 49.4, state_enrolled = 94930),
  list(year = 2023, assess_name = "NJSLA", state_prof = 51.3, state_enrolled = 94629),
  list(year = 2024, assess_name = "NJSLA", state_prof = 50.8, state_enrolled = 94890)
)

for (spec in parcc_ela_g4_pins) {
  yr <- spec$year

  test_that(paste("fetch_parcc Grade 4 ELA loads for", yr), {
    skip_on_cran()
    skip_if_offline()

    p <- fetch_parcc(yr, 4, "ela", tidy = TRUE)

    expect_s3_class(p, "data.frame")
    expect_gt(nrow(p), 0)
  })

  test_that(paste("fetch_parcc Grade 4 ELA required columns present for", yr), {
    skip_on_cran()
    skip_if_offline()

    p <- fetch_parcc(yr, 4, "ela", tidy = TRUE)

    required_cols <- c(
      "testing_year", "assess_name", "test_name", "grade",
      "county_id", "district_id", "school_id",
      "subgroup", "subgroup_type",
      "number_enrolled", "number_of_valid_scale_scores",
      "scale_score_mean",
      "pct_l1", "pct_l2", "pct_l3", "pct_l4", "pct_l5",
      "proficient_above",
      "is_state", "is_district", "is_school", "is_charter"
    )
    for (col in required_cols) {
      expect_true(col %in% names(p),
        info = paste("Missing column:", col, "in year", yr))
    }
  })

  test_that(paste("fetch_parcc Grade 4 ELA assess_name correct for", yr), {
    skip_on_cran()
    skip_if_offline()

    p <- fetch_parcc(yr, 4, "ela", tidy = TRUE)

    state <- p %>% dplyr::filter(is_state, subgroup == "total_population")
    expect_equal(unique(state$assess_name), spec$assess_name,
      info = paste("Wrong assess_name for", yr))
  })

  test_that(paste("fetch_parcc Grade 4 ELA state proficiency matches pin for", yr), {
    skip_on_cran()
    skip_if_offline()

    p <- fetch_parcc(yr, 4, "ela", tidy = TRUE)

    state <- p %>% dplyr::filter(is_state, subgroup == "total_population")

    # Pinned state proficient_above from NJ DOE ELA04 file
    expect_equal(state$proficient_above, spec$state_prof,
      info = paste("State proficiency mismatch for", yr))
  })

  test_that(paste("fetch_parcc Grade 4 ELA state enrollment matches pin for", yr), {
    skip_on_cran()
    skip_if_offline()

    p <- fetch_parcc(yr, 4, "ela", tidy = TRUE)

    state <- p %>% dplyr::filter(is_state, subgroup == "total_population")

    # Pinned state number_enrolled from NJ DOE ELA04 file
    expect_equal(state$number_enrolled, spec$state_enrolled,
      info = paste("State enrollment mismatch for", yr))
  })

  test_that(paste("fetch_parcc Grade 4 ELA has expected subgroups for", yr), {
    skip_on_cran()
    skip_if_offline()

    p <- fetch_parcc(yr, 4, "ela", tidy = TRUE)

    subgroups <- unique(p$subgroup)

    # Core subgroups present in all years
    core_subgroups <- c(
      "total_population", "male", "female",
      "white", "black", "hispanic", "asian",
      "ed", "special_education"
    )
    for (sg in core_subgroups) {
      expect_true(sg %in% subgroups,
        info = paste("Missing subgroup:", sg, "in year", yr))
    }
  })

  test_that(paste("fetch_parcc Grade 4 ELA proficiency levels sum correctly for", yr), {
    skip_on_cran()
    skip_if_offline()

    p <- fetch_parcc(yr, 4, "ela", tidy = TRUE)

    # For rows with valid data, L1+L2+L3+L4+L5 should approximately equal 100
    complete_rows <- p %>%
      dplyr::filter(
        !is.na(pct_l1) & !is.na(pct_l2) & !is.na(pct_l3) &
        !is.na(pct_l4) & !is.na(pct_l5)
      ) %>%
      dplyr::mutate(total_pct = pct_l1 + pct_l2 + pct_l3 + pct_l4 + pct_l5)

    if (nrow(complete_rows) > 0) {
      # Allow 2% tolerance for rounding
      expect_true(all(abs(complete_rows$total_pct - 100) < 2),
        info = paste("Proficiency levels don't sum to ~100% in", yr))
    }
  })
}


# -- Grade 4 Math state proficiency (pinned per year) --------------------------

parcc_math_g4_pins <- list(
  # Pinned: state proficient_above for Grade 4 Math, subgroup=total_population
  # Source: NJ DOE PARCC/NJSLA data files (MAT04 sheets)
  list(year = 2015, state_prof = 40.6),
  list(year = 2016, state_prof = 46.6),
  list(year = 2017, state_prof = 47.3),
  list(year = 2018, state_prof = 49.4),
  list(year = 2019, state_prof = 51.0),
  list(year = 2022, state_prof = 39.4),
  list(year = 2023, state_prof = 44.3),
  list(year = 2024, state_prof = 45.0)
)

for (spec in parcc_math_g4_pins) {
  yr <- spec$year

  test_that(paste("fetch_parcc Grade 4 Math state proficiency matches pin for", yr), {
    skip_on_cran()
    skip_if_offline()

    p <- fetch_parcc(yr, 4, "math", tidy = TRUE)

    state <- p %>% dplyr::filter(is_state, subgroup == "total_population")

    # Pinned state proficient_above from NJ DOE MAT04 file
    expect_equal(state$proficient_above, spec$state_prof,
      info = paste("Math state proficiency mismatch for", yr))
  })
}


# -- Multiple grades per year -------------------------------------------------

test_that("fetch_parcc works for standard ELA grades in 2024", {
  skip_on_cran()
  skip_if_offline()

  # NJSLA 2019+ has grades 3-9 for ELA (10 and 11 may not be available)
  # Grade 10 ELA was discontinued starting 2024
  for (grade in 3:9) {
    p <- tryCatch(
      fetch_parcc(2024, grade, "ela"),
      error = function(e) NULL
    )

    expect_false(is.null(p),
      info = paste("fetch_parcc failed for 2024 grade", grade, "ELA"))

    if (!is.null(p)) {
      expect_true(nrow(p) > 0,
        info = paste("No rows for 2024 grade", grade, "ELA"))

      # Grade column should match
      expect_true(all(p$grade == as.character(grade)),
        info = paste("Grade mismatch for 2024 grade", grade, "ELA"))
    }
  }
})

test_that("fetch_parcc works for all standard Math grades in 2024", {
  skip_on_cran()
  skip_if_offline()

  for (grade in 3:8) {
    p <- tryCatch(
      fetch_parcc(2024, grade, "math"),
      error = function(e) NULL
    )

    expect_false(is.null(p),
      info = paste("fetch_parcc failed for 2024 grade", grade, "Math"))

    if (!is.null(p)) {
      expect_true(nrow(p) > 0,
      info = paste("No rows for 2024 grade", grade, "Math"))
    }
  }
})

test_that("fetch_parcc works for HS math courses (ALG1, ALG2) in 2024", {
  skip_on_cran()
  skip_if_offline()

  # GEO was discontinued starting 2024 (Geometry integrated into other courses)
  for (course in c("ALG1", "ALG2")) {
    p <- tryCatch(
      fetch_parcc(2024, course, "math"),
      error = function(e) NULL
    )

    expect_false(is.null(p),
      info = paste("fetch_parcc failed for 2024", course, "Math"))

    if (!is.null(p)) {
      expect_true(nrow(p) > 0,
        info = paste("No rows for 2024", course, "Math"))

      expect_true(all(p$grade == course),
        info = paste("Grade mismatch for 2024", course))
    }
  }
})


# -- Science assessments (2019+) -----------------------------------------------

test_that("fetch_parcc science works for 2024 grades 5, 8, 11", {
  skip_on_cran()
  skip_if_offline()

  for (grade in c(5, 8, 11)) {
    p <- tryCatch(
      fetch_parcc(2024, grade, "science"),
      error = function(e) NULL
    )

    expect_false(is.null(p),
      info = paste("Science failed for 2024 grade", grade))

    if (!is.null(p)) {
      expect_true(nrow(p) > 0,
      info = paste("No rows for 2024 science grade", grade))

      # Science has 4 levels (L1-L4), not 5
      expect_true(all(is.na(p$pct_l5)),
        info = paste("Science should not have pct_l5 for grade", grade))
    }
  }
})

test_that("fetch_parcc science rejects invalid grades", {
  skip_on_cran()
  skip_if_offline()

  expect_error(fetch_parcc(2024, 3, "science"))
  expect_error(fetch_parcc(2024, 7, "science"))
})

test_that("fetch_parcc science rejects pre-2019 years", {
  skip_on_cran()
  skip_if_offline()

  expect_error(fetch_parcc(2018, 8, "science"))
})


# -- NJGPA (graduation proficiency assessment, 2022+) --------------------------

test_that("fetch_njgpa works for 2024 ELA", {
  skip_on_cran()
  skip_if_offline()

  njgpa <- fetch_njgpa(2024, "ela")

  expect_s3_class(njgpa, "data.frame")
  expect_gt(nrow(njgpa), 0)
  expect_true("proficient_above" %in% names(njgpa))
  expect_true(all(njgpa$assess_name == "NJGPA"))
  expect_true(all(njgpa$grade == "GP"))

  # NJGPA has only 2 performance levels
  expect_true(all(is.na(njgpa$pct_l3)))
  expect_true(all(is.na(njgpa$pct_l4)))
  expect_true(all(is.na(njgpa$pct_l5)))
})

test_that("fetch_njgpa works for 2024 Math", {
  skip_on_cran()
  skip_if_offline()

  njgpa <- fetch_njgpa(2024, "math")

  expect_s3_class(njgpa, "data.frame")
  expect_gt(nrow(njgpa), 0)
  expect_true(all(njgpa$assess_name == "NJGPA"))
})

test_that("fetch_njgpa rejects pre-2022 years", {
  expect_error(fetch_njgpa(2021, "ela"))
  expect_error(fetch_njgpa(2020, "math"))
})


# -- Suppression marker handling -----------------------------------------------

test_that("PARCC suppression markers produce NA not character values", {
  skip_on_cran()
  skip_if_offline()

  # Fetch a year with known suppression (small subgroups)
  p <- fetch_parcc(2024, 4, "ela")

  # Numeric columns should be numeric, not character
  expect_true(is.numeric(p$pct_l1))
  expect_true(is.numeric(p$pct_l2))
  expect_true(is.numeric(p$pct_l3))
  expect_true(is.numeric(p$pct_l4))
  expect_true(is.numeric(p$pct_l5))
  expect_true(is.numeric(p$number_enrolled))
  expect_true(is.numeric(p$scale_score_mean))

  # Suppressed values should be NA, not "*" or "N"
  expect_false(any(p$pct_l1 == "*", na.rm = TRUE))
  expect_false(any(p$pct_l1 == "N", na.rm = TRUE))
})


# -- Cross-year consistency (Grade 4 ELA) --------------------------------------

test_that("PARCC state enrollment is consistent across years (no wild swings)", {
  skip_on_cran()
  skip_if_offline()

  # NJ 4th grade enrollment should be in the 90k-110k range
  for (yr in c(2015, 2019, 2024)) {
    p <- fetch_parcc(yr, 4, "ela", tidy = TRUE)
    state <- p %>% dplyr::filter(is_state, subgroup == "total_population")

    expect_true(state$number_enrolled > 80000,
      info = paste("State enrollment suspiciously low in", yr))
    expect_true(state$number_enrolled < 120000,
      info = paste("State enrollment suspiciously high in", yr))
  }
})

test_that("PARCC proficient_above is between 0 and 100 (with rounding tolerance)", {
  skip_on_cran()
  skip_if_offline()

  p <- fetch_parcc(2024, 4, "ela", tidy = TRUE)

  valid_prof <- p$proficient_above[!is.na(p$proficient_above)]
  # Allow 0.5% tolerance for rounding (e.g., 43.8 + 56.3 = 100.1)
  expect_true(all(valid_prof >= 0 & valid_prof <= 100.5),
    info = "proficient_above values outside 0-100.5 range")
})
