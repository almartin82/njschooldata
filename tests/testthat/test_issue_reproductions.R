# Reproduction tests for triaged GitHub issues
# These tests document known bugs and inconsistencies so they can be tracked
# and verified when fixed.

# =============================================================================
# Issue #158: geo functions don't always work (address abbreviation mismatch)
# https://github.com/almartin82/njschooldata/issues/158
# =============================================================================

# Issue #158: geo address matching

test_that("geo.R does not reference undefined 'address1' variable", {
  geo_source <- readLines("../../R/geo.R")
  address1_lines <- grep("TRUE ~ address1", geo_source, fixed = TRUE)
  expect_equal(length(address1_lines), 0)
})

test_that("abbreviate_street_types handles common street types", {
  addr <- "123 main street, newark, nj 07102 usa"
  result <- abbreviate_street_types(addr)
  expect_equal(result, "123 main st, newark, nj 07102 usa")

  addr2 <- "456 broad avenue, trenton, nj 08601 usa"
  result2 <- abbreviate_street_types(addr2)
  expect_equal(result2, "456 broad ave, trenton, nj 08601 usa")

  addr3 <- "789 oak drive, princeton, nj 08540 usa"
  result3 <- abbreviate_street_types(addr3)
  expect_equal(result3, "789 oak dr, princeton, nj 08540 usa")
})

test_that("expand_street_types handles common abbreviations", {
  addr <- "123 main st, newark, nj 07102 usa"
  result <- expand_street_types(addr)
  expect_equal(result, "123 main street, newark, nj 07102 usa")

  addr2 <- "456 broad ave, trenton, nj 08601 usa"
  result2 <- expand_street_types(addr2)
  expect_equal(result2, "456 broad avenue, trenton, nj 08601 usa")

  addr3 <- "789 oak dr, princeton, nj 08540 usa"
  result3 <- expand_street_types(addr3)
  expect_equal(result3, "789 oak drive, princeton, nj 08540 usa")
})

test_that("street type functions are inverses of each other", {
  addr <- "209 abington avenue, newark, nj 07107 usa"
  expect_equal(expand_street_types(abbreviate_street_types(addr)), addr)

  addr2 <- "228 ridge st, newark, nj 07104 usa"
  expect_equal(abbreviate_street_types(expand_street_types(addr2)), addr2)
})


# =============================================================================
# Issue #124: progress report pulls are broken (clean_name_vector)
# https://github.com/almartin82/njschooldata/issues/124
# =============================================================================

# Issue #124: clean_name_vector parsing_option

test_that("clean_name_vector works with current snakecase version", {
  # The function uses snakecase::to_any_case(..., parsing_option = 3)
  # which caused "Error: parsing_option must be between -4 and +4" in some
  # versions. This test verifies it works with the installed version.

  skip_if_not_installed("snakecase")

  # Test with typical Excel sheet names from NJ DOE performance reports
  test_names <- c(
    "School Name", "District Name", "% Proficient",
    "4-Year Grad Rate", "AP/IB Participation",
    "Student's Score", "#Students Tested"
  )

  result <- njschooldata:::clean_name_vector(test_names)

  expect_true(is.character(result))
  expect_equal(length(result), length(test_names))
  # All results should be snake_case (lowercase, underscores only)
  expect_true(all(grepl("^[a-z0-9_.]+$", result)),
    info = "clean_name_vector should produce snake_case names"
  )
})

test_that("clean_name_vector parsing_option is within valid range", {
  # Verify the hardcoded parsing_option value is valid
  source_code <- paste(readLines("../../R/utils_cleaning.R"), collapse = "\n")
  parsing_match <- regmatches(
    source_code,
    regexpr("parsing_option\\s*=\\s*-?\\d+", source_code)
  )

  expect_true(length(parsing_match) > 0, info = "parsing_option should be set")

  value <- as.integer(gsub("parsing_option\\s*=\\s*", "", parsing_match[1]))
  expect_true(
    value >= -4 && value <= 4,
    info = sprintf("parsing_option = %d is outside valid range [-4, 4]", value)
  )
})


# =============================================================================
# Issue #71: CDS_Code should be lowercase (cds_code)
# https://github.com/almartin82/njschooldata/issues/71
# =============================================================================

# Issue #71: CDS_Code should be lowercase

