# ==============================================================================
# Charter status is THREE-VALUED, on every surface that emits it
# ==============================================================================
#
# NJDOE assigns every charter LEA to county "80". The county code is therefore
# the evidence, and it answers in both directions:
#
#   published "80"        -> TRUE   (charter sector, affirmed)
#   published anything else -> FALSE (outside it, also affirmed -- a sourced fact)
#   published nothing     -> NA     (the source said nothing; neither do we)
#
# The banned idiom is `!is.na(x) & x == "80"`. It reads as a careful NA guard
# and is the opposite: it CANNOT return NA, so it answers "not a charter" for
# every row the source never typed. Four sites in this package carried it, and
# `append_sped_entity_flags()` carried the same fabrication as a bare `FALSE`
# fallback for frames with no county column at all.
#
# Measured against the live NJ DOE sources on 2026-08-10, the honest NA reaches
# 155 shipped rows: 141 in fetch_certificated_staff(level = "state") (the
# "STATE SUM" row publishes NO county code -- 12 rows each in 2000/2001/2002,
# 15 each in 2020-2026) and 14 in fetch_sped(level = "state") (the statewide
# by-disability rollup carries no county column). Every other row is unchanged:
# these tests pin BOTH directions so a future sweep toward NA cannot quietly
# destroy the sourced FALSE values either.
#
# These tests are OFFLINE and unconditional -- no network, no skip. Real-source
# assertions live in test-live-charter-provenance.R.
# ==============================================================================


# ------------------------------------------------------------------------------
# The decider
# ------------------------------------------------------------------------------

test_that("is_charter_district() answers all three values", {
  expect_true(is_charter_district("80"))

  # A published non-80 county code is a SOURCED not-charter, not an unknown.
  expect_false(is_charter_district("01"))
  expect_false(is_charter_district("41"))
  expect_false(is_charter_district("99"))   # statewide sentinel
  expect_false(is_charter_district("ST"))   # legacy statewide aggregation code
  expect_false(is_charter_district("CD"))   # DFG aggregate

  # No county code published -> no claim.
  expect_true(is.na(is_charter_district(NA_character_)))

  # Vectorized, mixed input: TRUE / FALSE / NA all survive together.
  expect_identical(
    is_charter_district(c("80", "01", NA_character_, "99")),
    c(TRUE, FALSE, NA, FALSE)
  )
})


test_that("is_charter_district() is logical, never a string or a 0/1", {
  out <- is_charter_district(c("80", NA_character_))
  expect_type(out, "logical")
  expect_length(out, 2L)
})


# ------------------------------------------------------------------------------
# Site 1: legacy assessment (NJASK / GEPA / HSPA) -- assign_legacy_assess_flags()
# ------------------------------------------------------------------------------

test_that("assign_legacy_assess_flags() keeps charter status three-valued", {
  # Raw-shaped: the County_Code/DFG/Aggregation_Code field as tidy_nj_assess()
  # leaves it, including the DFG-letter and "ST" aggregate encodings.
  raw <- data.frame(
    county_code = c("80", "01", "ST", "CD", NA_character_),
    district_code = c("6055", "0110", NA_character_, NA_character_, "0110"),
    school_code = c("010", "050", NA_character_, NA_character_, "050"),
    stringsAsFactors = FALSE
  )

  out <- assign_legacy_assess_flags(raw)

  expect_identical(out$is_charter, c(TRUE, FALSE, FALSE, FALSE, NA))
  expect_true(is.na(out$is_charter[5]))
  # The sourced FALSEs are still FALSE -- not swept into NA. Stated as the
  # value they must hold, never as a blanket ban on NA: a test that merely
  # forbids NA is how a package encodes the fabrication it is meant to catch.
  expect_identical(out$is_charter[2:4], c(FALSE, FALSE, FALSE))
})


test_that("assign_legacy_assess_flags() lower-case county code still reads 80", {
  raw <- data.frame(
    county_code = c("80", "st"),
    district_code = c("6055", NA_character_),
    school_code = c("010", NA_character_),
    stringsAsFactors = FALSE
  )
  out <- assign_legacy_assess_flags(raw)
  expect_identical(out$is_charter, c(TRUE, FALSE))
})


# ------------------------------------------------------------------------------
# Site 2: staff evaluations -- tidy_staff_evaluations()
# ------------------------------------------------------------------------------

