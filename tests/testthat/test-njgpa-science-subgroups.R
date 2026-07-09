# ==============================================================================
# NJGPA / Science subgroup column semantics
# ==============================================================================
#
# In the raw NJGPA and Science Excel files the 7th column ("Subgroup") holds the
# CATEGORY (Total / Race/Ethnicity / Gender / Subgroup) and the 8th column
# ("Subgroup Type") holds the actual student group (All Students / White / ...).
# The ELA/Math files have the same order and process_parcc already swapped them
# there; the NJGPA and Science branches used to map them un-swapped, so
# `subgroup` carried category labels and every district/school row was
# unusable by subgroup-keyed consumers. These tests pin the corrected mapping
# with synthetic raw frames (no network).

make_raw_gp <- function() {
  tibble::tibble(
    c1 = c("01", "01"),
    c2 = c("Atlantic", "Atlantic"),
    c3 = c("0110", "0110"),
    c4 = c("Atlantic City School District", "Atlantic City School District"),
    c5 = c(NA_character_, NA_character_),
    c6 = c("District Total", "District Total"),
    c7 = c("Total", "Race/Ethnicity"),          # category
    c8 = c("All Students", "African American"), # actual student group
    c9 = c("500", "120"),
    c10 = c("21", "10"),
    c11 = c("479", "110"),
    c12 = c("725", "710"),
    c13 = c("52.8", "67.9"),
    c14 = c("47.2", "32.1")
  )
}

make_raw_science <- function() {
  dplyr::bind_cols(
    make_raw_gp()[, 1:12],
    tibble::tibble(c13 = c("30", "40"), c14 = c("30", "35"),
                   c15 = c("25", "15"), c16 = c("15", "10"))
  )
}

test_that("process_parcc puts the NJGPA student group in `subgroup`", {
  p <- njschooldata:::process_parcc(make_raw_gp(), 2024, grade = "GP", subj = "ela")
  expect_setequal(unique(p$subgroup), c("All Students", "African American"))
  expect_setequal(unique(p$subgroup_type), c("Total", "Race/Ethnicity"))
  # district rows (school code NA) are flagged and keyed by real subgroups
  expect_true(all(p$is_district))
  # NJGPA proficiency = L2
  expect_equal(p$proficient_above, c(47.2, 32.1))
})

test_that("process_parcc puts the Science student group in `subgroup`", {
  p <- njschooldata:::process_parcc(make_raw_science(), 2024, grade = 8, subj = "science")
  expect_setequal(unique(p$subgroup), c("All Students", "African American"))
  expect_setequal(unique(p$subgroup_type), c("Total", "Race/Ethnicity"))
  # science proficiency = L3 + L4
  expect_equal(p$proficient_above, c(40, 25))
})

test_that("tidy_parcc_subgroup standardizes NJGPA/Science and 2024-25 labels", {
  expect_equal(tidy_parcc_subgroup("All Students"), "total_population")
  expect_equal(tidy_parcc_subgroup("Black or African American"), "black")
  expect_equal(tidy_parcc_subgroup("African American"), "black")
  expect_equal(tidy_parcc_subgroup("Multilingual Learners"), "lep_current_former")
  expect_equal(tidy_parcc_subgroup("Current - Ml"), "lep_current")
  expect_equal(tidy_parcc_subgroup("Former - Ml"), "lep_former")
  expect_equal(tidy_parcc_subgroup("English Language Learners"), "lep_current_former")
  expect_equal(tidy_parcc_subgroup("Non-Binary/Undesignated"), "nonbinary_undesignated")
  expect_equal(tidy_parcc_subgroup("SE Accommodation"), "sped_accomodations")
})

test_that("fetch_njgpa returns district rows keyed by standardized subgroups", {
  skip_on_cran()
  skip_if_offline()
  g <- tryCatch(fetch_njgpa(2024, "ela", tidy = TRUE), error = function(e) NULL)
  skip_if(is.null(g), "NJ DOE NJGPA source unreachable")
  dist_total <- g[!is.na(g$is_district) & g$is_district &
                    g$subgroup == "total_population", ]
  expect_gt(nrow(dist_total), 300)
  # Pinned: Atlantic City (0110) district ELA graduation-ready
  ac <- dist_total[dist_total$district_id == "0110", ]
  expect_equal(ac$number_of_valid_scale_scores[1], 479)
  expect_equal(ac$proficient_above[1], 47.2, tolerance = 0.01)
})

test_that("fetch_njgpa reaches the first (2021-22) administration", {
  skip_on_cran()
  skip_if_offline()
  g <- tryCatch(fetch_njgpa(2022, "ela", tidy = TRUE), error = function(e) NULL)
  skip_if(is.null(g), "NJ DOE NJGPA source unreachable")
  expect_gt(sum(g$is_district & g$subgroup == "total_population", na.rm = TRUE), 300)
})

test_that("fetch_math_course_enrollment normalizes grades and masks to NA", {
  skip_on_cran()
  skip_if_offline()
  m <- tryCatch(fetch_math_course_enrollment(2025, "district"),
                error = function(e) NULL)
  skip_if(is.null(m), "NJ DOE SPR source unreachable")
  expect_true(is.numeric(m$algebra_i))
  expect_true("8" %in% m$grade)
  expect_false(any(grepl("^Grade", m$grade)))
  # summary rows preserved
  expect_true("Total" %in% m$grade)
})
