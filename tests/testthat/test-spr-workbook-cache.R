# ==============================================================================
# Tests for the on-disk SPR workbook cache
# ==============================================================================
#
# The SPR Excel databases are large and hold dozens of sheets each. The disk
# cache stores the downloaded workbook so a year/level file is fetched at most
# once and reused across sheet reads and across sessions.

test_that("is_valid_xlsx accepts a ZIP and rejects error pages / tiny files", {
  ok <- tempfile(fileext = ".xlsx")
  writeBin(c(as.raw(c(0x50, 0x4B, 0x03, 0x04)), as.raw(rep(0L, 2000))), ok)
  expect_true(njschooldata:::is_valid_xlsx(ok))

  html <- tempfile(fileext = ".xlsx")
  writeLines(rep("<html>Service Unavailable</html>", 200), html)
  expect_false(njschooldata:::is_valid_xlsx(html))

  tiny <- tempfile(fileext = ".xlsx")
  writeBin(as.raw(c(0x50, 0x4B)), tiny)
  expect_false(njschooldata:::is_valid_xlsx(tiny)) # below the size floor

  expect_false(njschooldata:::is_valid_xlsx(tempfile())) # missing file
})

test_that("njsd_workbook_cache_dir honors the cache_dir option", {
  old <- options(njschooldata.cache_dir = "/tmp/njsd-xyz")
  on.exit(options(old), add = TRUE)
  expect_equal(njsd_workbook_cache_dir(), file.path("/tmp/njsd-xyz", "spr-workbooks"))
})

test_that("an SPR workbook is cached on disk and reused across sheet reads", {
  skip_on_cran()
  skip_if_offline()

  old <- options(
    njschooldata.cache_dir = file.path(tempdir(), "njsd-wbtest"),
    timeout = 600
  )
  on.exit(options(old), add = TRUE)
  njsd_workbook_cache_clear()

  # First touch downloads + caches the (smallest, SY2019-20) district workbook.
  list_spr_sheets(2020, "district")
  cached <- list.files(
    njsd_workbook_cache_dir(), pattern = "\\.xlsx$", full.names = TRUE
  )
  expect_length(cached, 1)
  mtime_before <- file.info(cached)$mtime

  Sys.sleep(1.1) # ensure any re-download would change mtime

  # A different operation on the same year/level must reuse the cached file.
  df <- fetch_spr_data("StudentGrowthTrends", 2020, "district")
  expect_gt(nrow(df), 0)

  cached_after <- list.files(
    njsd_workbook_cache_dir(), pattern = "\\.xlsx$", full.names = TRUE
  )
  expect_length(cached_after, 1) # no second copy
  expect_equal(file.info(cached_after)$mtime, mtime_before) # not re-downloaded
})

test_that("disk caching can be disabled via option", {
  skip_on_cran()
  skip_if_offline()

  old <- options(
    njschooldata.cache_dir = file.path(tempdir(), "njsd-wbtest-off"),
    njschooldata.workbook_cache = FALSE,
    timeout = 600
  )
  on.exit(options(old), add = TRUE)

  path <- njschooldata:::spr_cached_workbook(2020, "district")
  expect_true(file.exists(path))
  # Nothing is written to the cache directory when caching is off.
  expect_length(
    list.files(njsd_workbook_cache_dir(), pattern = "\\.xlsx$"), 0
  )
})
