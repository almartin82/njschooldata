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

test_that("a 2020 censored percentage is reported as unknown, not as a value", {
  # cds_code 313970999 is a district whose 2019-20 free-lunch share NJ DOE
  # published as the censoring token ">95" rather than a number.
  #
  # This test previously asserted pct == 0.975 and n_students == 13250.25.
  # Neither figure was ever published by NJ DOE: the fetcher rewrote ">95" to
  # "97.5" and multiplied that invented percentage by the district's 13,590
  # enrolled students. The test named it "the intentional 2020 transformation"
  # and locked it in. A withheld value is unknown and stays unknown.
  result <- get_raw_enr_result(
    2020,
    request_fn = fixture_request("enrollment-2020.zip", "application/zip")
  )
  expect_identical(result$source_status, "actual")

  raw <- result$data
  # which() because some rows carry an NA county code, and an NA in a logical
  # index would silently pull an extra NA row into every comparison below.
  censored <- which(
    raw[["County Code"]] == "31" & raw[["District Code"]] == "3970" &
      raw[["School Code"]] == "999" & raw[["Grade"]] == "All Grades"
  )
  expect_length(censored, 1L)

  # The censoring token survives into the raw frame as NJ DOE wrote it. The
  # old code overwrote this very cell with the string "97.5".
  expect_identical(raw[["%Free Lunch"]][censored], ">95")

  # And the count derived from it is unknown, not 0.975 * 13590 = 13250.25.
  expect_true(is.na(raw[["Free Lunch"]][censored]))
  expect_false(identical(raw[["Free Lunch"]][censored], 13250.25))

  # A percentage NJ DOE did publish still derives its count exactly, so the
  # guard removes the invented values and nothing else.
  published <- which(
    raw[["County Code"]] == "05" & raw[["District Code"]] == "3650" &
      raw[["School Code"]] == "300" & raw[["Grade"]] == "All Grades"
  )
  expect_length(published, 1L)
  expect_identical(raw[["%Free Lunch"]][published], "9.8")
  expect_equal(raw[["Free Lunch"]][published], 9.8 / 100 * 640)

  # A real published 0 percent is a value, not a suppression, and stays 0.
  expect_equal(raw[["Reduced Lunch"]][censored], 0)

  tidy <- suppressWarnings(tidy_enr(process_enr(raw)))
  total <- tidy[
    tidy$grade_level == "TOTAL" &
      tidy$subgroup %in% c(
        "free_lunch", "reduced_lunch", "free_reduced_lunch", "lep"
      ),
    c("cds_code", "subgroup", "n_students", "pct")
  ]

  # tidy_enr drops rows whose value is unknown, so an unknown subgroup is
  # ABSENT here rather than present-and-NA. Either is honest; publishing a
  # number NJ DOE never reported is not. Assert no such number appears.
  pick <- function(subgroup, column) {
    total[[column]][total$cds_code == "313970999" &
                      total$subgroup == subgroup]
  }

  expect_length(pick("free_lunch", "n_students"), 0L)
  expect_false(13250.25 %in% pick("free_lunch", "n_students"))
  expect_false(0.975 %in% pick("free_lunch", "pct"))

  # An unknown component makes the combined total unknown. It must not collapse
  # to 0, which would report the district as having no free/reduced students.
  expect_false(0 %in% pick("free_reduced_lunch", "n_students"))
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

test_that("directory fetch falls back to NJDOE performance-report contacts", {
  unavailable <- new_source_result(
    source_status = "source_unavailable",
    source_url = resolve_source_url("directory", level = "district"),
    retrieved_at = as.POSIXct("2026-07-29", tz = "UTC"),
    error = "fixture HTTP 403"
  )
  local_mocked_bindings(
    .directory_source_result = function(level, request_fn = NULL) unavailable,
    .default_source_request = fixture_request(
      "directory-spr-2025.json", "application/json"
    ),
    .package = "njschooldata"
  )

  snapshot <- fetch_directory()

  expect_identical(snapshot$meta$source_status, "ok")
  expect_equal(snapshot$meta$counts$districts, 1L)
  expect_equal(snapshot$meta$counts$schools, 1L)
  expect_setequal(snapshot$roles$role, c("superintendent", "principal"))
  expect_identical(
    snapshot$roles$person_name,
    c("Dr. Alan Burkhardt", "Dr. Alan Burkhardt")
  )
  expect_match(snapshot$meta$sources[[1]]$url, "www[.]nj[.]gov/education/spr/")
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
