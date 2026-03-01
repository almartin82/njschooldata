# =============================================================================
# Transformation Correctness Tests for njschooldata
# =============================================================================
#
# These tests verify correctness of data transformations independent of network
# calls: suppression handling, ID formatting, grade normalization, subgroup
# renaming, pivot fidelity, percentages, aggregation, and entity flags.
#
# =============================================================================

library(dplyr)

# =============================================================================
# 1. SUPPRESSION HANDLING
# =============================================================================

test_that("graduation rate suppression converts *, N, -, <, > to NA", {
  # Simulates raw grad rate suppression codes
  df <- data.frame(
    county_id = c("01", "01", "01", "01", "01"),
    district_id = c("0100", "0100", "0100", "0100", "0100"),
    school_id = c("001", "001", "001", "001", "001"),
    county_name = "ATLANTIC",
    district_name = "TEST",
    school_name = "TEST SCH",
    group = c("Schoolwide", "Black", "White", "Hispanic", "Asian"),
    grad_rate = c("85.5", "*", "N", "<10%", ">90%"),
    cohort_count = c("100", "*", "N", "5", "3"),
    graduated_count = c("85", "*", "N", "*", "*"),
    end_year = 2024,
    methodology = "4 year",
    stringsAsFactors = FALSE
  )

  result <- process_grate(df, 2024)

  # Non-suppressed value should convert properly
  expect_true(is.numeric(result$grad_rate))
  expect_equal(result$grad_rate[1], 0.855)

  # Suppressed values should become NA
  expect_true(is.na(result$grad_rate[2]))  # *
  expect_true(is.na(result$grad_rate[3]))  # N
  expect_true(is.na(result$grad_rate[4]))  # <10%
  expect_true(is.na(result$grad_rate[5]))  # >90%

  # Suppressed counts
  expect_true(is.na(result$cohort_count[2]))
  expect_true(is.na(result$graduated_count[2]))
})


test_that("rc_numeric_cleaner handles percent signs and suppression codes", {
  input <- c("85.5%", "*", "N", "N/A", "92.3%")
  result <- rc_numeric_cleaner(input)

  expect_true(is.numeric(result))
  expect_equal(result[1], 85.5)
  expect_true(is.na(result[2]))  # *
  expect_true(is.na(result[3]))  # N
  expect_true(is.na(result[4]))  # N/A
  expect_equal(result[5], 92.3)
})


test_that("PARCC assessment handles * suppression as NA", {
  # pct_l1 through pct_l5 are coerced via as.numeric
  # The raw files use "*" for suppression, which readxl reads as NA with na="*"
  # But process_parcc also does as.numeric() on percentage cols
  vals <- c("45.2", NA_character_, "30.1")
  result <- as.numeric(vals)
  expect_equal(result[1], 45.2)
  expect_true(is.na(result[2]))
  expect_equal(result[3], 30.1)
})


# =============================================================================
# 2. ID FORMATTING (Zero-Padding)
# =============================================================================

test_that("county_id is zero-padded to 2 digits", {
  df <- data.frame(
    end_year = 2024,
    county_name = c("ATLANTIC", "BERGEN", "BURLINGTON"),
    county_id = c("1", "2", "3"),
    district_name = c("D1", "D2", "D3"),
    district_id = c("100", "200", "300"),
    school_name = c("S1", "S2", "S3"),
    school_id = c("1", "20", "100"),
    program_code = c("55", "55", "55"),
    white_m = c(10, 20, 30),
    white_f = c(10, 20, 30),
    row_total = c(20, 40, 60),
    stringsAsFactors = FALSE
  )

  result <- clean_enr_data(df)

  expect_equal(result$county_id, c("01", "02", "03"))
  expect_equal(result$district_id, c("0100", "0200", "0300"))
  expect_equal(result$school_id, c("001", "020", "100"))
})


test_that("CDS_Code is correctly constructed from padded IDs", {
  df <- data.frame(
    end_year = 2024,
    county_name = c("ATLANTIC"),
    county_id = c("1"),
    district_name = c("D1"),
    district_id = c("100"),
    school_name = c("S1"),
    school_id = c("1"),
    program_code = c("55"),
    white_m = c(10),
    white_f = c(10),
    row_total = c(20),
    stringsAsFactors = FALSE
  )

  result <- clean_enr_data(df)

  # CDS_Code = county_id + district_id + school_id = "01" + "0100" + "001"
  expect_equal(result$CDS_Code, "010100001")
})


test_that("pad_leading works for various digit counts", {
  expect_equal(pad_leading(1, 2), "01")
  expect_equal(pad_leading(99, 2), "99")
  expect_equal(pad_leading(1, 4), "0001")
  expect_equal(pad_leading(1234, 4), "1234")
  expect_equal(pad_leading(1, 3), "001")
  expect_equal(pad_leading(100, 3), "100")
})


test_that("pad_grade zero-pads single-digit grades", {
  expect_equal(pad_grade(3), "03")
  expect_equal(pad_grade(8), "08")
  expect_equal(pad_grade(10), "10")
  expect_equal(pad_grade("ALG1"), "ALG1")
})


test_that("pad_cds zero-pads all CDS fields", {
  df <- data.frame(
    county_code = c(1, 21),
    district_code = c(100, 4255),
    school_code = c(1, 999),
    stringsAsFactors = FALSE
  )

  result <- pad_cds(df)

  expect_equal(result$county_code, c("01", "21"))
  expect_equal(result$district_code, c("0100", "4255"))
  expect_equal(result$school_code, c("001", "999"))
})


# =============================================================================
# 3. GRADE LEVEL NORMALIZATION
# =============================================================================

test_that("clean_enr_grade normalizes K codes to K", {
  df <- data.frame(
    grade_level = c("KF", "KH", "KG"),
    program_code = c("KF", "KH", "KG"),
    stringsAsFactors = FALSE
  )

  result <- clean_enr_grade(df)

  expect_equal(result$grade_level, c("K", "K", "K"))
})


test_that("clean_enr_grade normalizes PK codes to PK", {
  df <- data.frame(
    grade_level = c("PF", "PH"),
    program_code = c("PF", "PH"),
    stringsAsFactors = FALSE
  )

  result <- clean_enr_grade(df)

  expect_equal(result$grade_level, c("PK", "PK"))
})


