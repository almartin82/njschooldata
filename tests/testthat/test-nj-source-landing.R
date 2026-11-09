test_that("persistence preserves the published school cell and cohort definition", {
  local_nj_offline_transport()
  x <- fetch_stability(2025)
  row <- subset(x, district_id == "0680" & school_id == "030" &
                  student_group == "Students with Disabilities" & measure == "HS Persistence")
  # HSPersistenceTargets J852 in the retained 2024-25 school workbook.
  expect_equal(nrow(row), 1L)
  expect_equal(row$value, 58.7)
  expect_equal(row$source_value, "58.7%")
  expect_match(row$definition, "six years")
  expect_true(all(is.na(x$numerator)))
  expect_true(all(is.na(x$denominator)))
})

test_that("current cohort and accountability persistence keep their own periods", {
  local_nj_offline_transport()
  a <- fetch_stability(2024)
  r <- subset(a, district_id == "0680" & school_id == "030" &
               student_group == "Students with Disabilities")
  # 6YrGraduationCohortProfile N1441.
  expect_equal(r$value, 58.7)
  expect_equal(r$measure, "HighSchoolPersistance")
  expect_match(r$period, "Cohort 2022")
  b <- fetch_stability(2025)
  r <- subset(b, district_id == "0680" & school_id == "030" &
               student_group == "Students with disabilities" & measure == "Persisting")
  # GraduationCohortProfile S4337.
  expect_equal(r$value, 75.4)
  expect_match(r$period, "Cohort 2023")
  masked <- subset(b, grepl("[Ff]ewer|less than", source_value))
  expect_gt(nrow(masked), 0L)
  expect_true(all(is.na(masked$value)))
})

test_that("profile 5C uses school year and published rates rather than component sums", {
  local_nj_offline_transport()
  expected <- list(c(8.11, 90, 1110, 3.48, 201, 5771),
                   c(10.35, 104, 1005, 3.29, 192, 5836),
                   c(8.98, 103, 1147, 2.74, 164, 5995))
  for (y in 2023:2025) {
    x <- fetch_sped_environment(y)
    a <- subset(x, district_id == "0680")
    b <- subset(x, district_id == "3570")
    expect_equal(c(a$value_pct, a$value_count, a$n_students,
                   b$value_pct, b$value_count, b$n_students), expected[[y - 2022L]])
    expect_equal(a$report_year, y + 1L)
    expect_true(all(x$indicator == "5C"))
    expect_false(any(x$district_name == "County Level"))
    expect_false(anyDuplicated(x[c("district_id", "indicator", "end_year")]) > 0)
    marker <- subset(x, source_value %in% c("N", "NR"))
    expect_gt(nrow(marker), 0L)
    expect_true(all(is.na(marker$value_pct)))
    expect_true(all(is.na(marker$value_count)))
    expect_true(all(is.na(marker$n_students)))
  }
})

test_that("bundle tampering and missing bytes stop before any live fallback", {
  local_nj_offline_transport()
  path <- system.file("extdata", "program-sources", "environment-5c.csv",
                       package = "njschooldata")
  bytes <- readBin(path, "raw", n = file.info(path)$size)
  local({
    on.exit(writeBin(bytes, path))
    bad <- bytes
    bad[1L] <- as.raw(0)
    writeBin(bad, path)
    expect_error(fetch_sped_environment(2025), "SHA-256 mismatch")
  })
  local({
    on.exit(writeBin(bytes, path))
    unlink(path)
    expect_error(fetch_sped_environment(2025), "SHA-256 mismatch")
  })
})

test_that("unpublished years are explicit gaps and coverage includes the new families", {
  local_nj_offline_transport()
  expect_equal(get_available_years("stability"), 2024:2025)
  expect_equal(get_available_years("sped_environment"), 2023:2025)
  expect_error(fetch_stability(2023), "published bundled")
  expect_error(fetch_stability(2026), "published bundled")
  expect_error(fetch_sped_environment(2026), "published bundled")
  expect_error(fetch_sped_share(2026, "school_spr"), "published bundled")
})

test_that("the default remains the bundled LEA IDEA basis", {
  local_nj_offline_transport()
  x <- fetch_sped_share(2025)
  row <- subset(x, district_id == "3570" & grade_band == "all")
  expect_equal(row$n_sped, 6795)
  expect_equal(row$n_enrolled, 44264)
  expect_true(all(x$entity_level %in% c("district", "state")))
})

test_that("school SPR rates remain rates with source rounding bounds", {
  local_nj_offline_transport()
  # EnrollmentTrendsByStudentGroup L2487:L2489, Camden HS.
  for (y in 2023:2025) {
    x <- fetch_sped_share(y, basis = "school_spr")
    row <- subset(x, district_id == "0680" & school_id == "030")
    expect_equal(nrow(row), 1L)
    expect_equal(row$pct_sped, c(20, 16.9, 14.9)[y - 2022L])
    expect_equal(row$pct_sped_lo, row$pct_sped - 0.05)
    expect_equal(row$pct_sped_hi, row$pct_sped + 0.05)
    expect_true(all(is.na(x$n_sped)))
    expect_true(all(x$entity_level == "school"))
    expect_true(all(c("0680", "3570") %in% x$district_id))
    if (y == 2025L) {
      pooled <- sped_all_vs_all(x,
        data.frame(district_id = "0680", school_id = "030"),
        data.frame(district_id = "0680", school_id = "040"))
      expect_equal(pooled$pct, c(14.9, 8.5))
      expect_equal(pooled$pct_lo, c(14.85, 8.45))
      expect_equal(pooled$pct_hi, c(14.95, 8.55))
      expect_true(all(pooled$method == "published_rates_weighted"))
    }
  }
})