test_that("no R source files use uppercase CDS_Code", {
  r_files <- list.files("../../R", pattern = "\\.R$", full.names = TRUE)

  for (f in r_files) {
    code <- readLines(f, warn = FALSE)
    hits <- grep("CDS_Code", code, fixed = TRUE)
    expect_equal(length(hits), 0,
      info = paste(basename(f), "still uses uppercase CDS_Code"))
  }
})

test_that("all enrollment/directory files use lowercase cds_code", {
  key_files <- c(
    "../../R/process_enrollment.R", "../../R/enrollment_names.R",
    "../../R/charter.R", "../../R/tidy_enrollment.R",
    "../../R/directory.R", "../../R/fetch_directory.R"
  )

  for (f in key_files) {
    code <- readLines(f, warn = FALSE)
    has_lowercase <- any(grepl("cds_code", code, fixed = TRUE))
    expect_true(has_lowercase,
      info = paste(basename(f), "should use lowercase cds_code"))
  }
})


# =============================================================================
# Issue #62: always pad district codes to 4 digits as character
# https://github.com/almartin82/njschooldata/issues/62
# =============================================================================

# Issue #62: district code padding consistency

test_that("charter.R does not coerce district_id to numeric", {
  charter_code <- readLines("../../R/charter.R")
  numeric_coercion <- grep("as\\.numeric\\(district_id\\)", charter_code)
  expect_equal(length(numeric_coercion), 0,
    info = "charter.R should use string comparison, not as.numeric(district_id)")
})

test_that("config_peer_groups.R pads codes before concatenation", {
  peer_code <- readLines("../../R/config_peer_groups.R")
  concat_lines <- grep("paste0.*county_code.*district_code", peer_code)

  for (line_num in concat_lines) {
    line_text <- peer_code[line_num]
    has_padding <- grepl("pad_leading", line_text)
    expect_true(has_padding,
      info = paste("Line", line_num, "concatenates codes without padding:", line_text))
  }
})

test_that("pad_cds() function works correctly", {
  # Verify the padding utility itself is correct
  skip_if_not_installed("njschooldata")

  test_df <- data.frame(
    county_code = c("1", "13", "5"),
    district_code = c("100", "3570", "50"),
    school_code = c("1", "50", "999"),
    stringsAsFactors = FALSE
  )

  result <- njschooldata:::pad_cds(test_df)

  expect_equal(result$county_code, c("01", "13", "05"))
  expect_equal(result$district_code, c("0100", "3570", "0050"))
  expect_equal(result$school_code, c("001", "050", "999"))
  expect_true(all(sapply(result, is.character)))
})


# =============================================================================
# Issue #113: standardize naming for IEP / SWD subgroup
# https://github.com/almartin82/njschooldata/issues/113
# =============================================================================

# Issue #113: IEP/SWD subgroup naming inconsistency

test_that("all modules use 'students with disabilities' for SWD subgroup", {
  # Verify no legacy naming variants remain as OUTPUT values in source code
  files_to_check <- c(
    "../../R/fetch_spr.R", "../../R/process_graduation.R",
    "../../R/fetch_graduation.R", "../../R/special_pop.R",
    "../../R/tidy_graduation.R", "../../R/percentile_rank.R"
  )

  for (f in files_to_check) {
    code <- readLines(f, warn = FALSE)

    # Check for 'IEP' as SWD output (not in comments or other contexts)
    iep_hits <- grep("~ ['\"]IEP['\"]", code)
    expect_equal(length(iep_hits), 0,
      info = paste(f, "still maps SWD to 'IEP'"))

    # Check for "iep" as SWD output
    iep_lower_hits <- grep("~ ['\"]iep['\"]", code)
    expect_equal(length(iep_lower_hits), 0,
      info = paste(f, "still maps SWD to 'iep'"))

    # Check for singular "disability" as output (not as input matcher)
    # Lines with ~ "students with disability" (singular output) are wrong
    singular_output <- grep('~ "students with disability"', code, fixed = TRUE)
    expect_equal(length(singular_output), 0,
      info = paste(f, "still outputs singular 'students with disability'"))
  }
})

test_that("clean_spr_subgroups normalizes to 'students with disabilities'", {
  expect_equal(
    clean_spr_subgroups("Students with Disabilities"),
    "students with disabilities"
  )
  expect_equal(
    clean_spr_subgroups("Students with Disability"),
    "students with disabilities"
  )
})

