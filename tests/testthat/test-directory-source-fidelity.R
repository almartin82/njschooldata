nj_directory_byte_request <- function(name) {
  path <- testthat::test_path("fixtures", "directory-source", name)
  function(url, dest, timeout) {
    file.copy(path, dest, overwrite = TRUE)
    list(status_code = 200L, final_url = url, content_type = "text/csv")
  }
}

test_that("bounded source reconstruction restores every displaced field", {
  h <- .directory_source_result("district", request_fn = nj_directory_byte_request("hainesport-malformed.csv"))
  r <- .directory_source_result("district", request_fn = nj_directory_byte_request("robeson-malformed.csv"))
  expect_identical(h$source_status, "actual")
  expect_identical(r$source_status, "actual")
  expect_identical(h$data[["SEC Last Name"]][2], "Procopio, Jr.")
  expect_identical(h$data[["SEC Title2"]][2], "Supervisor of Special Services")
  expect_identical(h$data[["Website"]][2], "www.hainesport.k12.nj.us")
  expect_identical(r$data[["City"]][2], "Trenton")
  expect_identical(r$data[["State"]][2], "NJ")
  expect_identical(r$data[["BA First Name"]][2], "Brian")
  expect_identical(r$data[["BA Last Name"]][2], "Falkowski")
  expect_identical(r$data[["SEC First Name"]][2], "Ashanti")
  expect_identical(r$data[["SEC Last Name"]][2], "Waters")
  expect_identical(r$data[["Website"]][2], "www.paulrobesoncs.org")
  expect_identical(kill_padformulas(r$data[["NCES ID"]][2]), "3400723")
  expect_true(all(is.na(r$data[["X URL"]]) | r$data[["X URL"]] == ""))
  expect_identical(ncol(h$data), 53L)
  expect_identical(ncol(r$data), 53L)
})

test_that("unknown overflow remains a structural error", {
  result <- .directory_source_result("district", request_fn = function(url, dest, timeout) {
    lines <- readLines(test_path("fixtures", "directory-source", "hainesport-malformed.csv"))
    lines <- gsub("Procopio, Jr.", "Procopio, UNVERIFIED", lines, fixed = TRUE)
    writeLines(lines, dest)
    list(status_code = 200L, final_url = url, content_type = "text/csv")
  })
  expect_identical(result$source_status, "parse_error")
  expect_null(result$data)
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
