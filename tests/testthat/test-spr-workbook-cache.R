# ==============================================================================
# Tests for legacy SPR compatibility and per-call workbook reads
# ==============================================================================
#
# Held workbooks use the verified release store. Unheld workbooks live only
# for the current call; compatibility helpers remove legacy download folders.

test_that("is_valid_xlsx accepts workbooks and rejects corrupt ZIP-like files", {
  local_nj_offline_transport()
  expect_true(njschooldata:::is_valid_xlsx(
    source_adapter_fixture("spr-district-2025.xlsx")
  ))

  corrupt <- tempfile(fileext = ".xlsx")
  writeBin(c(as.raw(c(0x50, 0x4B, 0x03, 0x04)), as.raw(rep(0L, 2000))), corrupt)
  expect_false(njschooldata:::is_valid_xlsx(corrupt))

  html <- tempfile(fileext = ".xlsx")
  writeLines(rep("<html>Service Unavailable</html>", 200), html)
  expect_false(njschooldata:::is_valid_xlsx(html))

  tiny <- tempfile(fileext = ".xlsx")
  writeBin(as.raw(c(0x50, 0x4B)), tiny)
  expect_false(njschooldata:::is_valid_xlsx(tiny)) # below the size floor

  expect_false(njschooldata:::is_valid_xlsx(tempfile())) # missing file
})

test_that("njsd_workbook_cache_dir honors the cache_dir option", {
  local_nj_offline_transport()
  old <- options(njschooldata.cache_dir = "/tmp/njsd-xyz")
  on.exit(options(old), add = TRUE)
  expect_equal(njsd_workbook_cache_dir(), file.path("/tmp/njsd-xyz", "spr-workbooks"))
})

test_that("workbook reads create no persistent live folder regardless of old options", {
  local_nj_offline_transport()
  root <- withr::local_tempdir()
  withr::local_options(njschooldata.cache_dir = root)
  fixture <- source_adapter_fixture("spr-district-2025.xlsx")
  calls <- 0L
  request <- function(url, dest, timeout) {
    calls <<- calls + 1L
    file.copy(fixture, dest)
    list(status_code = 200L, final_url = url, content_type = "application/octet-stream")
  }
  for (enabled in c(TRUE, FALSE)) {
    withr::local_options(njschooldata.workbook_cache = enabled)
    result <- spr_cached_workbook_result(2025, "district", request_fn = request)
    expect_true(is_valid_xlsx(result$data))
    expect_identical(result$ownership, "temporary")
    .release_source_result(result)
    expect_false(file.exists(result$data))
    expect_length(list.files(root, recursive = TRUE, all.files = TRUE,
                             no.. = TRUE, include.dirs = TRUE), 0L)
  }
  expect_identical(calls, 2L)
})

test_that("legacy clear removes all five folders but preserves the release store", {
  local_nj_offline_transport()
  root <- withr::local_tempdir()
  withr::local_options(njschooldata.cache_dir = root)
  old <- c("spr-workbooks", "source-artifacts", "enrollment-sources", "sped-placement", "facilities")
  for (folder in c(old, "historical-assets-v1")) {
    dir.create(file.path(root, folder))
    writeLines("independent marker", file.path(root, folder, "marker"))
  }
  expect_equal(njsd_workbook_cache_clear(), 5L)
  expect_false(any(dir.exists(file.path(root, old))))
  expect_identical(readLines(file.path(root, "historical-assets-v1", "marker")), "independent marker")
  expect_identical(.njsd_cache_folders, "historical-assets-v1")
})