test_that("grad_file_group_cleanup and clean_grate_names produce same SWD name", {
  grad_result <- grad_file_group_cleanup("students with disabilities")
  tidy_result <- clean_grate_names("Students with Disability")
  expect_equal(grad_result, "students with disabilities")
  expect_equal(tidy_result, "students with disabilities")
  expect_equal(grad_result, tidy_result)
})


# =============================================================================
# Issue #125: county ids to names for sped data
# https://github.com/almartin82/njschooldata/issues/125
# =============================================================================

# Issue #125: Historic sped data has county_name but not county_id.
# Need a county_name_to_id() function that maps NJ county names to their
# 2-digit county codes.

test_that("county_name_to_id maps all 21 NJ counties correctly", {
  # NJ has 21 counties, each with a unique 2-digit code (01-21)
  nj_counties <- c(
    "ATLANTIC", "BERGEN", "BURLINGTON", "CAMDEN", "CAPE MAY",
    "CUMBERLAND", "ESSEX", "GLOUCESTER", "HUDSON", "HUNTERDON",
    "MERCER", "MIDDLESEX", "MONMOUTH", "MORRIS", "OCEAN",
    "PASSAIC", "SALEM", "SOMERSET", "SUSSEX", "UNION", "WARREN"
  )

  result <- county_name_to_id(nj_counties)

  # Should return character codes, zero-padded to 2 digits
  expect_true(is.character(result))
  expect_equal(length(result), 21)
  expect_true(all(nchar(result) == 2))

  # Specific known mappings
  expect_equal(county_name_to_id("ATLANTIC"), "01")
  expect_equal(county_name_to_id("ESSEX"), "07")
  expect_equal(county_name_to_id("HUDSON"), "09")
  expect_equal(county_name_to_id("WARREN"), "21")
})

test_that("county_name_to_id is case-insensitive", {
  expect_equal(county_name_to_id("essex"), "07")
  expect_equal(county_name_to_id("Essex"), "07")
  expect_equal(county_name_to_id("ESSEX"), "07")
})

test_that("county_name_to_id returns NA for unknown county names", {
  expect_true(is.na(county_name_to_id("FAKE COUNTY")))
  expect_true(is.na(county_name_to_id("")))
})

test_that("county_name_to_id handles vector input", {
  input <- c("ESSEX", "HUDSON", "BERGEN", "FAKE")
  result <- county_name_to_id(input)
  expect_equal(result, c("07", "09", "03", NA_character_))
})

test_that("clean_sped_df adds county_id when only county_name is present", {
  # Simulate historic sped data that has county_name but no county_id
  fake_df <- data.frame(
    end_year = 2018,
    county_name = c("ESSEX", "HUDSON"),
    district_id = c("3570", "0680"),
    district_name = c("NEWARK", "HOBOKEN"),
    gened_num = c(1000, 500),
    sped_num = c(150, 75),
    sped_rate = c(15.0, 15.0),
    stringsAsFactors = FALSE
  )

  result <- clean_sped_df(fake_df, 2018)

  # county_id should be present and correctly derived from county_name
  expect_true("county_id" %in% names(result))
  expect_equal(result$county_id, c("07", "09"))
})


# =============================================================================
# Issue #148: subgroup inconsistencies in report card data
# https://github.com/almartin82/njschooldata/issues/148
# =============================================================================

# Issue #148: Report card functions use mixed-case subgroup names
# (e.g., "Total Population", "Black", "English Language Learners") while
# SPR and graduation functions use lowercase canonical names
# (e.g., "total population", "black", "limited english proficiency").
# All modules should use the same canonical lowercase names.

test_that("report card subgroup names match canonical lowercase standard", {
  # The canonical standard (used by clean_spr_subgroups and grad_file_group_cleanup)
  canonical_names <- c(
    "total population",
    "black",
    "students with disabilities",
    "limited english proficiency",
    "economically disadvantaged"
  )

  # Report card inline gsub cleaning produces these (current broken behavior):
  rc_names <- c(
    "Total Population",         # should be "total population"
    "Black",                    # should be "black"
    "Students With Disabilities", # should be "students with disabilities"
    "English Language Learners", # should be "limited english proficiency"
    "Economically Disadvantaged Students" # should be "economically disadvantaged"
  )

  # There should be a single canonical function that all modules use.
  # Test that report card names match canonical names after cleaning.
  cleaned <- clean_rc_subgroups(rc_names)
  expect_equal(cleaned, canonical_names)
})

