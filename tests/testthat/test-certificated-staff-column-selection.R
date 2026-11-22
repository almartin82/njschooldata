# parse_certificated_modern() resolves each field from exact lower-cased
# header synonyms and must find ONE column per field. The sheet below is an
# in-memory picker fixture (header names as NJDOE prints them in the modern
# files, placeholder cells): it tests which column is chosen, not any value.

certificated_sheet <- function(headers) {
  cells <- stats::setNames(as.list(rep("1", length(headers))), headers)
  tibble::as_tibble(cells, .name_repair = "minimal")
}

modern_headers <- c("Co Code", "County", "Dist Code", "District", "Sch Code",
                    "School", "Position", "White", "Black", "Hispanic", "Asian",
                    "American Indian", "Hawaiian Native", "Two or More Races",
                    "Total", "Male", "Female")

parse_with <- function(headers) {
  sheet <- certificated_sheet(headers)
  testthat::local_mocked_bindings(read_excel = function(...) sheet, .package = "readxl")
  parse_certificated_modern("fixture.xlsx", "DISTRICT", 2024L)
}

test_that("one header per field parses", {
  out <- parse_with(modern_headers)
  expect_true(nrow(out) >= 1L)
  expect_true(all(out$county_id == "01"))
})

test_that("two synonyms of one field in the same sheet stop", {
  # "Co Code" and "Co" are both county_id synonyms; the first-hit pick used
  # whichever came first.
  expect_error(parse_with(c("Co", modern_headers)),
               "Ambiguous certificated-staff columns in fixture.xlsx: Co, Co Code")
})

test_that("a required field with zero matching headers stops", {
  expect_error(parse_with(setdiff(modern_headers, "Female")), "missing: female")
})
