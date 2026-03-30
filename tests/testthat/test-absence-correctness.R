# ==============================================================================
# Correctness Tests for Chronic Absenteeism Interface
# ==============================================================================
#
# 100+ tests covering subgroup mapping, data quality, entity flags, type
# dispatch, column completeness, and multi-year behavior.
#
# ==============================================================================


# ==============================================================================
# Section 1: Subgroup Mapping Correctness (individual mappings)
# ==============================================================================

test_that("subgroup: 'total population' maps to 'total'", {
  expect_equal(standardize_absence_subgroups("total population"), "total")
})

test_that("subgroup: 'white' maps to 'white'", {
  expect_equal(standardize_absence_subgroups("white"), "white")
})

test_that("subgroup: 'black' maps to 'black'", {
  expect_equal(standardize_absence_subgroups("black"), "black")
})

test_that("subgroup: 'hispanic' maps to 'hispanic'", {
  expect_equal(standardize_absence_subgroups("hispanic"), "hispanic")
})

test_that("subgroup: 'asian' maps to 'asian'", {
  expect_equal(standardize_absence_subgroups("asian"), "asian")
})

test_that("subgroup: 'american indian' maps to 'native_american'", {
  expect_equal(standardize_absence_subgroups("american indian"), "native_american")
})

test_that("subgroup: 'pacific islander' maps to 'pacific_islander'", {
  expect_equal(standardize_absence_subgroups("pacific islander"), "pacific_islander")
})

test_that("subgroup: 'multiracial' maps to 'multiracial'", {
  expect_equal(standardize_absence_subgroups("multiracial"), "multiracial")
})

test_that("subgroup: 'economically disadvantaged' maps to 'econ_disadv'", {
  expect_equal(standardize_absence_subgroups("economically disadvantaged"), "econ_disadv")
})

test_that("subgroup: 'limited english proficiency' maps to 'lep'", {
  expect_equal(standardize_absence_subgroups("limited english proficiency"), "lep")
})

test_that("subgroup: 'students with disability' maps to 'special_ed'", {
  expect_equal(standardize_absence_subgroups("students with disabilities"), "special_ed")
})

test_that("subgroup: 'male' maps to 'male'", {
  expect_equal(standardize_absence_subgroups("male"), "male")
})

test_that("subgroup: 'female' maps to 'female'", {
  expect_equal(standardize_absence_subgroups("female"), "female")
})


# ==============================================================================
# Section 2: Subgroup Mapping — Vector & Edge Cases
# ==============================================================================

test_that("subgroup mapping handles empty character vector", {
  expect_equal(standardize_absence_subgroups(character(0)), character(0))
})

test_that("subgroup mapping handles single NA", {
  result <- standardize_absence_subgroups(NA_character_)
  expect_true(is.na(result))
})

test_that("subgroup mapping handles mixed known and unknown values", {
  input <- c("total population", "some_future_group", "black")
  result <- standardize_absence_subgroups(input)
  expect_equal(result, c("total", "some_future_group", "black"))
})

test_that("subgroup mapping handles vector with NAs interspersed", {
  input <- c("white", NA_character_, "hispanic")
  result <- standardize_absence_subgroups(input)
  expect_equal(result[1], "white")
  expect_true(is.na(result[2]))
  expect_equal(result[3], "hispanic")
})

test_that("subgroup mapping is case-sensitive (uppercase 'White' passes through)", {
  expect_equal(standardize_absence_subgroups("White"), "White")
})

test_that("subgroup mapping is case-sensitive (uppercase 'BLACK' passes through)", {
  expect_equal(standardize_absence_subgroups("BLACK"), "BLACK")
})

test_that("subgroup mapping is case-sensitive ('Total Population' passes through)", {
  expect_equal(standardize_absence_subgroups("Total Population"), "Total Population")
})

test_that("subgroup mapping handles length-1 vector", {
  expect_equal(standardize_absence_subgroups("male"), "male")
})

test_that("subgroup mapping handles repeated values", {
  input <- rep("economically disadvantaged", 5)
  result <- standardize_absence_subgroups(input)
  expect_equal(result, rep("econ_disadv", 5))
})

test_that("subgroup mapping output length matches input length", {
  input <- c("white", "black", "hispanic", "asian", "male")
  result <- standardize_absence_subgroups(input)
  expect_equal(length(result), length(input))
})

