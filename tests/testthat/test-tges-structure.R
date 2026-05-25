# ==============================================================================
# Structural / correctness tests for fetch_tges() across the year range (live)
# ==============================================================================
#
# These exercise every code path (CSG era, TGES era, per-year bundles, and the
# 2001-2003 year_variable_converter path) and assert invariants that must hold
# for the tidy output to be correct: 3-year budget windows, 2-year personnel
# windows, no duplicate columns, numeric value columns, integer ranks, padded
# district codes, and the row-count multipliers that prove the wide->long
# reshape did not drop or duplicate rows.
# ==============================================================================


test_that("fetch returns a non-empty named list containing CSG1 for every year", {
  skip_on_cran()
  skip_if_offline()
  for (y in tges_years_live) {
    res <- tges_tidy(y)
    expect_type(res, "list")
    expect_gt(length(res), 0)
    expect_true("CSG1" %in% names(res), info = paste("year", y))
  }
})


test_that("no tidied table carries janitor-deduplicated (...N) columns", {
  # Regression guard for the personnel year-mask bug that duplicated columns.
  skip_on_cran()
  skip_if_offline()
  for (y in tges_years_live) {
    res <- tges_tidy(y)
    dup_tables <- names(res)[vapply(
      res, function(d) any(grepl("[.]{3}[0-9]+$", names(d))), logical(1)
    )]
    expect_identical(dup_tables, character(0),
                     info = paste("year", y, "had dup cols in", toString(dup_tables)))
  }
})


test_that("CSG1 budget table has the expected schema and 3-year window", {
  skip_on_cran()
  skip_if_offline()
  needed <- c("group", "county_name", "district_code", "district_name",
              "Per Pupil costs", "District rank", "end_year", "indicator")
  for (y in tges_years_live) {
    c1 <- tges_tidy(y)[["CSG1"]]
    expect_gt(nrow(c1), 0)
    expect_true(all(needed %in% names(c1)),
                info = paste("year", y, "missing", toString(setdiff(needed, names(c1)))))
    expect_identical(unique(c1$indicator), "Budgetary Per Pupil Cost")
    expect_setequal(unique(c1$end_year), c(y - 2, y - 1, y))
  }
})


test_that("budget per-pupil costs are numeric and within a plausible range", {
  skip_on_cran()
  skip_if_offline()
  # New/non-operating districts (eg charters in their first year) legitimately
  # report $0, so the floor is >= 0; the upper bound and "real dollars present"
  # checks guard against scale/parse regressions.
  for (y in tges_years_live) {
    c1 <- tges_tidy(y)[["CSG1"]]
    pp <- c1[["Per Pupil costs"]]
    expect_type(pp, "double")
    pp <- pp[!is.na(pp)]
    expect_gt(length(pp), 0)
    expect_true(all(pp >= 0), info = paste("year", y))
    expect_true(all(pp < 200000), info = paste("year", y))
    expect_gt(max(pp), 5000)
  }
})


test_that("district ranks are integers within a plausible range or NA", {
  skip_on_cran()
  skip_if_offline()
  # Rank 0 marks an unranked (non-operating / first-year charter) district.
  for (y in tges_years_live) {
    c1 <- tges_tidy(y)[["CSG1"]]
    rk <- c1[["District rank"]]
    expect_type(rk, "integer")
    rk <- rk[!is.na(rk)]
    expect_gt(length(rk), 0)               # ranks must survive tidying (was all-NA bug)
    expect_true(all(rk >= 0), info = paste("year", y))
    expect_true(all(rk <= 800), info = paste("year", y))
    expect_gt(max(rk), 1)                  # a real ranking exists
  }
})


test_that("district codes are character and four characters wide", {
  skip_on_cran()
  skip_if_offline()
  for (y in tges_years_live) {
    dc <- tges_tidy(y)[["CSG1"]]$district_code
    expect_type(dc, "character")
    dc <- dc[!is.na(dc)]
    expect_true(all(nchar(dc) == 4), info = paste("year", y))
  }
})