.charter_eval_raw <- function() {
  # Raw shape of the NJDOE_STAFF_EVAL_*.xlsx rating sheet: 12 text columns,
  # renamed by get_raw_staff_evaluations() before tidying.
  data.frame(
    county_id = c("80", "01", "99", NA_character_),
    county_name = c("CHARTERS", "ATLANTIC", "STATE", "STATE"),
    district_id = c("6055", "0010", "9999", "9999"),
    lea_name = c("HOBOKEN CHARTER SCHOOL", "ABSECON CITY", "STATE", "STATE"),
    school_id = c("010", "050", "999", "999"),
    school_name = c("HOBOKEN CHARTER", "EMMA C ATTALES", "STATE", "STATE"),
    category = rep("TEACHERS", 4),
    ineffective = c("*", "0", "10", "10"),
    partially_effective = c("1", "2", "20", "20"),
    effective = c("16", "36", "78099", "78099"),
    highly_effective = c("10", "36", "500", "500"),
    total = c("27", "74", "105759", "105759"),
    stringsAsFactors = FALSE
  )
}


test_that("tidy_staff_evaluations() flags county 80 TRUE and other codes FALSE", {
  out <- tidy_staff_evaluations(.charter_eval_raw(), 2014)

  # The NA-county row is dropped by the note-row filter, so three rows remain.
  expect_equal(nrow(out), 3L)
  expect_identical(out$is_charter, c(TRUE, FALSE, FALSE))
})


test_that("tidy_staff_evaluations() charter flag survives the leading-zero re-pad", {
  # The 2015 file drops leading zeros (district "10" for 0010). The charter
  # answer must be read off the RE-PADDED county code that actually ships, so
  # county "1" -> "01" is a sourced not-charter and "80" is still the sector.
  raw <- .charter_eval_raw()[1:2, ]
  raw$county_id <- c("80", "1")
  raw$district_id <- c("6055", "10")
  out <- tidy_staff_evaluations(raw, 2015)

  expect_identical(out$county_id, c("80", "01"))
  expect_identical(out$district_id, c("6055", "0010"))
  expect_identical(out$is_charter, c(TRUE, FALSE))
})


# ------------------------------------------------------------------------------
# Site 3: certificated staff, legacy CSV era -- parse_certificated_legacy()
# ------------------------------------------------------------------------------

.charter_legacy_csv <- function(co_values) {
  n <- length(co_values)
  path <- tempfile(pattern = "cert_legacy_", fileext = ".csv")
  utils::write.csv(
    data.frame(
      CO = co_values,
      CONAME = c("STATE SUM", rep("ATLANTIC", n - 1))[seq_len(n)],
      DIST = rep("0010", n),
      DISTNAME = rep("ABSECON CITY", n),
      SCH = rep("050", n),
      SCHNAME = rep("EMMA C ATTALES", n),
      POSITION = rep("TEACHER", n),
      SEX = rep("TOTAL", n),
      WHITE = rep("32.8", n),
      BLACK = rep("1.0", n),
      HISP = rep("2.0", n),
      ALS_IND = rep("0", n),
      ASI_PAC = rep("0", n),
      TOTAL = rep("35.8", n),
      stringsAsFactors = FALSE
    ),
    path, row.names = FALSE, na = ""
  )
  path
}


test_that("parse_certificated_legacy() returns NA charter for the codeless STATE SUM row", {
  # The legacy cs*.csv STATE SUM row publishes no CO value at all. That is the
  # 36 rows (2000/2001/2002) that used to ship a fabricated FALSE.
  path <- .charter_legacy_csv(c(NA_character_, "80", "01"))
  on.exit(unlink(path), add = TRUE)

  out <- parse_certificated_legacy(path, 2000)

  expect_true(is.na(out$is_charter[1]))
  expect_true(out$is_charter[2])
  expect_false(out$is_charter[3])
  expect_true(is.na(out$county_id[1]))
})


test_that("parse_certificated_legacy() compares the padded code, not the raw field", {
  # A drift year writing "8" ships county_id "08"; the charter answer must agree
  # with the code that ships, and "08" is not the charter sector.
  path <- .charter_legacy_csv(c("8", "80"))
  on.exit(unlink(path), add = TRUE)

  out <- parse_certificated_legacy(path, 2000)

  expect_identical(out$county_id[1:2], c("08", "80"))
  expect_identical(out$is_charter[1:2], c(FALSE, TRUE))
})


