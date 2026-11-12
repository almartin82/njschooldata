# Offline: fetch_spr_enrollment_by_group() turns each of NJDOE's layouts of
# EnrollmentTrendsByStudentGroup into one long shape, moving no value.

ebg_frame <- function(...) {
  ids <- data.frame(
    county_id = c("01", "01"), county_name = "Atlantic",
    district_id = c("0110", "0110"), district_name = "Absecon",
    school_id = c("050", "060"), school_name = c("A", "B"),
    stringsAsFactors = FALSE
  )
  flags <- data.frame(is_state = FALSE, is_county = FALSE, is_district = FALSE,
                      is_school = TRUE, is_charter = FALSE,
                      is_charter_sector = FALSE, is_allpublic = FALSE)
  cbind(ids, data.frame(..., stringsAsFactors = FALSE, check.names = FALSE), flags)
}

with_sheet <- function(sheet, code) {
  testthat::local_mocked_bindings(
    fetch_spr_data = function(sheet_name, end_year, level = "school",
                              clean_subgroups = TRUE) {
      sheet$end_year <- as.integer(end_year)
      sheet
    }
  )
  code
}

test_that("wide numeric, wide text, long and trend layouts give one schema", {
  wide_numeric <- ebg_frame(female = c(48.7, 50), economically_disadvantaged_students = c(42.4, 5),
                            english_learners = c(2.4, NA))
  wide_text <- ebg_frame(female = c("20-30%", "51"), economically_disadvantaged_students = c(39.1, 0),
                         multilingual_learners = c(8.9, 6.2),
                         non_binary_undesignated_gender = c("≤1%", NA))
  trend <- rbind(
    ebg_frame(school_year = "2023-24", female = "40%", economically_disadvantaged_students = "1.0%"),
    ebg_frame(school_year = "2024-25", female = "<=10%", economically_disadvantaged_students = "39.1%")
  )
  long <- ebg_frame(subgroup = c("econdis", "lep"), percent = c("42.7", "*"))
  long <- rbind(long, transform(long, subgroup = c("female", "disability"), percent = c("50.2", "17.5")))

  out <- list(
    with_sheet(wide_numeric, fetch_spr_enrollment_by_group(2019)),
    with_sheet(wide_text, fetch_spr_enrollment_by_group(2024)),
    with_sheet(trend, fetch_spr_enrollment_by_group(2025)),
    with_sheet(long, fetch_spr_enrollment_by_group(2017))
  )
  schemas <- lapply(out, sc_schema)
  for (s in schemas[-1]) expect_identical(s, schemas[[1]])
  expect_identical(names(out[[1]]), .spr_ebg_columns)

  a <- out[[1]]
  expect_identical(a$pct_published[a$school_id == "060" & a$subgroup == "economically disadvantaged"], "5")
  expect_identical(a$pct[a$school_id == "050" & a$subgroup == "female"], 48.7)
  expect_true(is.na(a$pct_published[a$school_id == "060" & a$subgroup == "limited english proficiency"]))

  b <- out[[2]]
  range_row <- b$school_id == "050" & b$subgroup == "female"
  expect_identical(b$pct_published[range_row], "20-30%")
  expect_true(is.na(b$pct[range_row]))
  expect_true(is.na(b$pct[b$subgroup == "non-binary/undesignated gender" & b$school_id == "050"]))
  expect_identical(sort(unique(b$subgroup)),
                   sort(c("female", "economically disadvantaged",
                          "limited english proficiency", "non-binary/undesignated gender")))

  c25 <- out[[3]]
  expect_identical(nrow(c25), 4L)  # 2023-24 rows in the 2024-25 sheet are dropped
  expect_identical(c25$pct[c25$subgroup == "economically disadvantaged"], c(39.1, 39.1))
  expect_true(all(is.na(c25$pct[c25$subgroup == "female"])))
  expect_identical(unique(c25$pct_published[c25$subgroup == "female"]), "<=10%")

  d <- out[[4]]
  expect_setequal(d$subgroup, c("economically disadvantaged", "limited english proficiency",
                                "female", "students with disabilities"))
  expect_true(is.na(d$pct[d$subgroup == "limited english proficiency"]))
  expect_identical(d$pct[d$subgroup == "economically disadvantaged"], 42.7)
  expect_identical(d$pct_published[d$subgroup == "limited english proficiency"], "*")
})

test_that("an unknown student group stops instead of disappearing", {
  sheet <- ebg_frame(female = c(50, 50), brand_new_group = c(1, 2))
  expect_error(with_sheet(sheet, fetch_spr_enrollment_by_group(2022)),
               "does not know: brand_new_group")
})

test_that("years outside the SPR range are refused", {
  expect_error(fetch_spr_enrollment_by_group(2016), "end_year must be one of")
  expect_error(fetch_spr_enrollment_by_group(c(2018, 2019)), "end_year must be one of")
})
