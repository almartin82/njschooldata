nj_rejection_gate <- function() {
  gate <- new.env(parent = globalenv())
  # Propagated master definitions, without running the fixture test blocks.
  for (expr in parse(test_path("test-directory-contract.R"))) {
    if (is.call(expr) && identical(expr[[1]], as.name("<-"))) {
      if (identical(expr[[2]], as.name(".dc_pkg"))) break
      eval(expr, gate)
    }
  }
  gate
}

nj_rejection_wire <- function(meta) jsonlite::fromJSON(jsonlite::toJSON(
  meta, auto_unbox = TRUE, na = "null", null = "null"), simplifyVector = FALSE)

nj_rejection_input <- function(level = "school", county = "13", district = "3570",
                               school = "001", name = NA_character_) {
  nj_screen_directory_rows(data.frame(county_code = county,
    district_code = district, school_code = school, school_name = name), level)$rejected
}

nj_rejection_meta <- function(rows, spr = FALSE) {
  meta <- list(state = "nj", id_scheme = DIRECTORY_ID_SCHEME,
               quality = list(rejected_source_row_count = nrow(rows)))
  nj_directory_add_rejection_evidence(meta, rows, spr)
}

test_that("exact school evidence survives JSON with all title mapper roles", {
  local_nj_offline_transport()
  rows <- nj_rejection_input()
  meta <- nj_rejection_wire(nj_rejection_meta(rows))
  expect_null(nj_rejection_gate()$.dc_rejected_extension_problem(meta, 1L))
  ext <- meta$extensions$nj
  expect_length(ext$rejected_rows, 1L)
  expect_setequal(vapply(ext$assignments, `[[`, "", "role"),
                  c("principal", "assistant_principal", "other"))
  expect_true(all(vapply(ext$assignments, function(a)
    identical(a$district_id, "133570") && identical(a$school_id, "133570001") &&
      !"match" %in% names(a) && identical(a$source_rows, list(1L)), logical(1))))
})

test_that("known parent without a school number uses district_role", {
  local_nj_offline_transport()
  rows <- nj_rejection_input(school = NA_character_)
  meta <- nj_rejection_wire(nj_rejection_meta(rows))
  expect_null(nj_rejection_gate()$.dc_rejected_extension_problem(meta, 1L))
  expect_true(all(vapply(meta$extensions$nj$assignments, function(a)
    identical(a$match, "district_role") && identical(a$district_id, "133570") &&
      is.null(a$school_id), logical(1))))
})

test_that("unknown district identity uses statewide district roles", {
  local_nj_offline_transport()
  rows <- nj_rejection_input("district", county = NA_character_)
  meta <- nj_rejection_wire(nj_rejection_meta(rows))
  expect_null(nj_rejection_gate()$.dc_rejected_extension_problem(meta, 1L))
  assignments <- meta$extensions$nj$assignments
  expect_setequal(vapply(assignments, `[[`, "", "role"),
    c("superintendent", "assistant_superintendent", "business_administrator",
      "special_education_director", "other"))
  expect_true(all(vapply(assignments, function(a)
    identical(a$match, "statewide_role") && identical(a$entity_type, "district") &&
      is.null(a$district_id) && is.null(a$school_id), logical(1))))
})

test_that("parentless composite school IDs and wholly unkeyable rows stay held", {
  local_nj_offline_transport()
  for (number in c("001", NA_character_)) {
    rows <- nj_rejection_input(county = NA_character_, school = number)
    meta <- nj_rejection_meta(rows)
    expect_null(meta$extensions)
    expect_match(nj_rejection_gate()$.dc_rejected_extension_problem(meta, 1L),
                 "requires serialized assignment evidence")
    expect_identical(meta$id_scheme, DIRECTORY_ID_SCHEME)
  }
})

test_that("combined sources get unique references and grouped assignment keys", {
  local_nj_offline_transport()
  structural <- nj_rejection_input("district")
  structural[1, ] <- list("district", "source line 6", "13", "3570", NA_character_, "structural overflow")
  rows <- rbind(structural, nj_rejection_input(), nj_rejection_input())
  meta <- nj_rejection_wire(nj_rejection_meta(rows))
  expect_null(nj_rejection_gate()$.dc_rejected_extension_problem(meta, 3L))
  expect_identical(vapply(meta$extensions$nj$rejected_rows, `[[`, 0L, "source_row"), 1:3)
  assignments <- meta$extensions$nj$assignments
  schools <- Filter(function(a) a$entity_type == "school", assignments)
  expect_true(all(vapply(schools, function(a) identical(a$source_rows, list(2L, 3L)), logical(1))))
  expect_true(all(vapply(Filter(function(a) a$entity_type == "district", assignments),
    function(a) is.null(a$school_id) && !"match" %in% names(a), logical(1))))
})

