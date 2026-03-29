# Reproduction tests for triaged GitHub issues
# These tests document known bugs and inconsistencies so they can be tracked
# and verified when fixed.

# =============================================================================
# Issue #158: geo functions don't always work (address abbreviation mismatch)
# https://github.com/almartin82/njschooldata/issues/158
# =============================================================================

context("Issue #158: geo address matching")

test_that("address_3 fallback uses wrong variable (address1 instead of address)", {
  # The geo.R address_3 case_when has `TRUE ~ address1` on line 90,

  # but `address1` doesn't exist in the pipeline — it should be `address`.
  # This means any address that doesn't match the abbreviation patterns
  # in address_3 will fail with an error or produce NA.

  geo_source <- readLines(system.file("R", "geo.R", package = "njschooldata"))

  # If that doesn't work (not installed), read from source

  if (length(geo_source) == 0) {
    geo_source <- readLines("../../R/geo.R")
  }

  # Find the address_3 case_when block — the TRUE fallback should use `address`
  address1_lines <- grep("TRUE ~ address1", geo_source, fixed = TRUE)
  expect_equal(
    length(address1_lines), 0,
    info = paste(
      "Bug: geo.R address_3 fallback references 'address1' which doesn't exist.",
      "Should be 'address'. See line 90 of geo.R."
    )
  )
})

test_that("geo address normalization covers common abbreviations", {
  # The address matching in geo.R only handles 3 abbreviation pairs:
  # street/st, avenue/ave, boulevard/blvd
  # Missing: drive/dr, road/rd, court/ct, lane/ln, place/pl, etc.
  #
  # This test documents the gap — addresses with these abbreviations
  # will fail to match between the directory and geocoded cache.

  common_abbrevs <- c("drive", "road", "court", "lane", "place",
                       "circle", "terrace", "parkway")

  geo_source <- paste(readLines("../../R/geo.R"), collapse = "\n")

  missing <- common_abbrevs[!sapply(common_abbrevs, function(a) grepl(a, geo_source))]

  expect_equal(
    length(missing), 0,
    info = paste(
      "geo.R address normalization is missing abbreviation handling for:",
      paste(missing, collapse = ", ")
    )
  )
})


# =============================================================================
# Issue #124: progress report pulls are broken (clean_name_vector)
# https://github.com/almartin82/njschooldata/issues/124
# =============================================================================

context("Issue #124: clean_name_vector parsing_option")

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

context("Issue #71: CDS_Code should be lowercase")

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

context("Issue #62: district code padding consistency")

test_that("charter.R converts district_id to numeric (drops leading zeros)", {
  # charter.R line 125 uses `as.numeric(district_id) >= 6000`
  # This is problematic because it coerces character district IDs to numeric,
  # which drops leading zeros. While district_ids >= 6000 don't have leading
  # zeros, this pattern is dangerous and inconsistent with the convention
  # that district_id should always be character.

  charter_code <- readLines("../../R/charter.R")
  numeric_coercion <- grep("as\\.numeric\\(district_id\\)", charter_code)

  expect_true(
    length(numeric_coercion) > 0,
    info = paste(
      "Bug: charter.R coerces district_id to numeric.",
      "If this fails, the as.numeric() call has been removed — update test."
    )
  )
})

test_that("config_peer_groups.R concatenates potentially unpadded codes", {
  # config_peer_groups.R line 46: district_id = paste0(county_code, district_code)
  # If county_code or district_code aren't padded, the resulting district_id
  # will be wrong (e.g., "13570" instead of "013570" or "0135700").

  peer_code <- readLines("../../R/config_peer_groups.R")
  concat_line <- grep("district_id.*paste0.*county_code.*district_code", peer_code)

  if (length(concat_line) > 0) {
    # Check if there's any padding before the paste0
    context_lines <- peer_code[max(1, concat_line[1] - 5):concat_line[1]]
    has_padding <- any(grepl("pad_leading|str_pad|sprintf.*%0", context_lines))

    expect_true(
      has_padding,
      info = paste(
        "Bug: config_peer_groups.R concatenates county_code + district_code",
        "without ensuring they are padded first. Line:", concat_line[1]
      )
    )
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

context("Issue #113: IEP/SWD subgroup naming inconsistency")

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