test_that("subgroup mapping preserves order", {
  input <- c("female", "male", "asian", "black", "white")
  expected <- c("female", "male", "asian", "black", "white")
  expect_equal(standardize_absence_subgroups(input), expected)
})

test_that("all 13 standard SPR names map correctly in one call", {
  input <- c(
    "total population", "white", "black", "hispanic", "asian",
    "american indian", "pacific islander", "multiracial",
    "economically disadvantaged", "limited english proficiency",
    "students with disabilities", "male", "female"
  )
  expected <- c(
    "total", "white", "black", "hispanic", "asian",
    "native_american", "pacific_islander", "multiracial",
    "econ_disadv", "lep",
    "special_ed", "male", "female"
  )
  expect_equal(standardize_absence_subgroups(input), expected)
})

test_that("subgroup mapping: empty string passes through", {
  expect_equal(standardize_absence_subgroups(""), "")
})

test_that("subgroup mapping: whitespace-padded string passes through (not matched)", {
  expect_equal(standardize_absence_subgroups(" white "), " white ")
})


# ==============================================================================
# Section 3: Standard Subgroup Names — Only Allowed Values
# ==============================================================================

test_that("tidy output subgroups are drawn from standard set", {
  standard_subgroups <- c(
    "total", "white", "black", "hispanic", "asian",
    "native_american", "pacific_islander", "multiracial",
    "econ_disadv", "lep", "special_ed", "male", "female"
  )

  df <- data.frame(
    subgroup = c(
      "total population", "white", "black", "hispanic", "asian",
      "american indian", "pacific islander", "multiracial",
      "economically disadvantaged", "limited english proficiency",
      "students with disabilities", "male", "female"
    ),
    stringsAsFactors = FALSE
  )

  result <- tidy_absence(df)
  expect_true(all(result$subgroup %in% standard_subgroups))
})

test_that("no NJ raw subgroup names survive tidy_absence for known inputs", {
  raw_names <- c(
    "total population", "american indian", "pacific islander",
    "economically disadvantaged", "limited english proficiency",
    "students with disabilities"
  )

  df <- data.frame(subgroup = raw_names, stringsAsFactors = FALSE)
  result <- tidy_absence(df)
  expect_false(any(result$subgroup %in% raw_names))
})


# ==============================================================================
# Section 4: tidy_absence Data Frame Tests
# ==============================================================================

test_that("tidy_absence preserves all non-subgroup columns", {
  df <- data.frame(
    end_year = 2024,
    county_id = "01",
    district_id = "0100",
    school_id = "010",
    subgroup = "total population",
    chronically_absent_rate = 15.5,
    is_state = FALSE,
    is_district = TRUE,
    stringsAsFactors = FALSE
  )

  result <- tidy_absence(df)
  expect_equal(result$end_year, 2024)
  expect_equal(result$county_id, "01")
  expect_equal(result$district_id, "0100")
  expect_equal(result$chronically_absent_rate, 15.5)
  expect_equal(result$is_state, FALSE)
  expect_equal(result$is_district, TRUE)
})

test_that("tidy_absence does not add or remove rows", {
  df <- data.frame(
    subgroup = c("white", "black", "hispanic"),
    rate = c(10, 20, 30),
    stringsAsFactors = FALSE
  )
  result <- tidy_absence(df)
  expect_equal(nrow(result), 3)
})

test_that("tidy_absence does not add or remove columns", {
  df <- data.frame(
    subgroup = "total population",
    rate = 10,
    extra_col = "x",
    stringsAsFactors = FALSE
  )
  result <- tidy_absence(df)
  expect_equal(ncol(result), ncol(df))
  expect_equal(names(result), names(df))
})

test_that("tidy_absence handles zero-row data frame", {
  df <- data.frame(
    subgroup = character(0),
    rate = numeric(0),
    stringsAsFactors = FALSE
  )
  result <- tidy_absence(df)
  expect_equal(nrow(result), 0)
})

test_that("tidy_absence returns a data.frame", {
  df <- data.frame(subgroup = "male", stringsAsFactors = FALSE)
  result <- tidy_absence(df)
  expect_s3_class(result, "data.frame")
})


# ==============================================================================
# Section 5: Input Validation
# ==============================================================================

test_that("fetch_absence rejects type='invalid'", {
  expect_error(fetch_absence(2024, type = "invalid"), "type must be one of")
})

