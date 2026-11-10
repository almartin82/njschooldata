test_that("2026 assessment URLs and the all-results grid match the release", {
  local_nj_offline_transport()
  base <- "https://www.nj.gov/education/assessment/results/reports/2526/"
  requests <- .parcc_request_grid()
  requests <- requests[requests$end_year == 2026, ]
  expect_equal(nrow(requests), 19L)
  expect_setequal(as.integer(requests$grade[requests$subject == "ela"]), 3:9)
  for (i in seq_len(nrow(requests))) {
    grade <- requests$grade[i]
    token <- if (grade %in% c("ALG1", "GEO", "ALG2")) {
      switch(grade, ALG1 = "ALG01", GEO = "GEO01", ALG2 = "ALG02")
    } else {
      paste0(switch(requests$subject[i], ela = "ELA", math = "MAT", science = "SC"),
             sprintf("%02d", as.integer(grade)))
    }
    expect_identical(
      resolve_source_url("parcc", 2026,
                         grade = if (grepl("^[0-9]+$", grade)) as.integer(grade) else grade,
                         subject = requests$subject[i]),
      paste0(base, "njsla/", token, "_NJSLA_DATA_2025_26.xlsx")
    )
  }
  expect_identical(get_source_years("njgpa"), 2022:2026)
  expect_identical(get_source_years("parcc", "raw"), c(2015:2019, 2022:2026))
  for (subject in c("ela", "math")) {
    expect_identical(resolve_source_url("njgpa", 2026, subject = subject),
                     paste0(base, "njgpa/", if (subject == "ela") "ELA" else "MAT",
                            "GP_NJGPA_DATA_2025_26.xlsx"))
  }
})

test_that("2026 fetchers preserve real source cells, levels, suppression and final rows", {
  local_nj_offline_transport()
  tokens <- c("MAT04", "ALG01", "ELA03", "ELAGP", "MATGP", "SC05")
  means <- c(1417, 2544, 1438, 451, 431, 161)
  valid <- c(78, 36, 84, 363, 357, 80)
  l2 <- c(17.9, 0, 23.8, 56.2, 33.9, 55)
  levels <- c(5L, 5L, 5L, 2L, 2L, 4L)
  for (i in seq_along(tokens)) {
    token <- tokens[i]
    gp <- grepl("GP$", token)
    file <- paste0(token, if (gp) "_NJGPA" else "_NJSLA", "_DATA_2025_26.xlsx")
    fixture <- test_path("fixtures", "assessment-2026", file)
    expected_url <- paste0("https://www.nj.gov/education/assessment/results/reports/2526/",
                           if (gp) "njgpa/" else "njsla/", file)
    request <- function(url, dest, timeout) {
      expect_identical(url, expected_url)
      file.copy(fixture, dest, overwrite = TRUE)
      list(status_code = 200L, final_url = url,
           content_type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
    }
    local_mocked_bindings(.default_source_request = request, .package = "njschooldata")
    subject <- if (grepl("^ELA", token)) "ela" else if (token == "SC05") "science" else "math"
    grade <- switch(token, MAT04 = 4, ALG01 = "ALG1", ELA03 = 3, SC05 = 5, "GP")
    raw <- .parse_assessment_workbook(fixture, if (gp) 3L else 2L)
    expect_equal(ncol(raw), 12L + levels[i])
    # Historical column-order warnings about optional aggregate columns are unrelated.
    out <- suppressWarnings(if (gp) fetch_njgpa(2026, subject, tidy = TRUE) else
      fetch_parcc(2026, grade, subject, tidy = TRUE))
    expect_equal(nrow(out), 5L)
    expect_equal(sum(out$is_state), 2L)
    expect_equal(sum(out$is_district), 1L)
    expect_equal(sum(out$is_school), 2L)
    expect_identical(get_source_results(out)$source_url, expected_url)
    school <- out[out$is_school & out$subgroup == "total_population", ]
    expect_equal(nrow(school), 1L)
    expect_identical(school$district_id, if (gp) "0110" else "0010")
    expect_identical(school$school_name, if (gp) "Atlantic City High School" else
      if (token %in% c("ALG01", "SC05")) "Emma C Attales" else "H Ashton Marsh")
    expect_equal(school$scale_score_mean, means[i])
    expect_equal(school$number_of_valid_scale_scores, valid[i])
    expect_equal(school$pct_l2, l2[i])
    expect_identical(school$assessment_era, if (gp) "NJGPA-2026" else
      if (token == "SC05") "NJSLA-S" else "NJSLA-2026")
    for (level in 1:5) {
      expect_identical(!is.na(school[[paste0("pct_l", level)]]), level <= levels[i])
    }
    masked <- out[out$is_school & is.na(out$number_of_valid_scale_scores), ]
    expect_equal(nrow(masked), 1L)
    expect_true(masked$suppressed)
    expect_true(is.na(masked$scale_score_mean))
    expect_true(all(is.na(as.matrix(masked[, paste0("pct_l", 1:5)]))))
    expect_true(all(is.na(as.matrix(masked[, paste0("num_l", 1:5)]))))
    if (gp) {
      last <- out[out$is_state & out$subgroup == "sped_accomodations", ]
      expect_equal(nrow(last), 1L)
      expect_equal(last$pct_l2, if (subject == "ela") 55.1 else 35.4)
      expect_equal(school$proficient_above, l2[i])
    } else {
      expect_equal(school$proficient_above, if (token == "SC05") 13.8 else
        switch(token, MAT04 = 32.1, ALG01 = 97.2, ELA03 = 45.2))
    }
  }
})