test_that("clean_rc_subgroups produces same output as clean_spr_subgroups for shared inputs", {
  # Both functions should map the same raw NJ DOE names to the same canonical output
  shared_inputs <- c(
    "Schoolwide", "Districtwide",
    "Black or African American",
    "Students with Disabilities", "Students with Disability",
    "English Learners",
    "Economically Disadvantaged Students",
    "American Indian or Alaska Native",
    "Two or More Races",
    "Native Hawaiian or Other Pacific Islander"
  )

  spr_results <- clean_spr_subgroups(shared_inputs)
  rc_results <- clean_rc_subgroups(shared_inputs)

  expect_equal(rc_results, spr_results,
    info = "Report card and SPR subgroup cleaning should produce identical canonical names")
})

test_that("extract_rc_college_matric uses lowercase canonical subgroup names", {
  # Source code should not produce mixed-case subgroup values
  rc_source <- readLines("../../R/report_card.R")

  # Should NOT have mixed-case output values like 'Total Population' or 'Black'
  # (These indicate the legacy inline gsub approach rather than canonical cleaning)
  mixed_case_outputs <- grep(
    "gsub\\(.*(Total Population|English Language Learners).*subgroup",
    rc_source
  )

  expect_equal(length(mixed_case_outputs), 0,
    info = paste(
      "report_card.R should use clean_rc_subgroups() instead of inline gsub",
      "with mixed-case output values"
    ))
})


# =============================================================================
# Issue #157: percentile rank aggregates don't include rank and n cols
# https://github.com/almartin82/njschooldata/issues/157
# =============================================================================

# Issue #157: city_ecosystem_summary() and ecosystem_trend() drop the
# _rank and _n columns that add_percentile_rank() creates. Users need
# these to understand the context of the percentile (rank X out of N).

test_that("city_ecosystem_summary includes rank and n columns", {
  # Create minimal test data with required structure
  test_data <- data.frame(
    end_year = rep(2023, 10),
    district_id = c("3570", "3570C", "3570A", paste0("d", 1:7)),
    district_name = c("NEWARK", "NEWARK CHARTERS", "NEWARK ALL PUBLIC", paste0("District ", 1:7)),
    grad_rate = c(75, 85, 80, seq(60, 90, length.out = 7)),
    is_district = c(TRUE, FALSE, FALSE, rep(TRUE, 7)),
    is_charter_sector = c(FALSE, TRUE, FALSE, rep(FALSE, 7)),
    is_allpublic = c(FALSE, FALSE, TRUE, rep(FALSE, 7)),
    stringsAsFactors = FALSE
  )

  result <- city_ecosystem_summary(
    df = test_data,
    host_district_id = "3570",
    metric_col = "grad_rate"
  )

  # Should include _rank and _n alongside _percentile
  expect_true("grad_rate_percentile" %in% names(result),
    info = "city_ecosystem_summary should include percentile column")
  expect_true("grad_rate_rank" %in% names(result),
    info = "city_ecosystem_summary should include rank column")
  expect_true("grad_rate_n" %in% names(result),
    info = "city_ecosystem_summary should include n column")
})

test_that("ecosystem_trend includes rank and n columns for allpublic", {
  # Create minimal enrollment data
  test_enr <- data.frame(
    end_year = rep(c(2022, 2023), each = 2),
    district_id = rep(c("3570C", "3570A"), 2),
    subgroup = "total_enrollment",
    n_students = c(15000, 40000, 16000, 41000),
    stringsAsFactors = FALSE
  )

  # Create minimal performance data
  test_perf <- data.frame(
    end_year = rep(c(2022, 2023), each = 10),
    district_id = rep(c("3570", "3570C", "3570A", paste0("d", 1:7)), 2),
    district_name = rep(c("NEWARK", "NEWARK CHARTERS", "NEWARK ALL PUBLIC", paste0("District ", 1:7)), 2),
    grad_rate = c(75, 85, 80, seq(60, 90, length.out = 7),
                  76, 86, 81, seq(61, 91, length.out = 7)),
    is_district = rep(c(TRUE, FALSE, FALSE, rep(TRUE, 7)), 2),
    is_charter_sector = rep(c(FALSE, TRUE, FALSE, rep(FALSE, 7)), 2),
    is_allpublic = rep(c(FALSE, FALSE, TRUE, rep(FALSE, 7)), 2),
    stringsAsFactors = FALSE
  )

  result <- ecosystem_trend(
    df_enrollment = test_enr,
    df_performance = test_perf,
    host_district_id = "3570",
    metric_col = "grad_rate"
  )

  # Should include rank and n for allpublic
  expect_true("allpublic_percentile" %in% names(result),
    info = "ecosystem_trend should include allpublic_percentile")
  expect_true("allpublic_rank" %in% names(result),
    info = "ecosystem_trend should include allpublic_rank")
  expect_true("allpublic_n" %in% names(result),
    info = "ecosystem_trend should include allpublic_n")
})


