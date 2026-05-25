# ==============================================================================
# Ground-truth / fidelity tests for fetch_tges() (live)
# ==============================================================================
#
# Two kinds of check:
#   1. Pinned values hand-verified against the NJ DOE files at
#      https://www.nj.gov/education/guide/ (Absecon City = district 0010,
#      Alpine Boro = district 0080).
#   2. Round-trip fidelity: every tidy value must trace back to a cell in the
#      raw wide file for the same district, and the long output must contain
#      exactly the rows the wide file implies (no fabricated or dropped numbers).
# ==============================================================================


test_that("CSG1 per-pupil cost and rank match the DOE file (pinned)", {
  skip_on_cran()
  skip_if_offline()
  for (a in tges_anchor_csg1) {
    yr <- a[[1]]; code <- a[[2]]; pp <- a[[3]]; rank <- a[[4]]
    row <- tges_district_row(yr, code, "CSG1")
    expect_equal(nrow(row), 1L, info = paste(yr, code))
    expect_equal(row[["Per Pupil costs"]][1], pp, info = paste("pp", yr, code))
    expect_equal(row[["District rank"]][1], rank, info = paste("rank", yr, code))
  }
})


test_that("CSG1 Absecon City names and peer group are correct (2025)", {
  skip_on_cran()
  skip_if_offline()
  row <- tges_district_row(2025, "0010", "CSG1")
  expect_match(toupper(row$district_name[1]), "ABSECON")
  expect_equal(row$end_year[1], 2025)
  expect_identical(row$indicator[1], "Budgetary Per Pupil Cost")
})


test_that("CSG16 personnel ratios/salaries match the DOE file (pinned, 2025)", {
  skip_on_cran()
  skip_if_offline()
  # current (budgeted) year
  r25 <- tges_district_row(2025, "0010", "CSG16", row_year = 2025)
  expect_equal(r25[["Student/Teacher ratio"]][1], 9.2)
  expect_equal(r25[["Ratio Rank"]][1], 63L)
  expect_equal(r25[["Teacher Salary"]][1], 69481)
  expect_equal(r25[["Salary Rank"]][1], 12L)
  # prior year in the same report
  r24 <- tges_district_row(2025, "0010", "CSG16", row_year = 2024)
  expect_equal(r24[["Student/Teacher ratio"]][1], 9.5)
  expect_equal(r24[["Ratio Rank"]][1], 60L)
  expect_equal(r24[["Teacher Salary"]][1], 71169)
  expect_equal(r24[["Salary Rank"]][1], 21L)
})


test_that("VITSTAT total spending and revenue mix match the DOE file (pinned, 2025)", {
  skip_on_cran()
  skip_if_offline()
  v <- tges_tidy(2025)[["VITSTAT_TOTAL"]]
  row <- v[!is.na(v$district_code) & v$district_code == "0010", , drop = FALSE]
  expect_equal(nrow(row), 1L)
  expect_equal(row[["Total Spending Per Pupil"]][1], 26470)
  expect_equal(row[["Revenue: State %"]][1], 0.494)
  expect_equal(row[["Revenue: Local %"]][1], 0.447)
  expect_equal(row$end_year[1], 2024)   # VITSTAT reports the prior completed year
})


test_that("the 2025 guide covers the expected number of NJ districts", {
  skip_on_cran()
  skip_if_offline()
  c1 <- tges_tidy(2025)[["CSG1"]]
  codes <- unique(c1$district_code[!is.na(c1$district_code) & c1$district_code != "00NA"])
  # NJ has ~600 reporting districts; guard against a parser that loses rows
  expect_gt(length(codes), 500)
  expect_lt(length(codes), 800)
})


# --- Round-trip fidelity -------------------------------------------------------

# every non-NA tidy value must equal a cell in the district's raw wide row
traces_to_raw <- function(tidy_vals, raw_vals, tol = 0.5) {
  tidy_vals <- tidy_vals[!is.na(tidy_vals)]
  raw_vals <- suppressWarnings(as.numeric(raw_vals))
  raw_vals <- raw_vals[!is.na(raw_vals)]
  if (length(tidy_vals) == 0) return(TRUE)
  all(vapply(tidy_vals, function(v) any(abs(raw_vals - v) <= tol), logical(1)))
}


test_that("tidy CSG1 per-pupil values trace back to the raw wide file", {
  skip_on_cran()
  skip_if_offline()
  for (y in c(2025, 2020, 2011, 2010, 2004, 2001)) {
    raw <- tges_raw(y)[["CSG1"]]
    tidy <- tges_tidy(y)[["CSG1"]]
    codes <- utils::head(
      unique(tidy$district_code[!is.na(tidy$district_code) &
                                  tidy$district_code != "00NA"]), 6)
    for (dc in codes) {
      raw_row <- raw[!is.na(raw$district_code) & raw$district_code == dc, , drop = FALSE]
      raw_pp <- unlist(raw_row[grep("^pp", names(raw_row))], use.names = FALSE)
      tidy_pp <- tidy[["Per Pupil costs"]][!is.na(tidy$district_code) &
                                             tidy$district_code == dc]
      expect_true(traces_to_raw(tidy_pp, raw_pp),
                  info = paste("year", y, "district", dc))
    }
  }
})


test_that("each district contributes exactly one row per reported year in CSG1", {
  skip_on_cran()
  skip_if_offline()
  for (y in c(2025, 2015, 2010, 2003, 2001)) {
    c1 <- tges_tidy(y)[["CSG1"]]
    real <- c1[!is.na(c1$district_code) & c1$district_code != "00NA", ]
    counts <- table(real$district_code, real$end_year)
    expect_true(all(counts <= 1),
                info = paste("year", y, "has a district duplicated within a year"))
  }
})


test_that("the wide->long reshape neither invents nor drops rows (CSG1)", {
  skip_on_cran()
  skip_if_offline()
  for (y in tges_years_live) {
    raw <- tges_raw(y)[["CSG1"]]
    tidy <- tges_tidy(y)[["CSG1"]]
    expect_equal(nrow(tidy), 3L * nrow(raw), info = paste("year", y))
  }
})


test_that("Absecon per-pupil cost rose over the available history (sanity)", {
  skip_on_cran()
  skip_if_offline()
  # 2010 -> 2025 is a real, large increase; guard against unit/scale regressions
  pp10 <- tges_district_row(2010, "0010", "CSG1")[["Per Pupil costs"]][1]
  pp25 <- tges_district_row(2025, "0010", "CSG1")[["Per Pupil costs"]][1]
  expect_gt(pp25, pp10)
  expect_gt(pp25, 20000)
  expect_lt(pp10, 15000)
})
