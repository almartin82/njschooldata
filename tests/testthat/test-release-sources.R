# Release-asset delivery of historical NJ DOE files: metadata and failure
# behaviour, no network. Every transfer here goes through an injected transport.

withr::local_options(njschooldata.release_sources = TRUE)

release_artifact <- function(url) {
  a <- njschooldata:::.nj_release_lookup(url)
  testthat::expect_false(is.null(a))
  a
}

small_url <- paste0(
  "https://www.nj.gov/education/specialed/monitor/ideapublicdata/docs/",
  "2023_618data/placement_StateWide_3-5_Age_2324.xlsx"
)

test_that("the release contract validates and pins every file to one immutable release", {
  docs <- njschooldata:::.nj_release_documents()
  arts <- docs$manifest$artifacts
  expect_length(arts, 160L)
  storage <- lapply(arts, `[[`, "storage")
  expect_true(all(vapply(storage, `[[`, "", "backend") == "release_asset"))
  expect_setequal(vapply(storage, `[[`, "", "tag"), c("sources-2026-11-08", "sources-2026-11-10"))
  expect_false(anyDuplicated(vapply(arts, `[[`, "", "sha256")) > 0)
  expect_false(anyDuplicated(vapply(storage, `[[`, "", "asset_name")) > 0)
  urls <- vapply(arts, `[[`, "", "source_identity")
  expect_true(all(startsWith(urls, "https://www.nj.gov/education/") |
                  grepl("^https://www[.]njsda[.]gov/(Projects/CapitalProgram|ProjectSchoolDetails/)", urls)))
})

test_that("held URLs resolve by their nj.gov address; others are not claimed", {
  spr <- release_artifact(paste0(
    "https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/",
    "Database_SchoolDetail.xlsx"))
  expect_equal(spr$byte_length, 346029712)
  expect_identical(spr$sha256,
                   "546cc2c06744549f3f4d9e3a3ab2502180ef222e58854b2c36b074472e2007ea")
  enr <- release_artifact("https://www.nj.gov/education/doedata/enr/enr99/enrollment_9899.zip")
  expect_identical(enr$selectors$end_year, "1999")
  expect_null(njschooldata:::.nj_release_lookup("https://www.nj.gov/education/not-held.xlsx"))
  expect_null(njschooldata:::.release_source("https://www.nj.gov/education/not-held.xlsx", "xlsx"))
})

test_that("an empty store offline stops with a typed error and never requests nj.gov", {
  withr::local_envvar(STATE_SCHOOLDATA_HISTORICAL_ROOT = withr::local_tempdir(),
                      NJSCHOOLDATA_OFFLINE = "true")
  err <- tryCatch(njschooldata:::download_source(small_url, "xlsx"), error = identity)
  expect_s3_class(err, "njschooldata_source_error")
  expect_s3_class(err, "historical_cold_offline_error")
})

test_that("a tampered transfer fails integrity, even at the committed length", {
  withr::local_envvar(STATE_SCHOOLDATA_HISTORICAL_ROOT = withr::local_tempdir(),
                      NJSCHOOLDATA_OFFLINE = "")
  a <- release_artifact(small_url)
  tampered <- function(url, emit) {
    expect_identical(url, a$storage$download_url)
    emit(as.raw(rep(0x50, a$byte_length)))
  }
  err <- tryCatch(
    njschooldata:::.release_source(small_url, "xlsx", .transport = tampered),
    error = identity)
  expect_s3_class(err, "njschooldata_historical_integrity_error")
  expect_s3_class(err, "njschooldata_source_error")
})

test_that("a tampered blob already in the store fails integrity at read time", {
  root <- withr::local_tempdir()
  withr::local_envvar(STATE_SCHOOLDATA_HISTORICAL_ROOT = root, NJSCHOOLDATA_OFFLINE = "true")
  a <- release_artifact(small_url)
  njschooldata:::.historical_store(root, create = TRUE)
  writeBin(as.raw(rep(0x50, a$byte_length)), file.path(root, "blobs", a$sha256))
  err <- tryCatch(njschooldata:::download_source(small_url, "xlsx"), error = identity)
  expect_s3_class(err, "njschooldata_historical_integrity_error")
})

test_that("bundled sheet extracts do not answer for their parent workbook URL", {
  # The 2024 and 2025 SPR school extracts share the full workbook's URL. Only a
  # complete publication may answer, or the workbook read stops as ambiguous.
  url <- paste0("https://www.nj.gov/education/sprreports/download/DataFiles/",
                "2024-2025/Database_SchoolDetail.xlsx")
  expect_null(njschooldata:::.package_source(url, "xlsx"))
})

test_that("the explicit opt-out leaves a URL unclaimed", {
  withr::local_options(njschooldata.release_sources = FALSE)
  expect_null(njschooldata:::.nj_release_lookup(small_url))
})
