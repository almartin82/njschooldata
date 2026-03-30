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
