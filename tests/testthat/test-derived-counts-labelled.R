# Derived counts: label them, do not remove them (plan 09, njschooldata batch 1)
#
# Four sites in this package compute a count from a published percentage times
# a same-cell published denominator:
#   - special_pop.R:45          get_reportcard_special_pop()  -> fetch_reportcard_special_pop()
#   - report_card.R:788         enrich_rc_enrollment()
#   - agg_calcs.R:136-140       parcc_perf_level_counts()      -> fetch_parcc()/fetch_njgpa()
#   - fetch_enrollment.R:143-146 .parse_enr_archive() pct_cols loop -> fetch_enr()
#
# Every affected output carries a `value_source` column (wide enrollment
# carries it per field, as `<field>_value_source`, because one wide row mixes
# columns of different provenance): "published" (a real state count),
# "derived_from_pct" (this row's own published pct x this row's own published
# denominator), or "published_pct_only" (the state published only a percent;
# the count is NA). This file quotes real rows from bundled/fixture NJ DOE
# files for fetch_enr() and parcc_perf_level_counts() per the campaign plan;
# special_pop.R and report_card.R have no bundled Report Card fixture, so
# their correctness tests are live-gated like every other test on those two
# functions in this suite (test_issue_reproductions.R).

fixture_request <- function(name, content_type) {
  fx <- source_adapter_fixture(name)
  force(content_type)
  function(url, dest, timeout) {
    file.copy(fx, dest, overwrite = TRUE)
    list(status_code = 200L, final_url = url, content_type = content_type)
  }
}

# -----------------------------------------------------------------------------
# fetch_enr() -- real bundled district row, enrollment-2020.zip
# -----------------------------------------------------------------------------
#
# No 2024 enrollment archive is bundled in this package; enrollment-2020.zip
# (used by the existing censoring test in test-source-adapter-fixtures.R) is
# the real bundled 2020+-format file, and the modern pct_cols derivation this
# item labels is identical in every 2020+ year. County 05 / district 3650 /
# school 300 published "%Free Lunch" = "9.8" against Total Enrollment = 640
# for end_year 2020 -- both real NJ DOE numbers for the same row.

test_that("fetch_enr(tidy=TRUE) labels a real derived district row derived_from_pct", {
  raw <- source_result_data(get_raw_enr_result(
    2020, request_fn = fixture_request("enrollment-2020.zip", "application/zip")
  ))
  wide <- process_enr(raw)
  tidy <- suppressWarnings(tidy_enr(wide))

  expect_true("value_source" %in% names(tidy))
  expect_true(all(
    stats::na.omit(unique(tidy$value_source)) %in%
      c("published", "derived_from_pct", "published_pct_only")
  ))

  row <- tidy[
    tidy$cds_code == "053650300" & tidy$subgroup == "free_lunch",
  ]
  expect_equal(nrow(row), 1L)
  expect_identical(row$value_source, "derived_from_pct")
  # count == pct/100 * row_total for this row's own published percent (9.8)
  # and this row's own published total enrollment (640) -- never rounded.
  expect_equal(row$n_students, 9.8 / 100 * 640)
  expect_equal(row$pct, 9.8 / 100)

  # free_reduced_lunch sums two derived_from_pct components and inherits the
  # label rather than going unlabelled.
  frl <- tidy[tidy$cds_code == "053650300" & tidy$subgroup == "free_reduced_lunch", ]
  expect_equal(nrow(frl), 1L)
  expect_identical(frl$value_source, "derived_from_pct")

  # race/gender subgroups and total_enrollment are real published counts,
  # never derived from a percent.
  demo <- tidy[
    tidy$cds_code == "053650300" &
      tidy$subgroup %in% c("total_enrollment", "white", "male", "female"),
  ]
  expect_true(nrow(demo) > 0)
  expect_true(all(demo$value_source == "published"))
})

test_that("fetch_enr(tidy=TRUE) never derives a count from a missing denominator or a censored percent", {
  raw <- source_result_data(get_raw_enr_result(
    2020, request_fn = fixture_request("enrollment-2020.zip", "application/zip")
  ))
  wide <- process_enr(raw)
  tidy <- suppressWarnings(tidy_enr(wide))

  # cds_code 313970999 published its 2019-20 free-lunch share as the
  # censoring token ">95", not a number (see test-source-adapter-fixtures.R).
  # tidy_enr() drops rows whose value is entirely unknown -- absence, not a
  # fabricated number, is the honest outcome, so this subgroup must not
  # appear with a derived_from_pct label or a manufactured count.
  censored <- tidy[tidy$cds_code == "313970999" & tidy$subgroup == "free_lunch", ]
  expect_equal(nrow(censored), 0L)
  expect_false(13250.25 %in% tidy$n_students[tidy$cds_code == "313970999"])

  # Rule 4, generally: value_source == "published_pct_only" implies n_students
  # is NA, and no row with a non-NA denominator's subgroup count is missing
  # its label.
  pct_only <- tidy[!is.na(tidy$value_source) & tidy$value_source == "published_pct_only", ]
  if (nrow(pct_only) > 0) {
    expect_true(all(is.na(pct_only$n_students)))
  }
})