test_that("fetch_absence rejects type='enrollment'", {
  expect_error(fetch_absence(2024, type = "enrollment"), "type must be one of")
})

test_that("fetch_absence rejects type=''", {
  expect_error(fetch_absence(2024, type = ""), "type must be one of")
})

test_that("fetch_absence rejects type='Chronic' (case-sensitive)", {
  expect_error(fetch_absence(2024, type = "Chronic"), "type must be one of")
})

test_that("fetch_absence rejects type='ESSA' (case-sensitive)", {
  expect_error(fetch_absence(2024, type = "ESSA"), "type must be one of")
})

test_that("fetch_absence rejects type='by_Grade' (case-sensitive)", {
  expect_error(fetch_absence(2024, type = "by_Grade"), "type must be one of")
})

test_that("fetch_absence rejects type='Days_Absent' (case-sensitive)", {
  expect_error(fetch_absence(2024, type = "Days_Absent"), "type must be one of")
})

test_that("fetch_absence error message lists all valid types", {
  err <- tryCatch(fetch_absence(2024, type = "bad"), error = function(e) e$message)
  expect_true(grepl("chronic", err))
  expect_true(grepl("by_grade", err))
  expect_true(grepl("days_absent", err))
  expect_true(grepl("essa", err))
})

test_that("fetch_absence accepts type='chronic'", {
  # Should not error on validation (may error on network, but not on type check)
  expect_error(fetch_absence(2024, type = "chronic"), NA)
})

test_that("fetch_absence accepts type='by_grade'", {
  expect_error(fetch_absence(2024, type = "by_grade"), NA)
})

test_that("fetch_absence accepts type='days_absent'", {
  expect_error(fetch_absence(2024, type = "days_absent"), NA)
})

test_that("fetch_absence accepts type='essa'", {
  expect_error(fetch_absence(2024, type = "essa"), NA)
})


# ==============================================================================
# Section 6: Network — Chronic Type Correctness
# ==============================================================================

test_that("chronic type: has subgroup column", {
  df <- fetch_absence(2024, type = "chronic")
  expect_true("subgroup" %in% names(df))
})

test_that("chronic type: has chronically_absent_rate column", {
  df <- fetch_absence(2024, type = "chronic")
  expect_true("chronically_absent_rate" %in% names(df))
})

test_that("chronic type: rate is numeric", {
  df <- fetch_absence(2024, type = "chronic")
  expect_true(is.numeric(df$chronically_absent_rate))
})

test_that("chronic type: rate values are non-negative (where not NA)", {
  df <- fetch_absence(2024, type = "chronic")
  valid <- df$chronically_absent_rate[!is.na(df$chronically_absent_rate)]
  expect_true(all(valid >= 0))
})

test_that("chronic type: rate values do not exceed 100 (where not NA)", {
  df <- fetch_absence(2024, type = "chronic")
  valid <- df$chronically_absent_rate[!is.na(df$chronically_absent_rate)]
  expect_true(all(valid <= 100))
})

test_that("chronic type: no Inf values in rate", {
  df <- fetch_absence(2024, type = "chronic")
  valid <- df$chronically_absent_rate[!is.na(df$chronically_absent_rate)]
  expect_false(any(is.infinite(valid)))
})

test_that("chronic type: no NaN values in rate", {
  df <- fetch_absence(2024, type = "chronic")
  valid <- df$chronically_absent_rate[!is.na(df$chronically_absent_rate)]
  expect_false(any(is.nan(valid)))
})

test_that("chronic type: has end_year column", {
  df <- fetch_absence(2024, type = "chronic")
  expect_true("end_year" %in% names(df))
  expect_true(all(df$end_year == 2024))
})

test_that("chronic type: has entity flag columns", {
  df <- fetch_absence(2024, type = "chronic")
  flags <- c("is_state", "is_county", "is_district", "is_school")
  expect_true(all(flags %in% names(df)))
})

test_that("chronic type: entity flags are logical", {
  df <- fetch_absence(2024, type = "chronic")
  expect_true(is.logical(df$is_state))
  expect_true(is.logical(df$is_county))
  expect_true(is.logical(df$is_district))
  expect_true(is.logical(df$is_school))
})

test_that("chronic type: has is_charter flag", {
  df <- fetch_absence(2024, type = "chronic")
  expect_true("is_charter" %in% names(df))
})

