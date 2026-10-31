.sped_grade_workbook <- function() {
  readxl::read_excel(
    system.file("extdata/program-sources/sped_grade-opra-C255254.xlsx",
                package = "njschooldata"),
    na = "", col_types = "text"
  )
}

test_that("fetch_sped_by_grade keeps every released count for every year", {
  book <- .sped_grade_workbook()
  grades <- names(njschooldata:::.SPED_GRADE_LEVELS)
  for (year in 2022:2025) {
    d <- fetch_sped_by_grade(year)
    rows <- book[book[["School Year"]] == sprintf("%d-%02d", year - 1L, year %% 100L), ]
    cells <- unlist(rows[grades], use.names = FALSE)
    expect_equal(sum(d$n_students, na.rm = TRUE),
                 sum(as.numeric(cells[!is.na(cells) & cells != "*"])))
    expect_equal(sum(d$suppressed), sum(cells == "*", na.rm = TRUE))
    expect_equal(nrow(d), sum(!is.na(cells)))
    expect_equal(dplyr::n_distinct(d$district_id, d$county_id), nrow(rows))
    expect_equal(anyDuplicated(d[c("county_id", "district_id", "grade_level")]), 0L)
  }
})

test_that("suppressed cells are NA, never zero, and blanks have no row", {
  d <- fetch_sped_by_grade(2022)
  absecon <- d[d$district_id == "0010" & d$county_id == "01", ]
  grade1 <- absecon[absecon$grade_level == "01", ]
  expect_true(grade1$suppressed)
  expect_true(is.na(grade1$n_students))
  expect_false(any(absecon$grade_level %in% c("09", "10", "11", "12")))
  expect_true(all(is.na(d$n_students[d$suppressed])))
  expect_false(anyNA(d$n_students[!d$suppressed]))
})

test_that("ids keep their leading zeros and charters are county 80", {
  d <- fetch_sped_by_grade(2025)
  expect_true(all(nchar(d$district_id) == 4L))
  expect_true(all(nchar(d$county_id) == 2L))
  expect_true(all(d$grade_level %in% c("PK", "K", sprintf("%02d", 1:12), "NO_GRADE")))
  expect_identical(d$is_charter, d$county_id == "80")
  expect_true(all(d$is_district))
})

test_that("OPRA totals agree with NJDOE's published classification file", {
  opra <- fetch_sped_by_grade(2025) %>%
    dplyr::group_by(county_id, district_id) %>%
    dplyr::summarise(total = sum(n_students), any_suppressed = any(suppressed),
                     .groups = "drop")
  published <- fetch_sped(2025) %>%
    dplyr::filter(!is.na(sped_num)) %>%
    dplyr::select(county_id, district_id, sped_num)
  joined <- dplyr::inner_join(
    opra[!opra$any_suppressed, ], published, by = c("county_id", "district_id")
  )
  expect_gt(nrow(joined), 400)
  expect_gt(mean(joined$total == joined$sped_num), 0.95)
})

test_that("2025-26 warns that it looks incomplete and returns released values", {
  expect_warning(d <- fetch_sped_by_grade(2026), "incomplete")
  expect_gt(nrow(d), 0)
  expect_silent(fetch_sped_by_grade(2025))
})

test_that("invalid years and tampered bytes stop", {
  expect_error(fetch_sped_by_grade(2021), "not a valid")
  expect_error(fetch_sped_by_grade(2027), "not a valid")
  local_mocked_bindings(.source_digest = function(...) "tampered",
                        .package = "njschooldata")
  expect_error(fetch_sped_by_grade(2025), "SHA-256 mismatch")
})

test_that("source records name the OPRA response", {
  records <- get_source_results(fetch_sped_by_grade(2024))
  expect_identical(records$source_status, "actual")
  expect_identical(records$domain, "sped_by_grade")
  expect_match(records$source_url, "C255254")
})
