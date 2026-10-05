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

test_that("cache acquisition identity and time survive reuse truthfully", {
  fixture <- audit_fixture("spr-district-2025.xlsx")
  path <- tempfile(fileext = ".xlsx")
  on.exit(unlink(c(path, paste0(path, ".source.rds"))), add = TRUE)
  requests <- 0L
  request <- function(url, dest, timeout) {
    requests <<- requests + 1L; file.copy(fixture, dest)
    list(status_code = 200L, final_url = url, content_type = "application/octet-stream")
  }
  first <- download_source("https://www.nj.gov/old.xlsx", "xlsx", path, request_fn = request)
  Sys.setFileTime(path, as.POSIXct("2001-01-01", tz = "UTC"))
  warm <- download_source("https://www.nj.gov/old.xlsx", "xlsx", path, request_fn = request)
  expect_identical(warm$retrieved_at, first$retrieved_at)
  changed <- download_source("https://www.nj.gov/new.xlsx", "xlsx", path, request_fn = request)
  expect_identical(changed$source_status, "source_unavailable")
  expect_equal(requests, 1L)
  expect_identical(.source_digest(path), first$digest)
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

test_that("legacy cache and corrupt metadata are preserved without requests", {
  fixture <- audit_fixture("spr-district-2025.xlsx")
  path <- tempfile(fileext = ".xlsx")
  on.exit(unlink(c(path, paste0(path, ".source.rds"))), add = TRUE)
  file.copy(fixture, path)
  digest <- .source_digest(path)
  requests <- 0L
  request <- function(...) { requests <<- requests + 1L; stop("must not request") }
  legacy <- download_source("https://www.nj.gov/old.xlsx", "xlsx", path, request_fn = request)
  expect_identical(legacy$source_status, "source_unavailable")
  expect_null(legacy$retrieved_at)
  writeLines("corrupt metadata", paste0(path, ".source.rds"))
  corrupt <- download_source("https://www.nj.gov/old.xlsx", "xlsx", path, request_fn = request)
  expect_identical(corrupt$source_status, "source_unavailable")
  expect_equal(requests, 0L)
  expect_identical(.source_digest(path), digest)
})

test_that("SPR sheet absence and actual reader failures keep their meaning", {
  env <- new.env(parent = environment(fetch_spr_data))
  fixture <- audit_fixture("spr-district-2025.xlsx")
  env$cache_get <- function(...) NULL
  env$cache_set <- function(...) invisible(NULL)
  env$spr_cached_workbook_result <- function(...) new_source_result(data = fixture, source_status = "actual")
  env$spr_cached_workbook <- function(...) fixture
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
    env$spr_cached_workbook <- function(...) bad
    error <- tryCatch(f("ChronicAbsenteeismStudentGroup", 2025, "district"), error = identity)
    expect_s3_class(error, "error")
    expect_false(grepl("not found.*Available sheets", conditionMessage(error)))
    unlink(bad); unlink(work, recursive = TRUE)
    env$spr_cached_workbook_result <- function(...) new_source_result(data = fixture, source_status = "actual")
    env$spr_cached_workbook <- function(...) fixture
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

test_that("cached bytes, metadata and active acquisition are never silently replaced", {
  path <- tempfile(fileext = ".xlsx")
  unrelated <- tempfile(); writeLines("independent marker", unrelated)
  on.exit(unlink(c(path, paste0(path, ".source.rds"), paste0(path, ".acquiring"), unrelated), recursive = TRUE), add = TRUE)
  fixture <- audit_fixture("spr-district-2025.xlsx")
  request <- function(url, dest, timeout) {
    file.copy(fixture, dest)
    list(status_code = 200L, final_url = url, content_type = "application/octet-stream")
  }
  url <- "https://www.nj.gov/old.xlsx"
  first <- download_source(url, "xlsx", path, request_fn = request)
  expect_identical(first$source_status, "actual")
  metadata <- readRDS(paste0(path, ".source.rds"))
  metadata$digest <- paste(rep("0", 64), collapse = "")
  saveRDS(metadata, paste0(path, ".source.rds"))
  bad <- download_source(url, "xlsx", path, request_fn = function(...) stop("no request"))
  expect_identical(bad$source_status, "parse_error")
  expect_identical(.source_digest(path), first$digest)
  active <- tempfile(fileext = ".xlsx"); dir.create(paste0(active, ".acquiring"))
  on.exit(unlink(paste0(active, ".acquiring"), recursive = TRUE), add = TRUE)
  busy <- download_source(url, "xlsx", active, request_fn = function(...) stop("no request"))
  expect_identical(busy$source_status, "source_unavailable")
  expect_true(dir.exists(paste0(active, ".acquiring")))
  expect_identical(readLines(unrelated), "independent marker")
})

test_that("actual transport outage and invalid workbook propagate through cohorts", {
  env <- new.env(parent = environment(fetch_spr_grad_cohort))
  for (name in c("fetch_spr_grad_cohort", "fetch_spr_data", "spr_cached_workbook_result")) {
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
  expect_error(env$fetch_spr_grad_cohort(2024), class = "njsd_parse_error")
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

test_that("explicit retained adoption preserves unknown acquisition time", {
  path <- tempfile(fileext = ".xlsx")
  on.exit(unlink(c(path, paste0(path, ".source.rds")), recursive = TRUE), add = TRUE)
  file.copy(audit_fixture("spr-district-2025.xlsx"), path)
  url <- "https://www.nj.gov/retained.xlsx"
  digest <- .source_digest(path)
  expect_error(.adopt_source_cache(path, url, "xlsx", "wrong"), "adoption evidence")
  .adopt_source_cache(path, url, "xlsx", digest)
  result <- download_source(url, "xlsx", path, request_fn = function(...) stop("no request"))
  expect_identical(result$source_status, "actual")
  expect_null(result$retrieved_at)
  expect_identical(result$digest, digest)
})

test_that("explicit scoped workbook clear removes paired metadata and keeps active inputs", {
  root <- tempfile("nj-clear-"); dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  prior <- options(njschooldata.cache_dir = root)
  on.exit(options(prior), add = TRUE)
  directory <- njsd_workbook_cache_dir(); dir.create(directory)
  old <- file.path(directory, "SPR_district_2020.xlsx")
  active <- file.path(directory, "SPR_school_2020.xlsx")
  unrelated <- file.path(directory, "SPR_district_2021.xlsx")
  for (p in c(old, active, unrelated)) {
    file.copy(audit_fixture("spr-district-2025.xlsx"), p)
    writeLines("paired metadata diagnostic", paste0(p, ".source.rds"))
  }
  dir.create(paste0(active, ".acquiring"))
  expect_equal(njsd_workbook_cache_clear(2020), 1L)
  expect_false(file.exists(old)); expect_false(file.exists(paste0(old, ".source.rds")))
  expect_true(file.exists(active)); expect_true(file.exists(paste0(active, ".source.rds")))
  expect_true(file.exists(unrelated)); expect_true(file.exists(paste0(unrelated, ".source.rds")))
})

test_that("nonfinite acquisition clocks are refused without replacement or requests", {
  path <- tempfile(fileext = ".xlsx")
  metadata_path <- paste0(path, ".source.rds")
  on.exit(unlink(c(path, metadata_path)), add = TRUE)
  file.copy(audit_fixture("spr-district-2025.xlsx"), path)
  digest <- .source_digest(path)
  url <- "https://www.nj.gov/retained.xlsx"
  requests <- 0L
  request <- function(...) { requests <<- requests + 1L; stop("must not request") }
  for (value in c(Inf, -Inf)) {
    clock <- as.POSIXct(value, origin = "1970-01-01", tz = "UTC")
    expect_error(.adopt_source_cache(path, url, "xlsx", digest, retrieved_at = clock),
                 "Acquisition time")
    expect_false(file.exists(metadata_path))
    metadata <- list(version = 1L, requested_url = url, final_url = url,
                     source_type = "xlsx", retrieved_at = clock, clock = "recorded",
                     size = as.numeric(file.info(path)$size), digest = digest)
    saveRDS(metadata, metadata_path)
    sidecar_digest <- .source_digest(metadata_path)
    result <- download_source(url, "xlsx", path, request_fn = request)
    expect_identical(result$source_status, "source_unavailable")
    expect_null(result$retrieved_at)
    expect_equal(requests, 0L)
    expect_identical(.source_digest(path), digest)
    expect_identical(.source_digest(metadata_path), sidecar_digest)
    unlink(metadata_path) # Only this test's owned invalid sidecar.
  }
  finite <- as.POSIXct("2026-07-20", tz = "UTC")
  .adopt_source_cache(path, url, "xlsx", digest, retrieved_at = finite)
  result <- download_source(url, "xlsx", path, request_fn = request)
  expect_identical(result$source_status, "actual")
  expect_identical(result$retrieved_at, finite)
  finite_sidecar_digest <- .source_digest(metadata_path)
  for (value in c(Inf, -Inf)) {
    expect_error(.adopt_source_cache(path, url, "xlsx", digest,
                   retrieved_at = as.POSIXct(value, origin = "1970-01-01", tz = "UTC")),
                 "Acquisition time")
    expect_identical(.source_digest(metadata_path), finite_sidecar_digest)
    expect_identical(.source_digest(path), digest)
  }
  .adopt_source_cache(path, url, "xlsx", digest, retrieved_at = NULL)
  unknown <- download_source(url, "xlsx", path, request_fn = request)
  expect_identical(unknown$source_status, "actual")
  expect_null(unknown$retrieved_at)
  expect_equal(requests, 0L)
})
