# NOTE: NJ DOE retired the old state.nj.us achievement file tree in 2024 and
# rehosted the legacy NJASK/HSPA/GEPA summary files under nj.gov at
# education/assessment/results/njask/njask{YY}/ (see nj_legacy_assess_url()).
# 2005-2014 fetch live from nj.gov; 2004 (not rehosted) is recovered from the
# Internet Archive, which rate-limits (HTTP 429) under repeated access. The
# njsd_live() guards below skip on a declared source condition and on nothing
# else -- a parse failure or a failed expectation still reaches the reporter.

test_that("valid_call correctly identifies status of years/grade pairs", {
  expect_true(valid_call(2014, 8))
  expect_false(valid_call(2014, 12))

  expect_true(valid_call(2007, 8))
  expect_false(valid_call(2005, 5))
})

test_that("standard_assess correctly calls data for 2014", {
  skip_if_no_live_tests()

  hspa_ex <- njsd_live(standard_assess(2014, 11), "standard_assess(2014, 11)")

  expect_equal(nrow(hspa_ex), 742)
  expect_equal(ncol(hspa_ex), 560)
  expect_equal(
    sum(hspa_ex$GENERAL_EDUCATION_Number_Enrolled_LAL, na.rm = TRUE), 405655
  )
  expect_equal(
    sum(hspa_ex$GENERAL_EDUCATION_LANGUAGE_ARTS_Scale_Score_Mean, na.rm = TRUE),
    174325.5, tolerance = 0.01
  )

  njask_ex <- njsd_live(standard_assess(2014, 7), "standard_assess(2014, 7)")

  expect_equal(nrow(njask_ex), 1329)
  expect_equal(ncol(njask_ex), 551)
  expect_equal(
    sum(njask_ex$GENERAL_EDUCATION_Number_Enrolled_ELA, na.rm = TRUE), 420111
  )
  expect_equal(
    sum(njask_ex$GENERAL_EDUCATION_LANGUAGE_ARTS_Scale_Score_Mean, na.rm = TRUE),
    265911.4, tolerance = 0.01
  )
})


test_that("fetch_old_nj_assess returns correct output for a variety of calls", {
  skip_if_no_live_tests()

  #2014 njask
  njask_14 <- njsd_live(
    fetch_old_nj_assess(2014, 6),
    "fetch_old_nj_assess(2014, 6)"
  )

  expect_equal(nrow(njask_14), 1505)
  expect_equal(ncol(njask_14), 551)
  expect_equal(
    sum(njask_14$GENERAL_EDUCATION_Number_Enrolled_ELA, na.rm = TRUE), 412827
  )

  #2014 hspa
  hspa_14 <- njsd_live(
    fetch_old_nj_assess(2014, 11),
    "fetch_old_nj_assess(2014, 11)"
  )

  expect_equal(nrow(hspa_14), 742)
  expect_equal(ncol(hspa_14), 560)
  expect_equal(
    sum(hspa_14$GENERAL_EDUCATION_Number_Enrolled_LAL, na.rm = TRUE), 405655
  )

  #2007 gepa
  gepa_07 <- njsd_live(
    fetch_old_nj_assess(2007, 11),
    "fetch_old_nj_assess(2007, 11)"
  )

  expect_equal(nrow(gepa_07), 681)
  expect_equal(ncol(gepa_07), 529)
  expect_equal(
    sum(gepa_07$GENERAL_EDUCATION_Number_Enrolled, na.rm = TRUE), 410704
  )

  #2004 gr3
  njask_04 <- njsd_live(
    fetch_old_nj_assess(2004, 3),
    "fetch_old_nj_assess(2004, 3)"
  )

  expect_equal(nrow(njask_04), 1956)
  expect_equal(ncol(njask_04), 363)
  expect_equal(
    sum(njask_04$GENERAL_EDUCATION_Number_Enrolled, na.rm = TRUE), 418669
  )
})

test_that("legacy layouts load without attaching the package", {
  layouts <- c(
    "layout_njask", "layout_njask04", "layout_njask05", "layout_njask06gr3",
    "layout_njask06gr5", "layout_njask07gr3", "layout_njask07gr5",
    "layout_njask09", "layout_njask10", "layout_hspa", "layout_hspa04",
    "layout_hspa05", "layout_hspa06", "layout_hspa10", "layout_gepa",
    "layout_gepa05", "layout_gepa06"
  )
  # A clean subprocess loads this checkout, never the installed copy. An
  # empty-parent evaluation environment cannot resolve attached datasets.
  script <- tempfile(fileext = ".R")
  on.exit(unlink(script), add = TRUE)
  writeLines(c(
    paste0(".libPaths(", paste(deparse(.libPaths()), collapse = ""), ")"),
    paste0("root <- ", deparse(package_source_root())),
    'pkgload::load_all(root, export_all = FALSE, attach = FALSE, quiet = TRUE)',
    'stopifnot(!"package:njschooldata" %in% search())',
    paste0("layouts <- ", paste(deparse(layouts), collapse = "")),
    'for (name in layouts) {',
    '  expected <- new.env(parent = emptyenv())',
    '  load(file.path(root, "data", paste0(sub("^layout_", "", name), "_layout.rda")), envir = expected)',
    '  stopifnot(identical(njschooldata:::.legacy_assessment_layout(name), expected[[name]]))',
    '}',
    'testthat::local_mocked_bindings(',
    '  common_fwf_req = function(target_url, layout) {',
    '    stopifnot(is.data.frame(layout), nrow(layout) > 0L)',
    '    data.frame(Testing_Year = 2004L, Grade = 3L)',
    '  },',
    '  process_nj_assess = function(df, layout) {',
    '    stopifnot(is.data.frame(layout), nrow(layout) > 0L)',
    '    df',
    '  }, .package = "njschooldata", .env = globalenv())',
    'for (year in 2004:2014) for (grade in c(3:8, 11)) {',
    '  if (njschooldata:::valid_call(year, grade)) {',
    '    out <- njschooldata::fetch_old_nj_assess(year, grade)',
    '    stopifnot(nrow(out) == 1L)',
    '  }',
    '}',
    'njschooldata:::get_raw_gepa(2007)',
    'stopifnot(!"package:njschooldata" %in% search())'
  ), script)
  output <- suppressWarnings(system2(
    file.path(R.home("bin"), "Rscript"),
    c("--vanilla", shQuote(script)), stdout = TRUE, stderr = TRUE
  ))
  status <- attr(output, "status")
  if (is.null(status)) status <- 0L
  expect_equal(status, 0L, info = paste(output, collapse = "\n"))
})