test_that("parse_certificated_legacy() keeps a published county 99 as a sourced FALSE", {
  # 2003-2008 publish "99" on the STATE SUM row. That is an answer, and it must
  # stay FALSE rather than being swept into NA along with the codeless years.
  path <- .charter_legacy_csv(c("99", "80"))
  on.exit(unlink(path), add = TRUE)

  out <- parse_certificated_legacy(path, 2004)

  expect_identical(out$is_charter[1:2], c(FALSE, TRUE))
})


# ------------------------------------------------------------------------------
# Site 4: certificated staff, modern xlsx era -- parse_certificated_modern()
# ------------------------------------------------------------------------------
#
# Fixture: inst/extdata/test-fixtures/certificated-staff-modern-2026.xlsx, a
# six-row slice of the real NJ DOE "Certificated Staff 2026.xlsx" with every
# value copied verbatim (see data-raw/build_certificated_modern_fixture.R).
# The STATE sheet is the point: NJ publishes it with NO "Co Code" column at all,
# which is why 105 of the 141 rows that used to ship a fabricated FALSE come
# from this parser.

.charter_modern_fixture <- function() {
  system.file(
    "extdata", "test-fixtures", "certificated-staff-modern-2026.xlsx",
    package = "njschooldata"
  )
}


test_that("the committed modern certificated-staff fixture is present", {
  expect_true(nzchar(.charter_modern_fixture()))
  expect_true(file.exists(.charter_modern_fixture()))
})


test_that("parse_certificated_modern() abstains on the codeless STATE sheet", {
  out <- parse_certificated_modern(.charter_modern_fixture(), "STATE", 2026)

  # NJ publishes no county code on the STATE sheet, so charter status is
  # unknown -- not FALSE.
  expect_true(all(is.na(out$county_id)))
  expect_true(all(is.na(out$is_charter)))
  expect_type(out$is_charter, "logical")
  expect_true(all(out$is_state))
})


test_that("parse_certificated_modern() answers TRUE/FALSE from a published county code", {
  out <- parse_certificated_modern(.charter_modern_fixture(), "DISTRICT", 2026)

  charter <- out[out$district_id == "6010", ]
  regular <- out[out$district_id == "0010", ]

  expect_gt(nrow(charter), 0)
  expect_gt(nrow(regular), 0)
  # NJ DOE labels county 80 "Charters" in its own County column.
  expect_true(all(charter$county_id == "80"))
  expect_true(all(charter$is_charter))
  expect_true(all(regular$county_id == "01"))
  expect_false(any(regular$is_charter))
  # Every DISTRICT row publishes a county code, so every answer is sourced.
  expect_identical(out$is_charter, out$county_id == "80")

  # Published values ride through untouched (real 2026 workbook figures).
  admin_total <- charter[charter$position == "administrators" &
                           charter$gender == "total", ]
  expect_equal(admin_total$white, 0.8)
  expect_equal(admin_total$total, 0.8)
})


# ------------------------------------------------------------------------------
# Site 5: SPED entity flags -- append_sped_entity_flags()
# ------------------------------------------------------------------------------

test_that("append_sped_entity_flags() abstains when the frame has no county column", {
  # fetch_sped(level = "state") builds a by-disability rollup with no county_id
  # at all. The source has published nothing about charter status, so neither
  # can we. This used to be a bare FALSE.
  state_rollup <- data.frame(
    end_year = 2025L,
    disability_category = c("all_disabilities", "autism"),
    n_students = c(250000, 30000),
    stringsAsFactors = FALSE
  )

  out <- append_sped_entity_flags(state_rollup, is_state = TRUE)

  expect_true(all(is.na(out$is_charter)))
  expect_type(out$is_charter, "logical")
  expect_true(all(out$is_state))
})


test_that("append_sped_entity_flags() still answers from county_id when it exists", {
  district <- data.frame(
    end_year = 2025L,
    county_id = c("80", "01", NA_character_),
    district_id = c("6055", "0010", "0010"),
    stringsAsFactors = FALSE
  )

  out <- append_sped_entity_flags(district, is_district = TRUE)

  expect_identical(out$is_charter, c(TRUE, FALSE, NA))
})


