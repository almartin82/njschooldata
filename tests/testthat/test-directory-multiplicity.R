nj_directory_spr_rows <- function(principals, emails) {
  dplyr::tibble(
    school_year = rep("2024-2025", length(principals)),
    county_code = rep("13", length(principals)),
    county_name = rep("Essex", length(principals)),
    district_code = rep("3570", length(principals)),
    district_name = rep("Example Public Schools", length(principals)),
    school_code = rep("001", length(principals)),
    school_name = rep("Example Elementary School", length(principals)),
    address1 = rep("200 State Street", length(principals)),
    city = rep("Newark", length(principals)),
    zip_code = rep("07102", length(principals)),
    s_schoolphone = rep("9735550100", length(principals)),
    s_website = rep("mock://school-website", length(principals)),
    s_principalname = principals,
    s_principalemail = emails,
    d_address = rep("100 State Street", length(principals)),
    d_city = rep("Newark", length(principals)),
    d_zip_code = rep("07102", length(principals)),
    d_districtphone = rep("9735550200", length(principals)),
    d_website = rep("mock://district-website", length(principals)),
    d_superintendentname = rep("Sam Superintendent", length(principals)),
    d_superintendentemail = rep("sam@example.org", length(principals))
  )
}

nj_directory_spr_result <- function(rows) {
  njschooldata:::new_source_result(
    data = rows,
    source_status = "actual",
    source_url = "mock://nj-spr-fixture",
    retrieved_at = as.POSIXct("2026-07-29 00:00:00", tz = "UTC")
  )
}

nj_build_spr_directory <- function(rows) {
  result <- nj_directory_spr_result(rows)
  njschooldata:::build_directory_from_spr(
    rows,
    as.POSIXct("2026-07-29 00:00:00", tz = "UTC"),
    result
  )
}

test_that("NJ SPR builder collapses repeats and retains co-principals", {
  source_rows <- nj_directory_spr_rows(
    c("Alex Exact", "Alex Exact", "Blake Distinct"),
    c("alex@example.org", "alex@example.org", "blake@example.org")
  )

  roles <- expect_directory_multiplicity_contract_v1(
    source_rows = source_rows,
    build_roles = function(rows) {
      built <- nj_build_spr_directory(rows)$roles
      built[built$role == "principal", , drop = FALSE]
    },
    expected_names = c("Alex Exact", "Blake Distinct")
  )

  reversed <- nj_build_spr_directory(source_rows[3:1, ])$roles
  reversed <- reversed[reversed$role == "principal", , drop = FALSE]

  expect_identical(roles, reversed)
  expect_identical(roles, njschooldata:::dc_sort_roles(roles))
  expect_identical(njschooldata:::dc_duplicate_key_count(roles), 1L)
})

test_that("NJ SPR builder rejects conflicting assignment evidence", {
  source_rows <- nj_directory_spr_rows(
    c("Alex Exact", " Alex Exact "),
    c("alex@example.org", "other@example.org")
  )

    quarantined_result <- {
    nj_build_spr_directory(source_rows)
  }
  quarantine <- attr(quarantined_result$roles, "directory_quarantine", exact = TRUE)
  expect_true(is.list(quarantine))
  expect_gt(quarantine$role_row_count, 0L)
})

test_that("directory surface declares the live zero-argument contract", {
  fetcher <- get("fetch_directory", envir = asNamespace("njschooldata"))

  expect_length(formals(fetcher), 0L)
})
