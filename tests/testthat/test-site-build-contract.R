load_site_build_helpers <- function() {
  script <- package_source_path("site", "build-data.R")
  withr::local_dir(tempdir())
  env <- new.env(parent = globalenv())
  sys.source(script, envir = env)
  env$.build_manifest$rows <- env$.build_manifest$rows[0, , drop = FALSE]
  env$MANIFEST_PATH <- tempfile(fileext = ".json")
  env
}

load_discovery_build_helpers <- function() {
  script <- package_source_path("site", "discovery-build.R")
  withr::local_dir(tempdir())
  env <- new.env(parent = globalenv())
  sys.source(script, envir = env)
  env$.discovery_manifest$rows <-
    env$.discovery_manifest$rows[0, , drop = FALSE]
  env$SW_DIR <- tempfile("discovery-statewide-")
  dir.create(env$SW_DIR, recursive = TRUE)
  env$DISCOVERY_MANIFEST_PATH <- tempfile(fileext = ".json")
  env
}

test_that("strict site coverage fails and writes every missing request", {
  site <- load_site_build_helpers()
  site$manifest_request("enrollment", 2024:2025, required = TRUE)
  site$manifest_request("optional", 2025, required = FALSE)
  site$manifest_record("enrollment", 2024, status = "actual")
  site$manifest_record(
    "enrollment", 2025, status = "source_unavailable", error = "HTTP 503"
  )
  site$manifest_record(
    "optional", 2025, status = "not_published", completed = FALSE
  )

  expect_error(
    site$assert_required_coverage(FALSE),
    "enrollment/2025.*source_unavailable"
  )
  manifest <- jsonlite::fromJSON(site$MANIFEST_PATH)
  expect_equal(nrow(manifest$requests), 3L)
  expect_identical(
    manifest$requests$source_status,
    c("actual", "source_unavailable", "not_published")
  )
})

test_that("partial site coverage requires an explicit opt-in", {
  site <- load_site_build_helpers()
  site$manifest_request("njgpa", 2025, c("ela", "math"), required = TRUE)
  site$manifest_record("njgpa", 2025, "ela", status = "actual")
  site$manifest_record(
    "njgpa", 2025, "math", status = "parse_error", error = "schema changed"
  )

  expect_error(site$assert_required_coverage(FALSE), "njgpa/2025/math")
  expect_false(site$assert_required_coverage(TRUE))
})

test_that("bundle success is recorded only after an artifact exists", {
  script <- readLines(
    package_source_path("site", "build-data.R"), warn = FALSE
  )
  success_line <- grep("ok <- ok [+] 1", script)
  artifact_line <- grep("file[.]exists[(]artifact[)]", script)
  expect_length(success_line, 1L)
  expect_length(artifact_line, 1L)
  expect_gt(success_line, artifact_line)
})

test_that("site fetch failures use explicit sentinels rather than NULL", {
  site <- load_site_build_helpers()
  site$manifest_request("njgpa", 2025, "math")
  value <- suppressWarnings(site$fetch_year_components(
    2025, "math", function(year, component) stop("bad workbook"), "njgpa"
  ))

  expect_s3_class(value, "data.frame")
  row <- site$.build_manifest$rows
  expect_identical(row$source_status, "source_unavailable")
  expect_match(row$error, "bad workbook")
  expect_false(any(vapply(
    list(site$site_source_failure("parse_error", "bad")),
    is.null,
    logical(1)
  )))
})

test_that("cached partial builds retain per-request source status", {
  site <- load_site_build_helpers()
  site$SW_DIR <- tempfile("site-statewide-")
  dir.create(site$SW_DIR, recursive = TRUE)
  site$manifest_request("njgpa", 2025, c("ela", "math"))

  built <- site$cache_or_build(
    "njgpa-contract",
    function() {
      site$manifest_record("njgpa", 2025, "ela", status = "actual")
      site$manifest_record(
        "njgpa", 2025, "math", status = "parse_error",
        error = "fixture schema changed"
      )
      data.frame(subject = "ela", value = 1)
    },
    refresh = TRUE,
    records_inside = TRUE,
    domain = "njgpa"
  )
  expect_s3_class(built, "data.frame")

  site$.build_manifest$rows <- site$.build_manifest$rows[0, , drop = FALSE]
  site$manifest_request("njgpa", 2025, c("ela", "math"))
  reused <- site$cache_or_build(
    "njgpa-contract",
    function() stop("cache should have been reused"),
    domain = "njgpa"
  )

  expect_s3_class(reused, "data.frame")
  expect_identical(
    site$.build_manifest$rows$source_status,
    c("actual", "parse_error")
  )
  expect_error(site$assert_required_coverage(FALSE), "njgpa/2025/math")
})