test_that("append_sped_entity_flags() never overwrites a charter flag already set", {
  df <- data.frame(county_id = "01", is_charter = TRUE, stringsAsFactors = FALSE)
  expect_true(append_sped_entity_flags(df)$is_charter)
})


# ------------------------------------------------------------------------------
# Site 6: charter host aggregations -- charter_flag_host_aware()
# ------------------------------------------------------------------------------
#
# These helpers used to derive charter status as pure roster membership,
# `!is.na(host_district_id)`, which discarded NJDOE's own county-80 flag and
# typed every charter the bundled charter_city table had not caught yet as
# "not a charter".

test_that("charter_flag_host_aware() keeps a county-80 charter the roster missed", {
  # Kindle Education (7898) and Thrive (7902) are real county-80 charters absent
  # from the bundled host map. Roster membership must not be able to deny them.
  df <- data.frame(
    county_id = c("80", "80", "01"),
    district_id = c("6055", "7898", "0010"),
    host_district_id = c("3570", NA_character_, NA_character_),
    stringsAsFactors = FALSE
  )
  expect_identical(charter_flag_host_aware(df), c(TRUE, TRUE, FALSE))
})


test_that("charter_flag_host_aware() reads the roster as affirmative for pre-2010 vintages", {
  # NJ enrollment did not use county 80 before end_year 2010 -- charters carry
  # their HOST county code. County alone would type them "not a charter"; the
  # roster is the evidence that saves them.
  df <- data.frame(
    county_id = c("13", "13"),
    district_id = c("6055", "3570"),
    host_district_id = c("3570", NA_character_),
    stringsAsFactors = FALSE
  )
  expect_identical(charter_flag_host_aware(df), c(TRUE, FALSE))
})


test_that("charter_flag_host_aware() abstains with no county column and no roster hit", {
  df <- data.frame(
    district_id = c("6055", "0010"),
    host_district_id = c("3570", NA_character_),
    stringsAsFactors = FALSE
  )
  out <- charter_flag_host_aware(df)
  expect_true(out[1])
  expect_true(is.na(out[2]))
  expect_type(out, "logical")
})


test_that("charter_flag_host_aware() never demotes an incoming sourced TRUE", {
  df <- data.frame(
    county_id = c("80", "01"),
    is_charter = c(TRUE, FALSE),
    host_district_id = c(NA_character_, NA_character_),
    stringsAsFactors = FALSE
  )
  expect_identical(charter_flag_host_aware(df), c(TRUE, FALSE))
})


# ------------------------------------------------------------------------------
# Fleet-standard entity flags
# ------------------------------------------------------------------------------

test_that("assign_entity_flags() charter status is three-valued", {
  df <- data.frame(
    county_id = c("80", "01", NA_character_),
    district_id = c("6055", "0010", "0010"),
    school_id = c("010", "050", "050"),
    stringsAsFactors = FALSE
  )
  out <- assign_entity_flags(df)
  expect_identical(out$is_charter, c(TRUE, FALSE, NA))
})


# ------------------------------------------------------------------------------
# No surface may re-introduce the banned idiom
# ------------------------------------------------------------------------------

test_that("no R source derives is_charter through an NA-collapsing guard", {
  r_dir <- test_path("..", "..", "R")
  skip_if_not(dir.exists(r_dir), "R/ source tree not available in this build")

  files <- list.files(r_dir, pattern = "[.]R$", full.names = TRUE)
  offenders <- character()

  for (f in files) {
    lines <- readLines(f, warn = FALSE)
    lines <- lines[!grepl("^\\s*#", lines)]
    charter_lines <- grep("is_charter\\s*(<-|=)", lines, value = TRUE)
    # Exclude is_charter_sector / is_charter_district, which are a synthetic
    # aggregate-row marker and the decider itself, not per-row claims.
    charter_lines <- charter_lines[
      !grepl("is_charter_sector|is_charter_district\\s*<-", charter_lines)
    ]
    bad <- charter_lines[
      grepl("!is\\.na\\s*\\(", charter_lines) |
        grepl("dplyr::coalesce|[^_]coalesce\\s*\\(", charter_lines) |
        grepl("replace_na", charter_lines) |
        grepl("na\\.rm\\s*=\\s*TRUE", charter_lines)
    ]
    if (length(bad)) {
      offenders <- c(offenders, paste0(basename(f), ": ", trimws(bad)))
    }
  }

  expect_identical(offenders, character())
})