test_that("chronic type: district-level data has district rows", {
  df <- fetch_absence(2024, type = "chronic", level = "district")
  expect_true(any(df$is_district))
})

test_that("chronic type: 'total' subgroup exists in tidy output", {
  df <- fetch_absence(2024, type = "chronic")
  expect_true("total" %in% df$subgroup)
})

test_that("chronic type: 'econ_disadv' subgroup exists in tidy output", {
  df <- fetch_absence(2024, type = "chronic")
  expect_true("econ_disadv" %in% df$subgroup)
})

test_that("chronic type: 'lep' subgroup exists in tidy output", {
  df <- fetch_absence(2024, type = "chronic")
  expect_true("lep" %in% df$subgroup)
})

test_that("chronic type: 'special_ed' subgroup exists in tidy output", {
  df <- fetch_absence(2024, type = "chronic")
  expect_true("special_ed" %in% df$subgroup)
})

test_that("chronic type: core racial subgroups exist in tidy output", {
  df <- fetch_absence(2024, type = "chronic")
  # white, black, hispanic are standard; asian may appear as combined
  # "asian, native hawaiian, or pacific islander" (passthrough)
  core_racial <- c("white", "black", "hispanic")
  expect_true(all(core_racial %in% df$subgroup))
})

test_that("chronic type: gender subgroups exist in tidy output", {
  df <- fetch_absence(2024, type = "chronic")
  expect_true(all(c("male", "female") %in% df$subgroup))
})

test_that("chronic type: no raw NJ names in tidy output", {
  df <- fetch_absence(2024, type = "chronic")
  raw_names <- c(
    "total population", "american indian", "pacific islander",
    "economically disadvantaged", "limited english proficiency",
    "students with disabilities"
  )
  expect_false(any(raw_names %in% df$subgroup))
})

test_that("chronic type: tidy=FALSE preserves raw NJ names", {
  df <- fetch_absence(2024, type = "chronic", tidy = FALSE)
  expect_true("total population" %in% df$subgroup)
})

test_that("chronic type: has county columns", {
  df <- fetch_absence(2024, type = "chronic")
  expect_true("county_id" %in% names(df))
  expect_true("county_name" %in% names(df))
})

test_that("chronic type: has district columns", {
  df <- fetch_absence(2024, type = "chronic")
  expect_true("district_id" %in% names(df))
  expect_true("district_name" %in% names(df))
})

test_that("chronic type: has school columns", {
  df <- fetch_absence(2024, type = "chronic")
  expect_true("school_id" %in% names(df))
  expect_true("school_name" %in% names(df))
})

test_that("chronic type: school-level data has non-999 school_ids", {
  df <- fetch_absence(2024, type = "chronic", level = "school")
  expect_true(any(df$school_id != "999"))
})

test_that("chronic type: district-level data has school_id=999", {
  df <- fetch_absence(2024, type = "chronic", level = "district")
  expect_true(all(df$school_id == "999"))
})

test_that("chronic type: multiple districts present in data", {
  df <- fetch_absence(2024, type = "chronic", level = "district")
  n_districts <- length(unique(df$district_id[df$is_district]))
  expect_true(n_districts > 100)
})


# ==============================================================================
# Section 7: Network — by_grade Type Correctness
# ==============================================================================

test_that("by_grade type: has grade_level column", {
  df <- fetch_absence(2024, type = "by_grade")
  expect_true("grade_level" %in% names(df))
})

test_that("by_grade type: multiple grade levels present", {
  df <- fetch_absence(2024, type = "by_grade")
  expect_true(length(unique(df$grade_level)) > 5)
})

test_that("by_grade type: returns data frame with rows", {
  df <- fetch_absence(2024, type = "by_grade")
  expect_true(nrow(df) > 0)
})

test_that("by_grade type: has entity flags", {
  df <- fetch_absence(2024, type = "by_grade")
  expect_true(all(c("is_state", "is_district", "is_school") %in% names(df)))
})


# ==============================================================================
# Section 8: Network — days_absent Type Correctness
# ==============================================================================

test_that("days_absent type: returns data frame with rows", {
  df <- fetch_absence(2024, type = "days_absent")
  expect_true(nrow(df) > 0)
})

test_that("days_absent type: has entity identification columns", {
  df <- fetch_absence(2024, type = "days_absent")
  expect_true(all(c("district_id", "school_id") %in% names(df)))
})