test_that("fetch_enr() wide output carries a per-field value_source for the 2020+ derived populations", {
  raw <- source_result_data(get_raw_enr_result(
    2020, request_fn = fixture_request("enrollment-2020.zip", "application/zip")
  ))
  wide <- process_enr(raw)

  expected_cols <- c(
    "free_lunch_value_source", "reduced_lunch_value_source",
    "lep_value_source", "migrant_value_source", "homeless_value_source"
  )
  expect_true(all(expected_cols %in% names(wide)))

  row <- wide[
    wide$county_id == "05" & wide$district_id == "3650" &
      wide$school_id == "300" & wide$grade_level == "TOTAL",
  ]
  expect_equal(nrow(row), 1L)
  expect_identical(row$free_lunch_value_source, "derived_from_pct")
  expect_equal(row$free_lunch, 9.8 / 100 * 640)

  # The statewide row is bound in directly from the State worksheet, which
  # publishes these as real counts with no percentage column at all -- the
  # marker is genuinely absent for that row (not "unknown"), and the wide
  # frame must not invent a label for it.
  state_row <- wide[
    wide$county_id == "99" & wide$district_id == "9999" &
      wide$school_id == "999" & wide$grade_level == "TOTAL",
  ]
  expect_equal(nrow(state_row), 1L)
  expect_true(is.na(state_row$free_lunch_value_source))
  expect_false(is.na(state_row$free_lunch))
})

# -----------------------------------------------------------------------------
# parcc_perf_level_counts() -- real bundled row, njsla-ela04-2025.xlsx
# -----------------------------------------------------------------------------
#
# County 01 / district 0010 (Absecon) / school 060, grade 4 ELA, "All
# Students": Valid Scores = 82, L1 Percent = 9.8, L2 = 18.3, L3 = 26.8,
# L4 = 36.6, L5 = 8.5 -- all real NJDOE-published numbers for this one row.

test_that("parcc_perf_level_counts labels a real derived row and a real percentage-only row", {
  raw <- source_result_data(get_raw_sla_result(
    2025, 4, "ela",
    request_fn = fixture_request(
      "njsla-ela04-2025.xlsx",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    )
  ))
  processed <- process_parcc(raw, 2025, 4, "ela")

  expect_true("value_source" %in% names(processed))
  expect_true(all(
    stats::na.omit(unique(processed$value_source)) %in%
      c("published", "derived_from_pct", "published_pct_only")
  ))

  all_students <- processed[processed$subgroup == "All Students", ]
  expect_equal(nrow(all_students), 1L)
  expect_identical(all_students$value_source, "derived_from_pct")
  expect_equal(all_students$number_of_valid_scale_scores, 82)
  # num_lN == round(pct_lN / 100 * number_of_valid_scale_scores) for this
  # row's own published percentages and its own published Valid Scores.
  expect_equal(all_students$num_l1, round(9.8 / 100 * 82))
  expect_equal(all_students$num_l2, round(18.3 / 100 * 82))
  expect_equal(all_students$num_l3, round(26.8 / 100 * 82))
  expect_equal(all_students$num_l4, round(36.6 / 100 * 82))
  expect_equal(all_students$num_l5, round(8.5 / 100 * 82))

  # A real row on the SAME sheet where NJDOE suppressed Valid Scores (small
  # cell): number_of_valid_scale_scores is NA, so every num_lN must be NA and
  # the row must be labelled published_pct_only, never a fabricated count.
  suppressed <- processed[
    processed$subgroup == "Black or African American",
  ]
  expect_equal(nrow(suppressed), 1L)
  expect_true(is.na(suppressed$number_of_valid_scale_scores))
  expect_identical(suppressed$value_source, "published_pct_only")
  expect_true(all(is.na(suppressed[, c("num_l1", "num_l2", "num_l3", "num_l4", "num_l5")])))
})