# Real source bytes, including the single-byte Windows-1252 en dash. Mock only
# transport: the public fetcher, actual layouts, reader, processor and tidier run.
legacy_fixture_transport <- function(file, env = parent.frame()) {
  fixture <- testthat::test_path("fixtures", "legacy-assessment", file)
  testthat::local_mocked_bindings(
    download_source = function(url, source_type, ...) {
      path <- tempfile()
      file.copy(fixture, path)
      new_source_result(path, "actual", source_url = url)
    }, .package = "njschooldata", .env = env
  )
}

for (case in list(
  list(year = 2013L, grade = 6L, values = rep(NA_real_, 4)),
  list(year = 2013L, grade = 7L, values = c(278, 43.9, 51.8, 4.3)),
  list(year = 2013L, grade = 8L, values = c(294, 27.6, 69.0, 3.4)),
  list(year = 2014L, grade = 7L, values = c(251, 50.2, 42.2, 7.6)),
  list(year = 2014L, grade = 8L, values = c(279, 26.2, 66.3, 7.5))
)) {
  test_that(paste("single-byte NJASK names preserve fields", case$year, case$grade), {
    legacy_fixture_transport(paste0("njask-", case$year, "-", case$grade, ".txt"))
    out <- suppressMessages(suppressWarnings(
      fetch_old_nj_assess(case$year, case$grade, tidy = TRUE)
    ))
    expect_equal(nrow(out), 180L)
    expect_equal(c(sum(out$is_state), sum(out$is_district), sum(out$is_school)),
                 c(60, 60, 60))
    expect_true(all(out$testing_year == case$year))
    rahway <- out[out$is_school, ]
    expect_true(all(rahway$school_name == "RAHWAY 7 \u2013 8 ACADEMY"))
    expect_true(all(rahway$county_code == "39"))
    expect_true(all(rahway$district_code == "4290"))
    expect_true(all(rahway$school_code == "060"))
    cell <- rahway[rahway$subgroup == "total_population" &
                     rahway$test_name == "language_arts", ]
    expect_equal(nrow(cell), 1L)
    # Raw byte fields: 187:192, 193:196, 197:200, 201:204. Percentages
    # have one implied decimal; all four cells are '*' for 2013 grade 6.
    expect_equal(unname(unlist(cell[c("number_valid_scale_scores",
      "partially_proficient", "proficient", "advanced_proficient")])), case$values)
  })
}

for (case in list(
  list(year = 2012L, values = c(96413, 8.5, 69.7, 21.8)),
  list(year = 2013L, values = c(95571, 8.4, 65.0, 26.6)),
  list(year = 2014L, values = c(97091, 6.7, 60.4, 32.8))
)) {
  test_that(paste("HSPA blank final numeric fields stay numeric", case$year), {
    legacy_fixture_transport(paste0("hspa-", case$year, ".txt"))
    wide <- suppressWarnings(fetch_hspa(case$year))
    final <- "SCIENCE_SPECIAL_EDUCATION_WITH_ACCOMMODATIONS_Advanced_Proficient_Percentage"
    expect_type(wide[[final]], "double")
    expect_true(all(is.na(wide[[final]])))
    out <- suppressMessages(suppressWarnings(
      fetch_old_nj_assess(case$year, 11, tidy = TRUE)
    ))
    expect_equal(nrow(out), 207L)
    expect_equal(c(sum(out$is_state), sum(out$is_district), sum(out$is_school)),
                 c(69, 69, 69))
    expect_type(out$advanced_proficient, "double")
    expect_true(all(is.na(out$advanced_proficient[
      out$subgroup == "sped_accomodations" & out$test_name == "science"])))
    cell <- out[out$is_state & out$subgroup == "total_population" &
                  out$test_name == "language_arts", ]
    expect_equal(nrow(cell), 1L)
    # Raw fields 181:186, 187:190, 191:194, 195:198.
    expect_equal(unname(unlist(cell[c("number_valid_scale_scores",
      "partially_proficient", "proficient", "advanced_proficient")])), case$values)
  })
}