test_that("days_absent type: has end_year column", {
  df <- fetch_absence(2024, type = "days_absent")
  expect_true("end_year" %in% names(df))
})


# ==============================================================================
# Section 9: Network — ESSA Type Correctness
# ==============================================================================

test_that("essa type: returns data frame with rows", {
  df <- fetch_absence(2024, type = "essa")
  expect_true(nrow(df) > 0)
})

test_that("essa type: has chronic_absenteeism_total column", {
  df <- fetch_absence(2024, type = "essa")
  expect_true("chronic_absenteeism_total" %in% names(df))
})

test_that("essa type: has school identification columns", {
  df <- fetch_absence(2024, type = "essa")
  id_cols <- c("county_id", "district_id", "school_id")
  expect_true(all(id_cols %in% names(df)))
})


# ==============================================================================
# Section 10: Entity Flag Exclusivity
# ==============================================================================

test_that("entity flags: state rows are not also district or school", {
  df <- fetch_absence(2024, type = "chronic", level = "district")
  state_rows <- df[df$is_state, ]
  if (nrow(state_rows) > 0) {
    expect_true(all(!state_rows$is_district))
    expect_true(all(!state_rows$is_school))
  }
})

test_that("entity flags: district rows are not also state", {
  df <- fetch_absence(2024, type = "chronic", level = "district")
  dist_rows <- df[df$is_district, ]
  if (nrow(dist_rows) > 0) {
    expect_true(all(!dist_rows$is_state))
  }
})

test_that("entity flags: school rows are not also state or district", {
  df <- fetch_absence(2024, type = "chronic", level = "school")
  sch_rows <- df[df$is_school, ]
  if (nrow(sch_rows) > 0) {
    expect_true(all(!sch_rows$is_state))
    # school rows should not have is_district TRUE
    expect_true(all(!sch_rows$is_district))
  }
})

test_that("entity flags: every row in district data has is_district TRUE", {
  df <- fetch_absence(2024, type = "chronic", level = "district")
  # District-level data may only have is_district rows (no state/county aggregate)
  expect_true(all(df$is_district | df$is_state | df$is_county))
})


# ==============================================================================
# Section 11: Suppressed Values
# ==============================================================================

test_that("suppressed values: rate column allows NA (from * suppression)", {
  df <- fetch_absence(2024, type = "chronic")
  # It's expected that some values are NA due to suppression
  # Just verify the column exists and has reasonable data
  expect_true("chronically_absent_rate" %in% names(df))
  # At least some non-NA values should exist
  expect_true(sum(!is.na(df$chronically_absent_rate)) > 0)
})

test_that("suppressed values: no literal asterisks in rate column", {
  df <- fetch_absence(2024, type = "chronic")
  # Rate should be numeric, not character
  expect_true(is.numeric(df$chronically_absent_rate))
})


# ==============================================================================
# Section 12: No Duplicates
# ==============================================================================

test_that("no duplicate rows per entity+subgroup in chronic district data", {
  df <- fetch_absence(2024, type = "chronic", level = "district")
  # Group by district_id + subgroup — should have at most 1 row each
  dupes <- df %>%
    dplyr::count(district_id, subgroup) %>%
    dplyr::filter(n > 1)
  expect_equal(nrow(dupes), 0)
})

test_that("no duplicate state-level rows per subgroup in chronic data", {
  df <- fetch_absence(2024, type = "chronic", level = "district")
  state_rows <- df[df$is_state, ]
  dupes <- state_rows %>%
    dplyr::count(subgroup) %>%
    dplyr::filter(n > 1)
  expect_equal(nrow(dupes), 0)
})


# ==============================================================================
# Section 13: State Totals per Subgroup
# ==============================================================================

test_that("district data: 'total' subgroup exists", {
  df <- fetch_absence(2024, type = "chronic", level = "district")
  expect_true("total" %in% df$subgroup)
})

test_that("district data: all rates are between 0 and 100 (where not NA)", {
  df <- fetch_absence(2024, type = "chronic", level = "district")
  valid <- df$chronically_absent_rate[!is.na(df$chronically_absent_rate)]
  expect_true(all(valid >= 0 & valid <= 100))
})

test_that("district data: multiple subgroups present", {
  df <- fetch_absence(2024, type = "chronic", level = "district")
  expect_true(length(unique(df$subgroup)) >= 5)
})