test_that("budget tables reshape to exactly 3x the raw row count", {
  skip_on_cran()
  skip_if_offline()
  for (y in tges_years_live) {
    raw <- tges_raw(y)
    tidy <- tges_tidy(y)
    for (tb in tges_budget_tables) {
      if (is.null(raw[[tb]]) || is.null(tidy[[tb]])) next
      expect_equal(nrow(tidy[[tb]]), 3 * nrow(raw[[tb]]),
                   info = paste("year", y, "table", tb))
    }
  }
})


test_that("personnel tables split into a 2-year window with no dup columns", {
  skip_on_cran()
  skip_if_offline()
  for (y in tges_years_live) {
    raw <- tges_raw(y)
    tidy <- tges_tidy(y)
    for (tb in tges_personnel_tables) {
      p <- tidy[[tb]]
      if (is.null(p)) next
      expect_false(any(grepl("[.]{3}[0-9]+$", names(p))),
                   info = paste("year", y, "table", tb))
      expect_setequal(unique(p$end_year), c(y - 1, y))
      expect_equal(nrow(p), 2 * nrow(raw[[tb]]),
                   info = paste("year", y, "table", tb))
    }
  }
})


test_that("personnel rank columns are integer and ratios are numeric", {
  skip_on_cran()
  skip_if_offline()
  for (y in tges_years_live) {
    p <- tges_tidy(y)[["CSG16"]]
    if (is.null(p)) next
    expect_type(p[["Ratio Rank"]], "integer")
    expect_type(p[["Salary Rank"]], "integer")
    expect_type(p[["Student/Teacher ratio"]], "double")
    expect_type(p[["Teacher Salary"]], "double")
    rr <- p[["Ratio Rank"]][!is.na(p[["Ratio Rank"]])]
    expect_gt(length(rr), 0)              # ranks must survive (pipe-format guard)
    expect_true(all(rr >= 0 & rr <= 800), info = paste("year", y))  # 0 = unranked
    expect_gt(max(rr), 1)
  }
})


test_that("teacher salaries are plausible where reported", {
  skip_on_cran()
  skip_if_offline()
  for (y in tges_years_live) {
    p <- tges_tidy(y)[["CSG16"]]
    if (is.null(p)) next
    sal <- p[["Teacher Salary"]]
    sal <- sal[!is.na(sal)]
    expect_gt(length(sal), 0)
    expect_true(all(sal >= 0), info = paste("year", y))   # $0 = non-operating district
    expect_true(all(sal < 250000), info = paste("year", y))
    expect_gt(stats::median(sal), 30000)                  # typical salaries are real
  }
})


test_that("VITSTAT is present and numeric in the TGES era (>=2011)", {
  skip_on_cran()
  skip_if_offline()
  for (y in tges_years_live[tges_years_live >= 2011]) {
    v <- tges_tidy(y)[["VITSTAT_TOTAL"]]
    expect_false(is.null(v), info = paste("year", y))
    expect_true("Total Spending Per Pupil" %in% names(v))
    expect_type(v[["Total Spending Per Pupil"]], "double")
    sp <- v[["Total Spending Per Pupil"]]
    sp <- sp[!is.na(sp)]
    expect_true(all(sp >= 0 & sp < 200000), info = paste("year", y))  # $0 = non-operating
    expect_gt(max(sp), 5000)
  }
})


test_that("every tidied indicator table carries an end_year column", {
  skip_on_cran()
  skip_if_offline()
  cleaned <- c(tges_budget_tables, tges_personnel_tables,
               "CSG1AA_AVGS", "CSG20", "CSG21", "VITSTAT_TOTAL")
  for (y in tges_years_live) {
    res <- tges_tidy(y)
    for (tb in intersect(cleaned, names(res))) {
      expect_true("end_year" %in% names(res[[tb]]),
                  info = paste("year", y, "table", tb))
    }
  }
})


test_that("reported end_year values never exceed the reporting year", {
  skip_on_cran()
  skip_if_offline()
  for (y in tges_years_live) {
    res <- tges_tidy(y)
    for (tb in intersect(tges_budget_tables, names(res))) {
      ey <- res[[tb]]$end_year
      expect_true(all(ey <= y), info = paste("year", y, "table", tb))
      expect_true(all(ey >= y - 2), info = paste("year", y, "table", tb))
    }
  }
})
