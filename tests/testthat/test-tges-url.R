# ==============================================================================
# Unit tests for tges_url_for_year() (no network)
# ==============================================================================
#
# NJ DOE relocated the guide files under nj.gov/education/guide/docs/.  The URL
# builder must route each reporting year to the right path:
#   2001-2010  docs/{year}_CSG.zip
#   2011-2023  docs/{year}_TGES.zip
#   2024       docs/2024/TGES24_Zipped.zip
#   2025       docs/2025/TGES2025_Zipped.zip
# ==============================================================================

url_for <- function(y) njschooldata:::tges_url_for_year(y)


test_that("CSG-era years (2001-2010) route to docs/{year}_CSG.zip", {
  for (y in 2001:2010) {
    u <- url_for(y)
    expect_match(u, paste0("/", y, "_CSG\\.zip$"), info = paste("year", y))
    expect_match(u, "/education/guide/docs/", info = paste("year", y))
  }
})

test_that("TGES-era years (2011-2023) route to docs/{year}_TGES.zip", {
  for (y in 2011:2023) {
    u <- url_for(y)
    expect_match(u, paste0("/", y, "_TGES\\.zip$"), info = paste("year", y))
    expect_match(u, "/education/guide/docs/", info = paste("year", y))
  }
})

test_that("2024 and 2025 route to the per-year bundle zips", {
  expect_identical(
    url_for(2024),
    "https://www.nj.gov/education/guide/docs/2024/TGES24_Zipped.zip"
  )
  expect_identical(
    url_for(2025),
    "https://www.nj.gov/education/guide/docs/2025/TGES2025_Zipped.zip"
  )
  # bundles live in a per-year subfolder, unlike the flat {year}_TGES.zip years
  expect_match(url_for(2024), "/docs/2024/")
  expect_match(url_for(2025), "/docs/2025/")
})

test_that("every valid year yields an https nj.gov .zip URL", {
  for (y in 2001:2025) {
    u <- url_for(y)
    expect_match(u, "^https://", info = paste("year", y))
    expect_match(u, "^https://www\\.nj\\.gov/", info = paste("year", y))
    expect_match(u, "\\.zip$", info = paste("year", y))
  }
})

test_that("no valid-year URL points at the retired state.nj.us tree", {
  for (y in 2001:2025) {
    expect_false(grepl("state\\.nj\\.us", url_for(y)), info = paste("year", y))
  }
})

test_that("URLs are a single string with no whitespace", {
  for (y in c(2001, 2010, 2011, 2023, 2024, 2025)) {
    u <- url_for(y)
    expect_type(u, "character")
    expect_length(u, 1L)
    expect_false(grepl("\\s", u), info = paste("year", y))
  }
})

test_that("years below 2001 are rejected", {
  for (y in c(1990, 1995, 1998, 1999, 2000)) {
    expect_error(url_for(y), "Valid values are 2001-2025", info = paste("year", y))
  }
})

test_that("years above 2025 are rejected", {
  for (y in c(2026, 2027, 2030, 2050, 2100)) {
    expect_error(url_for(y), "Valid values are 2001-2025", info = paste("year", y))
  }
})

test_that("the error names the offending year", {
  expect_error(url_for(2000), "2000")
  expect_error(url_for(2026), "2026")
})

test_that("numeric and character years are equivalent", {
  for (y in c(2003, 2010, 2011, 2024, 2025)) {
    expect_identical(url_for(y), url_for(as.character(y)),
                     info = paste("year", y))
  }
})

test_that("era boundaries land on the correct path", {
  # last CSG year vs first TGES year
  expect_match(url_for(2010), "_CSG\\.zip$")
  expect_match(url_for(2011), "_TGES\\.zip$")
  # last flat TGES year vs first bundle year
  expect_match(url_for(2023), "_TGES\\.zip$")
  expect_match(url_for(2024), "TGES24_Zipped\\.zip$")
})