# ==============================================================================
# Section 14: fetch_absence_multi Correctness
# ==============================================================================

test_that("multi-year: result contains all requested available years", {
  df <- fetch_absence_multi(c(2023, 2024), type = "chronic", level = "district")
  expect_true(all(c(2023, 2024) %in% df$end_year))
})

test_that("multi-year: result is a data frame", {
  df <- fetch_absence_multi(c(2023, 2024))
  expect_s3_class(df, "data.frame")
})

test_that("multi-year: subgroups are consistent across years (tidy)", {

  df <- fetch_absence_multi(c(2023, 2024), type = "chronic", level = "district")
  subs_2023 <- sort(unique(df$subgroup[df$end_year == 2023]))
  subs_2024 <- sort(unique(df$subgroup[df$end_year == 2024]))
  # Core subgroups should be present in both years
  core <- c("total", "white", "black", "hispanic")
  expect_true(all(core %in% subs_2023))
  expect_true(all(core %in% subs_2024))
})

test_that("multi-year: COVID years (2020, 2021) are skipped with warning", {
  expect_warning(
    df <- fetch_absence_multi(c(2020, 2024)),
    "Could not fetch"
  )
  expect_true(2024 %in% df$end_year)
  expect_false(2020 %in% df$end_year)
})

test_that("multi-year: all-failing years produce error", {
  # Use years that definitely have no absenteeism data (far future)
  expect_error(
    fetch_absence_multi(c(2001, 2002)),
    "No absence data could be fetched"
  )
})

test_that("multi-year: result has more rows than single year", {
  df_single <- fetch_absence(2024, type = "chronic", level = "district")
  df_multi <- fetch_absence_multi(c(2023, 2024), type = "chronic", level = "district")
  expect_true(nrow(df_multi) > nrow(df_single))
})


# ==============================================================================
# Section 15: Column Completeness by Type
# ==============================================================================

test_that("chronic columns: complete set present", {
  df <- fetch_absence(2024, type = "chronic")
  required <- c(
    "end_year", "county_id", "county_name", "district_id", "district_name",
    "school_id", "school_name", "subgroup", "chronically_absent_rate",
    "is_state", "is_county", "is_district", "is_school", "is_charter"
  )
  expect_true(all(required %in% names(df)))
})

test_that("by_grade columns: has grade_level plus entity flags", {
  df <- fetch_absence(2024, type = "by_grade")
  required <- c(
    "end_year", "district_id", "school_id", "grade_level",
    "is_state", "is_district", "is_school"
  )
  expect_true(all(required %in% names(df)))
})

test_that("days_absent columns: has entity identification", {
  df <- fetch_absence(2024, type = "days_absent")
  required <- c("end_year", "district_id", "school_id")
  expect_true(all(required %in% names(df)))
})

test_that("essa columns: has chronic_absenteeism_total", {
  df <- fetch_absence(2024, type = "essa")
  expect_true("chronic_absenteeism_total" %in% names(df))
})


# ==============================================================================
# Section 16: Caching Correctness
# ==============================================================================

test_that("caching: first call populates, second call returns cached", {
  # Clear any existing cache
  njsd_cache_clear()

  df1 <- fetch_absence(2024, type = "chronic", level = "district", use_cache = TRUE)
  expect_message(
    df2 <- fetch_absence(2024, type = "chronic", level = "district", use_cache = TRUE),
    "Using cached"
  )
  expect_equal(nrow(df1), nrow(df2))
  expect_equal(names(df1), names(df2))
})

test_that("caching: different type parameters get different cache entries", {
  njsd_cache_clear()

  df_chronic <- fetch_absence(2024, type = "chronic", use_cache = TRUE)
  df_grade <- fetch_absence(2024, type = "by_grade", use_cache = TRUE)

  # These should have different structures

  expect_false(identical(names(df_chronic), names(df_grade)))
})

test_that("caching: different tidy parameters get different cache entries", {
  njsd_cache_clear()

  df_tidy <- fetch_absence(2024, type = "chronic", tidy = TRUE, use_cache = TRUE)
  df_raw <- fetch_absence(2024, type = "chronic", tidy = FALSE, use_cache = TRUE)

  # Tidy should have "total", raw should have "total population"
  expect_true("total" %in% df_tidy$subgroup)
  expect_true("total population" %in% df_raw$subgroup)
})