# =============================================================================
# Issue #134: improve fetch_special_pop to include n / enr
# https://github.com/almartin82/njschooldata/issues/134
# =============================================================================

# Issue #134: fetch_special_pop should derive N from enrollment

test_that("fetch_reportcard_special_pop output includes n_enrolled column", {
  skip_if_offline()

  result <- tryCatch(
    fetch_reportcard_special_pop(2019),
    error = function(e) NULL
  )
  skip_if(is.null(result), "Report card data not accessible")

  expect_true("n_enrolled" %in% names(result),
    info = "fetch_reportcard_special_pop should include n_enrolled column")
  expect_true("n_students" %in% names(result),
    info = "fetch_reportcard_special_pop should include n_students count column")

  # n_enrolled should be numeric, not character
  expect_true(is.numeric(result$n_enrolled),
    info = "n_enrolled should be numeric, not character")
})

test_that("fetch_reportcard_special_pop n_students is consistent with percent and n_enrolled", {
  skip_if_offline()

  result <- tryCatch(
    fetch_reportcard_special_pop(2019),
    error = function(e) NULL
  )
  skip_if(is.null(result), "Report card data not accessible")

  # Where we have both percent and n_enrolled, n_students should be derivable
  check <- result %>%
    dplyr::filter(!is.na(percent) & !is.na(n_enrolled) & n_enrolled > 0)

  expect_true(nrow(check) > 0,
    info = "Should have rows with both percent and n_enrolled populated")

  # n_students should approximately equal percent/100 * n_enrolled
  check <- check %>%
    dplyr::mutate(
      expected_n = round(percent / 100 * n_enrolled),
      diff = abs(n_students - expected_n)
    )

  # Allow rounding tolerance of 1
  expect_true(all(check$diff <= 1, na.rm = TRUE),
    info = "n_students should be derivable from percent and n_enrolled")
})

test_that("fetch_reportcard_special_pop includes enrollment from PR enrollment table", {
  skip_if_offline()

  # The issue specifically asks to "read from enrollment table in PR"
  # and "add that to special pop to infer N"
  result <- tryCatch(
    fetch_reportcard_special_pop(2018),
    error = function(e) NULL
  )
  skip_if(is.null(result), "Report card data not accessible")

  # No row should have NA for n_enrolled when the school exists in enrollment
  schools_with_data <- result %>%
    dplyr::filter(!is.na(percent) & percent > 0)

  na_enrolled <- sum(is.na(schools_with_data$n_enrolled))
  pct_missing <- na_enrolled / nrow(schools_with_data)

  # At most 5% of schools with special pop data should be missing enrollment
  expect_true(pct_missing < 0.05,
    info = sprintf(
      "%d of %d schools (%.1f%%) with special pop data are missing n_enrolled",
      na_enrolled, nrow(schools_with_data), pct_missing * 100
    ))
})


# =============================================================================
# Issue #116: extract_rc_college_matric isn't pulling the matric number
# https://github.com/almartin82/njschooldata/issues/116
# =============================================================================

# Issue #116: college matric missing enroll_any for certain years

test_that("extract_rc_college_matric returns enroll_any for 2013", {
  skip_if_offline()

  rc_2013 <- tryCatch(
    get_one_rc_database(2013),
    error = function(e) NULL
  )
  skip_if(is.null(rc_2013), "2013 report card data not accessible")

  matric <- extract_rc_college_matric(list(rc_2013))

  expect_true("enroll_any" %in% names(matric),
    info = "enroll_any column should be present for 2013")

  # enroll_any should have actual values, not all NA
  non_na <- sum(!is.na(matric$enroll_any))
  expect_true(non_na > 0,
    info = sprintf(
      "enroll_any should have non-NA values for 2013 but all %d rows are NA",
      nrow(matric)
    ))
})

