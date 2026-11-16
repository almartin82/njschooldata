# Representative installed-source paths for the ordinary no-egress check.

nj_fast_artifact <- function(artifact_id) {
  root <- system.file(
    "extdata", "source-contract", "contracts",
    "new_jersey_shipped_sources", package = "njschooldata"
  )
  manifest <- jsonlite::read_json(
    file.path(root, "artifact-manifest.json"), simplifyVector = FALSE
  )
  matches <- Filter(function(artifact) {
    identical(artifact$artifact_id, artifact_id)
  }, manifest$artifacts)
  testthat::expect_length(matches, 1L)
  if (length(matches) != 1L) return(NULL)

  artifact <- matches[[1L]]
  path <- system.file(
    sub("^inst/", "", artifact$storage$path), package = "njschooldata"
  )
  testthat::expect_true(nzchar(path), info = artifact_id)
  testthat::expect_true(file.exists(path), info = artifact_id)
  testthat::expect_identical(
    as.numeric(file.info(path)$size), as.numeric(artifact$byte_length),
    info = artifact_id
  )
  testthat::expect_identical(
    njschooldata:::.source_digest(path), artifact$sha256,
    info = artifact_id
  )
  list(artifact = artifact, path = path)
}

test_that("fast offline tier parses verified installed enrollment and SPED sources", {
  local_nj_offline_transport()

  enrollment_source <- nj_fast_artifact("enrollment-2026")
  enrollment_url <- enrollment_source$artifact$source_identity$url
  enrollment <- njschooldata:::get_raw_enr_result(2026L)
  expect_identical(enrollment$source_status, "actual")
  expect_identical(enrollment$source_url, enrollment_url)
  expect_identical(enrollment$digest, enrollment_source$artifact$sha256)
  expect_s3_class(enrollment$data, "data.frame")
  expect_gt(nrow(enrollment$data), 0L)
  expect_identical(
    njschooldata:::.source_digest(enrollment$raw_path), enrollment$digest
  )

  sped_source <- nj_fast_artifact("sped-2025")
  sped <- fetch_sped(2025L)
  sped_provenance <- get_source_results(sped)
  expect_gt(nrow(sped), 0L)
  expect_identical(sped_provenance$source_status, "actual")
  expect_identical(sped_provenance$source_url, sped_source$artifact$source_identity$url)
  expect_identical(sped_provenance$digest, sped_source$artifact$sha256)

  grade_source <- nj_fast_artifact("sped_grade-opra-C255254")
  grade <- fetch_sped_by_grade(2025L)
  grade_provenance <- get_source_results(grade)
  expect_gt(nrow(grade), 0L)
  expect_identical(grade_provenance$source_status, "actual")
  expect_identical(grade_provenance$digest, grade_source$artifact$sha256)
})

test_that("fast offline tier reuses the processed enrollment result", {
  local_nj_offline_transport()
  cache_root <- withr::local_tempdir("njschooldata-fast-cache-")
  withr::local_options(njschooldata.cache_dir = cache_root)
  withr::local_envvar(NJSCHOOLDATA_CACHE_DIR = cache_root)
  njsd_cache_clear()

  first <- fetch_enr(2026L, tidy = TRUE, use_cache = TRUE)
  expect_gt(nrow(first), 0L)
  expect_identical(get_source_results(first)$source_status, "actual")
  expect_identical(get_source_results(first)$digest,
                   nj_fast_artifact("enrollment-2026")$artifact$sha256)

  testthat::local_mocked_bindings(
    get_raw_enr_result = function(...) {
      stop("processed enrollment result cache was not used", call. = FALSE)
    },
    .package = "njschooldata"
  )
  second <- fetch_enr(2026L, tidy = TRUE, use_cache = TRUE)
  expect_identical(second, first)
})

test_that("unseeded category assets return typed cold misses offline", {
  local_nj_offline_transport()
  withr::local_options(njschooldata.release_sources = TRUE)
  withr::local_envvar(c(
    NJSCHOOLDATA_OFFLINE = "true",
    STATE_SCHOOLDATA_HISTORICAL_ROOT = withr::local_tempdir(
      "njschooldata-cold-release-"
    )
  ))

  cold_sources <- list(
    enrollment = list(
      url = resolve_source_url("enrollment", end_year = 2020L)[[1L]],
      fetch = function() njschooldata:::get_raw_enr_result(2020L)
    ),
    assessment = list(
      url = resolve_source_url(
        "parcc", end_year = 2025L, grade = 4, subject = "ela"
      ),
      fetch = function() njschooldata:::get_raw_sla_result(2025L, 4, "ela")
    ),
    graduation = list(
      url = njschooldata:::.graduation_source_descriptor(2025L, "4 year")$url,
      fetch = function() njschooldata:::get_raw_grad_file_result(2025L, "4 year")
    ),
    SPR = list(
      url = get_spr_url(2025L, level = "school"),
      fetch = function() njschooldata:::spr_cached_workbook_result(2025L, "school")
    ),
    spending = list(
      url = njschooldata:::tges_url_for_year(2025L),
      fetch = function() njschooldata:::get_raw_tges_result(2025L)
    ),
    state_aid = list(
      url = resolve_source_url("state_aid", end_year = 2026L)[["direct"]],
      fetch = function() njschooldata:::get_raw_state_aid_result(2026L)
    )
  )

  for (name in names(cold_sources)) {
    source <- cold_sources[[name]]
    expect_false(is.null(njschooldata:::.nj_release_lookup(source$url)),
                 info = paste(name, "source is declared by the release contract"))
    result <- tryCatch(source$fetch(), error = identity)
    expect_s3_class(result, "njschooldata_source_error")
    expect_s3_class(result, "historical_cold_offline_error")
  }
})
