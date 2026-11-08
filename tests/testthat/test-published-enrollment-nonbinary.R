test_that("enrollment keeps the published statewide Non-Binary count and rate", {
  codes <- c("PH", "PF", "KH", "KF", sprintf("%02d", 1:12), "55")
  withr::local_options(njschooldata.cache_dir = withr::local_tempdir())

  for (year in 2023:2026) {
    archive <- system.file(
      sprintf("extdata/program-sources/enrollment-%d.zip", year), package = "njschooldata"
    )
    workbook <- unzip(archive, exdir = withr::local_tempdir())
    raw <- readxl::read_excel(workbook, sheet = "State", skip = 2)
    raw <- raw[!is.na(raw$Total), ]
    source_codes <- ifelse(raw$Grade == "Ungraded", "UG", codes[match(
      raw$Grade,
      c("Pre-K Halfday", "Pre-K Fullday", "Kindergarten Halfday", "Kindergarten Fullday",
        "First Grade", "Second Grade", "Third Grade", "Fourth Grade", "Fifth Grade",
        "Sixth Grade", "Seventh Grade", "Eight Grade", "Ninth Grade", "Tenth Grade",
        "Eleventh Grade", "Twelfth Grade", "All Grades")
    )])
    actual <- fetch_enr(year, tidy = TRUE, use_cache = FALSE)
    subgroup <- actual[actual$subgroup == "non_binary", ]
    totals <- actual[actual$is_state & actual$subgroup == "total_enrollment", ]
    expect_equal(nrow(subgroup), nrow(raw))
    expect_setequal(subgroup$program_code, source_codes)
    expect_true(all(subgroup$is_state))
    ordered <- subgroup[match(source_codes, subgroup$program_code), ]
    if (year == 2024) {
      # NJ DOE printed 0 in every statewide Non-Binary cell of the 2023-24
      # file (675 in 2023, 633 in 2025): a category not collected that year,
      # served as not reported rather than as zero students.
      expect_true(all(as.numeric(raw[["Non-Binary"]]) == 0))
      expect_true(all(as.numeric(raw[["% Non-Binary"]]) == 0))
      expect_true(all(subgroup$value_source == "not_reported"))
      expect_true(all(is.na(ordered$n_students)))
      expect_true(all(is.na(ordered$pct)))
      expect_true(all(is.na(ordered$published_pct)))
      wide <- fetch_enr(year, tidy = FALSE, use_cache = FALSE)
      wide_state <- wide[wide$cds_code == "999999999", ]
      expect_true(all(is.na(wide_state$non_binary)))
      expect_true(all(is.na(wide_state$non_binary_published_pct)))
      expect_true(all(wide_state$non_binary_value_source == "not_reported"))
    } else {
      expect_true(all(subgroup$value_source == "published"))
      expect_true(sum(ordered$n_students) > 0)
      expect_equal(ordered$n_students, raw[["Non-Binary"]])
      expect_equal(ordered$published_pct, raw[["% Non-Binary"]] / 100)
      expect_equal(ordered$pct, raw[["Non-Binary"]] / raw$Total)
    }
    expect_equal(totals$n_students[match(source_codes, totals$program_code)], raw$Total)
  }
})

test_that("a masked statewide Non-Binary count stays missing and its published rate is independent", {
  archive <- system.file("extdata/program-sources/enrollment-2025.zip", package = "njschooldata")
  read_publisher <- readxl::read_excel
  testthat::local_mocked_bindings(read_excel = function(path, sheet, ...) {
    data <- read_publisher(path, sheet = sheet, ...)
    if (sheet == "State") {
      data[["Non-Binary"]][1:2] <- "*"
      data[["% Non-Binary"]][2] <- ">95"
    }
    data
  }, .package = "readxl")

  raw <- njschooldata:::.parse_enr_archive(archive, 2025)
  tidy <- tidy_enr(njschooldata:::process_enr(raw))
  subgroup <- tidy[tidy$subgroup == "non_binary" & tidy$program_code %in% c("PH", "PF"), ]
  expect_equal(nrow(subgroup), 2L)
  expect_true(all(subgroup$cds_code == "999999999"))
  expect_true(all(is.na(subgroup$n_students)))
  expect_true(all(is.na(subgroup$pct)))
  expect_equal(subgroup$published_pct[match(c("PH", "PF"), subgroup$program_code)], c(0, NA_real_))
  pk <- enr_grade_aggs(id_enr_aggs(tidy))
  pk <- pk[pk$is_state & pk$grade_level == "PK (Any)" & pk$subgroup == "non_binary", ]
  expect_equal(nrow(pk), 1L)
  expect_true(is.na(pk$n_students))
})

test_that("the 2024 not-reported rule is narrow: a real nonzero 2024 cell stays published", {
  archive <- system.file("extdata/program-sources/enrollment-2024.zip", package = "njschooldata")
  read_publisher <- readxl::read_excel
  testthat::local_mocked_bindings(read_excel = function(path, sheet, ...) {
    data <- read_publisher(path, sheet = sheet, ...)
    # One nonzero published cell means NJ DOE did collect the category.
    if (sheet == "State") data[["Non-Binary"]][1] <- 3
    data
  }, .package = "readxl")

  raw <- njschooldata:::.parse_enr_archive(archive, 2024)
  tidy <- tidy_enr(njschooldata:::process_enr(raw))
  subgroup <- tidy[tidy$subgroup == "non_binary", ]
  expect_true(nrow(subgroup) > 0)
  expect_true(all(subgroup$value_source == "published"))
  expect_equal(subgroup$n_students[subgroup$program_code == "PH"], 3)
  expect_true(all(subgroup$n_students[subgroup$program_code != "PH"] == 0))
})
