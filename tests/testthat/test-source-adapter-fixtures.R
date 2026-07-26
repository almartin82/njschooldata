source_fixture <- function(name) {
  source_adapter_fixture(name)
}

fixture_request <- function(name, content_type) {
  fixture <- source_fixture(name)
  force(content_type)
  function(url, dest, timeout) {
    file.copy(fixture, dest, overwrite = TRUE)
    list(status_code = 200L, final_url = url, content_type = content_type)
  }
}

test_that("enrollment fixture preserves the intentional 2020 transformation", {
  result <- get_raw_enr_result(
    2020,
    request_fn = fixture_request("enrollment-2020.zip", "application/zip")
  )
  expect_identical(result$source_status, "actual")

  tidy <- suppressWarnings(tidy_enr(process_enr(result$data)))
  total <- tidy[
    tidy$grade_level == "TOTAL" &
      tidy$subgroup %in% c(
        "free_lunch", "reduced_lunch", "free_reduced_lunch", "lep"
      ),
    c("cds_code", "subgroup", "n_students", "pct")
  ]

  expect_equal(
    total$n_students[total$cds_code == "313970999" &
                       total$subgroup == "free_lunch"],
    13250.25
  )
  expect_equal(
    total$pct[total$cds_code == "313970999" &
                total$subgroup == "free_lunch"],
    0.975
  )
  expect_equal(
    total$n_students[total$cds_code == "313970999" &
                       total$subgroup == "free_reduced_lunch"],
    13250.25
  )
})

test_that("assessment fixture exercises the real workbook parser", {
  result <- get_raw_sla_result(
    2025, 4, "ela",
    request_fn = fixture_request(
      "njsla-ela04-2025.xlsx",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    )
  )

  expect_identical(result$source_status, "actual")
  expect_equal(nrow(result$data), 5L)
  expect_true(all(c("County Code", "Subgroup", "L4 Percent") %in%
                    names(result$data)))
})

test_that("SPR fixture exercises the registered workbook boundary", {
  fixture <- source_fixture("spr-district-2025.xlsx")
  local_mocked_bindings(
    spr_cached_workbook_result = function(end_year, level) {
      new_source_result(
        data = fixture,
        source_status = "actual",
        source_url = resolve_source_url("spr", end_year, level = level),
        retrieved_at = as.POSIXct("2026-07-20", tz = "UTC"),
        digest = digest::digest(file = fixture, algo = "sha256", serialize = FALSE)
      )
    },
    .package = "njschooldata"
  )
  njsd_cache_clear()
  out <- fetch_spr_data(
    "ChronicAbsenteeismStudentGroup", 2025, level = "district"
  )

  expect_gt(nrow(out), 0L)
  expect_true(all(c("county_id", "district_id", "subgroup") %in% names(out)))
  expect_identical(get_source_results(out)$source_status, "actual")
})

test_that("finance fixture exercises TGES archive parsing", {
  parsed <- .parse_tges_archive(source_fixture("tges-2025.zip"))
  expect_named(parsed, "CSG1")
  expect_gt(nrow(parsed$CSG1), 0L)
  expect_true("file_name" %in% names(parsed$CSG1))
})

test_that("directory fixture exercises Homeroom CSV parsing", {
  result <- .directory_source_result(
    "district",
    request_fn = fixture_request("directory-district.csv", "text/csv")
  )
  expect_identical(result$source_status, "actual")
  parsed <- process_district_directory(result$data)
  expect_equal(nrow(parsed), 1L)
  expect_identical(parsed$district_id, "1431")
  expect_identical(parsed$entity_type, "district")
})

test_that("directory adapter rejects plaintext error responses", {
  request <- function(url, dest, timeout) {
    writeLines(c("header", "header", "header", "Access Denied"), dest)
    list(status_code = 200L, final_url = url, content_type = "text/csv")
  }
  result <- .directory_source_result("district", request_fn = request)

  expect_identical(result$source_status, "parse_error")
  expect_match(result$error, "structural contract")
})

test_that("report-card workbooks cross the validated transport boundary", {
  url <- resolve_source_url("report_card", 2019)[["district"]]
  out <- download_and_clean_pr(
    tempfile(fileext = ".xlsx"), url, 2019,
    request_fn = fixture_request(
      "spr-district-2025.xlsx",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    )
  )

  expect_type(out, "list")
  expect_gt(length(out), 0L)
  records <- get_source_results(out)
  expect_identical(records$source_status, "actual")
  expect_identical(records$source_url, url)
})

test_that("SPED workbooks cross the validated transport boundary", {
  source <- list(
    url = "https://www.nj.gov/example/sped.xlsx",
    zip_member = NA_character_
  )
  result <- download_sped_classification_workbook(
    source, 2025,
    request_fn = fixture_request(
      "spr-district-2025.xlsx",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    )
  )
  on.exit(unlink(result$data), add = TRUE)

  expect_s3_class(result, "njsd_source_result")
  expect_identical(result$source_status, "actual")
  expect_true(file.exists(result$data))
})

test_that("DFG schema failures are distinguished from source outages", {
  result <- .fetch_dfg_result(
    2000,
    request_fn = fixture_request(
      "spr-district-2025.xlsx",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    )
  )

  expect_identical(result$source_status, "parse_error")
  expect_match(result$error, "county_name")
  expect_error(fetch_dfg(1990.5), "revision")
})
