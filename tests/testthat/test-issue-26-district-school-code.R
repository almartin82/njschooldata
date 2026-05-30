# Tests for issue #26 — district-aggregate rows in tidy NJASK/HSPA/GEPA
# output must use a single canonical encoding for school_code.
#
# Original report: "school_code == '000' and school_code == '' (empty string)
# both code for district-level results. fix that."
#
# Fix (R/fetch_nj_assess.R):
#   canonicalize_legacy_assess_school_code() collapses both encodings
#   (whitespace-only and the literal "000") to NA_character_ before
#   selector flags are assigned. After this, is.na(school_code) is the
#   single correct test for "not a school", which matches the convention
#   already used by process_parcc() (PARCC tidy output) for district rows.
#
# This file is organized in three sections:
#   1. Unit tests — exercise canonicalize_legacy_assess_school_code()
#      in isolation against synthetic vectors.
#   2. Integration tests — drive the full tidy_nj_assess() pipeline on
#      fixtures whose raw School_Code column contains the mixed encodings
#      and verify the tidy output has a single canonical convention.
#   3. Correctness tests — assert cross-format invariants (PARCC parity,
#      filter equivalence, idempotency, no information loss for real
#      school codes).
#
# All identifier values are NJ DOE structural sentinels documented in the
# layout files (layout_njask, layout_hspa, layout_gepa). No measure
# values are typed — only the column NAMES are exercised, because the
# entity classification logic is driven entirely by the CDS code columns.


# ==============================================================================
# Section 1: UNIT TESTS — canonicalize_legacy_assess_school_code()
# ==============================================================================
#
# These tests exercise the normalization helper directly on hand-built
# data frames. They cover every encoding the raw NJ DOE files have been
# observed to emit for the school_code column.

test_that("unit: empty-string school_code collapses to NA", {
  df <- data.frame(school_code = c("", "030", "001"), stringsAsFactors = FALSE)
  out <- canonicalize_legacy_assess_school_code(df)
  expect_true(is.na(out$school_code[1]))
  expect_equal(out$school_code[2], "030")
  expect_equal(out$school_code[3], "001")
})


test_that("unit: literal '000' school_code collapses to NA", {
  df <- data.frame(school_code = c("000", "030", "999"), stringsAsFactors = FALSE)
  out <- canonicalize_legacy_assess_school_code(df)
  expect_true(is.na(out$school_code[1]))
  expect_equal(out$school_code[2], "030")
  expect_equal(out$school_code[3], "999")
})


test_that("unit: whitespace-only school_code (any padding) collapses to NA", {
  # Fixed-width reads can leave 3-space padding intact if the column was
  # read with options that preserve trailing whitespace.
  df <- data.frame(
    school_code = c("   ", " ", "\t", "  "),
    stringsAsFactors = FALSE
  )
  out <- canonicalize_legacy_assess_school_code(df)
  expect_true(all(is.na(out$school_code)))
})


test_that("unit: existing NA school_code stays NA (no double-coercion)", {
  df <- data.frame(school_code = c(NA_character_, "030"), stringsAsFactors = FALSE)
  out <- canonicalize_legacy_assess_school_code(df)
  expect_true(is.na(out$school_code[1]))
  expect_equal(out$school_code[2], "030")
})


test_that("unit: real school codes 001..999 are preserved unchanged", {
  # NJ DOE layout valid_values for School_Code: "001 to 999, blank"
  codes <- c("001", "002", "010", "030", "099", "100", "500", "998", "999")
  df <- data.frame(school_code = codes, stringsAsFactors = FALSE)
  out <- canonicalize_legacy_assess_school_code(df)
  expect_equal(out$school_code, codes)
})


test_that("unit: idempotent — applying twice yields the same result", {
  df <- data.frame(
    school_code = c("", "000", "   ", "030", NA_character_, "999"),
    stringsAsFactors = FALSE
  )
  once <- canonicalize_legacy_assess_school_code(df)
  twice <- canonicalize_legacy_assess_school_code(once)
  expect_identical(once, twice)
})


test_that("unit: missing school_code column passes through unchanged", {
  # Defensive: if the column was dropped upstream, the helper is a no-op.
  df <- data.frame(district_code = c("0010", "0020"), stringsAsFactors = FALSE)
  out <- canonicalize_legacy_assess_school_code(df)
  expect_identical(out, df)
})


test_that("unit: row count and column count are preserved", {
  df <- data.frame(
    school_code = c("", "000", "030"),
    other_col = 1:3,
    stringsAsFactors = FALSE
  )
  out <- canonicalize_legacy_assess_school_code(df)
  expect_equal(nrow(out), 3L)
  expect_equal(ncol(out), 2L)
  expect_equal(out$other_col, 1:3)
})


