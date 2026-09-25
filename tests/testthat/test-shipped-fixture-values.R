# Value pins for the parser families that run offline against the checked-in
# NJDOE fixture slices (inst/extdata/test-fixtures/source-adapters/). Every
# number below is read from those files, which are verbatim rows of the NJDOE
# publications recorded in provenance.json. A parser that miscounts, rescales
# or shifts a column changes one of these values and fails here.

fixture_values_path <- function(name) {
  source_adapter_fixture(name)
}

test_that("NJSLA ELA grade 4 2025 fixture parses to NJDOE's published values", {
  fixture <- fixture_values_path("njsla-ela04-2025.xlsx")
  request <- function(url, dest, timeout) {
    file.copy(fixture, dest, overwrite = TRUE)
    list(
      status_code = 200L, final_url = url,
      content_type = paste0(
        "application/vnd.openxmlformats-officedocument.",
        "spreadsheetml.sheet"
      )
    )
  }
  raw <- get_raw_sla_result(2025, 4, "ela", request_fn = request)
  out <- process_parcc(raw$data, 2025, 4, "ela")

  expect_equal(nrow(out), 5L)
  expect_identical(unique(out$county_id), "01")
  expect_identical(unique(out$district_id), "0010")
  expect_identical(unique(out$school_id), "060")

  all_students <- out[out$subgroup == "All Students", ]
  expect_equal(nrow(all_students), 1L)
  expect_equal(all_students$number_of_valid_scale_scores, 82)
  expect_equal(all_students$scale_score_mean, 743)
  expect_equal(
    unname(unlist(all_students[, c("pct_l1", "pct_l2", "pct_l3",
                                   "pct_l4", "pct_l5")])),
    c(9.8, 18.3, 26.8, 36.6, 8.5)
  )
  expect_equal(all_students$proficient_above, 36.6 + 8.5)

  hispanic <- out[out$subgroup == "Hispanic", ]
  expect_equal(hispanic$number_of_valid_scale_scores, 24)
  expect_equal(hispanic$scale_score_mean, 731)
  expect_equal(hispanic$pct_l4, 29.2)

  # NJDOE prints "*" for suppressed cells. They stay unknown, never 0.
  suppressed <- out[out$subgroup == "Black or African American", ]
  expect_true(is.na(suppressed$number_of_valid_scale_scores))
  expect_true(is.na(suppressed$scale_score_mean))
  expect_true(is.na(suppressed$pct_l1))
  expect_true(all(is.na(out$number_enrolled)))
})

test_that("TGES 2025 CSG1 fixture tidies to NJDOE's published per-pupil costs", {
  parsed <- .parse_tges_archive(fixture_values_path("tges-2025.zip"))
  out <- tidy_budgetary_per_pupil_cost(parsed$CSG1, 2025)

  # 9 published rows x 3 years (two actuals, one budgeted).
  expect_equal(nrow(out), 27L)
  expect_setequal(unique(out$end_year), c(2023, 2024, 2025))

  pick <- function(district, year) {
    out[out$district_name == district & out$end_year == year, ]
  }

  edgewater_23 <- pick("Edgewater Boro", 2023)
  expect_equal(edgewater_23$`Per Pupil costs`, 19010)
  expect_equal(edgewater_23$`District rank`, 33)
  expect_equal(as.numeric(edgewater_23$`Enrollment (ADE)`), 659)
  expect_identical(edgewater_23$calc_type, "Actuals")

  saddle_25 <- pick("Saddle River School District", 2025)
  expect_equal(saddle_25$`Per Pupil costs`, 41165)
  expect_equal(saddle_25$`District rank`, 56)
  expect_identical(saddle_25$calc_type, "Budgeted")

  expect_equal(pick("Chesterfield Twp", 2024)$`Per Pupil costs`, 18401)
  expect_identical(unique(pick("Chesterfield Twp", 2024)$district_id), "0830")

  state_avg <- out[grepl("^State average", out$district_name), ]
  expect_equal(
    state_avg$`Per Pupil costs`[order(state_avg$end_year)],
    c(18404, 19286, 21199)
  )
  # The statewide rows publish "N.A." for rank; that is unknown, not 0.
  expect_true(all(is.na(state_avg$`District rank`)))
})

test_that("SPR 2025 chronic absenteeism fixture yields NJDOE's published rates", {
  fixture <- fixture_values_path("spr-district-2025.xlsx")
  local_mocked_bindings(
    spr_cached_workbook_result = function(end_year, level) {
      new_source_result(
        data = fixture,
        source_status = "actual",
        source_url = resolve_source_url("spr", end_year, level = level),
        retrieved_at = as.POSIXct("2026-07-20", tz = "UTC"),
        digest = digest::digest(file = fixture, algo = "sha256", serialize = FALSE)
      )
    },
    .package = "njschooldata"
  )
  njsd_cache_clear()
  out <- suppressWarnings(fetch_chronic_absenteeism(2025, level = "district"))

  expect_equal(nrow(out), 5L)
  expect_identical(unique(out$district_id), "0010")
  rate <- function(group) out$chronically_absent_rate[out$subgroup == group]
  expect_equal(rate("total population"), 9.9)
  expect_equal(rate("asian, native hawaiian, or pacific islander"), 5.8)
  expect_equal(rate("black"), 15.6)
  expect_equal(rate("economically disadvantaged"), 13.5)
  # "Enrollment for this group was less than 10 students." is unknown, not 0.
  expect_true(is.na(rate("american indian")))
})
