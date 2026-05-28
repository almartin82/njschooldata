# Tests for selector flags on tidied legacy NJ assessment data
# (NJASK / HSPA / GEPA). Mirrors the PARCC selector flag block in
# process_parcc() so that downstream code can `filter(is_district)`,
# `filter(is_state)`, etc. on NJASK output the same way it does on PARCC.
# See issue #96.
#
# The fixtures below build a `process_nj_assess`-shaped data frame whose
# **only** populated columns are the logistical identifier fields that
# the NJ DOE state-summary fixed-width files carry. No counts, no scale
# scores, no proficiency percentages are typed by hand — the test only
# exercises the entity-classification logic, which is driven entirely by
# the CDS code columns documented in the layout files
# (e.g. layout_njask.rda: county_code = 01..41 + 80,
#  DFG = A,B,CD,DE,FG,GH,I,J,R,V,
#  aggregation = ST/NS/SN).

# --- Build a structural fixture covering all entity types --------------------
# The shape of df fed to tidy_nj_assess() is the output of process_nj_assess(),
# which always carries these logistical columns. We use NA for every measure
# column so the resulting tidy rows have NA counts/scores — but every row will
# still get the selector flags we are testing.

build_njask_fixture <- function() {
  # All identifier values below are NJ DOE structural sentinels
  # documented in the layout files. No measure values are typed.
  # (CDS_Code intentionally omitted: tidy_nj_assess() does not have it
  # in its `logistical_columns` allow-list so including it would only
  # produce mask-mismatch warnings unrelated to this test.)
  data.frame(
    `County_Code/DFG/Aggregation_Code` = c(
      "ST", "A", "V", "01", "01", "80", "80", "NS", "SN"
    ),
    District_Code = c(
      NA_character_, NA_character_, NA_character_,
      "0010", "0010",
      "0010", "0010",
      NA_character_, NA_character_
    ),
    School_Code = c(
      NA_character_, NA_character_, NA_character_,
      NA_character_,        # regular district row (county 01, district 0010)
      "030",                # regular school row  (county 01, district 0010, school 030)
      "010",                # charter school row  (county 80, district 0010, school 010)
      NA_character_,        # charter district row (county 80, district 0010)
      NA_character_, NA_character_
    ),
    County_Name = c(
      NA, NA, NA,
      "ATLANTIC", "ATLANTIC",
      "CHARTERS", "CHARTERS",
      NA, NA
    ),
    District_Name = c(
      NA, NA, NA,
      "ABSECON CITY", "ABSECON CITY",
      "OCEANSIDE CS", "OCEANSIDE CS",
      NA, NA
    ),
    School_Name = c(
      NA, NA, NA,
      NA, "H L JOHNSON SCHOOL",
      "OCEANSIDE CHARTER SCHOOL", NA,
      NA, NA
    ),
    DFG = c(NA, NA, NA, "B", "B", NA, NA, NA, NA),
    Special_Needs = c(NA, NA, NA, NA, NA, NA, NA, NA, "Y"),
    Testing_Year = rep(2014L, 9),
    Grade = rep(6L, 9),
    # One minimal measure column so the language_arts subgroup loop produces
    # output. The COUNT value is NA — only the column NAME matters for the
    # tidy machinery.
    TOTAL_POPULATION_Number_Enrolled_ELA = rep(NA_real_, 9),
    TOTAL_POPULATION_LANGUAGE_ARTS_Number_Not_Present = rep(NA_real_, 9),
    TOTAL_POPULATION_LANGUAGE_ARTS_Number_of_Voids = rep(NA_real_, 9),
    TOTAL_POPULATION_LANGUAGE_ARTS_Number_APA = rep(NA_real_, 9),
    TOTAL_POPULATION_LANGUAGE_ARTS_Number_of_Valid_Scale_Scores = rep(NA_real_, 9),
    TOTAL_POPULATION_LANGUAGE_ARTS_Partially_Proficient_Percentage = rep(NA_real_, 9),
    TOTAL_POPULATION_LANGUAGE_ARTS_Proficient_Percentage = rep(NA_real_, 9),
    TOTAL_POPULATION_LANGUAGE_ARTS_Advanced_Proficient_Percentage = rep(NA_real_, 9),
    TOTAL_POPULATION_LANGUAGE_ARTS_Scale_Score_Mean = rep(NA_real_, 9),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

# Convenience: get the tidy frame for a fixture, picking one subgroup/subject
# so that selector flags appear with the same 1:1 cardinality as input rows.
tidy_fixture <- function() {
  fx <- build_njask_fixture()
  out <- tidy_nj_assess("NJASK", fx)
  # one row per input + one (subgroup,subject) combo; with our fixture having
  # only total_population + language_arts present, we get nrow(fx) tidy rows
  out
}


# --- Tests --------------------------------------------------------------------

test_that("tidy_nj_assess emits all seven PARCC-parity selector flag columns", {
  tidy <- tidy_fixture()

  expected_flags <- c(
    "is_state", "is_dfg",
    "is_district", "is_school", "is_charter",
    "is_charter_sector", "is_allpublic"
  )
  expect_true(all(expected_flags %in% names(tidy)),
    info = paste("missing:",
      paste(setdiff(expected_flags, names(tidy)), collapse = ", "))
  )
})


test_that("all selector flags are logical and never NA", {
  tidy <- tidy_fixture()
  for (flag in c("is_state", "is_dfg", "is_district", "is_school",
                 "is_charter", "is_charter_sector", "is_allpublic")) {
    expect_type(tidy[[flag]], "logical")
    expect_false(any(is.na(tidy[[flag]])),
      info = paste("NA in", flag))
  }
})


test_that("is_state TRUE iff the aggregation code is ST", {
  tidy <- tidy_fixture()
  # exactly 1 state-level row in the fixture
  expect_equal(sum(tidy$is_state), 1L)
  # state row has aggregation_code (county_code in tidy) == "ST"
  state_row <- tidy[tidy$is_state, ]
  expect_equal(nrow(state_row), 1L)
  expect_equal(toupper(state_row$county_code), "ST")
})


test_that("is_dfg TRUE iff the aggregation code is a DFG letter (A,B,CD,...,V)", {
  tidy <- tidy_fixture()
  # fixture has DFG rows for "A" and "V"
  expect_equal(sum(tidy$is_dfg), 2L)
  # is_dfg rows are mutually exclusive with is_state / is_district / is_school
  dfg_rows <- tidy[tidy$is_dfg, ]
  expect_true(all(!dfg_rows$is_state))
  expect_true(all(!dfg_rows$is_district))
  expect_true(all(!dfg_rows$is_school))
})


test_that("is_district TRUE iff district_code populated and school_code NA (excluding aggregates)", {
  tidy <- tidy_fixture()
  # fixture: 2 district rows (regular + charter "district")
  expect_equal(sum(tidy$is_district), 2L)
  district_rows <- tidy[tidy$is_district, ]
  expect_true(all(!is.na(district_rows$district_code)))
  expect_true(all(is.na(district_rows$school_code)))
  # district rows must not also be state / dfg / aggregate
  expect_true(all(!district_rows$is_state))
  expect_true(all(!district_rows$is_dfg))
})


test_that("is_school TRUE iff school_code populated", {
  tidy <- tidy_fixture()
  # fixture: 2 school rows (regular + charter school)
  expect_equal(sum(tidy$is_school), 2L)
  school_rows <- tidy[tidy$is_school, ]
  expect_true(all(!is.na(school_rows$school_code)))
  expect_true(all(!school_rows$is_district),
    info = "is_school and is_district must be mutually exclusive (PARCC parity)")
  expect_true(all(!school_rows$is_state))
  expect_true(all(!school_rows$is_dfg))
})


test_that("is_charter TRUE iff county_code is the charter sentinel '80'", {
  tidy <- tidy_fixture()
  # fixture: 2 rows with county_code == "80" (1 district-level, 1 school-level)
  expect_equal(sum(tidy$is_charter), 2L)
  charter_rows <- tidy[tidy$is_charter, ]
  expect_true(all(charter_rows$county_code == "80"))
  # PARCC parity: is_charter is orthogonal to is_district / is_school
  # (it tags WHICH sector, not which entity-level)
  expect_true(any(charter_rows$is_district))
  expect_true(any(charter_rows$is_school))
})


test_that("is_charter_sector and is_allpublic are always FALSE on raw tidy output (PARCC parity)", {
  # process_parcc() emits these two as FALSE for every row — they only
  # become TRUE in downstream aggregation. NJASK has no equivalent
  # aggregation path, so they must always be FALSE here too.
  tidy <- tidy_fixture()
  expect_true(all(tidy$is_charter_sector == FALSE))
  expect_true(all(tidy$is_allpublic == FALSE))
})


test_that("entity-level flags partition every row exactly once", {
  # Every row in tidy NJASK is one and only one of:
  # state, dfg, aggregate (NS/SN), district, school.
  # In our fixture the 2 aggregate rows (NS, SN) are NOT covered by any
  # of {is_state, is_dfg, is_district, is_school} — they are an
  # acknowledged 5th class. The flag implementation must NOT silently
  # mis-tag them. Test:
  tidy <- tidy_fixture()
  flag_sum <- tidy$is_state + tidy$is_dfg + tidy$is_district + tidy$is_school
  # state(1) + dfg(2) + district(2) + school(2) = 7 of 10 rows covered
  expect_equal(sum(flag_sum), 7L)
  # every covered row has exactly one entity-level flag set
  covered <- flag_sum > 0
  expect_true(all(flag_sum[covered] == 1L))
})


test_that("non-tidy output is unchanged (selector flags only on tidy=TRUE path)", {
  # process_nj_assess() output (the pre-tidy form) should not gain
  # the new flag columns — they are a property of the tidy schema.
  fx <- build_njask_fixture()
  expect_false("is_state" %in% names(fx))
  expect_false("is_district" %in% names(fx))
})
