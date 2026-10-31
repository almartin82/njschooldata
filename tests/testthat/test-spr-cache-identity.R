test_that("legacy SPR files do not occupy the identity-aware cache key", {
  root <- tempfile("spr-identity-")
  withr::local_options(njschooldata.cache_dir = root,
                      njschooldata.workbook_cache = TRUE)
  old_enabled <- .njsd_cache$enabled
  withr::defer({.njsd_cache$enabled <- old_enabled; unlink(root, recursive = TRUE)})
  .njsd_cache$enabled <- TRUE
  dir.create(njsd_workbook_cache_dir(), recursive = TRUE)
  legacy <- file.path(njsd_workbook_cache_dir(), "SPR_school_2025.xlsx")
  fixture <- source_adapter_fixture("spr-district-2025.xlsx")
  file.copy(fixture, legacy)
  legacy_digest <- .source_digest(legacy)
  calls <- 0L
  request <- function(url, dest, timeout) {
    calls <<- calls + 1L
    file.copy(fixture, dest, overwrite = TRUE)
    list(status_code = 200L, final_url = url,
         content_type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
  }
  first <- spr_cached_workbook_result(2025, "school", request_fn = request)
  second <- spr_cached_workbook_result(2025, "school", request_fn = request)
  expect_identical(first$source_status, "actual")
  expect_identical(second$source_status, "actual")
  expect_identical(calls, 1L)
  expect_false(identical(first$data, legacy))
  expect_identical(.source_digest(legacy), legacy_digest)
  expect_false(file.exists(paste0(legacy, ".source.rds")))
  metadata <- readRDS(paste0(first$data, ".source.rds"))
  expect_identical(metadata$requested_url, get_spr_url(2025, "school"))
  expect_identical(metadata$digest, first$digest)
  # The new namespace must still refuse altered or missing identity metadata.
  metadata$requested_url <- get_spr_url(2024, "school")
  saveRDS(metadata, paste0(first$data, ".source.rds"))
  expect_match(spr_cached_workbook_result(2025, "school", request_fn = request)$error,
               "identity")
  unlink(paste0(first$data, ".source.rds"))
  expect_match(spr_cached_workbook_result(2025, "school", request_fn = request)$error,
               "identity")
  expect_identical(calls, 1L)
})
