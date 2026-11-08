test_that("public enrollment fetch keeps each modern published program cell at its workbook grain", {
  programs <- c(free_lunch = "Free Lunch", reduced_lunch = "Reduced Lunch",
                lep = "Multilingual Learners", migrant = "Migrant",
                military = "Military", homeless = "Homeless")
  source_urls <- c(
    "https://www.nj.gov/education/doedata/enr/enr23/enrollment_2223.zip",
    "https://www.nj.gov/education/doedata/enr/enr24/enrollment_2324.zip",
    "https://www.nj.gov/education/doedata/enr/enr25/enrollment_2425.zip",
    "https://www.nj.gov/education/doedata/enr/enr26/Enrollment_2526.zip"
  )
  state_program_codes <- c("PH", "PF", "KH", "KF", sprintf("%02d", 1:12), "55")
  withr::local_options(njschooldata.cache_dir = withr::local_tempdir())

  for (year in 2023:2026) {
    archive <- system.file(
      sprintf("extdata/program-sources/enrollment-%d.zip", year), package = "njschooldata"
    )
    workbook <- unzip(archive, exdir = withr::local_tempdir())
    actual <- fetch_enr(year, tidy = TRUE, use_cache = FALSE)
    expect_identical(attr(actual, "source_url"), source_urls[[year - 2022L]])
    expect_identical(attr(actual, "raw_sha256"), digest::digest(archive, file = TRUE, algo = "sha256"))

    for (sheet in c("State", "District", "School")) {
      raw <- readxl::read_excel(workbook, sheet = sheet, skip = 2)
      names(raw) <- gsub("_", " ", trimws(names(raw)), fixed = TRUE)
      names(raw) <- sub("^% +", "%", names(raw))
      names(raw) <- sub("English Learners$", "Multilingual Learners", names(raw))
      if (sheet == "State") {
        raw <- raw[!is.na(raw$Total), ]
        codes <- if (year == 2023) append(state_program_codes, "UG", after = 16L) else state_program_codes
        raw_key <- paste("999999999", codes)
        expect_equal(nrow(raw), length(codes))
      } else {
        raw <- raw[grepl("^[0-9]+$", raw[["County Code"]]), ]
        school <- if (sheet == "District") 999L else as.integer(raw[["School Code"]])
        raw_key <- paste(sprintf("%02d%04d%03d", as.integer(raw[["County Code"]]),
                                 as.integer(raw[["District Code"]]), school), "55")
      }

      for (group in names(programs)) {
        matched <- actual[actual$subgroup == group &
                            paste(actual$cds_code, actual$program_code) %in% raw_key, ]
        expect_setequal(paste(matched$cds_code, matched$program_code), raw_key)
        expect_equal(nrow(matched), nrow(raw))
        ordered <- matched[match(raw_key, paste(matched$cds_code, matched$program_code)), ]
        expect_equal(ordered$n_students, raw[[programs[[group]]]])
        expect_equal(ordered$published_pct, raw[[paste0("%", programs[[group]])]] / 100)
        expect_true(all(ordered$value_source == "published"))
      }
    }
    district_grade_programs <- actual[actual$is_district & actual$is_subprogram &
                                        actual$subgroup %in% names(programs), ]
    school_grade_programs <- actual[actual$is_school & actual$is_subprogram &
                                      actual$subgroup %in% names(programs), ]
    expect_equal(nrow(district_grade_programs), 0L)
    expect_equal(nrow(school_grade_programs), 0L)
    # The worksheets' "End of worksheet" footer rows publish no program cell.
    expect_false(any(grepl("End of worksheet", actual$cds_code, fixed = TRUE)))
  }
})

test_that("a modern masked program count or rate stays missing", {
  archive <- system.file("extdata/program-sources/enrollment-2025.zip", package = "njschooldata")
  read_publisher <- readxl::read_excel
  testthat::local_mocked_bindings(read_excel = function(path, sheet, ...) {
    raw <- read_publisher(path, sheet = sheet, ...)
    if (sheet == "State") {
      raw[["Free Lunch"]][1] <- "*"
      raw[["% Reduced_Lunch"]][1] <- ">95"
      raw[["Military"]][1] <- "*"
      raw[["% Military"]][1] <- ">95"
    }
    raw
  }, .package = "readxl")

  raw <- njschooldata:::.parse_enr_archive(archive, 2025)
  tidy <- tidy_enr(process_enr(raw))
  first_grade <- tidy[tidy$cds_code == "999999999" & tidy$program_code == "PH", ]
  free <- first_grade[first_grade$subgroup == "free_lunch", ]
  reduced <- first_grade[first_grade$subgroup == "reduced_lunch", ]
  military <- first_grade[first_grade$subgroup == "military", ]
  frl <- first_grade[first_grade$subgroup == "free_reduced_lunch", ]

  expect_equal(nrow(free), 1L)
  expect_true(is.na(free$n_students))
  expect_true(is.na(free$pct))
  expect_equal(free$published_pct, 0.126)
  expect_equal(nrow(reduced), 1L)
  expect_equal(reduced$n_students, 131)
  expect_true(is.na(reduced$published_pct))
  expect_equal(nrow(military), 1L)
  expect_true(is.na(military$n_students))
  expect_true(is.na(military$published_pct))
  expect_equal(nrow(frl), 1L)
  expect_true(is.na(frl$n_students))

  pk <- enr_grade_aggs(id_enr_aggs(tidy))
  pk <- pk[pk$is_state & pk$grade_level == "PK (Any)" &
             pk$subgroup %in% c("free_lunch", "military", "free_reduced_lunch"), ]
  expect_equal(nrow(pk), 3L)
  expect_true(all(is.na(pk$n_students)))
})