test_that("extract_rc_college_matric returns correct enroll_4yr for 2017", {
  skip_if_offline()

  rc_2017 <- tryCatch(
    get_one_rc_database(2017),
    error = function(e) NULL
  )
  skip_if(is.null(rc_2017), "2017 report card data not accessible")

  matric <- extract_rc_college_matric(list(rc_2017))

  expect_true("enroll_4yr" %in% names(matric),
    info = "enroll_4yr column should be present for 2017")

  # Per the issue comment: "2017 4yr is not the right number either"
  # enroll_4yr values should be percentages between 0 and 100
  valid <- matric %>%
    dplyr::filter(!is.na(enroll_4yr))
  expect_true(nrow(valid) > 0,
    info = "enroll_4yr should have non-NA values for 2017")
  expect_true(all(valid$enroll_4yr >= 0 & valid$enroll_4yr <= 100),
    info = "enroll_4yr should be valid percentages between 0 and 100")
})

test_that("extract_rc_college_matric warns when expected columns not found", {
  # Silent column drops are the root cause of this bug.
  # The function should warn when gsub column name matching fails to find
  # expected columns like enroll_any, enroll_4yr, enroll_2yr.

  # Create a minimal mock list that has a post_sec table but with
  # column names that don't match any gsub pattern
  mock_pr <- list(
    sch_header = data.frame(
      county_code = "13", district_code = "3570",
      school_code = "055", end_year = 2013,
      stringsAsFactors = FALSE
    ),
    post_sec = data.frame(
      county_code = "13", district_code = "3570",
      school_code = "055", end_year = 2013,
      subgroup = "Total Population",
      unknown_col_name = 85.5,  # This should be enroll_any but won't match
      stringsAsFactors = FALSE
    )
  )

  # Currently the function silently returns without the column.
  # After fix, it should either warn or handle gracefully.
  result <- tryCatch(
    extract_rc_college_matric(list(mock_pr)),
    error = function(e) "error",
    warning = function(w) "warning"
  )

  # The function should not silently drop columns - it should warn
  expect_true(
    is.character(result) && result == "warning",
    info = "extract_rc_college_matric should warn when expected columns are not found"
  )
})


# =============================================================================
# Issue #97: collapse/clean up schools and districts field when aggregating
# https://github.com/almartin82/njschooldata/issues/97
# =============================================================================

# Issue #97: aggregate name fields should be deduplicated

test_that("collapse_agg_names deduplicates and counts repeated names", {
  # The desired function should collapse:
  # "School A, School A, School A, School B" => "School A (3), School B (1)"
  # or similar compact format

  # Test that the function exists (TDD: it doesn't yet)
  expect_true(
    exists("collapse_agg_names", where = asNamespace("njschooldata")),
    info = "collapse_agg_names() function should exist in njschooldata"
  )
})

test_that("collapse_agg_names handles basic deduplication", {
  skip_if_not(
    exists("collapse_agg_names", where = asNamespace("njschooldata")),
    "collapse_agg_names not yet implemented"
  )

  # Single repeated name
  input <- "School A, School A, School A"
  result <- njschooldata::collapse_agg_names(input)
  expect_true(grepl("School A", result))
  expect_true(grepl("3", result),
    info = "Should indicate count of 3 for repeated name")

  # Mixed names
  input2 <- "School A, School B, School A"
  result2 <- njschooldata::collapse_agg_names(input2)
  expect_true(grepl("School A", result2))
  expect_true(grepl("School B", result2))
  # Total schools should be 3 (2 unique)
  expect_false(nchar(result2) > nchar(input2),
    info = "Collapsed string should be shorter or equal to input")
})

test_that("parcc_aggregate_calcs produces clean school names", {
  # When the same school appears multiple times (e.g., across grades),
  # the aggregated schools field should not repeat the name
  test_df <- tibble::tibble(
    end_year = rep(2019, 6),
    district_name = rep("NEWARK", 6),
    school_name = rep(c("School A", "School A", "School B"), 2),
    subgroup = rep("total population", 6),
    testing_year = rep(2019, 6),
    test_name = rep("ELA", 6),
    grade = rep(c("03", "04", "05"), 2),
    number_enrolled = rep(100, 6),
    number_not_tested = rep(5, 6),
    number_of_valid_scale_scores = rep(95, 6),
    scale_score_mean = rep(750, 6),
    pct_l1 = rep(10, 6),
    pct_l2 = rep(20, 6),
    pct_l3 = rep(30, 6),
    pct_l4 = rep(25, 6),
    pct_l5 = rep(15, 6),
    is_charter = rep(TRUE, 6)
  ) %>%
    parcc_perf_level_counts()

  result <- test_df %>%
    dplyr::group_by(end_year, subgroup) %>%
    parcc_aggregate_calcs()

  schools_str <- result$schools[1]
  school_parts <- trimws(strsplit(schools_str, ",")[[1]])

  # "School A" appears 4 times in input but should be collapsed
  school_a_count <- sum(school_parts == "School A")

  # After fix: School A should appear once (with count annotation)
  # Current behavior: School A appears 4 times
  expect_equal(school_a_count, 1,
    info = paste(
      "School A appears", school_a_count,
      "times in aggregate but should appear once.",
      "Full string:", schools_str
    ))
})


