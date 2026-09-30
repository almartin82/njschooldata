nj_directory_byte_request <- function(name) {
  path <- testthat::test_path("fixtures", "directory-source", name)
  function(url, dest, timeout) {
    file.copy(path, dest, overwrite = TRUE)
    list(status_code = 200L, final_url = url, content_type = "text/csv")
  }
}

test_that("malformed Homeroom source rows cannot become personnel", {
  for (name in c("hainesport-malformed.csv", "robeson-malformed.csv")) {
    result <- suppressWarnings(.directory_source_result(
      "district", request_fn = nj_directory_byte_request(name)
    ))
    expect_identical(result$source_status, "parse_error")
    expect_null(result$data)
    expect_match(result$error, "CSV row 3")
    expect_match(result$error, "53 columns")
    expect_match(result$error, if (grepl("hainesport", name)) {
      "54 columns.*051910"
    } else {
      "55 columns.*806025"
    })
    expect_match(result$digest, "^[a-f0-9]{64}$")
    expect_identical(result$source_url, get_district_directory_url())
  }
})

test_that("malformed Homeroom is not hidden by a successful fallback", {
  district <- suppressWarnings(.directory_source_result(
    "district", request_fn = nj_directory_byte_request("robeson-malformed.csv")
  ))
  school <- .directory_source_result(
    "school", request_fn = nj_directory_byte_request("school-slot-titles.csv")
  )
  local_mocked_bindings(
    .directory_source_result = function(level) {
      if (level == "district") district else school
    },
    .directory_spr_source_result = function() stop("fallback must not run"),
    .package = "njschooldata"
  )
  failure <- tryCatch(fetch_directory(), error = identity)
  expect_s3_class(failure, "directory_parse_error")
  expect_match(conditionMessage(failure), "55 columns.*806025")
  records <- failure$source_results
  expect_identical(records$source_status, c("parse_error", "actual"))
  expect_match(records$error[1], "55 columns.*806025")
})

test_that("valid Homeroom rows preserve published roles and slot titles", {
  district <- .directory_source_result(
    "district", request_fn = nj_directory_byte_request("district-valid.csv")
  )
  school <- .directory_source_result(
    "school", request_fn = nj_directory_byte_request("school-slot-titles.csv")
  )
  local_mocked_bindings(
    .directory_source_result = function(level) {
      if (level == "district") district else school
    },
    .package = "njschooldata"
  )
  snapshot <- fetch_directory()
  expect_identical(snapshot$meta$source_status, "ok")
  expect_true(all(!is.na(snapshot$roles$title_raw)))
  expect_true(all(c("business_administrator", "special_education_director") %in%
                    snapshot$meta$coverage$district_roles))
  principals <- snapshot$roles[snapshot$roles$entity_type == "school", ]
  expect_setequal(principals$title_raw, c("Director", "Education Coordinator"))
  expect_true(all(principals$role == "other"))
  expect_identical(as.integer(snapshot$meta$quality$unmapped_title_count), 16L)
  expect_false(any(snapshot$roles$title_raw %in% c("Jr.", "Falkowski", "Ashanti")))
})

test_that("SPR field provenance never fabricates a verbatim title or vacancy", {
  result <- .directory_spr_source_result(
    request_fn = function(url, dest, timeout) {
      file.copy(source_adapter_fixture("directory-spr-2025.json"), dest)
      list(status_code = 200L, final_url = url, content_type = "application/json")
    }
  )
  snapshot <- build_directory_from_spr(result$data, result$retrieved_at, result)
  expect_true(all(is.na(snapshot$roles$title_raw)))
  expect_identical(snapshot$meta$coverage$role_provenance,
                   list(superintendent = "column", principal = "column"))
  expect_true(all(is.na(snapshot$roles$first_name)))
  expect_true(all(is.na(snapshot$roles$last_name)))
  expect_setequal(snapshot$meta$coverage$district_roles, "superintendent")
  expect_setequal(snapshot$meta$coverage$school_roles, "principal")
  result$data$s_principalname <- NA_character_
  result$data$s_principalemail <- NA_character_
  snapshot <- build_directory_from_spr(result$data, result$retrieved_at, result)
  blank <- snapshot$roles[snapshot$roles$role == "principal", ]
  expect_true(all(is.na(blank$person_name)))
  expect_true(all(is.na(blank$title_raw)))
})


test_that("role provenance validates null titles in both directions", {
  roles <- empty_directory_roles()
  roles[1, ] <- list("nj", "051910", NA_character_, "district", "superintendent",
                    NA_character_, "Source Name", NA_character_, NA_character_,
                    NA_character_, NA_character_)
  expect_error(dc_role_provenance(NULL, roles), "no declared provenance",
               class = "directory_integrity_error")
  expect_error(dc_role_provenance(list(superintendent = "title"), roles),
               "title-derived", class = "directory_integrity_error")
  expect_identical(dc_role_provenance(list(superintendent = "column"), roles),
                   list(superintendent = "column"))
  roles$title_raw <- "Superintendent"
  expect_error(dc_role_provenance(list(superintendent = "column"), roles),
               "cannot carry a source title", class = "directory_integrity_error")
})
