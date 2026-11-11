# Routing tests use real workbook fixtures; diagnostic HTML tests only transport.
test_that("all newly held years and facilities captures have pinned identities", {
  local_nj_offline_transport()
  withr::local_options(njschooldata.release_sources = TRUE)
  arts <- .nj_release_documents()$manifest$artifacts
  added <- Filter(function(a) a$storage$tag == "sources-2026-11-10", arts)
  expect_length(added, 30L)
  expect_equal(sum(vapply(added, `[[`, 0, "byte_length")), 39692151)
  for (y in 2012:2019) {
    a <- .nj_release_lookup(.graduation_source_descriptor(y, "5 year")$url)
    expect_identical(a$selectors$end_year, as.character(y))
    expect_identical(a$selectors$family, "graduation")
  }
  for (y in 2012:2016) {
    a <- .nj_release_lookup(resolve_source_url("report_card", y, level = "school"))
    expect_identical(a$selectors$end_year, as.character(y))
    expect_identical(a$selectors$family, "report_card")
  }
  for (source in c("njdoe_sda_allocation", "njdoe_lead_soa", "njsda_active_projects")) {
    expect_identical(.nj_release_lookup(facilities_sources()[[source]]$url)$selectors$family,
                     "facilities")
  }
})

test_that("held workbook URLs bypass publisher transport on every call", {
  local_nj_offline_transport()
  withr::local_options(njschooldata.release_sources = TRUE)
  calls <- character()
  local_mocked_bindings(
    .default_source_request = function(...) stop("publisher transport must not run"),
    .nj_release_materialize = function(artifact, destination, ...) {
      calls <<- c(calls, artifact$source_identity)
      file.copy(source_adapter_fixture("spr-district-2025.xlsx"), destination)
      invisible(destination)
    }, .package = "njschooldata")
  arts <- Filter(function(a) a$storage$tag == "sources-2026-11-10" &&
                   a$publisher_identity$source_type == "xlsx",
                 .nj_release_documents()$manifest$artifacts)
  for (a in arts) {
    result <- download_source(a$source_identity, "xlsx")
    expect_identical(result$source_status, "actual")
    expect_identical(result$digest, a$sha256)
    .release_source_result(result)
    expect_false(file.exists(result$data))
  }
  expect_identical(calls, vapply(arts, `[[`, "", "source_identity"))
})

test_that("every held project page is read through the release hook", {
  local_nj_offline_transport()
  withr::local_options(njschooldata.release_sources = TRUE)
  calls <- character()
  diagnostic <- "<!DOCTYPE html><html><body>transport diagnostic</body></html>"
  local_mocked_bindings(.nj_release_materialize = function(artifact, destination, ...) {
    calls <<- c(calls, artifact$source_identity)
    writeLines(diagnostic, destination)
  }, .package = "njschooldata")
  local_mocked_bindings(GET = function(...) stop("publisher HTML transport must not run"),
                        .package = "httr")
  arts <- Filter(function(a) a$publisher_identity$source_type == "html",
                 .nj_release_documents()$manifest$artifacts)
  expect_length(arts, 15L)
  for (a in arts) expect_identical(facilities_get_text(a$source_identity), diagnostic)
  expect_identical(calls, vapply(arts, `[[`, "", "source_identity"))
})

test_that("facility registers and snapshots never use the old parsed cache", {
  local_nj_offline_transport()
  root <- withr::local_tempdir()
  withr::local_options(njschooldata.cache_dir = root)
  calls <- character()
  record <- function(src) {
    calls <<- c(calls, src$url)
    list(source_url = src$url)
  }
  local_mocked_bindings(get_raw_njdoe_cds = record, get_raw_facilities_arcgis = record,
                        get_raw_njdoe_sda_allocation = record,
                        get_raw_njdoe_lead_soa = record,
                        get_raw_njsda_active_projects = record, .package = "njschooldata")
  for (src in names(facilities_sources())) {
    first <- get_raw_facilities(src, use_cache = TRUE)
    second <- get_raw_facilities(src, use_cache = TRUE)
    third <- get_raw_facilities(src, use_cache = FALSE)
    expect_identical(first, second)
    expect_identical(first, third)
    expect_identical(sum(calls == facilities_sources()[[src]]$url), 3L)
  }
  expect_length(list.files(root, recursive = TRUE, all.files = TRUE,
                           no.. = TRUE, include.dirs = TRUE), 0L)
})

test_that("a failed held project page stops the complete snapshot", {
  local_nj_offline_transport()
  withr::local_options(njschooldata.release_sources = TRUE)
  index <- facilities_sources()$njsda_active_projects$url
  details <- Filter(function(a) startsWith(a$source_identity,
                      "https://www.njsda.gov/ProjectSchoolDetails/"),
                    .nj_release_documents()$manifest$artifacts)
  url <- details[[1]]$source_identity
  local_mocked_bindings(facilities_get_text = function(requested) {
    if (identical(requested, index)) {
      return(paste0('<html><a href="', url, '">Project</a></html>'))
    }
    stop(structure(list(message = "held detail integrity failure", call = NULL),
                   class = c("historical_integrity_error", "error", "condition")))
  }, .package = "njschooldata")
  expect_error(get_raw_facilities("njsda_active_projects"),
               class = "historical_integrity_error")
})

test_that("placement workbooks are session-independent temporary copies", {
  local_nj_offline_transport()
  root <- withr::local_tempdir()
  withr::local_options(njschooldata.cache_dir = root, njschooldata.workbook_cache = TRUE)
  calls <- 0L
  local_mocked_bindings(.release_download_to = function(url, destfile) {
    calls <<- calls + 1L
    file.copy(source_adapter_fixture("spr-district-2025.xlsx"), destfile)
    TRUE
  }, .package = "njschooldata")
  first <- sped_placement_cached_workbook(2025, url = "https://www.nj.gov/placement.xlsx")
  second <- sped_placement_cached_workbook(2025, url = "https://www.nj.gov/placement.xlsx")
  withr::defer(unlink(c(first, second)))
  expect_identical(calls, 2L)
  expect_false(identical(first, second))
  expect_true(is_valid_xlsx(first))
  expect_identical(.source_digest(first), .source_digest(second))
  expect_length(list.files(root, recursive = TRUE, all.files = TRUE,
                           no.. = TRUE, include.dirs = TRUE), 0L)
})