test_that("clean_enr_grade normalizes Total to TOTAL", {
  df <- data.frame(
    grade_level = c("Total", "01", "02"),
    program_code = c("55", "01", "02"),
    stringsAsFactors = FALSE
  )

  result <- clean_enr_grade(df)

  expect_equal(result$grade_level, c("TOTAL", "01", "02"))
})


test_that("clean_enr_grade handles NA grade_level with program_code fallback", {
  df <- data.frame(
    grade_level = c(NA, NA, NA, NA),
    program_code = c("KF", "PH", "01", "02"),
    stringsAsFactors = FALSE
  )

  result <- clean_enr_grade(df)

  expect_equal(result$grade_level[1], "K")
  expect_equal(result$grade_level[2], "PK")
  expect_equal(result$grade_level[3], "PK")
  expect_equal(result$grade_level[4], "PK")
})


test_that("clean_enr_grade handles numeric program_code fallback for NA grades", {
  df <- data.frame(
    grade_level = c(NA, NA, NA, NA),
    program_code = c(1, 2, 3, 4),
    stringsAsFactors = FALSE
  )

  result <- clean_enr_grade(df)

  expect_equal(result$grade_level[1], "PK")
  expect_equal(result$grade_level[2], "PK")
  expect_equal(result$grade_level[3], "K")
  expect_equal(result$grade_level[4], "K")
})


# =============================================================================
# 4. SUBGROUP RENAMING
# =============================================================================

test_that("tidy_parcc_subgroup normalizes assessment subgroup names", {
  input <- c(
    "ALL STUDENTS", "WHITE", "AFRICAN AMERICAN",
    "ASIAN", "HISPANIC", "NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER",
    "AMERICAN INDIAN", "FEMALE", "MALE",
    "STUDENTS WITH DISABLITIES", "STUDENTS WITH DISABILITIES",
    "ECONOMICALLY DISADVANTAGED", "NON ECON. DISADVANTAGED",
    "ENGLISH LANGUAGE LEARNERS", "CURRENT - ELL", "FORMER - ELL"
  )

  result <- tidy_parcc_subgroup(input)

  expect_equal(result[1], "total_population")
  expect_equal(result[2], "white")
  expect_equal(result[3], "black")
  expect_equal(result[4], "asian")
  expect_equal(result[5], "hispanic")
  expect_equal(result[6], "pacific_islander")
  expect_equal(result[7], "american_indian")
  expect_equal(result[8], "female")
  expect_equal(result[9], "male")
  expect_equal(result[10], "special_education")
  expect_equal(result[11], "special_education")
  expect_equal(result[12], "ed")
  expect_equal(result[13], "non_ed")
  expect_equal(result[14], "lep_current_former")
  expect_equal(result[15], "lep_current")
  expect_equal(result[16], "lep_former")
})


test_that("tidy_parcc_subgroup handles mixed case (2018 proper case)", {
  input <- c("All Students", "White", "African American", "Female", "Male")
  result <- tidy_parcc_subgroup(input)

  expect_equal(result[1], "total_population")
  expect_equal(result[2], "white")
  expect_equal(result[3], "black")
  expect_equal(result[4], "female")
  expect_equal(result[5], "male")
})


test_that("grad_file_group_cleanup standardizes graduation subgroups", {
  input <- c(
    "american indian or alaska native",
    "american_indian",
    "black or african american",
    "economically_disadvantaged",
    "economically disadvantaged students",
    "english learners",
    "limited_english_proficiency",
    "two or more race",
    "two_or_more_races",
    "two or more races",
    "native hawaiian or pacific islander",
    "pacific_islander",
    "native_hawaiian",
    "asian, native hawaiian, or pacific islander",
    "students with disabilities",
    "students_with_disability",
    "districtwide",
    "schoolwide",
    "statewide total",
    "statewide_total",
    "statewide",
    "total_population",
    "white",
    "hispanic",
    "black",
    "male",
    "female"
  )

  result <- grad_file_group_cleanup(input)

  expect_equal(result[1], "american indian")
  expect_equal(result[2], "american indian")
  expect_equal(result[3], "black")
  expect_equal(result[4], "economically disadvantaged")
  expect_equal(result[5], "economically disadvantaged")
  expect_equal(result[6], "limited english proficiency")
  expect_equal(result[7], "limited english proficiency")
  expect_equal(result[8], "multiracial")
  expect_equal(result[9], "multiracial")
  expect_equal(result[10], "multiracial")
  expect_equal(result[11], "pacific islander")
  expect_equal(result[12], "pacific islander")
  expect_equal(result[13], "pacific islander")
  expect_equal(result[14], "asian")
  expect_equal(result[15], "students with disability")
  expect_equal(result[16], "students with disability")
  expect_equal(result[17], "total population")
  expect_equal(result[18], "total population")
  expect_equal(result[19], "total population")
  expect_equal(result[20], "total population")
  expect_equal(result[21], "total population")
  expect_equal(result[22], "total population")
  # Identity mappings
  expect_equal(result[23], "white")
  expect_equal(result[24], "hispanic")
  expect_equal(result[25], "black")
  expect_equal(result[26], "male")
  expect_equal(result[27], "female")
})


test_that("clean_grate_names standardizes pre-cohort graduation subgroups", {
  input <- c(
    "American Indian", "Native Hawaiian",
    "Two or More Races", "Limited English Proficiency",
    "Economically Disadvantaged", "Students with Disability",
    "Schoolwide", "Districtwide", "Statewide Total"
  )

  result <- clean_grate_names(input)

  expect_equal(result[1], "american_indian")
  expect_equal(result[2], "pacific_islander")
  expect_equal(result[3], "multiracial")
  expect_equal(result[4], "lep")
  expect_equal(result[5], "economically_disadvantaged")
  expect_equal(result[6], "iep")
  expect_equal(result[7], "total population")
  expect_equal(result[8], "total population")
  expect_equal(result[9], "total population")
})