test_that("legacy aggregate caches without provenance are not trusted", {
  site <- load_site_build_helpers()
  site$SW_DIR <- tempfile("site-statewide-")
  dir.create(site$SW_DIR, recursive = TRUE)
  site$manifest_request("enrollment", 2025)
  saveRDS(data.frame(end_year = 2025), site$sw_path("enrollment-contract"))

  restored <- site$cache_or_build(
    "enrollment-contract",
    function() stop("cache should have been reused"),
    domain = "enrollment"
  )

  expect_true(site$is_site_source_failure(restored))
  row <- site$.build_manifest$rows
  expect_false(row$completed)
  expect_identical(row$source_status, "source_unavailable")
  expect_match(row$error, "lacks source-manifest provenance")
  expect_error(site$assert_required_coverage(FALSE), "enrollment/2025")
})

test_that("partial site builds cannot consume incompletely proven caches", {
  site <- load_site_build_helpers()
  site$SW_DIR <- tempfile("site-statewide-")
  dir.create(site$SW_DIR, recursive = TRUE)
  site$manifest_request("njgpa", 2025, c("ela", "math"))

  cached <- data.frame(subject = "ela", value = 1)
  attr(cached, site$SITE_MANIFEST_ATTR) <- data.frame(
    domain = "njgpa",
    end_year = 2025L,
    component = "ela",
    completed = TRUE,
    source_status = "actual",
    source_url = "https://www.nj.gov/ela.xlsx",
    retrieved_at = "2026-01-01 UTC",
    digest = "fixture",
    warning = NA_character_,
    error = NA_character_
  )
  saveRDS(cached, site$sw_path("njgpa-contract"))

  restored <- site$cache_or_build(
    "njgpa-contract",
    function() stop("cache should have been reused"),
    domain = "njgpa"
  )

  expect_true(site$is_site_source_failure(restored))
  expect_identical(
    site$.build_manifest$rows$source_status,
    c("actual", "source_unavailable")
  )
  expect_false(site$assert_required_coverage(TRUE))
})

test_that("aggregate parse failures supersede successful source retrieval", {
  site <- load_site_build_helpers()
  site$SW_DIR <- tempfile("site-statewide-")
  dir.create(site$SW_DIR, recursive = TRUE)
  site$manifest_request("enrollment", 2025)

  value <- suppressWarnings(site$cache_or_build(
    "enrollment-contract",
    function() {
      site$manifest_record("enrollment", 2025, status = "actual")
      stop("unexpected statewide schema")
    },
    refresh = TRUE,
    records_inside = TRUE,
    domain = "enrollment"
  ))

  expect_true(site$is_site_source_failure(value))
  row <- site$.build_manifest$rows
  expect_false(row$completed)
  expect_identical(row$source_status, "parse_error")
  expect_match(row$error, "failed after source retrieval.*unexpected statewide schema")
  expect_error(site$assert_required_coverage(FALSE), "enrollment/2025.*parse_error")
})

test_that("bundle filenames accept only canonical district identifiers", {
  site <- load_site_build_helpers()
  expect_identical(site$safe_bundle_id("4900"), "4900")
  expect_error(site$safe_bundle_id("../../4900"), "Unsafe district identifier")
  expect_error(site$safe_bundle_id("4900.yml"), "Unsafe district identifier")
})

test_that("discovery builds are strict and manifest-backed", {
  source <- paste(readLines(
    package_source_path("site", "discovery-build.R"), warn = FALSE
  ), collapse = "\n")

  expect_match(source, "--allow-partial", fixed = TRUE)
  expect_match(source, "discovery-build-manifest[.]json")
  expect_match(source, "new_source_result")
  expect_match(source, "if [(]sys[.]nframe[(][)] == 0L[)]")
  expect_false(grepl("error\\s*=\\s*function\\s*\\([^)]*\\)\\s*\\{?[^}]*NULL",
                     source, perl = TRUE))
})

