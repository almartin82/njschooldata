# schema-consistency contract v1: a tidy fetcher returns the same columns, in
# the same order, with the same classes, for every year it supports.
#
# Years come from the package's own declarations (get_source_years() and the
# per-fetcher guards cited beside each entry). A fetcher's known breaks name
# the year and the reason; an entry that no longer differs fails as stale.
#
# fetch_spr_data() is a raw sheet reader and is outside the contract: it
# returns each year's sheet in NJDOE's layout. Read the tidy fetchers instead
# (for EnrollmentTrendsByStudentGroup, fetch_spr_enrollment_by_group()).

test_that("the schema checker can fail", {
  sc_contract_self_test()
})

.sc_spr <- function(from = -Inf, except = integer()) {
  years <- get_source_years("spr")
  setdiff(years[years >= from], except)
}

.sc_parcc <- function(from = -Inf) {
  years <- get_source_years("parcc")
  years[years >= from]
}

# fetcher, non-year arguments, supported years, known breaks.
.sc_spec <- function() {
  e <- function(fetcher, args, years, known = character()) {
    list(fetcher = fetcher, args = args, years = years, known = known)
  }
  list(
    e("fetch_enr", list(tidy = TRUE), get_source_years("enrollment")),
    e("fetch_ell", list(), get_source_years("ell")),
    e("fetch_sped", list(), get_valid_sped_years()),
    e("fetch_parcc", list(grade_or_subj = 3L, subj = "ela", tidy = TRUE), .sc_parcc()),
    e("fetch_parcc", list(grade_or_subj = 8L, subj = "math", tidy = TRUE), .sc_parcc()),
    e("fetch_parcc", list(grade_or_subj = "ALG1", subj = "math", tidy = TRUE), .sc_parcc()),
    # Science is published from 2018-19 (fetch_parcc science guard).
    e("fetch_parcc", list(grade_or_subj = 5L, subj = "science", tidy = TRUE), .sc_parcc(2019),
      c(`2019` = "NJDOE file returns HTTP 404 (https://www.nj.gov/education/assessment/results/reports/1819/spring/SC05%20NJSLA%20DATA%202018-19.xlsx)")),
    e("fetch_njgpa", list(subj = "math", tidy = TRUE), get_source_years("njgpa")),
    e("fetch_njgpa", list(subj = "ela", tidy = TRUE), get_source_years("njgpa")),
    e("fetch_msgp", list(), get_source_years("msgp")),
    e("fetch_essa_status", list(level = "school"), spr_supported_years("essa_status")),
    e("fetch_spr_naep", list(), .sc_spr()),
    e("fetch_spr_enrollment_by_group", list(level = "school"), .sc_spr()),
    e("fetch_spr_enrollment_by_group", list(level = "district"), .sc_spr()),
    e("fetch_finance", list(with_status = TRUE, level = "all"), get_available_years("finance")),
    e("fetch_finance", list(tidy = TRUE), get_available_years("finance")),
    e("fetch_state_aid", list(), get_source_years("state_aid", capability = "raw")),
    e("fetch_absence", list(level = "district", type = "chronic", tidy = TRUE), absence_supported_years("chronic")),
    e("fetch_absence", list(level = "district", type = "by_grade", tidy = TRUE), absence_supported_years("by_grade")),
    e("fetch_absence", list(level = "district", type = "days_absent", tidy = TRUE), absence_supported_years("days_absent")),
    e("fetch_absence", list(level = "school", type = "chronic", tidy = TRUE), absence_supported_years("chronic")),
    e("fetch_grad_rate", list(methodology = "4 year"), get_source_years("grate_4yr")),
    e("fetch_grad_rate", list(methodology = "5 year"), get_source_years("grate_5yr")),
    # fetch_spr_grad_cohort guard: end_year >= 2020.
    e("fetch_spr_grad_cohort", list(level = "district"), .sc_spr(2020)),
    e("fetch_6yr_grad_rate", list(level = "district"), get_source_years("grate_6yr")),
    # fetch_spr_fed_grad guard: end_year >= 2021.
    e("fetch_spr_fed_grad", list(level = "district"), .sc_spr(2021)),
    e("fetch_dropout_rates", list(level = "district"), .sc_spr()),
    # fetch_spr_grad_pathways guard: end_year >= 2018, no 2022-23 sheet.
    e("fetch_spr_grad_pathways", list(level = "district"), .sc_spr(2018, except = 2023L)),
    e("fetch_teacher_experience", list(level = "district"), spr_supported_years("teacher_experience")),
    e("fetch_teacher_experience", list(level = "school"), spr_supported_years("teacher_experience")),
    e("fetch_staff_ratios", list(level = "district"), .sc_spr()),
    e("fetch_staff_ratios", list(level = "school"), .sc_spr()),
    # fetch_spr_staff_counts guard: end_year >= 2021.
    e("fetch_spr_staff_counts", list(level = "district"), .sc_spr(2021)),
    # fetch_spr_staff_education / _retention guards: end_year >= 2018.
    e("fetch_spr_staff_education", list(level = "district"), .sc_spr(2018)),
    e("fetch_spr_staff_retention", list(level = "district"), .sc_spr(2018)),
    e("fetch_disciplinary_removals",
      list(level = "district", with_status = TRUE, with_denominator = TRUE,
           with_subgroup_std = TRUE), .sc_spr(2018)),
    e("fetch_violence_vandalism_hib",
      list(level = "district", with_status = TRUE, with_denominator = TRUE), .sc_spr()),
    # fetch_police_notifications / fetch_hib_investigations guards: >= 2018.
    e("fetch_police_notifications",
      list(level = "district", with_status = TRUE, with_denominator = TRUE), .sc_spr(2018)),
    e("fetch_hib_investigations", list(level = "district"), .sc_spr(2018)),
    e("fetch_sat_participation", list(level = "district"), .sc_spr()),
    e("fetch_sat_performance", list(level = "district"), .sc_spr()),
    e("fetch_sat_performance", list(level = "school"), .sc_spr()),
    e("fetch_ap_participation", list(level = "district"), .sc_spr()),
    e("fetch_ap_participation", list(level = "school"), .sc_spr()),
    e("fetch_cte_participation", list(level = "district"), spr_supported_years("cte_participation")),
    e("fetch_cte_participation", list(level = "school"), spr_supported_years("cte_participation")),
    e("fetch_industry_credentials", list(level = "district"), .sc_spr()),
    e("fetch_industry_credentials", list(level = "school"), .sc_spr()),
    e("fetch_math_course_enrollment", list(level = "district"), .sc_spr()),
    e("fetch_sgp", list(level = "district", type = "trends"), sgp_supported_years("trends")),
    e("fetch_sgp", list(level = "district", type = "by_grade"), sgp_supported_years("by_grade")),
    e("fetch_sped_placement", list(), get_source_years("sped_placement"))
  )
}