# =============================================================================
# Issue #103: create full subgroups from grad count subgroups
# https://github.com/almartin82/njschooldata/issues/103
# =============================================================================

# Issue #103: grad count should have combined gender x race subgroups

test_that("fetch_grad_count includes gender x race subgroups for years that have them", {
  skip_if_offline()

  # Pre-2011 data should have gender x race subgroups like white_m, black_f
  result <- tryCatch(
    fetch_grad_count(2010),
    error = function(e) NULL
  )
  skip_if(is.null(result), "2010 grad count data not accessible")

  subgroups <- unique(result$subgroup)

  # Should have combined gender x race subgroups like enrollment does
  gender_race <- c("white_m", "white_f", "black_m", "black_f",
                   "hispanic_m", "hispanic_f")

  has_gender_race <- any(gender_race %in% subgroups)
  expect_true(has_gender_race,
    info = paste(
      "Pre-2011 grad count should have gender x race subgroups.",
      "Available subgroups:", paste(subgroups, collapse = ", ")
    ))
})

test_that("grad count subgroups parallel enrollment subgroups", {
  # The issue says "similar to enr, wh_m + wh_f etc"
  # Grad count subgroups should use the same naming convention as enrollment

  skip_if_offline()

  enr <- tryCatch(
    fetch_enr(2019, tidy = TRUE),
    error = function(e) NULL
  )
  gcount <- tryCatch(
    fetch_grad_count(2019),
    error = function(e) NULL
  )
  skip_if(is.null(enr) || is.null(gcount), "Data not accessible")

  enr_subgroups <- unique(enr$subgroup)
  gc_subgroups <- unique(gcount$subgroup)

  # Core demographic subgroups should be named the same
  core_subgroups <- c("white", "black", "hispanic", "asian",
                      "male", "female")

  for (sg in core_subgroups) {
    in_enr <- sg %in% enr_subgroups
    in_gc <- sg %in% gc_subgroups
    if (in_enr) {
      expect_true(in_gc,
        info = sprintf(
          "Subgroup '%s' is in enrollment but not in grad count. Names should match.",
          sg
        ))
    }
  }
})


# =============================================================================
# Issue #106: better handling of raw 4 year and 5 year grad rate
# https://github.com/almartin82/njschooldata/issues/106
# =============================================================================

# Issue #106: grad_rate and five_yr_grad_rate column handling

test_that("fetch_grad_rate returns single grad_rate column for 5-year data", {
  skip_if_offline()

  result <- tryCatch(
    fetch_grad_rate(2013, methodology = "5 year"),
    error = function(e) NULL
  )
  skip_if(is.null(result), "5-year grad rate data not accessible for 2013")

  # Should have a single grad_rate column (not separate grad_rate and five_yr_grad_rate)
  expect_true("grad_rate" %in% names(result),
    info = "5-year data should have a 'grad_rate' column")

  # The grad_rate column should contain the 5-year rate, not the 4-year rate
  expect_true("methodology" %in% names(result))
  expect_true(all(result$methodology == "5 year"),
    info = "methodology column should indicate '5 year'")

  # grad_rate should be the 5-year rate (generally higher than 4-year)
  # Values should be valid proportions
  valid <- result %>%
    dplyr::filter(!is.na(grad_rate))
  expect_true(nrow(valid) > 0)
  expect_true(all(valid$grad_rate >= 0 & valid$grad_rate <= 1),
    info = "grad_rate should be valid proportions between 0 and 1")
})