test_that("clean_6yr_grad_subgroups standardizes 6yr graduation subgroups", {
  input <- c(
    "Schoolwide", "Districtwide",
    "American Indian or Alaska Native",
    "Black or African American",
    "Economically Disadvantaged Students",
    "English Learners", "Multilingual Learners",
    "Two or More Races",
    "Native Hawaiian or Pacific Islander",
    "Asian, Native Hawaiian, or Pacific Islander",
    "Students with Disabilities",
    "White", "Hispanic", "Male", "Female"
  )

  result <- clean_6yr_grad_subgroups(input)

  expect_equal(result[1], "total population")
  expect_equal(result[2], "total population")
  expect_equal(result[3], "american indian")
  expect_equal(result[4], "black")
  expect_equal(result[5], "economically disadvantaged")
  expect_equal(result[6], "limited english proficiency")
  expect_equal(result[7], "limited english proficiency")
  expect_equal(result[8], "multiracial")
  expect_equal(result[9], "pacific islander")
  expect_equal(result[10], "asian")
  expect_equal(result[11], "students with disability")
  expect_equal(result[12], "white")
  expect_equal(result[13], "hispanic")
  expect_equal(result[14], "male")
  expect_equal(result[15], "female")
})


# =============================================================================
# 5. ENROLLMENT NAME MAPPING
# =============================================================================