test_that("unit: school_code column is character type after normalization", {
  # Even if the input column was a factor (which old code paths could
  # produce), the output should be character — same type process_parcc()
  # emits.
  df <- data.frame(
    school_code = factor(c("000", "030", "")),
    stringsAsFactors = FALSE
  )
  out <- canonicalize_legacy_assess_school_code(df)
  expect_type(out$school_code, "character")
})


# ==============================================================================
# Section 2: INTEGRATION TESTS — full tidy_nj_assess() pipeline
# ==============================================================================
#
# These tests construct a process_nj_assess()-shaped data frame where the
# School_Code column contains the mixed encodings that the issue
# documents, then drive the full tidy_nj_assess() pipeline and assert
# the post-tidy output is consistent.

# Build a fixture covering all four cases for district-aggregate encoding
# plus a school row as the control:
#   row 1: regular district, School_Code = ""            (whitespace encoding)
#   row 2: regular district, School_Code = "000"         (sentinel encoding)
#   row 3: regular district, School_Code = NA_character_ (already canonical)
#   row 4: regular school,   School_Code = "030"         (real code, control)
#   row 5: charter district, School_Code = "000"         (charter-sector district)
#   row 6: charter school,   School_Code = "010"         (charter-sector school)
build_mixed_encoding_fixture <- function() {
  data.frame(
    `County_Code/DFG/Aggregation_Code` = c(
      "01", "01", "01", "01", "80", "80"
    ),
    District_Code = c(
      "0010", "0020", "0030", "0010", "0040", "0040"
    ),
    School_Code = c(
      "",            # blank district
      "000",         # sentinel district
      NA_character_, # already canonical
      "030",         # real school code
      "000",         # charter district uses "000" too
      "010"          # charter school
    ),
    County_Name = c(
      "ATLANTIC", "ATLANTIC", "ATLANTIC", "ATLANTIC", "CHARTERS", "CHARTERS"
    ),
    District_Name = c(
      "ABSECON CITY", "ATLANTIC CITY", "BRIGANTINE",
      "ABSECON CITY", "CHARTER A", "CHARTER A"
    ),
    School_Name = c(
      NA, NA, NA,
      "H L JOHNSON SCHOOL",
      NA,
      "CHARTER A SCHOOL"
    ),
    DFG = c("B", "A", "B", "B", NA, NA),
    Special_Needs = rep(NA_character_, 6),
    Testing_Year = rep(2014L, 6),
    Grade = rep(6L, 6),
    TOTAL_POPULATION_Number_Enrolled_ELA = rep(NA_real_, 6),
    TOTAL_POPULATION_LANGUAGE_ARTS_Number_Not_Present = rep(NA_real_, 6),
    TOTAL_POPULATION_LANGUAGE_ARTS_Number_of_Voids = rep(NA_real_, 6),
    TOTAL_POPULATION_LANGUAGE_ARTS_Number_APA = rep(NA_real_, 6),
    TOTAL_POPULATION_LANGUAGE_ARTS_Number_of_Valid_Scale_Scores = rep(NA_real_, 6),
    TOTAL_POPULATION_LANGUAGE_ARTS_Partially_Proficient_Percentage = rep(NA_real_, 6),
    TOTAL_POPULATION_LANGUAGE_ARTS_Proficient_Percentage = rep(NA_real_, 6),
    TOTAL_POPULATION_LANGUAGE_ARTS_Advanced_Proficient_Percentage = rep(NA_real_, 6),
    TOTAL_POPULATION_LANGUAGE_ARTS_Scale_Score_Mean = rep(NA_real_, 6),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}


test_that("integration: tidy_nj_assess output has no '000' school_code values", {
  fx <- build_mixed_encoding_fixture()
  tidy <- tidy_nj_assess("NJASK", fx)
  expect_false(any(tidy$school_code == "000", na.rm = TRUE),
    info = "issue #26: '000' must be normalized to NA in tidy output")
})


test_that("integration: tidy_nj_assess output has no blank/whitespace school_code values", {
  fx <- build_mixed_encoding_fixture()
  tidy <- tidy_nj_assess("NJASK", fx)
  blank_like <- !is.na(tidy$school_code) & trimws(tidy$school_code) == ""
  expect_false(any(blank_like),
    info = "issue #26: whitespace/blank school_code must be normalized to NA")
})


test_that("integration: tidy output emits NA school_code for all four district rows", {
  fx <- build_mixed_encoding_fixture()
  tidy <- tidy_nj_assess("NJASK", fx)
  # Fixture has 4 district-aggregate rows (rows 1, 2, 3, 5 in the fixture).
  # Each appears in the tidy output 1x (single subgroup, single subject).
  district_rows <- tidy[tidy$is_district, ]
  expect_equal(nrow(district_rows), 4L)
  expect_true(all(is.na(district_rows$school_code)),
    info = "every district row must have NA school_code after canonicalization")
})


test_that("integration: school rows preserve their real school_code unchanged", {
  fx <- build_mixed_encoding_fixture()
  tidy <- tidy_nj_assess("NJASK", fx)
  school_rows <- tidy[tidy$is_school, ]
  # Fixture has 2 school rows: regular school "030" and charter school "010".
  expect_equal(nrow(school_rows), 2L)
  expect_setequal(school_rows$school_code, c("030", "010"))
})


test_that("integration: filter(is.na(school_code)) catches ALL district rows", {
  # The original bug: filter(school_code == "000") missed blank-encoded
  # district rows, and filter(is.na(school_code)) missed "000"-encoded
  # district rows. After the fix, the second filter must catch them all.
  fx <- build_mixed_encoding_fixture()
  tidy <- tidy_nj_assess("NJASK", fx)
  # All 4 district rows in our fixture should be caught.
  na_filter_rows <- tidy[is.na(tidy$school_code) & tidy$is_district, ]
  expect_equal(nrow(na_filter_rows), 4L)
})


test_that("integration: filter(school_code == '000') returns ZERO rows post-fix", {
  # After canonicalization, "000" must never appear — the literal-equality
  # filter that the original issue documented should now return no rows.
  fx <- build_mixed_encoding_fixture()
  tidy <- tidy_nj_assess("NJASK", fx)
  zero_zero_zero_rows <- tidy[!is.na(tidy$school_code) & tidy$school_code == "000", ]
  expect_equal(nrow(zero_zero_zero_rows), 0L)
})


test_that("integration: row count unchanged by canonicalization", {
  # The fix is a value normalization, not a row filter — every input row
  # must produce the same number of tidy output rows as it did before.
  fx <- build_mixed_encoding_fixture()
  tidy <- tidy_nj_assess("NJASK", fx)
  # Fixture has 6 input rows × 1 subgroup × 1 subject = 6 tidy rows.
  expect_equal(nrow(tidy), 6L)
})


test_that("integration: HSPA pipeline emits the same canonical encoding", {
  # Same fixture shape, tagged as HSPA — the assess_name parameter
  # changes the constant column but the canonicalization should run
  # identically.
  fx <- build_mixed_encoding_fixture()
  tidy <- tidy_nj_assess("HSPA", fx)
  expect_false(any(tidy$school_code == "000", na.rm = TRUE))
  expect_equal(unique(tidy$assess_name), "HSPA")
})


test_that("integration: GEPA pipeline emits the same canonical encoding", {
  fx <- build_mixed_encoding_fixture()
  tidy <- tidy_nj_assess("GEPA", fx)
  expect_false(any(tidy$school_code == "000", na.rm = TRUE))
  expect_equal(unique(tidy$assess_name), "GEPA")
})


# ==============================================================================
# Section 3: CORRECTNESS TESTS — cross-format invariants
# ==============================================================================
#
# These tests assert structural properties that must hold for the fix to
# be correct, regardless of which fixture is used. They cover:
#   (a) PARCC parity — tidy NJASK and tidy PARCC use the same district
#       row convention (school_code = NA).
#   (b) Filter equivalence — selector-flag filters and value-based
#       filters return identical row sets.
#   (c) is_district / is_school mutual exclusivity.
#   (d) Information preservation — no real school code is lost.
#   (e) Canonical-encoding invariant — only NA or a real 001..999 code
#       ever appears in school_code post-tidy.

test_that("correctness: is_district and is_school are mutually exclusive", {
  fx <- build_mixed_encoding_fixture()
  tidy <- tidy_nj_assess("NJASK", fx)
  expect_false(any(tidy$is_district & tidy$is_school),
    info = "no row may be tagged as both is_district AND is_school")
})


test_that("correctness: is_district implies is.na(school_code)", {
  fx <- build_mixed_encoding_fixture()
  tidy <- tidy_nj_assess("NJASK", fx)
  district_rows <- tidy[tidy$is_district, ]
  expect_true(all(is.na(district_rows$school_code)))
})


test_that("correctness: is_school implies !is.na(school_code)", {
  fx <- build_mixed_encoding_fixture()
  tidy <- tidy_nj_assess("NJASK", fx)
  school_rows <- tidy[tidy$is_school, ]
  expect_true(all(!is.na(school_rows$school_code)))
})


test_that("correctness: filter(is_district) matches the canonical NA-based filter", {
  # The two filters that a tidyverse user would naturally write must
  # return identical row sets. Before the fix, they disagreed.
  fx <- build_mixed_encoding_fixture()
  tidy <- tidy_nj_assess("NJASK", fx)

  flag_filter <- tidy[tidy$is_district, ]
  na_filter <- tidy[
    !is.na(tidy$district_code) &
      is.na(tidy$school_code) &
      !tidy$is_state &
      !tidy$is_dfg, ]

  expect_equal(nrow(flag_filter), nrow(na_filter))
  expect_setequal(flag_filter$district_code, na_filter$district_code)
})


test_that("correctness: every non-NA school_code is a 3-character string", {
  # NJ DOE layout valid_values for School_Code: "001 to 999, blank".
  # After canonicalization the only blank-equivalent is NA; every
  # remaining value must be a 3-char zero-padded code.
  fx <- build_mixed_encoding_fixture()
  tidy <- tidy_nj_assess("NJASK", fx)
  non_na <- tidy$school_code[!is.na(tidy$school_code)]
  expect_true(all(nchar(non_na) == 3),
    info = paste("non-3-char codes:", paste(non_na[nchar(non_na) != 3], collapse = ", ")))
})


test_that("correctness: PARCC and NJASK tidy outputs agree on district-row convention", {
  # process_parcc() emits district rows with school_code/school_id = NA
  # (line 254 of process_assessment.R: is_district = is.na(school_code) &
  #  !is.na(district_code)). After the issue #26 fix, NJASK does the
  # same. This test makes that parity explicit by exercising both
  # pipelines on minimal in-memory fixtures.

  # Build a 1-row PARCC-shaped fixture for a district row.
  parcc_fx <- data.frame(
    county_code = "01", county_name = "ATLANTIC",
    district_code = "0010", district_name = "ABSECON CITY",
    school_code = NA_character_, school_name = NA_character_,
    dfg = "B",
    subgroup_type = "Total", subgroup = "All Students",
    number_enrolled = 100, number_not_tested = 0,
    number_of_valid_scale_scores = 100,
    scale_score_mean = 750,
    pct_l1 = 10, pct_l2 = 20, pct_l3 = 30, pct_l4 = 25, pct_l5 = 15,
    stringsAsFactors = FALSE
  )
  # process_parcc()'s column-order helper expects downstream aggregation
  # columns that don't exist on a minimal raw fixture; the resulting
  # tidyselect "Unknown columns" warning is unrelated to issue #26.
  parcc_tidy <- suppressWarnings(
    process_parcc(parcc_fx, end_year = 2016, grade = 6, subj = "ela")
  )
  parcc_district <- parcc_tidy[parcc_tidy$is_district, ]
  expect_true(all(is.na(parcc_district$school_id)),
    info = "PARCC: district rows have NA school_id")

  # NJASK side.
  njask_fx <- build_mixed_encoding_fixture()
  njask_tidy <- tidy_nj_assess("NJASK", njask_fx)
  njask_district <- njask_tidy[njask_tidy$is_district, ]
  expect_true(all(is.na(njask_district$school_code)),
    info = "NJASK: district rows have NA school_code (post issue #26)")
})


test_that("correctness: canonicalization is value-only — no rows added or dropped", {
  # The fix is normalization. The number of rows tagged as district +
  # school + state + dfg before and after must add up to the same total
  # as the raw input row count × the cross product of subgroups × subjects.
  fx <- build_mixed_encoding_fixture()
  tidy <- tidy_nj_assess("NJASK", fx)
  # Sanity: input was 6 rows, single subgroup, single subject → 6 tidy rows.
  expect_equal(nrow(tidy), 6L)
  # And those 6 rows are exactly 4 district + 2 school (no state/DFG
  # rows in this fixture).
  expect_equal(sum(tidy$is_district), 4L)
  expect_equal(sum(tidy$is_school), 2L)
  expect_equal(sum(tidy$is_state), 0L)
  expect_equal(sum(tidy$is_dfg), 0L)
})


test_that("correctness: canonical-encoding invariant — school_code is NA or 001..999", {
  # The post-tidy column may take only two kinds of values:
  #   (a) NA_character_
  #   (b) a 3-digit code between "001" and "999" inclusive
  # No other strings should ever appear.
  fx <- build_mixed_encoding_fixture()
  tidy <- tidy_nj_assess("NJASK", fx)
  non_na <- tidy$school_code[!is.na(tidy$school_code)]
  # Each non-NA value parses as an integer in [1, 999].
  parsed <- suppressWarnings(as.integer(non_na))
  expect_false(any(is.na(parsed)),
    info = "every non-NA school_code must parse as an integer")
  expect_true(all(parsed >= 1L & parsed <= 999L))
})


test_that("correctness: idempotent end-to-end — re-running canonicalize on tidy output is a no-op", {
  # tidy_nj_assess already runs canonicalize internally; running it
  # again on the tidy output should change nothing.
  fx <- build_mixed_encoding_fixture()
  tidy <- tidy_nj_assess("NJASK", fx)
  tidy_twice <- canonicalize_legacy_assess_school_code(tidy)
  expect_identical(tidy, tidy_twice)
})
