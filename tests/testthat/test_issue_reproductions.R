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

test_that("enrollment data uses CDS_Code (uppercase) instead of cds_code", {
  # This test documents the inconsistency: enrollment uses CDS_Code
  # while postsecondary enrollment uses cds_code.
  # The package convention is snake_case for all column names.

  source_files <- c(
    "../../R/process_enrollment.R",
    "../../R/enrollment_names.R",
    "../../R/charter.R",
    "../../R/tidy_enrollment.R"
  )

  uppercase_count <- 0
  for (f in source_files) {
    if (file.exists(f)) {
      code <- readLines(f)
      uppercase_count <- uppercase_count + sum(grepl("CDS_Code", code, fixed = TRUE))
    }
  }

  # This test will PASS when the bug EXISTS (documenting current state)
  # and FAIL when fixed (at which point update the test)
  expect_true(
    uppercase_count > 0,
    info = paste(
      "Expected CDS_Code (uppercase) to still exist in source files.",
      "If this fails, issue #71 may have been fixed — update this test."
    )
  )
})

test_that("postsecondary enrollment already uses lowercase cds_code", {
  # Verify the correct convention exists in fetch_assessment.R
  assess_code <- readLines("../../R/fetch_assessment.R")
  has_lowercase <- any(grepl("cds_code", assess_code, fixed = TRUE))

  expect_true(has_lowercase,
    info = "fetch_assessment.R should use lowercase cds_code as the reference convention"
  )
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

test_that("SWD subgroup has different names across data modules", {
  # This test documents the inconsistency across modules.
  # Each module uses a different name for the same subgroup:
  #
  # Module                  | Name used
  # ----------------------- | ---------
  # SPR (clean_spr)         | "students with disability" (singular)
  # Graduation (grad_file)  | "students with disability" (singular)
  # mSGP                    | "students with disabilities" (PLURAL)
  # Report card matric      | "Students With Disabilities" (TITLE CASE, plural)
  # Special population      | "IEP" (acronym)
  # Tidy graduation         | "iep" (lowercase acronym)
  # Percentile rank         | "iep" (lowercase acronym)
  # Chronic absence (tidy)  | "special_ed" (cross-state standard)

  # SPR uses singular
  spr_code <- readLines("../../R/fetch_spr.R")
  spr_swd <- grep('"students with disability"', spr_code, fixed = TRUE)
  expect_true(length(spr_swd) > 0, info = "SPR uses 'students with disability' (singular)")

  # mSGP uses plural
  msgp_code <- readLines("../../R/msgp.R")
  msgp_swd <- grep("'students with disabilities'", msgp_code, fixed = TRUE)
  expect_true(length(msgp_swd) > 0, info = "mSGP uses 'students with disabilities' (plural)")

  # Special pop uses IEP
  spop_code <- readLines("../../R/special_pop.R")
  spop_swd <- grep("'IEP'", spop_code, fixed = TRUE)
  expect_true(length(spop_swd) > 0, info = "special_pop uses 'IEP' (acronym)")

  # Tidy graduation maps to "iep"
  tidy_code <- readLines("../../R/tidy_graduation.R")
  tidy_swd <- grep('"iep"', tidy_code, fixed = TRUE)
  expect_true(length(tidy_swd) > 0, info = "tidy_graduation maps SWD to 'iep'")
})

test_that("clean_spr_subgroups and msgp use different SWD names", {
  # These two functions should produce the same name for the same subgroup
  # but they don't: SPR → "students with disability" vs mSGP → "students with disabilities"

  skip_if_not_installed("njschooldata")

  spr_result <- njschooldata:::clean_spr_subgroups("Students with Disabilities")
  expect_equal(spr_result, "students with disability",
    info = "SPR normalizes to singular 'students with disability'"
  )

  # If you join SPR and mSGP data on subgroup, these won't match:
  # SPR: "students with disability" != mSGP: "students with disabilities"
})

test_that("report card matric uses title case for SWD", {
  # report_card.R line 425 normalizes TO "Students With Disabilities" (title case)
  # while every other module uses lowercase
  rc_code <- readLines("../../R/report_card.R")
  rc_swd <- grep("Students With Disabilities", rc_code, fixed = TRUE)
  expect_true(length(rc_swd) > 0,
    info = paste(
      "report_card.R uses 'Students With Disabilities' (title case)",
      "while other modules use lowercase. Joining will fail."
    )
  )
})

test_that("grad_file_group_cleanup and clean_grate_names produce different SWD names", {
  # grad_file_group_cleanup() → "students with disability"
  # clean_grate_names() → "iep"
  # Both operate on graduation data but produce incompatible subgroup names.

  skip_if_not_installed("njschooldata")

  grad_result <- njschooldata:::grad_file_group_cleanup("students with disabilities")
  expect_equal(grad_result, "students with disability")

  tidy_result <- njschooldata:::clean_grate_names("Students with Disability")
  expect_equal(tidy_result, "iep")

  # These two functions produce different names for the same concept
  expect_false(
    grad_result == tidy_result,
    info = paste(
      "grad_file_group_cleanup gives 'students with disability'",
      "but clean_grate_names gives 'iep' — inconsistent within graduation module"
    )
  )
})