test_that("discovery year failures are explicit and strict caches are not written", {
  discovery <- load_discovery_build_helpers()
  value <- suppressWarnings(discovery$cache_or_build(
    "contract",
    function() discovery$years_bind(
      2024:2025,
      function(year) {
        if (year == 2025) stop("HTTP 503")
        data.frame(end_year = year, value = 1)
      },
      "contract"
    ),
    refresh = TRUE,
    allow_partial = FALSE
  ))

  expect_true(discovery$is_discovery_failure(value))
  expect_false(file.exists(discovery$sw_path("contract")))
  expect_identical(
    discovery$.discovery_manifest$rows$source_status,
    c("actual", "source_unavailable")
  )
  expect_error(
    discovery$assert_discovery_coverage(FALSE),
    "contract/2025.*source_unavailable"
  )
})

test_that("partial discovery caches require opt-in and retain provenance", {
  discovery <- load_discovery_build_helpers()
  value <- suppressWarnings(discovery$cache_or_build(
    "contract",
    function() discovery$years_bind(
      2024:2025,
      function(year) {
        if (year == 2025) stop("schema changed")
        data.frame(end_year = year, value = 1)
      },
      "contract"
    ),
    refresh = TRUE,
    allow_partial = TRUE
  ))

  expect_s3_class(value, "data.frame")
  expect_true(file.exists(discovery$sw_path("contract")))
  expect_identical(
    attr(value, discovery$DISCOVERY_MANIFEST_ATTR)$source_status,
    c("actual", "source_unavailable")
  )
  expect_false(discovery$assert_discovery_coverage(TRUE))
  manifest <- jsonlite::fromJSON(discovery$DISCOVERY_MANIFEST_PATH)
  expect_true(manifest$allow_partial)
})

test_that("discovery rejects malformed cached provenance", {
  discovery <- load_discovery_build_helpers()
  value <- data.frame(end_year = 2025L)
  attr(value, discovery$DISCOVERY_MANIFEST_ATTR) <- data.frame(
    domain = "contract", completed = TRUE
  )
  saveRDS(value, discovery$sw_path("contract"))

  restored <- discovery$cache_or_build(
    "contract", function() stop("cache should have been reused")
  )
  expect_true(discovery$is_discovery_failure(restored))
  expect_identical(
    discovery$.discovery_manifest$rows$source_status,
    "source_unavailable"
  )
})

test_that("empty discovery categories are parser failures", {
  discovery <- load_discovery_build_helpers()
  value <- discovery$cache_or_build(
    "contract", function() data.frame(), refresh = TRUE,
    allow_partial = FALSE
  )

  expect_true(discovery$is_discovery_failure(value))
  expect_false(file.exists(discovery$sw_path("contract")))
  expect_identical(
    discovery$.discovery_manifest$rows$source_status,
    "parse_error"
  )
})

test_that("post-filter empty discovery aggregates cannot pass on slice success", {
  discovery <- load_discovery_build_helpers()
  value <- discovery$cache_or_build(
    "contract",
    function() {
      discovery$years_bind(
        2024:2025,
        function(year) data.frame(end_year = year, is_district = FALSE),
        "contract"
      ) |>
        dplyr::filter(is_district)
    },
    refresh = TRUE,
    allow_partial = FALSE
  )

  expect_true(discovery$is_discovery_failure(value))
  expect_false(file.exists(discovery$sw_path("contract")))
  expect_identical(
    tail(discovery$.discovery_manifest$rows$source_status, 1),
    "parse_error"
  )
})

test_that("post-filter empty statewide aggregates cannot be cached", {
  site <- load_site_build_helpers()
  site$SW_DIR <- tempfile("site-statewide-")
  dir.create(site$SW_DIR, recursive = TRUE)
  site$manifest_request("enrollment", 2025)

  value <- suppressWarnings(site$cache_or_build(
    "enrollment-contract",
    function() {
      site$manifest_record("enrollment", 2025, status = "actual")
      data.frame()
    },
    refresh = TRUE,
    records_inside = TRUE,
    domain = "enrollment"
  ))

  expect_true(site$is_site_source_failure(value))
  expect_false(file.exists(site$sw_path("enrollment-contract")))
  aggregate <- tail(site$.build_manifest$rows, 1)
  expect_identical(aggregate$source_status, "parse_error")
  expect_false(aggregate$completed)
})
