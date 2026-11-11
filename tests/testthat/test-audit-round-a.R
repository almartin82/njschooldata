# Real source-derived subsets exercise values; diagnostic inputs only test flow.
audit_fixture <- function(name) source_adapter_fixture(name)

test_that("published school PK cells survive LF headers through tidy output", {
  archive <- audit_fixture("enrollment-2020.zip")
  work <- tempfile("nj-pk-oracle-"); dir.create(work)
  on.exit(unlink(work, recursive = TRUE), add = TRUE)
  book <- utils::unzip(archive, exdir = work)[1]
  sheet <- readxl::read_excel(book, sheet = "School", skip = 2)
  header <- grep("Pre-K.*Full day", names(sheet), value = TRUE)
  expect_length(header, 1L)
  expect_true(grepl("\n", header, fixed = TRUE))
  expected <- sheet[[header]]
  expect_equal(sort(expected), c(0, 155))
  raw <- .parse_enr_archive(archive, 2020)
  wide <- process_enr(raw)
  tidy <- suppressWarnings(tidy_enr(wide))
  for (i in seq_len(nrow(sheet))) {
    id <- paste0(sheet[["County Code"]][i], sheet[["District Code"]][i], sheet[["School Code"]][i])
    r <- raw[which(paste0(raw[["County Code"]], raw[["District Code"]], raw[["School Code"]]) == id & raw$Grade == "Pre-K Fullday"), ]
    expect_equal(r[["Total Enrollment"]], expected[i])
    w <- wide[which(wide$cds_code == id & wide$grade_level == "PK" & wide$program_code == "PF"), ]
    expect_equal(w$row_total, expected[i])
    t <- tidy[which(tidy$cds_code == id & tidy$grade_level == "PK" & tidy$program_code == "PF" & tidy$subgroup == "total_enrollment"), ]
    expect_equal(t$n_students, expected[i])
  }
})

test_that("cohort fetching propagates failures in each required cohort", {
  env <- new.env(parent = environment(fetch_spr_grad_cohort))
  f <- fetch_spr_grad_cohort; environment(f) <- env
  for (required in c("4YrGraduationCohortProfile", "5YrGraduationCohortProfile", "6YrGraduationCohortProfile")) {
  env$fetch_spr_data <- function(sheet_name, end_year, level) {
    if (sheet_name == required) stop("diagnostic workbook parser failure")
    # A diagnostic NA row tests flow without inventing NJ numeric values.
    data.frame(end_year = end_year, county_id = NA_character_, county_name = NA_character_, district_id = NA_character_, district_name = NA_character_, school_id = NA_character_, school_name = NA_character_, subgroup = NA_character_, graduates = NA_real_, continuing_students = NA_real_, non_continuing_student = NA_real_, is_state = FALSE, is_county = FALSE, is_district = FALSE, is_school = TRUE, is_charter = NA, is_charter_sector = FALSE, is_allpublic = FALSE)
  }
  expect_error(f(2024), "diagnostic workbook parser failure")
  }
})

test_that("fresh acquisition identity and time do not inherit a legacy file clock", {
  fixture <- audit_fixture("spr-district-2025.xlsx")
  request <- function(url, dest, timeout) {
    file.copy(fixture, dest)
    list(status_code = 200L, final_url = url, content_type = "application/octet-stream")
  }
  before <- Sys.time()
  first <- download_source("https://www.nj.gov/old.xlsx", "xlsx", request_fn = request)
  Sys.setFileTime(first$data, as.POSIXct("2001-01-01", tz = "UTC"))
  changed <- download_source("https://www.nj.gov/new.xlsx", "xlsx", request_fn = request)
  withr::defer({.release_source_result(first); .release_source_result(changed)})
  expect_gte(as.numeric(changed$retrieved_at), as.numeric(before))
  expect_identical(changed$source_url, "https://www.nj.gov/new.xlsx")
  expect_identical(.source_digest(changed$data), first$digest)
  expect_false(identical(first$data, changed$data))
})

test_that("observed aliases normalize exactly and collisions fail loudly", {
  for (alias in c("Pre-K\r\n Full day", "Pre-K\n Full day", "Pre-K FullDay")) {
    df <- setNames(data.frame(value = NA_real_), alias)
    expect_identical(names(.normalize_enr_headers(df)), "Pre-K Fullday")
  }
  unknown <- setNames(data.frame(value = NA_real_), "Unobserved PK label")
  expect_identical(.normalize_enr_headers(unknown), unknown)
  conflicting <- setNames(data.frame(a = NA_real_, b = NaN), c("Pre-K\n Full day", "Pre-K Fullday"))
  expect_error(.normalize_enr_headers(conflicting), "unique|duplicated", ignore.case = TRUE)
})