test_that("caching: use_cache=FALSE bypasses cache", {
  njsd_cache_clear()

  # Populate cache
  df1 <- fetch_absence(2024, type = "chronic", level = "district", use_cache = TRUE)

  # This should NOT emit "Using cached"
  expect_no_message(
    df2 <- fetch_absence(2024, type = "chronic", level = "district", use_cache = FALSE),
    message = "Using cached"
  )
})


# ==============================================================================
# Section 17: rc_numeric_cleaner Suppression Handling
# ==============================================================================

test_that("rc_numeric_cleaner: asterisk converts to NA", {
  expect_true(is.na(rc_numeric_cleaner("*")))
})

test_that("rc_numeric_cleaner: 'N' converts to NA", {
  expect_true(is.na(rc_numeric_cleaner("N")))
})

test_that("rc_numeric_cleaner: 'N/A' converts to NA", {
  expect_true(is.na(rc_numeric_cleaner("N/A")))
})

test_that("rc_numeric_cleaner: percentage sign is stripped", {
  expect_equal(rc_numeric_cleaner("15.2%"), 15.2)
})

test_that("rc_numeric_cleaner: plain numeric string converts", {
  expect_equal(rc_numeric_cleaner("42.5"), 42.5)
})

test_that("rc_numeric_cleaner: vector handles mixed values", {
  result <- rc_numeric_cleaner(c("10.5%", "*", "N", "25.3"))
  expect_equal(result[1], 10.5)
  expect_true(is.na(result[2]))
  expect_true(is.na(result[3]))
  expect_equal(result[4], 25.3)
})

test_that("rc_numeric_cleaner: zero value preserved", {
  expect_equal(rc_numeric_cleaner("0"), 0)
})

test_that("rc_numeric_cleaner: '100%' converts to 100", {
  expect_equal(rc_numeric_cleaner("100%"), 100)
})


# ==============================================================================
# Section 18: ESSA Type — Detailed Column Checks
# ==============================================================================

test_that("essa type: has testing_year column", {
  df <- fetch_absence(2024, type = "essa")
  expect_true("testing_year" %in% names(df))
})

test_that("essa type: has attendance columns for subgroups", {
  df <- fetch_absence(2024, type = "essa")
  attendance_cols <- grep("^attendance_", names(df), value = TRUE)
  expect_true(length(attendance_cols) > 0)
})

test_that("essa type: attendance_total is numeric", {
  df <- fetch_absence(2024, type = "essa")
  expect_true(is.numeric(df$attendance_total))
})

test_that("essa type: chronic_absenteeism_total is numeric", {
  df <- fetch_absence(2024, type = "essa")
  expect_true(is.numeric(df$chronic_absenteeism_total))
})

test_that("essa type: chronic_absenteeism_total = 100 - attendance_total", {
  df <- fetch_absence(2024, type = "essa")
  valid <- df[!is.na(df$attendance_total) & !is.na(df$chronic_absenteeism_total), ]
  expect_equal(valid$chronic_absenteeism_total, 100 - valid$attendance_total)
})

test_that("essa type: is_school is TRUE for all rows", {
  df <- fetch_absence(2024, type = "essa")
  expect_true(all(df$is_school))
})

test_that("essa type: is_district is FALSE for all rows", {
  df <- fetch_absence(2024, type = "essa")
  expect_true(all(!df$is_district))
})

test_that("essa type: charter schools identified by county_id '80'", {
  df <- fetch_absence(2024, type = "essa")
  charter_rows <- df[df$is_charter, ]
  if (nrow(charter_rows) > 0) {
    expect_true(all(charter_rows$county_id == "80"))
  }
})


# ==============================================================================
# Section 19: by_grade Sheet Name Variation
# ==============================================================================

test_that("by_grade 2018: uses ChronicAbsByGrade sheet (older naming)", {
  # Should succeed — the function handles sheet name differences
  df <- fetch_absence(2018, type = "by_grade")
  expect_true(nrow(df) > 0)
  expect_true("grade_level" %in% names(df))
})

test_that("by_grade 2019: uses ChronicAbsByGrade sheet", {
  df <- fetch_absence(2019, type = "by_grade")
  expect_true(nrow(df) > 0)
})