test_that("parcc_perf_level_counts never derives a count from a missing denominator, even if a percent is present", {
  # In the bundled fixture, a suppressed number_of_valid_scale_scores always
  # coincides with a suppressed pct_lN (NJDOE withholds both together), so
  # that real row alone cannot distinguish "correctly propagates NA" from "a
  # zero-filled denominator happened to multiply out to NA anyway". This
  # constructs the one input shape the fixture cannot: a published pct with a
  # missing denominator, to pin rule 4 (no derived count exists where the
  # denominator is NA) directly against the function under test.
  synthetic <- data.frame(
    pct_l1 = 50, pct_l2 = 50, pct_l3 = NA_real_, pct_l4 = NA_real_, pct_l5 = NA_real_,
    number_of_valid_scale_scores = NA_real_
  )
  out <- parcc_perf_level_counts(synthetic)
  expect_true(is.na(out$num_l1))
  expect_true(is.na(out$num_l2))
  expect_identical(out$value_source, "published_pct_only")
})

test_that("fetch_parcc/fetch_njgpa output (via parcc_column_order) retains value_source", {
  raw <- source_result_data(get_raw_sla_result(
    2025, 4, "ela",
    request_fn = fixture_request(
      "njsla-ela04-2025.xlsx",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    )
  ))
  # process_parcc() unconditionally derives and runs parcc_column_order(),
  # which is what fetch_parcc() returns for both tidy = TRUE and FALSE.
  ordered <- process_parcc(raw, 2025, 4, "ela")
  expect_true("value_source" %in% names(ordered))
  expect_identical(
    ordered$value_source[ordered$subgroup == "All Students"],
    "derived_from_pct"
  )

  # parcc_aggregate_calcs() output (charter-sector roll-ups) is an
  # already-derived aggregate, not a same-cell conversion, so it carries no
  # value_source -- parcc_column_order() must not error when the column is
  # absent (dplyr::one_of()).
  aggregated <- ordered %>%
    dplyr::group_by(testing_year, assess_name, test_name, grade, subgroup, subgroup_type) %>%
    parcc_aggregate_calcs() %>%
    dplyr::ungroup()
  expect_false("value_source" %in% names(aggregated))
  reordered <- parcc_column_order(aggregated %>% dplyr::mutate(
    county_id = NA_character_, county_name = NA_character_,
    district_id = NA_character_, district_name = NA_character_,
    school_id = NA_character_, school_name = NA_character_,
    is_state = FALSE, is_dfg = FALSE, is_district = FALSE, is_school = FALSE,
    is_charter = FALSE, is_charter_sector = FALSE, is_allpublic = FALSE
  ))
  expect_false("value_source" %in% names(reordered))
})

# -----------------------------------------------------------------------------
# special_pop.R / report_card.R -- no bundled Report Card fixture; live-gated
# like every other correctness test on these two functions in this suite
# (test_issue_reproductions.R "Issue #134").
# -----------------------------------------------------------------------------

test_that("fetch_reportcard_special_pop labels n_students derived_from_pct against real data", {
  skip_if_no_live_tests()

  result <- njsd_live(
    fetch_reportcard_special_pop(2019),
    "fetch_reportcard_special_pop(2019)"
  )

  expect_true("value_source" %in% names(result))
  expect_true(all(
    stats::na.omit(unique(result$value_source)) %in%
      c("derived_from_pct", "published_pct_only")
  ))

  check <- result %>%
    dplyr::filter(!is.na(percent) & !is.na(n_enrolled) & n_enrolled > 0)
  expect_true(nrow(check) > 0)
  expect_true(all(check$value_source == "derived_from_pct"))
  expect_equal(
    check$n_students,
    ifelse(
      round(check$percent / 100 * check$n_enrolled) == 0 & check$percent > 0,
      1,
      round(check$percent / 100 * check$n_enrolled)
    )
  )

  na_case <- result %>% dplyr::filter(is.na(n_students))
  if (nrow(na_case) > 0) {
    expect_true(all(na_case$value_source == "published_pct_only"))
  }
})

test_that("enrich_rc_enrollment labels n_students derived_from_pct against real data", {
  skip_if_no_live_tests()

  base <- njsd_live(
    fetch_reportcard_special_pop(2019),
    "fetch_reportcard_special_pop(2019)"
  ) %>%
    dplyr::select(county_id, district_id, school_id, end_year, percent) %>%
    dplyr::mutate(end_year = 2019)

  result <- njsd_live(
    enrich_rc_enrollment(base),
    "enrich_rc_enrollment(...)"
  )

  expect_true("value_source" %in% names(result))
  expect_true(all(
    stats::na.omit(unique(result$value_source)) %in%
      c("derived_from_pct", "published_pct_only")
  ))
  expect_true(all(is.na(result$n_students[result$value_source == "published_pct_only"])))
  derived <- result %>% dplyr::filter(value_source == "derived_from_pct")
  if (nrow(derived) > 0) {
    expect_true(all(!is.na(derived$n_students) & !is.na(derived$n_enrolled)))
  }
})