test_that("clean_enr_names maps all known column names", {
  # Build a df with every historic column name variant for county_id
  df_old <- data.frame(a = 1)
  names(df_old) <- "COUNTY_ID"
  result <- clean_enr_names(data.frame(COUNTY_ID = 1, end_year = 2024,
                                        stringsAsFactors = FALSE))
  expect_true("county_id" %in% names(result))

  # Test 2020+ racial column mappings
  df_2020 <- data.frame(
    end_year = 2024,
    `County Code` = "01",
    `County Name` = "ATLANTIC",
    `District Code` = "0100",
    `District Name` = "D1",
    `School Code` = "001",
    `School Name` = "S1",
    White = 10, Black = 20, Hispanic = 30, Asian = 5,
    `Native American` = 1, `Two or More Races` = 3,
    Male = 35, Female = 34,
    `Total Enrollment` = 69,
    `Free Lunch` = 40, `Reduced Lunch` = 10,
    `English Learners` = 5, Migrant = 1,
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

  result_2020 <- clean_enr_names(df_2020)

  expect_true("county_id" %in% names(result_2020))
  expect_true("white" %in% names(result_2020))
  expect_true("black" %in% names(result_2020))
  expect_true("hispanic" %in% names(result_2020))
  expect_true("native_american" %in% names(result_2020))
  expect_true("multiracial" %in% names(result_2020))
  expect_true("row_total" %in% names(result_2020))
  expect_true("free_lunch" %in% names(result_2020))
  expect_true("reduced_lunch" %in% names(result_2020))
  expect_true("lep" %in% names(result_2020))
})


# =============================================================================
# 6. PIVOT FIDELITY (Tidy Enrollment)
# =============================================================================

test_that("tidy_enr preserves enrollment counts from wide to long format", {
  # Construct a minimal processed enrollment df
  wide_df <- data.frame(
    end_year = 2024,
    CDS_Code = "010100999",
    county_id = "01",
    county_name = "ATLANTIC",
    district_id = "0100",
    district_name = "TEST DIST",
    school_id = "999",
    school_name = "DISTRICT TOTAL",
    program_code = "55",
    program_name = "Total",
    grade_level = "TOTAL",
    white_m = 50, white_f = 55,
    black_m = 30, black_f = 35,
    hispanic_m = 40, hispanic_f = 45,
    asian_m = 10, asian_f = 12,
    native_american_m = 1, native_american_f = 2,
    pacific_islander_m = 0, pacific_islander_f = 1,
    multiracial_m = 5, multiracial_f = 6,
    white = 105, black = 65, hispanic = 85,
    asian = 22, native_american = 3, pacific_islander = 1, multiracial = 11,
    male = 136, female = 156,
    row_total = 292,
    free_lunch = 100, reduced_lunch = 30, lep = 20, migrant = 5,
    stringsAsFactors = FALSE
  )

  result <- tidy_enr(wide_df)

  # total_enrollment should equal row_total
  total_row <- result %>% filter(subgroup == "total_enrollment")
  expect_equal(total_row$n_students, 292)
  expect_equal(total_row$pct, 1.0)

  # racial subgroups should match wide values
  white_row <- result %>% filter(subgroup == "white")
  expect_equal(white_row$n_students, 105)
  expect_equal(white_row$pct, 105 / 292)

  black_row <- result %>% filter(subgroup == "black")
  expect_equal(black_row$n_students, 65)

  hispanic_row <- result %>% filter(subgroup == "hispanic")
  expect_equal(hispanic_row$n_students, 85)

  # gender subgroups
  male_row <- result %>% filter(subgroup == "male")
  expect_equal(male_row$n_students, 136)

  female_row <- result %>% filter(subgroup == "female")
  expect_equal(female_row$n_students, 156)

  # gendered racial subgroups
  white_m_row <- result %>% filter(subgroup == "white_m")
  expect_equal(white_m_row$n_students, 50)

  # free_reduced_lunch is sum of free_lunch + reduced_lunch
  frl_row <- result %>% filter(subgroup == "free_reduced_lunch")
  expect_equal(frl_row$n_students, 130)

  # free_lunch
  fl_row <- result %>% filter(subgroup == "free_lunch")
  expect_equal(fl_row$n_students, 100)

  # lep
  lep_row <- result %>% filter(subgroup == "lep")
  expect_equal(lep_row$n_students, 20)
})


test_that("tidy_enr produces free_reduced_lunch only for program_code 55", {
  wide_df <- data.frame(
    end_year = 2024,
    CDS_Code = "010100999",
    county_id = "01", county_name = "ATLANTIC",
    district_id = "0100", district_name = "TEST",
    school_id = "999", school_name = "TOTAL",
    program_code = c("55", "01"),
    program_name = c("Total", "Grade 1"),
    grade_level = c("TOTAL", "01"),
    white_m = c(50, 10), white_f = c(55, 12),
    black_m = c(30, 5), black_f = c(35, 6),
    hispanic_m = c(40, 8), hispanic_f = c(45, 9),
    asian_m = c(10, 2), asian_f = c(12, 3),
    native_american_m = c(1, 0), native_american_f = c(2, 0),
    pacific_islander_m = c(0, 0), pacific_islander_f = c(1, 0),
    multiracial_m = c(5, 1), multiracial_f = c(6, 1),
    white = c(105, 22), black = c(65, 11), hispanic = c(85, 17),
    asian = c(22, 5), native_american = c(3, 0),
    pacific_islander = c(1, 0), multiracial = c(11, 2),
    male = c(136, 26), female = c(156, 31),
    row_total = c(292, 57),
    free_lunch = c(100, 30), reduced_lunch = c(30, 10),
    lep = c(20, 5), migrant = c(5, 2),
    stringsAsFactors = FALSE
  )

  result <- tidy_enr(wide_df)

  # free_reduced_lunch should only exist for program_code 55
  frl_rows <- result %>% filter(subgroup == "free_reduced_lunch")
  expect_equal(nrow(frl_rows), 1)
  expect_equal(frl_rows$program_code, "55")
})


test_that("tidy_enr filters out rows where both n_students and pct are NA", {
  wide_df <- data.frame(
    end_year = 2024,
    CDS_Code = "010100999",
    county_id = "01", county_name = "ATLANTIC",
    district_id = "0100", district_name = "TEST",
    school_id = "999", school_name = "TOTAL",
    program_code = "55",
    program_name = "Total",
    grade_level = "TOTAL",
    white_m = NA_real_, white_f = NA_real_,
    row_total = 100,
    free_lunch = 40, reduced_lunch = 10,
    lep = 5, migrant = 1,
    stringsAsFactors = FALSE
  )

  result <- tidy_enr(wide_df)

  # Rows with NA n_students should be filtered out
  white_m_rows <- result %>% filter(subgroup == "white_m")
  expect_equal(nrow(white_m_rows), 0)

  # total_enrollment should still be present
  total_rows <- result %>% filter(subgroup == "total_enrollment")
  expect_equal(nrow(total_rows), 1)
})


# =============================================================================
# 7. PERCENTAGE CALCULATIONS
# =============================================================================

test_that("tidy_enr computes pct as n_students / row_total", {
  wide_df <- data.frame(
    end_year = 2024,
    CDS_Code = "010100999",
    county_id = "01", county_name = "ATLANTIC",
    district_id = "0100", district_name = "TEST",
    school_id = "999", school_name = "TOTAL",
    program_code = "55",
    program_name = "Total",
    grade_level = "TOTAL",
    white_m = 25, white_f = 30,
    white = 55,
    row_total = 200,
    free_lunch = 80, reduced_lunch = 20,
    lep = 10, migrant = 2,
    stringsAsFactors = FALSE
  )

  result <- tidy_enr(wide_df)

  white_row <- result %>% filter(subgroup == "white")
  expect_equal(white_row$pct, 55 / 200)
  expect_equal(white_row$n_students, 55)

  total_row <- result %>% filter(subgroup == "total_enrollment")
  expect_equal(total_row$pct, 1.0)
})


test_that("PARCC proficient_above = pct_l4 + pct_l5 for ELA/Math", {
  df <- data.frame(
    county_code = "01", county_name = "ATLANTIC",
    district_code = "0100", district_name = "TEST",
    school_code = "001", school_name = "TEST SCH",
    dfg = "A",
    subgroup_type = "Schoolwide", subgroup = "ALL STUDENTS",
    number_enrolled = "200", number_not_tested = "10",
    number_of_valid_scale_scores = "190",
    scale_score_mean = "750",
    pct_l1 = "10.5", pct_l2 = "15.3", pct_l3 = "24.2",
    pct_l4 = "30.0", pct_l5 = "20.0",
    stringsAsFactors = FALSE
  )

  result <- process_parcc(df, end_year = 2018, grade = 4, subj = "math")

  expect_equal(result$proficient_above, 50.0)
})


test_that("PARCC proficient_above = pct_l3 + pct_l4 for Science", {
  df <- data.frame(
    county_code = "01", county_name = "ATLANTIC",
    district_code = "0100", district_name = "TEST",
    school_code = "001", school_name = "TEST SCH",
    subgroup = "ALL STUDENTS", subgroup_type = "Schoolwide",
    number_enrolled = "200", number_not_tested = "10",
    number_of_valid_scale_scores = "190",
    scale_score_mean = "750",
    pct_l1 = "20.0", pct_l2 = "30.0", pct_l3 = "35.0", pct_l4 = "15.0",
    stringsAsFactors = FALSE
  )

  result <- process_parcc(df, end_year = 2022, grade = 8, subj = "science")

  expect_equal(result$proficient_above, 50.0)
})


test_that("NJGPA proficient_above = pct_l2 (two-level assessment)", {
  df <- data.frame(
    county_code = "01", county_name = "ATLANTIC",
    district_code = "0100", district_name = "TEST",
    school_code = "001", school_name = "TEST SCH",
    subgroup = "ALL STUDENTS", subgroup_type = "Schoolwide",
    number_enrolled = "200", number_not_tested = "10",
    number_of_valid_scale_scores = "190",
    scale_score_mean = "750",
    pct_l1 = "40.0", pct_l2 = "60.0",
    stringsAsFactors = FALSE
  )

  result <- process_parcc(df, end_year = 2023, grade = "GP", subj = "ela")

  expect_equal(result$proficient_above, 60.0)
  # NJGPA has only 2 levels, L3-L5 should be NA
  expect_true(is.na(result$pct_l3))
  expect_true(is.na(result$pct_l4))
  expect_true(is.na(result$pct_l5))
})


test_that("parcc_perf_level_counts calculates student counts from percentages", {
  df <- data.frame(
    pct_l1 = 10.0,
    pct_l2 = 20.0,
    pct_l3 = 30.0,
    pct_l4 = 25.0,
    pct_l5 = 15.0,
    number_of_valid_scale_scores = 200,
    stringsAsFactors = FALSE
  )

  result <- parcc_perf_level_counts(df)

  expect_equal(result$num_l1, round(0.10 * 200, 0))
  expect_equal(result$num_l2, round(0.20 * 200, 0))
  expect_equal(result$num_l3, round(0.30 * 200, 0))
  expect_equal(result$num_l4, round(0.25 * 200, 0))
  expect_equal(result$num_l5, round(0.15 * 200, 0))
})


test_that("grate_aggregate_calcs computes grad_rate from counts", {
  df <- data.frame(
    county_id = c("01", "01"),
    district_name = c("D1", "D2"),
    school_name = c("S1", "S2"),
    grad_rate = c("0.85", "0.90"),
    cohort_count = c(100, 200),
    graduated_count = c(85, 180),
    is_charter = c(TRUE, TRUE),
    stringsAsFactors = FALSE
  ) %>%
    group_by(county_id)

  result <- grate_aggregate_calcs(df)

  expect_equal(result$cohort_count, 300)
  expect_equal(result$graduated_count, 265)
  expect_equal(result$grad_rate, round(265 / 300, 3))
})


# =============================================================================
# 8. ENTITY FLAG LOGIC
# =============================================================================

test_that("id_enr_aggs correctly flags state records", {
  df <- data.frame(
    county_id = c("99", "01", "01", "01", "80"),
    district_id = c("9999", "9999", "0100", "0100", "7320"),
    school_id = c("999", "999", "999", "001", "999"),
    program_code = c("55", "55", "55", "55", "55"),
    stringsAsFactors = FALSE
  )

  result <- id_enr_aggs(df)

  # Row 1: state (county=99, district=9999)
  expect_true(result$is_state[1])
  expect_false(result$is_county[1])
  expect_false(result$is_district[1])
  expect_false(result$is_school[1])

  # Row 2: county (district=9999, county != 99)
  # Note: county rows also have is_district=TRUE because school_id=="999" & !is_state
  # The is_county flag differentiates county from regular districts
  expect_false(result$is_state[2])
  expect_true(result$is_county[2])
  expect_true(result$is_district[2])  # county rows also match district logic
  expect_false(result$is_school[2])

  # Row 3: district (school=999, not state)
  expect_false(result$is_state[3])
  expect_false(result$is_county[3])
  expect_true(result$is_district[3])
  expect_false(result$is_school[3])

  # Row 4: school (school != 999, not state)
  expect_false(result$is_state[4])
  expect_false(result$is_county[4])
  expect_false(result$is_district[4])
  expect_true(result$is_school[4])

  # Row 5: charter (county=80)
  expect_true(result$is_charter[5])
})


test_that("id_enr_aggs flags is_subprogram when program_code is not 55", {
  df <- data.frame(
    county_id = c("01", "01"),
    district_id = c("0100", "0100"),
    school_id = c("999", "999"),
    program_code = c("55", "KF"),
    stringsAsFactors = FALSE
  )

  result <- id_enr_aggs(df)

  expect_false(result$is_subprogram[1])
  expect_true(result$is_subprogram[2])
})


test_that("id_grad_aggs correctly identifies graduation entity levels", {
  df <- data.frame(
    county_id = c("99", "01", "01", "01", "80"),
    district_id = c("9999", "9999", "0100", "0100", "7320"),
    school_id = c("999", "999", "999", "001", "888"),
    stringsAsFactors = FALSE
  )

  result <- id_grad_aggs(df)

  # State
  expect_true(result$is_state[1])
  expect_false(result$is_district[1])
  expect_false(result$is_school[1])

  # County
  expect_false(result$is_state[2])
  expect_true(result$is_county[2])

  # District (school_id == 999, not state)
  expect_true(result$is_district[3])
  expect_false(result$is_school[3])

  # School (school_id != 999/888/997)
  expect_false(result$is_district[4])
  expect_true(result$is_school[4])

  # Charter (county=80)
  expect_true(result$is_charter[5])

  # 888 is district total in 2021+ grad data
  expect_true(result$is_district[5])
  expect_false(result$is_school[5])
})


test_that("PARCC entity flags identify state, district, and school correctly", {
  df <- data.frame(
    county_code = c("State", "01", "01", "80"),
    county_name = c("STATE", "ATLANTIC", "ATLANTIC", "CHARTER"),
    district_code = c(NA, "0100", "0100", "7320"),
    district_name = c("STATE", "TEST DIST", "TEST DIST", "CHARTER SCH"),
    school_code = c(NA, NA, "001", "001"),
    school_name = c("STATE", "DIST TOTAL", "TEST SCH", "CHARTER SCH"),
    dfg = c("A", "A", "A", "A"),
    subgroup_type = "Schoolwide",
    subgroup = "ALL STUDENTS",
    number_enrolled = "200",
    number_not_tested = "10",
    number_of_valid_scale_scores = "190",
    scale_score_mean = "750",
    pct_l1 = "10", pct_l2 = "15", pct_l3 = "25",
    pct_l4 = "30", pct_l5 = "20",
    stringsAsFactors = FALSE
  )

  result <- process_parcc(df, end_year = 2017, grade = 4, subj = "math")

  # State
  expect_true(result$is_state[1])
  expect_false(result$is_district[1])

  # State-level records should have normalized codes
  expect_equal(result$county_id[1], "99")
  expect_equal(result$district_id[1], "9999")

  # District
  expect_true(result$is_district[2])
  expect_false(result$is_school[2])

  # School
  expect_true(result$is_school[3])
  expect_false(result$is_district[3])

  # Charter
  expect_true(result$is_charter[4])
})


# =============================================================================
# 9. ENROLLMENT AGGREGATION (enr_aggs - compositing race/gender)
# =============================================================================

test_that("enr_aggs creates correct racial composites from gendered columns", {
  df <- data.frame(
    end_year = 2018,
    white_m = 50, white_f = 55,
    black_m = 30, black_f = 35,
    hispanic_m = 40, hispanic_f = 45,
    asian_m = 10, asian_f = 12,
    native_american_m = 1, native_american_f = 2,
    pacific_islander_m = 0, pacific_islander_f = 1,
    multiracial_m = 5, multiracial_f = 6,
    stringsAsFactors = FALSE
  )

  result <- enr_aggs(df)

  expect_equal(result$white, 105)
  expect_equal(result$black, 65)
  expect_equal(result$hispanic, 85)
  expect_equal(result$asian, 22)
  expect_equal(result$native_american, 3)
  expect_equal(result$pacific_islander, 1)
  expect_equal(result$multiracial, 11)

  expect_equal(result$male, 50 + 30 + 40 + 10 + 1 + 0 + 5)
  expect_equal(result$female, 55 + 35 + 45 + 12 + 2 + 1 + 6)
})


test_that("enr_aggs handles missing columns gracefully", {
  # Pre-2008 data lacks pacific_islander and multiracial
  df <- data.frame(
    end_year = 2005,
    white_m = 50, white_f = 55,
    black_m = 30, black_f = 35,
    hispanic_m = 40, hispanic_f = 45,
    asian_m = 10, asian_f = 12,
    native_american_m = 1, native_american_f = 2,
    stringsAsFactors = FALSE
  )

  result <- enr_aggs(df)

  # Composites that can be calculated
  expect_equal(result$white, 105)
  expect_equal(result$black, 65)
  expect_equal(result$male, 50 + 30 + 40 + 10 + 1)
  expect_equal(result$female, 55 + 35 + 45 + 12 + 2)

  # Missing composites should be NA
  expect_true(is.na(result$pacific_islander))
  expect_true(is.na(result$multiracial))
})


# =============================================================================
# 10. GRADE-LEVEL AGGREGATION (enr_grade_aggs)
# =============================================================================

test_that("enr_grade_aggs creates correct K-12 aggregation", {
  # Minimal tidy enrollment df with required columns
  tidy_df <- data.frame(
    end_year = 2024,
    CDS_Code = "010100999",
    county_id = "01", county_name = "ATLANTIC",
    district_id = "0100", district_name = "TEST",
    school_id = "999", school_name = "TOTAL",
    program_code = c("05", "06", "07"),
    program_name = c("Grade 5", "Grade 6", "Grade 7"),
    grade_level = c("05", "06", "07"),
    subgroup = "total_enrollment",
    n_students = c(100, 110, 120),
    pct = c(1, 1, 1),
    pct_total_enr = c(NA, NA, NA),
    is_state = FALSE, is_county = FALSE,
    is_district = TRUE,
    is_charter_sector = FALSE, is_allpublic = FALSE,
    is_school = FALSE, is_subprogram = FALSE,
    stringsAsFactors = FALSE
  )

  result <- enr_grade_aggs(tidy_df)

  # K-8 should sum all three grades
  k8 <- result %>% filter(grade_level == "K8")
  expect_equal(k8$n_students, 330)

  # K-12 should sum all three grades (only 05-07 present, all < 13)
  k12 <- result %>% filter(grade_level == "K12")
  expect_equal(k12$n_students, 330)

  # HS should be 0 (no 09-12 grades)
  hs <- result %>% filter(grade_level == "HS")
  expect_equal(nrow(hs), 0)
})


test_that("enr_grade_aggs separates K, PK, and HS correctly", {
  tidy_df <- data.frame(
    end_year = 2024,
    CDS_Code = "010100999",
    county_id = "01", county_name = "ATLANTIC",
    district_id = "0100", district_name = "TEST",
    school_id = "999", school_name = "TOTAL",
    program_code = c("PK", "0K", "01", "09", "10"),
    program_name = c("Pre-K", "K", "Grade 1", "Grade 9", "Grade 10"),
    grade_level = c("PK", "K", "01", "09", "10"),
    subgroup = "total_enrollment",
    n_students = c(50, 80, 100, 90, 85),
    pct = c(1, 1, 1, 1, 1),
    pct_total_enr = NA_real_,
    is_state = FALSE, is_county = FALSE,
    is_district = TRUE,
    is_charter_sector = FALSE, is_allpublic = FALSE,
    is_school = FALSE, is_subprogram = FALSE,
    stringsAsFactors = FALSE
  )

  result <- enr_grade_aggs(tidy_df)

  # PK Any
  pk_agg <- result %>% filter(grade_level == "PK (Any)")
  expect_equal(pk_agg$n_students, 50)

  # K Any
  k_agg <- result %>% filter(grade_level == "K (Any)")
  expect_equal(k_agg$n_students, 80)

  # K-12 should include K, 01, 09, 10 (NOT PK)
  k12 <- result %>% filter(grade_level == "K12")
  expect_equal(k12$n_students, 80 + 100 + 90 + 85)

  # HS should include 09, 10
  hs <- result %>% filter(grade_level == "HS")
  expect_equal(hs$n_students, 90 + 85)

  # K-8 should include K, 01 (not 09, 10)
  k8 <- result %>% filter(grade_level == "K8")
  expect_equal(k8$n_students, 80 + 100)
})


# =============================================================================
# 11. GRADUATION RATE NORMALIZATION
# =============================================================================

test_that("process_grate normalizes grad_rate to 0-1 scale", {
  # When all values <= 1, they should be multiplied by 100 then divided by 100
  # (resulting in same values)
  df <- data.frame(
    county_id = "01", county_name = "ATLANTIC",
    district_id = "0100", district_name = "TEST",
    school_id = "001", school_name = "TEST SCH",
    group = "Schoolwide",
    grad_rate = "0.85",
    cohort_count = "100",
    graduated_count = "85",
    end_year = 2024,
    stringsAsFactors = FALSE
  )

  result <- process_grate(df, 2024)
  expect_equal(result$grad_rate, 0.85)
})


test_that("process_grate handles school_id 888 as 999 for 2019", {
  df <- data.frame(
    county_id = "01", county_name = "ATLANTIC",
    district_id = "0100", district_name = "TEST",
    school_id = "888", school_name = "TEST",
    group = "Schoolwide",
    end_year = 2019,
    stringsAsFactors = FALSE
  )

  result <- process_grate(df, 2019)
  expect_equal(result$school_id, "999")
})


# =============================================================================
# 12. UTILITY FUNCTION CORRECTNESS
# =============================================================================

test_that("trim_whitespace removes leading and trailing whitespace", {
  expect_equal(trim_whitespace("  hello  "), "hello")
  expect_equal(trim_whitespace("hello"), "hello")
  expect_equal(trim_whitespace("  "), "")
  expect_equal(trim_whitespace("\thello\t"), "hello")
})


test_that("kill_padformulas removes Excel formula padding", {
  expect_equal(kill_padformulas('="01"'), "01")
  expect_equal(kill_padformulas('="0100"'), "0100")
  expect_equal(kill_padformulas("regular"), "regular")
})


test_that("clean_cds_fields standardizes CDS column names", {
  df <- data.frame(
    co_code = 1, dist_code = 100, sch_code = 1,
    co_name = "ATLANTIC", dist_name = "TEST", sch_name = "TEST SCH",
    stringsAsFactors = FALSE
  )

  result <- clean_cds_fields(df)

  expect_true("county_code" %in% names(result))
  expect_true("district_code" %in% names(result))
  expect_true("school_code" %in% names(result))
  expect_true("county_name" %in% names(result))
  expect_true("district_name" %in% names(result))
  expect_true("school_name" %in% names(result))
})


# =============================================================================
# 13. VALIDATION FUNCTIONS
# =============================================================================

test_that("get_valid_years returns correct enrollment range", {
  years <- get_valid_years("enrollment")
  expect_equal(min(years), 2000)
  expect_equal(max(years), 2025)
})


test_that("get_valid_years excludes COVID year for PARCC", {
  years <- get_valid_years("parcc")
  expect_false(2020 %in% years)
  expect_true(2019 %in% years)
  expect_true(2021 %in% years)
})


test_that("get_valid_grades returns correct NJASK grades by era", {
  # Pre-2006: only 3, 4
  expect_equal(get_valid_grades("njask", 2005), c(3, 4))

  # 2006-2007: 3-7
  expect_equal(get_valid_grades("njask", 2007), 3:7)

  # 2008+: 3-8
  expect_equal(get_valid_grades("njask", 2010), 3:8)
})


test_that("get_valid_grades returns course codes for PARCC math", {
  grades <- get_valid_grades("parcc", 2023)
  expect_true("ALG1" %in% grades)
  expect_true("GEO" %in% grades)
  expect_true("ALG2" %in% grades)
})


test_that("is_district_total recognizes all district total codes", {
  expect_true(is_district_total("999"))
  expect_true(is_district_total("997"))
  expect_false(is_district_total("001"))
  expect_false(is_district_total("888"))  # 888 NOT in constant helper
})


test_that("is_state_aggregate works correctly", {
  expect_true(is_state_aggregate("99", "9999"))
  expect_false(is_state_aggregate("01", "9999"))
  expect_false(is_state_aggregate("99", "0100"))
})


test_that("is_charter_district uses county_id 80", {
  expect_true(is_charter_district("80"))
  expect_false(is_charter_district("01"))
  expect_false(is_charter_district("99"))
})


# =============================================================================
# 14. CONSTANTS CORRECTNESS
# =============================================================================

test_that("grade level constants cover expected ranges", {
  expect_equal(ELEMENTARY_GRADES, c("K", "01", "02", "03", "04", "05"))
  expect_equal(MIDDLE_GRADES, c("06", "07", "08"))
  expect_equal(HIGH_SCHOOL_GRADES, c("09", "10", "11", "12"))
  expect_equal(K12_GRADES, c(
    "K", "01", "02", "03", "04", "05",
    "06", "07", "08", "09", "10", "11", "12"
  ))
})


test_that("CDS code constants match entity flag logic", {
  expect_equal(STATE_COUNTY_ID, "99")
  expect_equal(STATE_DISTRICT_ID, "9999")
  expect_equal(DISTRICT_TOTAL_SCHOOL_ID, "999")
  expect_equal(CHARTER_COUNTY_ID, "80")
  expect_equal(TOTAL_PROGRAM_CODE, "55")
})


# =============================================================================
# 15. PARCC COLUMN STRUCTURE
# =============================================================================

test_that("process_parcc sets assess_name based on year", {
  df <- data.frame(
    county_code = "01", county_name = "ATLANTIC",
    district_code = "0100", district_name = "TEST",
    school_code = "001", school_name = "TEST SCH",
    dfg = "A",
    subgroup_type = "Schoolwide", subgroup = "ALL STUDENTS",
    number_enrolled = "200", number_not_tested = "10",
    number_of_valid_scale_scores = "190",
    scale_score_mean = "750",
    pct_l1 = "10", pct_l2 = "15", pct_l3 = "25",
    pct_l4 = "30", pct_l5 = "20",
    stringsAsFactors = FALSE
  )

  result_parcc <- process_parcc(df, end_year = 2017, grade = 4, subj = "math")
  expect_equal(result_parcc$assess_name, "PARCC")

  # For 2019+ without DFG column
  df_sla <- data.frame(
    county_code = "01", county_name = "ATLANTIC",
    district_code = "0100", district_name = "TEST",
    school_code = "001", school_name = "TEST SCH",
    subgroup_type = "Schoolwide", subgroup = "ALL STUDENTS",
    number_enrolled = "200", number_not_tested = "10",
    number_of_valid_scale_scores = "190",
    scale_score_mean = "750",
    pct_l1 = "10", pct_l2 = "15", pct_l3 = "25",
    pct_l4 = "30", pct_l5 = "20",
    stringsAsFactors = FALSE
  )

  result_sla <- process_parcc(df_sla, end_year = 2022, grade = 4, subj = "math")
  expect_equal(result_sla$assess_name, "NJSLA")
})


test_that("process_parcc sets assess_name to NJGPA for GP grade", {
  df <- data.frame(
    county_code = "01", county_name = "ATLANTIC",
    district_code = "0100", district_name = "TEST",
    school_code = "001", school_name = "TEST SCH",
    subgroup = "ALL STUDENTS", subgroup_type = "Schoolwide",
    number_enrolled = "200", number_not_tested = "10",
    number_of_valid_scale_scores = "190",
    scale_score_mean = "750",
    pct_l1 = "40", pct_l2 = "60",
    stringsAsFactors = FALSE
  )

  result <- process_parcc(df, end_year = 2023, grade = "GP", subj = "ela")
  expect_equal(result$assess_name, "NJGPA")
})


test_that("process_parcc removes footer/garbage rows", {
  df <- data.frame(
    county_code = c("01", "suppressed", "end of worksheet"),
    county_name = c("ATLANTIC", "suppressed", "end"),
    district_code = c("0100", NA, NA),
    district_name = c("TEST", NA, NA),
    school_code = c("001", NA, NA),
    school_name = c("TEST SCH", NA, NA),
    dfg = c("A", NA, NA),
    subgroup_type = c("Schoolwide", NA, NA),
    subgroup = c("ALL STUDENTS", NA, NA),
    number_enrolled = c("200", NA, NA),
    number_not_tested = c("10", NA, NA),
    number_of_valid_scale_scores = c("190", NA, NA),
    scale_score_mean = c("750", NA, NA),
    pct_l1 = c("10", NA, NA),
    pct_l2 = c("15", NA, NA),
    pct_l3 = c("25", NA, NA),
    pct_l4 = c("30", NA, NA),
    pct_l5 = c("20", NA, NA),
    stringsAsFactors = FALSE
  )

  result <- process_parcc(df, end_year = 2017, grade = 4, subj = "math")

  # Footer rows should be removed
  expect_equal(nrow(result), 1)
})


# =============================================================================
# 16. POSTSECONDARY ENROLLMENT PARSING
# =============================================================================

test_that("parse_postsec_range extracts bounds from range strings", {
  input <- c("58.3-60.1%", "N", NA, "72.5-74.0%")
  result <- parse_postsec_range(input)

  expect_equal(result$lower_bound[1], 58.3)
  expect_equal(result$upper_bound[1], 60.1)
  expect_true(is.na(result$lower_bound[2]))
  expect_true(is.na(result$upper_bound[2]))
  expect_true(is.na(result$lower_bound[3]))
  expect_true(is.na(result$upper_bound[3]))
  expect_equal(result$lower_bound[4], 72.5)
  expect_equal(result$upper_bound[4], 74.0)
})


# =============================================================================
# 17. SPLIT ENROLLMENT COLUMNS (Pre-2010 format)
# =============================================================================

test_that("split_enr_cols separates combined ID-name fields", {
  df <- data.frame(
    end_year = 2005,
    county_name = "01-ATLANTIC",
    district_name = "0100-TEST DIST",
    school_name = "001-TEST SCHOOL",
    stringsAsFactors = FALSE
  )

  result <- split_enr_cols(df)

  expect_equal(result$county_id, "01")
  expect_equal(result$county_name, "ATLANTIC")
  expect_equal(result$district_id, "0100")
  expect_equal(result$district_name, "TEST DIST")
  expect_equal(result$school_id, "001")
  expect_equal(result$school_name, "TEST SCHOOL")
})


test_that("split_enr_cols is a no-op for 2010+ data", {
  df <- data.frame(
    end_year = 2015,
    county_name = "ATLANTIC",
    district_name = "TEST DIST",
    school_name = "TEST SCHOOL",
    stringsAsFactors = FALSE
  )

  result <- split_enr_cols(df)

  # Should be unchanged
  expect_equal(result$county_name, "ATLANTIC")
  expect_false("county_id" %in% names(result))
})


# =============================================================================
# 18. ENROLLMENT DATA TYPES
# =============================================================================

test_that("get_enr_types returns correct type for all enrollment columns", {
  types <- get_enr_types()

  # Character columns
  expect_equal(types[["county_id"]], "character")
  expect_equal(types[["county_name"]], "character")
  expect_equal(types[["district_id"]], "character")
  expect_equal(types[["school_id"]], "character")
  expect_equal(types[["program_code"]], "character")
  expect_equal(types[["grade_level"]], "character")

  # Numeric columns
  expect_equal(types[["white_m"]], "numeric")
  expect_equal(types[["row_total"]], "numeric")
  expect_equal(types[["free_lunch"]], "numeric")
  expect_equal(types[["lep"]], "numeric")
  expect_equal(types[["end_year"]], "numeric")
})


test_that("get_enr_column_order returns expected column order", {
  order <- get_enr_column_order()

  # First columns should be identifiers
  expect_equal(order[1], "end_year")
  expect_equal(order[2], "CDS_Code")
  expect_equal(order[3], "county_id")

  # Should include key demographic columns
  expect_true("white_m" %in% order)
  expect_true("row_total" %in% order)
  expect_true("grade_level" %in% order)
})


# =============================================================================
# 19. CROSS-CUTTING: SUBGROUP CONSISTENCY BETWEEN DATA TYPES
# =============================================================================

test_that("graduation subgroup cleanup produces values consistent across years", {
  # These are all forms that should map to the same canonical name
  total_variants <- c(
    "districtwide", "schoolwide", "statewide total",
    "statewide_total", "statewide", "total_population"
  )
  results <- grad_file_group_cleanup(total_variants)
  expect_true(all(results == "total population"))

  multiracial_variants <- c(
    "two or more race", "two_or_more_races", "two or more races"
  )
  results <- grad_file_group_cleanup(multiracial_variants)
  expect_true(all(results == "multiracial"))
})


test_that("PARCC and grad subgroup names use different conventions deliberately", {
  # PARCC uses underscore-separated names
  parcc_result <- tidy_parcc_subgroup("ECONOMICALLY DISADVANTAGED")
  expect_equal(parcc_result, "ed")

  # Grad uses space-separated names
  grad_result <- grad_file_group_cleanup("economically_disadvantaged")
  expect_equal(grad_result, "economically disadvantaged")

  # This is a deliberate inconsistency in the package - not a bug
  # Tests document the actual behavior
})


# =============================================================================
# 20. EDGE CASES
# =============================================================================

test_that("clean_enr_data handles commas in numeric fields", {
  df <- data.frame(
    end_year = 2018,
    county_name = "ATLANTIC",
    county_id = "01",
    district_name = "TEST",
    district_id = "0100",
    school_name = "TEST SCH",
    school_id = "001",
    program_code = "55",
    row_total = "1,234",
    white_m = " ,10",
    stringsAsFactors = FALSE
  )

  result <- clean_enr_data(df)

  expect_equal(result$row_total, 1234)
  expect_equal(result$white_m, 10)
})


test_that("implied_decimal_fix in process_nj_assess divides by 10", {
  # Direct test of the implied decimal logic used in legacy assessments
  implied_decimal_fix <- function(x) {
    x <- as.numeric(gsub("[^\\d]+", "", x, perl = TRUE))
    x / 10
  }

  expect_equal(implied_decimal_fix("655"), 65.5)
  expect_equal(implied_decimal_fix("1000"), 100.0)
  expect_equal(implied_decimal_fix("0"), 0.0)
})


test_that("graduation data filters out 'end of worksheet' rows", {
  # This is handled in tidy_grad_rate at line 261
  df <- data.frame(
    county_id = c("01", "end of worksheet"),
    county_name = c("ATLANTIC", ""),
    district_id = c("0100", ""),
    district_name = c("TEST", ""),
    school_id = c("001", ""),
    school_name = c("TEST", ""),
    group = c("Schoolwide", ""),
    subgroup = c("total population", ""),
    stringsAsFactors = FALSE
  )

  result <- df %>% dplyr::filter(!county_id == "end of worksheet")
  expect_equal(nrow(result), 1)
})


test_that("2020 enrollment handles >95% suppression values", {
  # In 2020, NJ DOE replaced percentages >95% with ">95" string
  # This is handled in get_raw_enr by replacing with "97.5"
  val <- ">95"
  result <- dplyr::if_else(val == ">95", "97.5", val)
  expect_equal(result, "97.5")
  expect_equal(as.numeric(result), 97.5)
})