.sc_label <- function(entry) {
  args <- vapply(names(entry$args), function(n) paste0(n, "=", format(entry$args[[n]])), "")
  paste0(entry$fetcher, "(", paste(args, collapse = ", "), ")")
}

test_that("every schema entry names an exported fetcher and real years", {
  exports <- getNamespaceExports("njschooldata")
  for (entry in .sc_spec()) {
    expect_true(entry$fetcher %in% exports, info = entry$fetcher)
    expect_gt(length(entry$years), 0L)
    expect_true(all(names(entry$known) %in% as.character(entry$years)), info = .sc_label(entry))
  }
  expect_false("fetch_spr_data" %in% vapply(.sc_spec(), `[[`, "", "fetcher"))
})

for (sc_entry in .sc_spec()) {
  local({
    entry <- sc_entry
    test_that(paste("schema consistency:", .sc_label(entry)), {
      skip_on_cran()
      skip_if_no_live_tests()
      # Read through the ordinary persistent cache, as the available-years
      # live test does; a cold year with no network is NOT-CHECKED.
      withr::local_options(njschooldata.cache_dir = NULL,
                           njschooldata.workbook_cache = TRUE)
      withr::local_envvar(c(NJSCHOOLDATA_CACHE_DIR = NA_character_,
                            STATE_SCHOOLDATA_HISTORICAL_ROOT = NA_character_))
      old_cache_state <- .njsd_cache$enabled
      withr::defer({ .njsd_cache$enabled <- old_cache_state })
      .njsd_cache$enabled <- TRUE
      fetcher <- getExportedValue("njschooldata", entry$fetcher)
      sc_expect_contract(.sc_label(entry), entry$years,
                         sc_fetch_one(fetcher, entry$args), entry$known)
    })
  })
}
