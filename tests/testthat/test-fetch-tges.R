# ==============================================================================
# Tests for the Taxpayers' Guide to Educational Spending (TGES) fetcher
# ==============================================================================
#
# fetch_tges() downloads one year of the NJ DOE Taxpayers' Guide to Educational
# Spending (branded the "Comparative Spending Guide" / CSG before 2011) and
# tidies the per-pupil cost, ratio, and vital-statistics sheets.
#
# NJ DOE relocated these files under /education/guide/docs/ (and moved the
# domain to nj.gov), so the historical URLs all 404. Current layout:
#   2001-2010  /education/guide/docs/{year}_CSG.zip
#   2011-2023  /education/guide/docs/{year}_TGES.zip
#   2024       /education/guide/docs/2024/TGES24_Zipped.zip
#   2025       /education/guide/docs/2025/TGES2025_Zipped.zip
#
# ==============================================================================


# ==============================================================================
# URL construction (no network)
# ==============================================================================

test_that("tges_url_for_year picks the right path per era", {
  expect_match(njschooldata:::tges_url_for_year(2001), "docs/2001_CSG\\.zip$")
  expect_match(njschooldata:::tges_url_for_year(2010), "docs/2010_CSG\\.zip$")
  expect_match(njschooldata:::tges_url_for_year(2011), "docs/2011_TGES\\.zip$")
  expect_match(njschooldata:::tges_url_for_year(2023), "docs/2023_TGES\\.zip$")
  expect_match(njschooldata:::tges_url_for_year(2024), "docs/2024/TGES24_Zipped\\.zip$")
  expect_match(njschooldata:::tges_url_for_year(2025), "docs/2025/TGES2025_Zipped\\.zip$")
  # all point at the current nj.gov host, not the retired state.nj.us tree
  expect_match(njschooldata:::tges_url_for_year(2019), "^https://www\\.nj\\.gov/education/guide/docs/")
})

test_that("tges_url_for_year rejects out-of-range years", {
  # NJ links 1999/2000 but those downloads 404 on the state site
  expect_error(njschooldata:::tges_url_for_year(2000), "Valid values are 2001-2025")
  expect_error(njschooldata:::tges_url_for_year(1999), "Valid values are 2001-2025")
  expect_error(njschooldata:::tges_url_for_year(2026), "Valid values are 2001-2025")
})


# ==============================================================================
# Live fetch + tidy (network)
# ==============================================================================

test_that("fetch_tges(2025) returns tidied per-pupil cost tables", {
  skip_on_cran()
  skip_if_offline()

  res <- fetch_tges(2025)

  expect_type(res, "list")
  expect_true(all(c("CSG1", "CSG1AA_AVGS", "VITSTAT_TOTAL") %in% names(res)))

  # Budgetary Per Pupil Cost: 3-year window (actuals y-2, y-1, budgeted y)
  csg1 <- res[["CSG1"]]
  expect_s3_class(csg1, "data.frame")
  expect_gt(nrow(csg1), 0)
  expect_true("indicator" %in% names(csg1))
  expect_identical(unique(csg1$indicator), "Budgetary Per Pupil Cost")
  expect_setequal(unique(csg1$end_year), c(2023, 2024, 2025))
  expect_true("Per Pupil costs" %in% names(csg1))
  pp <- csg1[["Per Pupil costs"]]
  expect_type(pp, "double")
  expect_true(all(pp[!is.na(pp)] >= 0))
})

test_that("fetch_tges(2025) coerces the N.R. marker instead of erroring", {
  # Regression: 2025 CSG1AA_AVGS has "N.R." in one year's per-pupil column,
  # which flipped it to character and broke bind_rows(). It must coerce to NA.
  skip_on_cran()
  skip_if_offline()

  avgs <- fetch_tges(2025)[["CSG1AA_AVGS"]]
  expect_s3_class(avgs, "data.frame")
  expect_true("Per Pupil Total Expenditures" %in% names(avgs))
  expect_type(avgs[["Per Pupil Total Expenditures"]], "double")
  expect_setequal(unique(avgs$end_year), c(2023, 2024))
})

test_that("fetch_tges handles the legacy CSG era (2010)", {
  skip_on_cran()
  skip_if_offline()

  res <- fetch_tges(2010)
  expect_true("CSG1" %in% names(res))

  csg1 <- res[["CSG1"]]
  expect_gt(nrow(csg1), 0)
  expect_setequal(unique(csg1$end_year), c(2008, 2009, 2010))
})