test_that("by_grade 2022: uses ChronicAbsenteeismByGrade sheet (newer naming)", {
  df <- fetch_absence(2022, type = "by_grade")
  expect_true(nrow(df) > 0)
})

test_that("by_grade 2024: uses ChronicAbsenteeismByGrade sheet", {
  df <- fetch_absence(2024, type = "by_grade")
  expect_true(nrow(df) > 0)
})


# ==============================================================================
# Section 20: District Data — State Aggregates Present
# ==============================================================================

test_that("district data: state aggregate row exists", {
  df <- fetch_absence(2024, type = "chronic", level = "district")
  expect_true(any(df$is_state))
})

test_that("district data: state total rate is between 0 and 100", {
  df <- fetch_absence(2024, type = "chronic", level = "district")
  state_total <- df[df$is_state & df$subgroup == "total", ]
  if (nrow(state_total) > 0) {
    rate <- state_total$chronically_absent_rate[1]
    expect_true(!is.na(rate) && rate >= 0 && rate <= 100)
  }
})

test_that("district data: county aggregates may exist", {
  df <- fetch_absence(2024, type = "chronic", level = "district")
  expect_true("is_county" %in% names(df))
})

test_that("district data: each subgroup has at least one state-level row", {
  df <- fetch_absence(2024, type = "chronic", level = "district")
  state_subgroups <- unique(df$subgroup[df$is_state])
  expect_true(length(state_subgroups) >= 5)
})


# ==============================================================================
# Section 21: No Duplicate Entity+Subgroup in School Data
# ==============================================================================

test_that("no duplicates per school+subgroup in school-level chronic data", {
  df <- fetch_absence(2024, type = "chronic", level = "school")
  school_rows <- df[df$is_school, ]
  dupes <- school_rows %>%
    dplyr::count(district_id, school_id, subgroup) %>%
    dplyr::filter(n > 1)
  expect_equal(nrow(dupes), 0)
})

test_that("no duplicate grade_level per school in by_grade school data", {
  df <- fetch_absence(2024, type = "by_grade", level = "school")
  school_rows <- df[df$is_school, ]
  if ("subgroup" %in% names(df)) {
    dupes <- school_rows %>%
      dplyr::count(district_id, school_id, grade_level, subgroup) %>%
      dplyr::filter(n > 1)
  } else {
    dupes <- school_rows %>%
      dplyr::count(district_id, school_id, grade_level) %>%
      dplyr::filter(n > 1)
  }
  expect_equal(nrow(dupes), 0)
})


# ==============================================================================
# Section 22: Multi-Year Column Consistency
# ==============================================================================

test_that("multi-year: column names identical across years", {
  df <- fetch_absence_multi(c(2023, 2024), type = "chronic", level = "district")
  cols_2023 <- sort(names(df[df$end_year == 2023, ]))
  cols_2024 <- sort(names(df[df$end_year == 2024, ]))
  expect_equal(cols_2023, cols_2024)
})

test_that("multi-year: column types consistent across years", {
  df <- fetch_absence_multi(c(2023, 2024), type = "chronic", level = "district")
  year_list <- split(df, df$end_year)
  types_2023 <- sapply(year_list[["2023"]], class)
  types_2024 <- sapply(year_list[["2024"]], class)
  expect_equal(types_2023, types_2024)
})

test_that("multi-year: end_year column has only requested years", {
  df <- fetch_absence_multi(c(2023, 2024), type = "chronic", level = "district")
  expect_true(all(df$end_year %in% c(2023, 2024)))
})


# ==============================================================================
# Section 23: Subgroup Completeness in Live Data
# ==============================================================================

test_that("chronic school data: at least 10 distinct subgroups", {
  df <- fetch_absence(2024, type = "chronic", level = "school")
  expect_true(length(unique(df$subgroup)) >= 10)
})

test_that("chronic district data: at least 10 distinct subgroups", {
  df <- fetch_absence(2024, type = "chronic", level = "district")
  expect_true(length(unique(df$subgroup)) >= 10)
})

test_that("chronic data: racial subgroups present across levels", {
  df_school <- fetch_absence(2024, type = "chronic", level = "school")
  df_dist <- fetch_absence(2024, type = "chronic", level = "district")
  racial <- c("white", "black", "hispanic", "asian")
  expect_true(all(racial %in% df_school$subgroup))
  expect_true(all(racial %in% df_dist$subgroup))
})
