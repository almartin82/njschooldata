nj_provenance_csv <- function(level, fixture) {
  .directory_source_result(level, request_fn = function(url, dest, timeout) {
    file.copy(test_path("fixtures", "directory-source", fixture), dest)
    list(status_code = 200L, final_url = url, content_type = "text/csv")
  })
}

test_that("canonical Homeroom sources retain original downloaded byte digests", {
  district <- nj_provenance_csv("district", "district-valid.csv")
  school <- nj_provenance_csv("school", "school-slot-titles.csv")
  local_mocked_bindings(.directory_source_result = function(level) {
    if (level == "district") district else school
  }, .package = "njschooldata")
  snapshot <- fetch_directory()
  # The public triple serializer omits R attributes; provenance must survive it.
  encoded <- jsonlite::toJSON(list(meta = snapshot$meta,
                                  entities = snapshot$entities, roles = snapshot$roles),
                              auto_unbox = TRUE, dataframe = "rows", na = "null")
  decoded <- jsonlite::fromJSON(encoded, simplifyVector = FALSE)
  expect_identical(decoded$meta$sources[[1]]$digest, district$digest)
  expect_identical(decoded$meta$sources[[2]]$digest, school$digest)
  expect_identical(decoded$meta$sources[[1]]$url, district$source_url)
  expect_identical(decoded$meta$sources[[2]]$url, school$source_url)
  expect_false(any(snapshot$roles$title_raw %in% c("Jr.", "Falkowski", "Ashanti")))
  expect_true(all(snapshot$roles$role[snapshot$roles$title_raw %in%
                                      c("Director", "Education Coordinator")] == "other"))
})

test_that("canonical SPR fallback retains its own acquired artifact digest", {
  result <- .directory_spr_source_result(request_fn = function(url, dest, timeout) {
    file.copy(source_adapter_fixture("directory-spr-2025.json"), dest)
    list(status_code = 200L, final_url = url, content_type = "application/json")
  })
  snapshot <- build_directory_from_spr(result$data, result$retrieved_at, result)
  expect_identical(snapshot$meta$sources[[1]]$digest, result$digest)
  expect_identical(snapshot$meta$sources[[1]]$url, result$source_url)
})
