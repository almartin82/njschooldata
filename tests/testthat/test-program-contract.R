test_that("default program calls use complete package releases without network", {
  local_mocked_bindings(
    .default_source_request = function(...) stop("Unexpected network request"),
    .package = "njschooldata"
  )
  crosswalk <- utils::read.csv(system.file(
    "extdata/crosswalk/nj_ccd_state_leaid_2024.csv", package = "njschooldata"
  ), colClasses = "character")
  for (year in 2023:2025) {
    s <- fetch_sped(year)
    d <- s[s$is_district, ]
    source <- sped_classification_source(year)
    raw <- readxl::read_excel(system.file(
      paste0("extdata/program-sources/sped-", year, ".xlsx"), package = "njschooldata"
    ), skip = source$skip, sheet = if (is.na(source$sheet)) 1 else source$sheet,
    col_types = "text")
    raw <- clean_sped_names(raw)
    raw <- raw[grepl("^[0-9]{4}$", raw$district_id) & raw$county_id != "99", ]
    key <- paste(d$county_id, d$district_id)
    expect_false(anyDuplicated(key) > 0)
    expect_setequal(key, paste(raw$county_id, raw$district_id))
    matched <- match(key, paste(raw$county_id, raw$district_id))
    expect_equal(d$n_students, suppressWarnings(as.numeric(raw$sped_num[matched])))
    expect_identical(d$suppressed, .program_suppressed(raw$sped_num[matched]))
    expect_equal(d$n_students, d$sped_num)
    expect_true(all(d$measure == "classification_count"))
    expect_false(any(s$measure == "child_count"))
    expect_true(all(d$age_group == "3_21"))
    expect_true(all(d$subgroup == "total" & d$disability_category == "all_disabilities"))
    expect_true(all(is.na(d$grade_level)))
    expect_equal(sum(s$is_state), 1L)
    expect_false(any(s$is_state & s$is_district))
    expect_true(all(is.na(d$n_students[d$suppressed])))
    expected <- crosswalk$nces_dist[match(paste0("NJ-", d$county_id, d$district_id),
                                         crosswalk$state_leaid)]
    expect_identical(d$nces_dist, expected)
    expect_true(all(is.na(s$nces_dist[s$is_state])))
    if (year < 2025L) {
      with_status <- fetch_sped(year, with_status = TRUE)
      expect_identical(as.character(with_status$value_status[with_status$is_state]), "actual")
    }
  }
  for (year in 2023:2026) {
    e <- fetch_ell(year)
    expect_true(all(e$el_status == "current" & e$subgroup == "total" & e$grade_level == "TOTAL"))
    expect_equal(sum(e$is_state), 1L)
    expect_false(anyDuplicated(e$cds_code) > 0)
    expect_type(e$suppressed, "logical")
    archive <- system.file(paste0("extdata/program-sources/enrollment-", year, ".zip"),
                           package = "njschooldata")
    published <- .parse_modern_ell_archive(archive, year)
    ent <- e[!e$is_state, ]
    i <- match(ent$cds_code, published$entities$cds_code)
    expect_false(anyNA(i))
    expect_equal(ent$n_students, published$entities$el_count[i])
    expect_equal(e$n_students[e$is_state], published$state$el_count)
    expect_identical(ent$suppressed, published$entities$suppressed[i])
    expected <- crosswalk$nces_dist[match(paste0("NJ-", e$county_id, e$district_id),
                                         crosswalk$state_leaid)]
    expect_identical(e$nces_dist, expected)
  }
})

test_that("EL never reconstructs a missing or suppressed statewide total", {
  archive <- system.file("extdata/program-sources/enrollment-2025.zip", package = "njschooldata")
  work <- tempfile("njschooldata-ell-total-")
  dir.create(work)
  on.exit(unlink(work, recursive = TRUE))
  utils::unzip(archive, exdir = work)
  path <- list.files(work, pattern = "xlsx$", full.names = TRUE)[1]
  sheet <- readxl::read_excel(path, sheet = "State", skip = 2, col_types = "text")
  grade <- names(sheet)[grepl("grade", names(sheet), ignore.case = TRUE)][1]
  count <- ell_locate_cols(names(sheet))$count
  total <- tolower(trimws(sheet[[grade]])) == "all grades"
  sheet[[count]][total] <- "*"
  local_mocked_bindings(read_excel = function(...) sheet, .package = "readxl")
  result <- ell_read_modern_state(path, 2025)
  expect_true(result$total_published)
  expect_true(result$suppressed)
  expect_true(is.na(result$el_count))
  sheet <- sheet[!total, ]
  result <- ell_read_modern_state(path, 2025)
  expect_false(result$total_published)
  expect_false(result$suppressed)
  expect_true(is.na(result$el_count))
})

test_that("CCD joins cannot confuse reused district codes or guess missing keys", {
  x <- utils::read.csv(system.file("extdata/crosswalk/nj_ccd_state_leaid_2024.csv",
                                  package = "njschooldata"), colClasses = "character")
  df <- data.frame(county_id = substr(x$state_leaid, 4, 5),
                   district_id = substr(x$state_leaid, 6, 9))
  expect_identical(.attach_program_nces(df)$nces_dist, x$nces_dist)
  # Reusing a real district code under a different county must not inherit
  # the first county's LEAID.
  probe <- df[1, , drop = FALSE]
  probe$county_id <- df$county_id[which(df$county_id != probe$county_id)[1]]
  expect_true(is.na(.attach_program_nces(probe)$nces_dist))
  df$county_id <- NA_character_
  expect_true(all(is.na(.attach_program_nces(df)$nces_dist)))
})