test_that("zero rejections leave metadata and existing extensions unchanged", {
  local_nj_offline_transport()
  rows <- nj_rejection_input(name = "Accepted school")
  meta <- list(state = "nj", quality = list(rejected_source_row_count = 0L),
               extensions = list(other = list(note = "retain")))
  expect_identical(nj_directory_add_rejection_evidence(meta, rows), meta)
  expect_null(nj_directory_rejected_extension(rows))
  bare <- list(state = "nj", quality = list(rejected_source_row_count = 0L))
  expect_identical(nj_directory_add_rejection_evidence(bare, rows), bare)
})

test_that("assignment quarantine evidence coexists with rejection evidence", {
  local_nj_offline_transport()
  key <- list(entity_type = "district", district_id = "019999", school_id = NULL,
              role = "superintendent", reason = "conflicting source contacts")
  meta <- list(state = "nj", extensions = list(nj = list(
    schema_version = "assignment-quarantine/v1", assignments = list(key))))
  meta <- nj_directory_add_rejection_evidence(meta, nj_rejection_input())
  expect_identical(meta$extensions$nj$quarantined_assignments, list(key))
  expect_null(nj_rejection_gate()$.dc_rejected_extension_problem(meta, 1L))
})

test_that("injected Homeroom rejection leaves unrelated assignments intact", {
  local_nj_offline_transport()
  source <- function(level) .directory_source_result(level, request_fn = function(url, dest, timeout) {
    file.copy(test_path("fixtures", "directory-source", if (level == "district")
      "district-valid.csv" else "school-slot-titles.csv"), dest)
    list(status_code = 200L, final_url = url, content_type = "text/csv")
  })
  district <- source("district")
  school <- source("school")
  # Append one complete-key row that the real screen rejects for a missing name.
  bad <- school$data[1, ]
  bad[["School Code"]] <- '="998"'
  bad[["School Name"]] <- NA_character_
  school$data <- rbind(school$data, bad)
  local_mocked_bindings(.directory_source_result = function(level)
    if (level == "district") district else school, .package = "njschooldata")
  out <- suppressWarnings(fetch_directory())
  meta <- nj_rejection_wire(out$meta)
  expect_identical(meta$quality$rejected_source_row_count, 1L)
  expect_null(nj_rejection_gate()$.dc_rejected_extension_problem(meta, 1L))
  expect_equal(nrow(attr(out, "rejected_source_rows")), 1L)
  expect_true(any(out$roles$entity_type == "school"))
  affected <- vapply(meta$extensions$nj$assignments, `[[`, "", "school_id")
  expect_false(any(out$roles$school_id %in% affected, na.rm = TRUE))
})

test_that("SPR rejection records both district and school contacts once", {
  local_nj_offline_transport()
  # This is the same screen used by the SPR builder. A school with a known
  # parent may fail while a sibling keeps the district entity in the result.
  rows <- nj_rejection_input(school = NA_character_)
  meta <- nj_rejection_wire(nj_rejection_meta(rows, spr = TRUE))
  expect_null(nj_rejection_gate()$.dc_rejected_extension_problem(meta, 1L))
  expect_length(meta$extensions$nj$rejected_rows, 1L)
  assignments <- meta$extensions$nj$assignments
  expect_setequal(vapply(assignments, `[[`, "", "role"), c("principal", "superintendent"))
  expect_identical(assignments[[1]]$match, "district_role")
  expect_identical(assignments[[2]]$district_id, "133570")
  expect_null(assignments[[2]]$match)
})


test_that("SPR builder serializes both tiers for a screened row", {
  local_nj_offline_transport()
  raw <- jsonlite::fromJSON(source_adapter_fixture("directory-spr-2025.json"))
  bad <- raw[1, ]
  bad$schoolName <- NA_character_
  raw <- rbind(raw, bad)
  result <- new_source_result(data = raw, source_status = "actual",
    source_url = "mock://spr", retrieved_at = as.POSIXct("2026-11-23", tz = "UTC"))
  out <- suppressWarnings(build_directory_from_spr(raw, result$retrieved_at, result))
  expect_identical(out$meta$quality$rejected_source_row_count, 1L)
  expect_length(out$meta$extensions$nj$rejected_rows, 1L)
  expect_setequal(vapply(out$meta$extensions$nj$assignments, `[[`, "", "entity_type"),
                  c("district", "school"))
  expect_null(nj_rejection_gate()$.dc_rejected_extension_problem(out$meta, 1L))
})
