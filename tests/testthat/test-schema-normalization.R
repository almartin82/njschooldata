test_that("structural normalization preserves text and refuses unknown fields", {
  input <- data.frame(end_year = 2025L, status_note = "<5",
                      school_year = "2024-25")
  out <- spr_schema_finish(input, "essa_status", 2025)
  expect_identical(out$status_note, "<5")
  expect_identical(out$notes, NA_character_)
  expect_false("school_year" %in% names(out))
  expect_identical(names(out), names(.spr_output_schemas$essa_status))
  input$unknown_measure <- "published"
  expect_error(spr_schema_finish(input, "essa_status", 2025), "Undeclared columns")
})

test_that("trend normalization keeps only the requested year's values", {
  input <- data.frame(end_year = c(2025L, 2025L),
                      school_year = c("2023-24", "2024-2025"),
                      status_note = c("prior", "current"))
  out <- spr_schema_finish(input, "essa_status", 2025)
  expect_identical(out$status_note, "current")
  expect_equal(nrow(out), 1L)
})

test_that("aliases cannot overwrite a different published cell", {
  input <- data.frame(hib = "<5", harassment_intimidation_bullying_hib = "N/A")
  expect_error(spr_rename_published(input, .spr_incident_aliases), "Conflicting")
})

test_that("out-of-field teacher aliases preserve published text bounds", {
  input <- data.frame(
    number_of_out_of_field_teachers_district = "<5",
    percentage_of_out_of_field_teachers_district = "<=5%"
  )
  out <- spr_schema_finish(input, "teacher_experience", 2023)
  expect_identical(out$number_of_out_of_field_teachers, "<5")
  expect_identical(out$percentage_of_out_of_field_teachers, "<=5%")
})

test_that("missing-sheet years fail before source acquisition", {
  for (year in c(2017L, 2018L)) {
    expect_error(fetch_essa_status(year), "not published")
    expect_error(fetch_teacher_experience(year), "not published")
    expect_error(fetch_cte_participation(year), "not published")
  }
  expect_error(fetch_absence(2017, type = "by_grade"), "not published")
  expect_error(fetch_days_absent(2020), "not published")
  for (type in c("chronic", "by_grade", "days_absent")) {
    expect_error(fetch_absence(2020, type = type), "not published")
  }
})

test_that("2017 AP reshape preserves blank entity cells on the state row", {
  input <- data.frame(
    end_year = 2017L,
    county_id = "STATE", district_id = "STATE", school_id = "999",
    county_name = NA_character_, district_name = NA_character_,
    school_name = NA_character_,
    is_state = TRUE,
    is_county = FALSE, is_district = FALSE, is_school = FALSE,
    is_charter = FALSE, is_charter_sector = FALSE, is_allpublic = FALSE,
    report_category = c(
      "StudentsEnrolledInOneOrMoreAPorIBCourse",
      "StudentsTakingInOneOrMoreAPorIBExam",
      "StudentsWithOneOrMoreExamsWithAScoreOfAtLest3AP4IBExams",
      "StudentsEnrolledInOneOrMoreDualEnrollmentCourse"
    ),
    district_percent = NA_character_, state_percent = "published token"
  )
  local_mocked_bindings(fetch_spr_data = function(...) input,
                        .package = "njschooldata")
  out <- fetch_ap_participation(2017, level = "district")
  entity <- c("apib_coursework_school", "apib_exam_school", "ap3_ib4_school",
              "dual_enrollment_school")
  state <- sub("_school$", "_state", entity)
  expect_true(all(is.na(unlist(out[entity]))))
  expect_true(all(unlist(out[state]) == "published token"))
})

test_that("a trend sheet with no row for the requested year stops instead of going empty", {
  input <- data.frame(end_year = 2025L, school_year = "2023-24", status_note = "prior")
  expect_error(spr_schema_finish(input, "essa_status", 2025), "labels were not recognized")
})