test_that("a corrupt fresh workbook is rejected before parsing and removed", {
  path <- NULL
  request <- function(url, dest, timeout) {
    path <<- dest
    writeLines("<html>publisher error</html>", dest)
    list(status_code = 200L, final_url = url, content_type = "text/html")
  }
  result <- download_source("https://www.nj.gov/old.xlsx", "xlsx", request_fn = request)
  expect_identical(result$source_status, "source_unavailable")
  expect_match(result$error, "HTML")
  expect_false(file.exists(path))
})

test_that("SPR sheet absence and actual reader failures keep their meaning", {
  env <- new.env(parent = environment(fetch_spr_data))
  fixture <- audit_fixture("spr-district-2025.xlsx")
  env$cache_get <- function(...) NULL
  env$cache_set <- function(...) invisible(NULL)
  env$spr_cached_workbook_result <- function(...) new_source_result(data = fixture, source_status = "actual")
  for (original in list(fetch_spr_data, fetch_spr_sheet_raw)) {
    f <- original; environment(f) <- env
    expect_error(f("not-a-published-sheet", 2025, "district"), "not found.*Available sheets")
    # Sheet inventory still succeeds, but its member is missing: an actual
    # read failure must not be relabeled as an unpublished sheet.
    work <- tempfile("nj-reader-error-"); dir.create(work)
    members <- utils::unzip(fixture, exdir = work)
    missing <- file.path(work, "xl", "worksheets", "sheet1.xml")
    unlink(missing)
    bad <- tempfile(fileext = ".xlsx")
    zip::zipr(bad, list.files(work, recursive = TRUE, all.files = TRUE), root = work, mode = "mirror")
    expect_true("ChronicAbsenteeismStudentGroup" %in% readxl::excel_sheets(bad))
    env$spr_cached_workbook_result <- function(...) new_source_result(data = bad, source_status = "actual")
    error <- tryCatch(f("ChronicAbsenteeismStudentGroup", 2025, "district"), error = identity)
    expect_s3_class(error, "error")
    expect_false(grepl("not found.*Available sheets", conditionMessage(error)))
    unlink(bad); unlink(work, recursive = TRUE)
    env$spr_cached_workbook_result <- function(...) new_source_result(data = fixture, source_status = "actual")
  }
})

test_that("2020 cohorts select exactly the documented four/five-year inputs", {
  env <- new.env(parent = environment(fetch_spr_grad_cohort))
  f <- fetch_spr_grad_cohort; environment(f) <- env
  requested <- character()
  env$fetch_spr_data <- function(sheet_name, end_year, level) {
    requested <<- c(requested, sheet_name)
    data.frame(end_year=end_year, county_id=NA_character_,county_name=NA_character_,district_id=NA_character_,district_name=NA_character_,school_id=NA_character_,school_name=NA_character_,subgroup=NA_character_,graduates=NA_real_,continuing_students=NA_real_,non_continuing_student=NA_real_,is_state=FALSE,is_county=FALSE,is_district=FALSE,is_school=TRUE,is_charter=NA,is_charter_sector=FALSE,is_allpublic=FALSE)
  }
  out <- f(2020)
  expect_identical(requested, c("4YrGraduationCohortProfile", "5YrGraduationCohortProfile"))
  expect_identical(out$cohort_type, c("4-Year", "5-Year"))
})

test_that("an invalid redirect removes its payload without touching independent files", {
  unrelated <- withr::local_tempfile()
  writeLines("independent marker", unrelated)
  path <- NULL
  request <- function(url, dest, timeout) {
    path <<- dest
    file.copy(audit_fixture("spr-district-2025.xlsx"), dest)
    list(status_code = 200L, final_url = "https://example.org/file.xlsx")
  }
  result <- download_source("https://www.nj.gov/file.xlsx", "xlsx", request_fn = request)
  expect_identical(result$source_status, "source_unavailable")
  expect_match(result$error, "redirect")
  expect_false(file.exists(path))
  expect_identical(readLines(unrelated), "independent marker")
})