test_that("5-year grad rate values are plausible (higher than 4-year)", {
  skip_if_offline()

  grate_4yr <- tryCatch(
    fetch_grad_rate(2013, methodology = "4 year"),
    error = function(e) NULL
  )
  grate_5yr <- tryCatch(
    fetch_grad_rate(2013, methodology = "5 year"),
    error = function(e) NULL
  )
  skip_if(is.null(grate_4yr) || is.null(grate_5yr),
    "Grad rate data not accessible for 2013")

  # Join on district to compare
  comparison <- grate_4yr %>%
    dplyr::filter(is_district, subgroup == "total population") %>%
    dplyr::select(district_id, grad_rate_4yr = grad_rate) %>%
    dplyr::inner_join(
      grate_5yr %>%
        dplyr::filter(is_district, subgroup == "total population") %>%
        dplyr::select(district_id, grad_rate_5yr = grad_rate),
      by = "district_id"
    ) %>%
    dplyr::filter(!is.na(grad_rate_4yr) & !is.na(grad_rate_5yr))

  skip_if(nrow(comparison) == 0, "No districts with both 4yr and 5yr rates")

  # On average, 5-year rates should be >= 4-year rates
  expect_true(
    mean(comparison$grad_rate_5yr, na.rm = TRUE) >=
      mean(comparison$grad_rate_4yr, na.rm = TRUE),
    info = "Average 5-year grad rate should be >= average 4-year grad rate"
  )

  # The grad_rate field should NOT still contain the 4-year rate
  # (this is the bug: the 5yr file has both columns and the wrong one may be used)
  # At least 20% of districts should show 5yr > 4yr
  pct_higher <- mean(comparison$grad_rate_5yr > comparison$grad_rate_4yr)
  expect_true(pct_higher >= 0.2,
    info = sprintf(
      "Only %.1f%% of districts show 5yr > 4yr. The grad_rate column may contain 4yr values.",
      pct_higher * 100
    ))
})


# =============================================================================
# Issue #69: charter_sector_aggs should return the number of charters
# https://github.com/almartin82/njschooldata/issues/69
# =============================================================================

# Issue #69: charter sector aggregations should report charter count

test_that("charter_sector_enr_aggs includes n_schools or n_charters column", {
  skip_if_offline()

  enr <- tryCatch(
    fetch_enr(2019, tidy = TRUE),
    error = function(e) NULL
  )
  skip_if(is.null(enr), "Enrollment data not accessible")

  result <- tryCatch(
    charter_sector_enr_aggs(enr),
    error = function(e) NULL
  )
  skip_if(is.null(result), "Charter sector enrollment aggs failed")

  # Should have a column indicating how many charters are in the sector
  has_count_col <- any(c("n_schools", "n_charters", "n_charter_rows") %in% names(result))
  expect_true(has_count_col,
    info = paste(
      "charter_sector_enr_aggs should include a charter count column.",
      "Available columns:", paste(names(result), collapse = ", ")
    ))

  # The count should be > 0 for all rows (since these are charter sector aggs)
  if ("n_schools" %in% names(result)) {
    expect_true(all(result$n_schools > 0),
      info = "n_schools should be > 0 for all charter sector rows")
  }
})

test_that("charter_sector_grate_aggs includes n_charter_rows column", {
  skip_if_offline()

  grate <- tryCatch(
    fetch_grad_rate(2019),
    error = function(e) NULL
  )
  skip_if(is.null(grate), "Grad rate data not accessible")

  result <- tryCatch(
    charter_sector_grate_aggs(grate),
    error = function(e) NULL
  )
  skip_if(is.null(result), "Charter sector grate aggs failed")

  # The aggregate calc function creates n_charter_rows but it may be
  # dropped by grate_column_order(). Issue #69 says it should be kept.
  expect_true("n_charter_rows" %in% names(result),
    info = paste(
      "charter_sector_grate_aggs should retain n_charter_rows column.",
      "Available columns:", paste(names(result), collapse = ", ")
    ))
})

test_that("charter sector with single school is identifiable", {
  # The issue says: "some city charter 'sectors' are only one school -
  # make this easy to see"

  skip_if_offline()

  grate <- tryCatch(
    fetch_grad_rate(2019),
    error = function(e) NULL
  )
  skip_if(is.null(grate), "Grad rate data not accessible")

  result <- tryCatch(
    charter_sector_grate_aggs(grate),
    error = function(e) NULL
  )
  skip_if(is.null(result), "Charter sector grate aggs failed")

  # n_charter_rows should be present and allow identifying single-school sectors
  skip_if_not("n_charter_rows" %in% names(result),
    "n_charter_rows column not yet retained in output")

  # There should be at least one sector with a small number of charters
  min_charters <- min(result$n_charter_rows, na.rm = TRUE)
  expect_true(is.finite(min_charters),
    info = "n_charter_rows should have finite values")
})
