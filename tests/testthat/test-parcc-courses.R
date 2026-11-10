test_that("PARCC course workbooks parse real totals and suppressed cells offline", {
  local_nj_offline_transport()
  folders <- c("1415/parcc", "1516/spring", "1617/spring", "1718/spring")
  state_scores <- c(91740, 105998, 110215, 110912)
  school_means <- c(NA_real_, 761, 759, 763)
  school_l4 <- c(NA_real_, 67.6, 67.9, 76.5)

  for (year in 2015:2018) {
    index <- year - 2014L
    fixture <- test_path("fixtures", "parcc-courses",
                         paste0("parcc-alg1-", year, ".xlsx"))
    expected_url <- paste0(
      "https://www.nj.gov/education/assessment/results/reports/",
      folders[[index]], "/MATALG1.xlsx"
    )
    request <- function(url, dest, timeout) {
      expect_identical(url, expected_url)
      file.copy(fixture, dest, overwrite = TRUE)
      list(status_code = 200L, final_url = url,
           content_type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
    }
    local_mocked_bindings(.default_source_request = request,
                          .package = "njschooldata")
    # Existing column-order warnings are unrelated to course acquisition.
    out <- suppressWarnings(fetch_parcc(year, "ALG1", "math", tidy = TRUE))
    expect_gt(nrow(out), 0L)
    expect_true(any(out$is_state))
    expect_true(any(out$is_district))
    expect_true(any(out$is_school))
    expect_true(all(out$assess_name == "PARCC"))
    expect_identical(get_source_results(out)$source_url, expected_url)

    state <- out[out$is_state & out$subgroup == "total_population", ]
    expect_equal(nrow(state), 1L)
    expect_equal(state$number_of_valid_scale_scores, state_scores[[index]])
    school <- out[out$is_school & out$subgroup == "total_population", ]
    expect_equal(nrow(school), 1L)
    expect_identical(school$district_id, "0010")
    expect_identical(school$school_id, "050")
    expect_equal(school$scale_score_mean, school_means[[index]])
    expect_equal(school$pct_l4, school_l4[[index]])

    suppressed <- out[out$is_school & is.na(out$number_of_valid_scale_scores), ]
    expect_equal(nrow(suppressed), 1L)
    expect_true(all(is.na(suppressed$scale_score_mean)))
    expect_true(all(is.na(suppressed$pct_l4)))
    expect_true(all(is.na(suppressed$num_l4)))
  }
})