test_that("actual transport outage and invalid workbook propagate through cohorts", {
  env <- new.env(parent = environment(fetch_spr_grad_cohort))
  for (name in c("fetch_spr_grad_cohort", "fetch_spr_data", "spr_cached_workbook_result",
                  "njsd_workbook_cache_on")) {
    f <- get(name, envir = env); environment(f) <- env; assign(name, f, envir = env)
  }
  env$cache_get <- function(...) NULL
  env$njsd_cache_enabled <- function() FALSE
  calls <- 0L
  env$.default_source_request <- function(url, dest, timeout) {
    calls <<- calls + 1L
    list(status_code = 404L, final_url = url)
  }
  expect_error(env$fetch_spr_grad_cohort(2024), class = "njsd_source_unavailable")
  expect_equal(calls, 1L)
  env$.default_source_request <- function(url, dest, timeout) {
    writeLines("malformed retained workbook diagnostic", dest)
    list(status_code = 200L, final_url = url, content_type = "application/octet-stream")
  }
  # M4 (Q4): bytes that fail the XLSX byte check are a source failure, not our
  # parser's (they were njsd_parse_error).
  caught <- tryCatch(env$fetch_spr_grad_cohort(2024), error = identity)
  expect_identical(class(caught)[[1]], "njsd_source_unavailable")
  expect_match(conditionMessage(caught), "no ZIP signature")
})

test_that("installed public enrollment paths retain PK values and exact keys", {
  fixture <- audit_fixture("enrollment-2020.zip")
  local_mocked_bindings(.default_source_request = function(url, dest, timeout) {
    file.copy(fixture, dest)
    list(status_code = 200L, final_url = url, content_type = "application/zip")
  }, .package = "njschooldata")
  uncached <- suppressWarnings(fetch_enr(2020, tidy = TRUE, use_cache = FALSE))
  cached <- suppressWarnings(fetch_enr_cached(2020, tidy = TRUE))
  expect_equal(cached, uncached, ignore_attr = TRUE)
  expect_identical(get_source_results(cached)$digest, get_source_results(uncached)$digest)
  expect_identical(get_source_results(cached)$source_url, get_source_results(uncached)$source_url)
  raw <- .parse_enr_archive(fixture, 2020)
  wide <- process_enr(raw)
  linked <- attach_nces_ids(wide)
  expect_identical(linked$county_id, wide$county_id)
  expect_identical(linked$district_id, wide$district_id)
  expect_identical(linked$school_id, wide$school_id)
  expected <- suppressWarnings(id_enr_aggs(tidy_enr(linked)))
  # Source/provenance attributes differ by fresh acquisition; compare values.
  expect_equal(as.data.frame(uncached), as.data.frame(expected), ignore_attr = TRUE)
  for (id in unique(expected$cds_code)) {
    actual_id <- uncached[uncached$cds_code == id, intersect(c("nces_dist", "nces_sch"), names(uncached)), drop = FALSE]
    reference_id <- expected[expected$cds_code == id, names(actual_id), drop = FALSE]
    expect_equal(actual_id, reference_id)
  }
  expect_false(any(uncached$cds_code == "313970999" & uncached$subgroup == "free_lunch"))
})

test_that("enrollment raw paths share only the current session lifetime", {
  path <- .enr_raw_cache_path(2020, "diagnostic-digest")
  expect_identical(dirname(path), file.path(tempdir(), "njschooldata-enrollment-sources"))
  expect_false(startsWith(path, njsd_cache_root()))
})

test_that("scoped legacy clear removes only the selected year's workbooks and sidecars", {
  root <- withr::local_tempdir()
  withr::local_options(njschooldata.cache_dir = root)
  directory <- njsd_workbook_cache_dir(); dir.create(directory)
  selected <- file.path(directory, "SPR_source-v1_school_2020_urlhash.xlsx")
  other <- file.path(directory, "SPR_school_2021.xlsx")
  for (p in c(selected, other)) {
    file.copy(audit_fixture("spr-district-2025.xlsx"), p)
    writeLines("legacy metadata", paste0(p, ".source.rds"))
  }
  expect_equal(njsd_workbook_cache_clear(2020), 1L)
  expect_false(file.exists(selected))
  expect_false(file.exists(paste0(selected, ".source.rds")))
  expect_true(file.exists(other))
  expect_true(file.exists(paste0(other, ".source.rds")))
})

test_that("successful live provenance uses the acquisition clock and verified bytes", {
  started <- Sys.time()
  request <- function(url, dest, timeout) {
    file.copy(audit_fixture("spr-district-2025.xlsx"), dest)
    list(status_code = 200L, final_url = url, content_type = "application/octet-stream")
  }
  result <- download_source("https://www.nj.gov/file.xlsx", "xlsx", request_fn = request)
  withr::defer(.release_source_result(result))
  expect_true(is.finite(as.numeric(result$retrieved_at)))
  expect_gte(as.numeric(result$retrieved_at), as.numeric(started))
  expect_lte(as.numeric(result$retrieved_at), as.numeric(Sys.time()))
  expect_identical(result$digest, .source_digest(result$data))
  expect_false(file.exists(paste0(result$data, ".source.rds")))
})
