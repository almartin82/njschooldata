# Only network failures may skip a reconciliation; parser and identity failures
# must reach the test reporter.
reconciliation_fetch <- function(expr) {
  tryCatch(expr, error = function(e) {
    if (ay_is_network_error(e)) testthat::skip(conditionMessage(e))
    stop(e)
  })
}

test_that("verified absence years agree with the source registry offline", {
  expect_identical(get_available_years("absence"), c(2017:2019, 2021:2025))
  expect_identical(get_available_years("absence"), get_source_years("absence"))
  expect_false(2020L %in% get_available_years("absence"))
  expect_true(all(2019:2021 %in% get_available_years("finance")))
})

for (year in 2019:2021) local({
  y <- year
  total <- c(`2019` = 8485965463, `2020` = 8676882785,
             `2021` = 8680457745)[[as.character(y)]]
  test_that(paste("finance revised aid reconciles to the printed total", y), {
    skip_if_no_live_tests()
    fin <- reconciliation_fetch(fetch_finance(y))
    expect_gt(nrow(fin), 0L)
    rev <- fin[fin$metric == "revenue_state", ]
    expect_equal(nrow(rev[rev$is_state, ]), 1L)
    expect_equal(rev$value[rev$is_state], total)
    expect_equal(sum(rev$value[rev$is_district]), total)
    expect_false(any(rev$is_state & rev$is_district))
    expect_true(y %in% get_available_years("finance"))
  })
})

# Emma C Attales, CDS 01-0010-050, Schoolwide / All Students.
# These rates are printed in each year's school SPR workbook, not calculated
# from rounded counts or from another publication.
absence_rates <- c(`2017` = 9.3, `2018` = 6.7, `2019` = 7.1,
                   `2021` = 15.0, `2022` = 11.6, `2023` = 13.3, `2024` = 11.0, `2025` = 7.3)
for (year in names(absence_rates)) local({
  y <- as.integer(year)
  rate <- absence_rates[[year]]
  test_that(paste("absence preserves the printed schoolwide rate", y), {
    skip_if_no_live_tests()
    d <- reconciliation_fetch(fetch_absence(y, use_cache = FALSE))
    row <- d[d$county_id == "01" & d$district_id == "0010" &
               d$school_id == "050" & d$subgroup == "total", ]
    expect_gt(nrow(d), 0L)
    expect_equal(nrow(row), 1L)
    expect_equal(row$chronically_absent_rate, rate)
    expect_false(is.na(row$school_name))
    expect_true(y %in% get_available_years("absence"))
  })
})
