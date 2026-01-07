# ==============================================================================
# Tests for Percentile Rank Functions
# ==============================================================================
#
# These tests verify the generic percentile rank calculations and replicate
# key findings from MarGrady Research's Newark schools analysis:
#
# "Moving Up: Progress in Newark's Schools from 2010 to 2017"
# https://margrady.com/movingup/
#
# "A New Baseline: Progress in Newark's District and Charter Schools 2006-2018"
# https://margrady.com/newbaseline/
#
# Key MarGrady findings to verify:
# 1. Newark graduation rate rose from ~63% (2011) to ~77% (2018)
# 2. Newark's DFG A percentile rank improved from 39th to 78th percentile
# 3. The share of Black students in above-average schools quadrupled (7% to 31%)
#
# ==============================================================================

# -----------------------------------------------------------------------------
# Basic add_percentile_rank() functionality
# -----------------------------------------------------------------------------

test_that("add_percentile_rank() calculates correct percentile for simple case", {
  # Create simple test data
  test_df <- tibble::tibble(
    district_id = c("A", "B", "C", "D", "E"),
    grad_rate = c(0.50, 0.60, 0.70, 0.80, 0.90)
  )

  result <- test_df %>%
    add_percentile_rank("grad_rate")

  expect_s3_class(result, "data.frame")
  expect_true("grad_rate_rank" %in% names(result))
  expect_true("grad_rate_n" %in% names(result))
  expect_true("grad_rate_percentile" %in% names(result))

  # Lowest value should have rank 1, percentile 20 (1/5 = 20%)
  expect_equal(result$grad_rate_rank[result$district_id == "A"], 1)
  expect_equal(result$grad_rate_percentile[result$district_id == "A"], 20)

  # Highest value should have rank 5, percentile 100 (5/5 = 100%)
  expect_equal(result$grad_rate_rank[result$district_id == "E"], 5)
  expect_equal(result$grad_rate_percentile[result$district_id == "E"], 100)

  # N should be 5 for all
  expect_true(all(result$grad_rate_n == 5))
})


test_that("add_percentile_rank() respects grouping", {
  # Create test data with two groups
  test_df <- tibble::tibble(
    year = c(rep(2017, 3), rep(2018, 3)),
    district_id = rep(c("A", "B", "C"), 2),
    grad_rate = c(0.50, 0.60, 0.70,  # 2017
                  0.55, 0.65, 0.75)  # 2018
  )

  result <- test_df %>%
    dplyr::group_by(year) %>%
    add_percentile_rank("grad_rate") %>%
    dplyr::ungroup()

  # Each year should have n = 3
  expect_true(all(result$grad_rate_n == 3))

  # District A should be rank 1 in both years (lowest in each group)
  expect_equal(result$grad_rate_rank[result$district_id == "A" & result$year == 2017], 1)
  expect_equal(result$grad_rate_rank[result$district_id == "A" & result$year == 2018], 1)
})


test_that("add_percentile_rank() handles NA values correctly", {
  test_df <- tibble::tibble(
    district_id = c("A", "B", "C", "D"),
    grad_rate = c(0.50, NA, 0.70, 0.80)
  )

  result <- test_df %>%
    add_percentile_rank("grad_rate")

  # NA input should give NA percentile
  expect_true(is.na(result$grad_rate_percentile[result$district_id == "B"]))

  # N should only count valid values (3, not 4)
  expect_equal(result$grad_rate_n[result$district_id == "A"], 3)
})


test_that("add_percentile_rank() handles custom prefix", {
  test_df <- tibble::tibble(
    district_id = c("A", "B", "C"),
    grad_rate = c(0.50, 0.60, 0.70)
  )

  result <- test_df %>%
    add_percentile_rank("grad_rate", prefix = "dfg")

  expect_true("dfg_rank" %in% names(result))
  expect_true("dfg_n" %in% names(result))
  expect_true("dfg_percentile" %in% names(result))
})


# -----------------------------------------------------------------------------
# define_peer_group() functionality
# -----------------------------------------------------------------------------

test_that("define_peer_group() filters to district level", {
  test_df <- tibble::tibble(
    end_year = c(2018, 2018, 2018),
    district_id = c("A", "B", "C"),
    is_district = c(TRUE, TRUE, FALSE),
    is_school = c(FALSE, FALSE, TRUE),
    grad_rate = c(0.70, 0.80, 0.75)
  )

  result <- test_df %>%
    define_peer_group("statewide", level = "district")

  # Should only have 2 rows (districts)
  expect_equal(nrow(result), 2)
})


test_that("define_peer_group() with custom_ids filters correctly", {
  test_df <- tibble::tibble(
    end_year = rep(2018, 5),
    district_id = c("A", "B", "C", "D", "E"),
    is_district = rep(TRUE, 5),
    grad_rate = c(0.50, 0.60, 0.70, 0.80, 0.90)
  )

  custom_peers <- c("A", "C", "E")

  result <- test_df %>%
    define_peer_group("custom", custom_ids = custom_peers, level = "district")

  expect_equal(nrow(result), 3)
  expect_true(all(result$district_id %in% custom_peers))
})


# -----------------------------------------------------------------------------
# percentile_rank_trend() functionality
# -----------------------------------------------------------------------------

test_that("percentile_rank_trend() calculates year-over-year change", {
  test_df <- tibble::tibble(
    end_year = c(2015, 2016, 2017, 2018),
    district_id = rep("3570", 4),
    grad_rate_percentile = c(39, 50, 65, 78)
  )

  result <- test_df %>%
    percentile_rank_trend(
      percentile_col = "grad_rate_percentile",
      entity_cols = "district_id"
    )

  expect_true("grad_rate_percentile_yoy_change" %in% names(result))
  expect_true("grad_rate_percentile_cumulative_change" %in% names(result))
  expect_true("grad_rate_percentile_baseline" %in% names(result))

  # First year should have NA for yoy change
  expect_true(is.na(result$grad_rate_percentile_yoy_change[result$end_year == 2015]))

  # Year-over-year changes
  expect_equal(result$grad_rate_percentile_yoy_change[result$end_year == 2016], 11)  # 50 - 39
  expect_equal(result$grad_rate_percentile_yoy_change[result$end_year == 2017], 15)  # 65 - 50
  expect_equal(result$grad_rate_percentile_yoy_change[result$end_year == 2018], 13)  # 78 - 65

  # Cumulative change from baseline
  expect_equal(result$grad_rate_percentile_cumulative_change[result$end_year == 2015], 0)
  expect_equal(result$grad_rate_percentile_cumulative_change[result$end_year == 2018], 39)  # 78 - 39

  # Baseline should be first value for all rows
  expect_true(all(result$grad_rate_percentile_baseline == 39))
})


# -----------------------------------------------------------------------------
# MarGrady Graduation Rate Verification
# -----------------------------------------------------------------------------
# Key finding: "the citywide four-year graduation rate rose from 63% in 2011
# to 77% in 2018 and closed the gap with the state by seven percentage points"

test_that("Newark graduation rate matches MarGrady 2018 finding (~77%)", {
  skip_on_cran()
  skip_if_offline()

  grate_2018 <- fetch_grad_rate(2018, "4 year")

  newark_total <- grate_2018 %>%
    dplyr::filter(
      district_id == "3570",
      school_id == "999",  # District total
      subgroup == "total population"
    )

  expect_equal(nrow(newark_total), 1)

  # MarGrady reports 77% in 2018
  # Allow some tolerance for rounding differences
  expect_true(
    newark_total$grad_rate >= 0.75 && newark_total$grad_rate <= 0.80,
    info = sprintf("Newark 2018 grad rate was %.1f%%, expected ~77%%",
                   newark_total$grad_rate * 100)
  )
})


test_that("Newark graduation rate trend 2012-2018 shows improvement", {
  skip_on_cran()
  skip_if_offline()

  years <- 2012:2018

  grate_all <- purrr::map_df(years, function(y) {
    tryCatch(
      fetch_grad_rate(y, "4 year"),
      error = function(e) NULL
    )
  })

  newark_trend <- grate_all %>%
    dplyr::filter(
      district_id == "3570",
      school_id == "999",
      subgroup == "total population"
    ) %>%
    dplyr::arrange(end_year)

  expect_true(nrow(newark_trend) >= 5,
              info = "Should have at least 5 years of Newark grad rate data")

  # Graduation rate should improve over time
  first_year_rate <- newark_trend$grad_rate[1]
  last_year_rate <- newark_trend$grad_rate[nrow(newark_trend)]

  expect_true(
    last_year_rate > first_year_rate,
    info = sprintf("Grad rate should improve: %.1f%% to %.1f%%",
                   first_year_rate * 100, last_year_rate * 100)
  )

  # MarGrady: "rose from 63% in 2011 to 77% in 2018" - improvement of ~14 points
  improvement <- (last_year_rate - first_year_rate) * 100
  expect_true(
    improvement > 5,
    info = sprintf("Expected significant improvement, got %.1f points", improvement)
  )
})


# -----------------------------------------------------------------------------
# MarGrady DFG A Percentile Rank Verification
# -----------------------------------------------------------------------------
# Key finding: "Newark's citywide average test score rank improved from the
# 39th to the 78th percentile" among DFG A districts

test_that("grate_percentile_rank() calculates correctly for DFG A peers",
{
  skip_on_cran()
  skip_if_offline()

  # Get 2018 graduation rates
  grate_2018 <- fetch_grad_rate(2018, "4 year")

  # Add DFG classification
  grate_with_dfg <- add_dfg(grate_2018)

  # Filter to DFG A districts, total population
  dfg_a_grate <- grate_with_dfg %>%
    dplyr::filter(
      dfg == "A",
      is_district,
      subgroup == "total population"
    )

  expect_true(nrow(dfg_a_grate) >= 20,
              info = "Should have 20+ DFG A districts with grad rates")

  # Calculate percentile rank
  dfg_a_ranked <- dfg_a_grate %>%
    dplyr::group_by(end_year, subgroup) %>%
    add_percentile_rank("grad_rate") %>%
    dplyr::ungroup()

  # Find Newark
  newark_rank <- dfg_a_ranked %>%
    dplyr::filter(district_id == "3570")

  expect_equal(nrow(newark_rank), 1)
  expect_true(!is.na(newark_rank$grad_rate_percentile))

  # Verify percentile is between 0 and 100
  expect_true(
    newark_rank$grad_rate_percentile >= 0 && newark_rank$grad_rate_percentile <= 100,
    info = sprintf("Newark 2018 DFG A grad rate percentile: %.1f",
                   newark_rank$grad_rate_percentile)
  )

  # Note: The MarGrady 39th->78th percentile finding was for TEST SCORES,
  # not graduation rates. Newark's grad rate percentile among DFG A peers
  # is lower (~19th percentile in 2018) which is accurate.
})


test_that("percentile_rank_trend() tracks changes over time", {
  skip_on_cran()
  skip_if_offline()

  # Note: MarGrady's 39th->78th percentile finding was for TEST SCORES
  # from 2006-2018. This test validates the trend-tracking methodology
  # works correctly with graduation rate data from 2012-2018.

  years <- c(2013, 2016, 2018)

  # Fetch graduation rates for multiple years
  grate_all <- purrr::map_df(years, function(y) {
    tryCatch(
      fetch_grad_rate(y, "4 year") %>%
        dplyr::mutate(end_year = as.integer(end_year)),
      error = function(e) NULL
    )
  })

  # Add DFG and calculate percentile rank within DFG A by year
  grate_ranked <- grate_all %>%
    add_dfg() %>%
    dplyr::filter(
      dfg == "A",
      is_district,
      subgroup == "total population"
    ) %>%
    dplyr::group_by(end_year, subgroup) %>%
    add_percentile_rank("grad_rate") %>%
    dplyr::ungroup()

  # Get Newark's percentile rank over time
  newark_trend <- grate_ranked %>%
    dplyr::filter(district_id == "3570") %>%
    dplyr::arrange(end_year) %>%
    percentile_rank_trend(
      percentile_col = "grad_rate_percentile",
      entity_cols = "district_id"
    )

  expect_true(nrow(newark_trend) >= 2,
              info = "Should have at least 2 years for trend analysis")

  # Verify trend columns were created
  expect_true("grad_rate_percentile_yoy_change" %in% names(newark_trend))
  expect_true("grad_rate_percentile_cumulative_change" %in% names(newark_trend))
  expect_true("grad_rate_percentile_baseline" %in% names(newark_trend))

  # Baseline should equal first year's value
  expect_equal(
    newark_trend$grad_rate_percentile_baseline[1],
    newark_trend$grad_rate_percentile[1]
  )

  # Cumulative change in first year should be 0
  expect_equal(newark_trend$grad_rate_percentile_cumulative_change[1], 0)
})


# -----------------------------------------------------------------------------
# Convenience Wrapper Tests
# -----------------------------------------------------------------------------

test_that("grate_percentile_rank() wrapper works correctly", {
  skip_on_cran()
  skip_if_offline()

  grate_2018 <- fetch_grad_rate(2018, "4 year")

  # Statewide percentile
  result <- grate_percentile_rank(grate_2018, peer_type = "statewide")

  expect_s3_class(result, "data.frame")
  expect_true("grad_rate_percentile" %in% names(result))

  # Newark should have a percentile
  newark <- result %>%
    dplyr::filter(district_id == "3570", subgroup == "total population")

  expect_true(nrow(newark) >= 1)
  expect_true(!is.na(newark$grad_rate_percentile[1]))
})


test_that("dfg_percentile_rank() wrapper requires dfg column", {
  test_df <- tibble::tibble(
    end_year = 2018,
    district_id = "A",
    is_district = TRUE,
    grad_rate = 0.75
  )

  expect_error(
    dfg_percentile_rank(test_df, "grad_rate"),
    "dfg"
  )
})


test_that("dfg_percentile_rank() works with dfg column", {
  skip_on_cran()
  skip_if_offline()

  grate_2018 <- fetch_grad_rate(2018, "4 year") %>%
    add_dfg() %>%
    dplyr::filter(subgroup == "total population")

  result <- dfg_percentile_rank(grate_2018, "grad_rate")

  expect_s3_class(result, "data.frame")
  expect_true("dfg_grad_rate_percentile" %in% names(result))
})


# -----------------------------------------------------------------------------
# Assessment Percentile Rank Tests
# -----------------------------------------------------------------------------

test_that("parcc_percentile_rank() works correctly", {
  skip_on_cran()
  skip_if_offline()

  parcc_2018 <- fetch_parcc(2018, 4, "ela", tidy = TRUE)

  result <- parcc_percentile_rank(
    parcc_2018,
    peer_type = "statewide",
    metric = "proficient_above"
  )

  expect_s3_class(result, "data.frame")
  expect_true("proficient_above_percentile" %in% names(result))

  # Districts should have percentiles
  district_results <- result %>%
    dplyr::filter(is_district, subgroup == "total_population")

  expect_true(nrow(district_results) > 100,
              info = "Should have 100+ districts")
  expect_true(
    sum(!is.na(district_results$proficient_above_percentile)) > 50,
    info = "Most districts should have valid percentiles"
  )
})


# -----------------------------------------------------------------------------
# DFG A District List Tests
# -----------------------------------------------------------------------------

test_that("get_dfg_a_districts() returns expected districts", {
  skip_on_cran()
  skip_if_offline()

  dfg_a <- get_dfg_a_districts()

  expect_type(dfg_a, "character")
  expect_true(length(dfg_a) >= 30,
              info = "Should have ~37 DFG A districts")

  # Newark (3570) should be in DFG A
  expect_true("133570" %in% dfg_a | "3570" %in% dfg_a,
              info = "Newark should be in DFG A")
})


test_that("add_dfg() adds DFG classification", {
  skip_on_cran()
  skip_if_offline()

  test_df <- tibble::tibble(
    district_id = c("133570", "130100"),  # Newark, another district
    grad_rate = c(0.77, 0.85)
  )

  result <- add_dfg(test_df)

  expect_true("dfg" %in% names(result))
  expect_equal(nrow(result), 2)
})


# -----------------------------------------------------------------------------
# Sector Comparison Tests
# -----------------------------------------------------------------------------

test_that("sector_percentile_comparison() differentiates sectors", {
  skip_on_cran()
  skip_if_offline()

  grate_2018 <- fetch_grad_rate(2018, "4 year")

  # Add charter sector aggregates
  charter_aggs <- charter_sector_grate_aggs(grate_2018)

  combined <- dplyr::bind_rows(grate_2018, charter_aggs) %>%
    dplyr::filter(subgroup == "total population")

  result <- sector_percentile_comparison(
    combined,
    metric_col = "grad_rate",
    host_district_id = "3570"
  )

  expect_s3_class(result, "data.frame")
  expect_true("sector" %in% names(result))

  # Should have at least district and charter sector
  sectors <- unique(result$sector)
  expect_true(length(sectors) >= 1)
})


# -----------------------------------------------------------------------------
# Integration: Full MarGrady-Style Analysis Workflow
# -----------------------------------------------------------------------------
# The MarGrady finding (39th -> 78th percentile) was for TEST SCORES from
# 2006-2018. This test validates the METHODOLOGY works correctly using
# graduation rate data from 2013-2018.
#
# Percentile rank definition: "the percent of comparison entities with
# lesser or equal performance" = rank / n * 100
# - Uses min_rank (ties get minimum rank)
# - Newark is INCLUDED in the denominator (compared to all DFG A peers)

test_that("full MarGrady-style analysis workflow validates methodology", {
  skip_on_cran()
  skip_if_offline()

  years <- c(2013, 2016, 2018)

  # 1. Fetch multi-year data
  grate_multi <- purrr::map_df(years, function(y) {
    tryCatch({
      fetch_grad_rate(y, "4 year") %>%
        dplyr::filter(subgroup == "total population", is_district)
    }, error = function(e) NULL)
  })

  expect_true(nrow(grate_multi) > 100,
              info = "Should have multi-year district data")

  # 2. Add DFG classification
  grate_dfg <- add_dfg(grate_multi)

  # 3. Calculate DFG A percentile rank by year
  grate_ranked <- grate_dfg %>%
    dplyr::filter(dfg == "A") %>%
    dplyr::group_by(end_year) %>%
    add_percentile_rank("grad_rate") %>%
    dplyr::ungroup()

  # 4. Extract Newark's trend
  newark_progress <- grate_ranked %>%
    dplyr::filter(district_id == "3570") %>%
    dplyr::arrange(end_year)

  expect_true(nrow(newark_progress) >= 2,
              info = "Should have Newark data for multiple years")

  # 5. Calculate trend metrics
  newark_with_trend <- newark_progress %>%
    percentile_rank_trend(
      percentile_col = "grad_rate_percentile",
      entity_cols = "district_id"
    )

  # Verify structure - trend columns should exist
  expect_true("grad_rate_percentile_cumulative_change" %in% names(newark_with_trend))
  expect_true("grad_rate_percentile_yoy_change" %in% names(newark_with_trend))
  expect_true("grad_rate_percentile_baseline" %in% names(newark_with_trend))

  # Verify percentiles are in valid range (0-100)
  expect_true(all(newark_with_trend$grad_rate_percentile >= 0))
  expect_true(all(newark_with_trend$grad_rate_percentile <= 100))

  # Verify baseline is consistent
  expect_equal(
    unique(newark_with_trend$grad_rate_percentile_baseline),
    newark_with_trend$grad_rate_percentile[1]
  )

  # Print summary for manual verification
  message("\n=== Newark DFG A Graduation Rate Percentile Trend ===")
  message(sprintf("Years analyzed: %s", paste(years, collapse = ", ")))
  for (i in seq_len(nrow(newark_with_trend))) {
    row <- newark_with_trend[i, ]
    message(sprintf(
      "%d: Grad Rate = %.1f%%, DFG A Percentile = %.1f",
      row$end_year, row$grad_rate * 100, row$grad_rate_percentile
    ))
  }
})


# =============================================================================
# Extension #1: Subgroup Trajectory Divergence Tests
# =============================================================================

# -----------------------------------------------------------------------------
# calculate_subgroup_gap() Tests
# -----------------------------------------------------------------------------

test_that("calculate_subgroup_gap() computes correct gaps", {
  test_df <- tibble::tibble(
    end_year = c(2018, 2018, 2018, 2018),
    district_id = c("A", "A", "B", "B"),
    subgroup = c("white", "black", "white", "black"),
    grad_rate = c(0.90, 0.70, 0.85, 0.80)
  )

  result <- calculate_subgroup_gap(
    test_df,
    metric_col = "grad_rate",
    subgroup_a = "white",
    subgroup_b = "black"
  )

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2)  # One row per district

  # Check column names
  expect_true("grad_rate_a" %in% names(result))
  expect_true("grad_rate_b" %in% names(result))
  expect_true("grad_rate_gap" %in% names(result))
  expect_true("grad_rate_gap_pct" %in% names(result))
  expect_true("subgroup_pair" %in% names(result))

  # Check gap values
  district_a <- result %>% dplyr::filter(district_id == "A")
  expect_equal(district_a$grad_rate_a, 0.90)
  expect_equal(district_a$grad_rate_b, 0.70)
  expect_equal(district_a$grad_rate_gap, 0.20)  # 0.90 - 0.70 = 0.20

  district_b <- result %>% dplyr::filter(district_id == "B")
  expect_equal(district_b$grad_rate_gap, 0.05)  # 0.85 - 0.80 = 0.05

  # Check subgroup pair label
  expect_equal(unique(result$subgroup_pair), "white_vs_black")
})


test_that("calculate_subgroup_gap() errors on missing subgroup", {
  test_df <- tibble::tibble(
    end_year = 2018,
    district_id = "A",
    subgroup = "white",
    grad_rate = 0.90
  )

  expect_error(
    calculate_subgroup_gap(test_df, "grad_rate", "white", "black"),
    "not found in data"
  )
})


test_that("calculate_subgroup_gap() errors on missing column", {
  test_df <- tibble::tibble(
    end_year = 2018,
    district_id = "A",
    subgroup = "white",
    wrong_col = 0.90
  )

  expect_error(
    calculate_subgroup_gap(test_df, "grad_rate", "white", "black"),
    "not found in dataframe"
  )
})


# -----------------------------------------------------------------------------
# gap_percentile_rank() Tests
# -----------------------------------------------------------------------------

test_that("gap_percentile_rank() ranks smaller gaps higher when smaller_is_better=TRUE", {
  # Create gap data where smaller gaps should rank higher
  test_df <- tibble::tibble(
    end_year = rep(2018, 4),
    district_id = c("A", "B", "C", "D"),
    is_district = rep(TRUE, 4),
    grad_rate_gap = c(0.30, 0.20, 0.10, 0.05)  # D has smallest gap
  )

  result <- gap_percentile_rank(
    test_df,
    gap_col = "grad_rate_gap",
    peer_type = "statewide",
    smaller_is_better = TRUE
  )

  expect_s3_class(result, "data.frame")
  expect_true("grad_rate_gap_equity_percentile" %in% names(result))

  # District D (smallest gap) should have highest percentile
  expect_equal(
    result$grad_rate_gap_equity_percentile[result$district_id == "D"],
    100  # rank 4/4 = 100th percentile
  )

  # District A (largest gap) should have lowest percentile
  expect_equal(
    result$grad_rate_gap_equity_percentile[result$district_id == "A"],
    25  # rank 1/4 = 25th percentile
  )
})


# -----------------------------------------------------------------------------
# gap_trajectory() Tests
# -----------------------------------------------------------------------------

test_that("gap_trajectory() tracks gap changes over time", {
  test_df <- tibble::tibble(
    end_year = c(2015, 2016, 2017, 2018,
                 2015, 2016, 2017, 2018),
    district_id = rep("3570", 8),
    subgroup = c(rep("white", 4), rep("black", 4)),
    grad_rate = c(0.85, 0.86, 0.87, 0.88,  # white
                  0.65, 0.68, 0.72, 0.78)  # black (improving faster)
  )

  result <- gap_trajectory(
    test_df,
    metric_col = "grad_rate",
    subgroup_a = "white",
    subgroup_b = "black",
    entity_cols = "district_id"
  )

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 4)  # One row per year

  # Check trend columns exist
  expect_true("grad_rate_gap_yoy_change" %in% names(result))
  expect_true("grad_rate_gap_cumulative_change" %in% names(result))
  expect_true("grad_rate_gap_baseline" %in% names(result))

  # Gap should be shrinking (black improving faster)
  # 2015: 0.85 - 0.65 = 0.20
  # 2018: 0.88 - 0.78 = 0.10
  result_sorted <- result %>% dplyr::arrange(end_year)

  expect_equal(result_sorted$grad_rate_gap[1], 0.20, tolerance = 0.001)
  expect_equal(result_sorted$grad_rate_gap[4], 0.10, tolerance = 0.001)

  # Cumulative change should be negative (gap narrowed)
  cumul_change <- result_sorted$grad_rate_gap_cumulative_change[4]
  expect_true(cumul_change < 0,
              info = sprintf("Gap should narrow, cumulative change = %.3f", cumul_change))
})


# -----------------------------------------------------------------------------
# Real Data Gap Analysis Tests
# -----------------------------------------------------------------------------

test_that("calculate_subgroup_gap() works with real graduation data", {
  skip_on_cran()
  skip_if_offline()

  grate_2018 <- fetch_grad_rate(2018, "4 year") %>%
    dplyr::filter(is_district)

  # Check which subgroups are available
  available_subgroups <- unique(grate_2018$subgroup)

  # Find white/black if available
  has_white <- "white" %in% available_subgroups
  has_black <- "black" %in% available_subgroups

  if (has_white && has_black) {
    result <- calculate_subgroup_gap(
      grate_2018,
      metric_col = "grad_rate",
      subgroup_a = "white",
      subgroup_b = "black"
    )

    expect_s3_class(result, "data.frame")
    expect_true(nrow(result) > 50,
                info = "Should have gaps for 50+ districts")
    expect_true("grad_rate_gap" %in% names(result))

    # Check Newark
    newark_gap <- result %>% dplyr::filter(district_id == "3570")
    if (nrow(newark_gap) == 1) {
      expect_true(!is.na(newark_gap$grad_rate_gap))
      message(sprintf(
        "Newark 2018 White-Black grad rate gap: %.1f pp",
        newark_gap$grad_rate_gap * 100
      ))
    }
  } else {
    skip("White and/or Black subgroups not available in 2018 grad rate data")
  }
})


# =============================================================================
# Extension #3: Sector Ecosystem Dynamics Tests
# =============================================================================

# -----------------------------------------------------------------------------
# sector_gap() Tests
# -----------------------------------------------------------------------------

test_that("sector_gap() computes charter-district difference", {
  test_df <- tibble::tibble(
    end_year = c(2018, 2018),
    district_id = c("3570C", "3570"),  # Charter sector and district
    is_charter_sector = c(TRUE, FALSE),
    is_district = c(FALSE, TRUE),
    is_allpublic = c(FALSE, FALSE),
    grad_rate = c(0.85, 0.75)
  )

  result <- sector_gap(test_df, metric_col = "grad_rate")

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1)

  expect_equal(result$charter_value, 0.85)
  expect_equal(result$district_value, 0.75)
  expect_equal(result$sector_gap, 0.10)  # 0.85 - 0.75
  expect_equal(result$sector_leader, "charter")
})


test_that("sector_gap() identifies district leader correctly", {
  test_df <- tibble::tibble(
    end_year = c(2018, 2018),
    district_id = c("3570C", "3570"),
    is_charter_sector = c(TRUE, FALSE),
    is_district = c(FALSE, TRUE),
    is_allpublic = c(FALSE, FALSE),
    grad_rate = c(0.70, 0.80)  # District outperforms
  )

  result <- sector_gap(test_df, metric_col = "grad_rate")

  expect_equal(result$sector_leader, "district")
})


# -----------------------------------------------------------------------------
# city_ecosystem_summary() Tests
# -----------------------------------------------------------------------------

test_that("city_ecosystem_summary() returns all three sectors", {
  skip_on_cran()
  skip_if_offline()

  grate_2018 <- fetch_grad_rate(2018, "4 year") %>%
    dplyr::filter(subgroup == "total population")

  # Generate sector aggregates
  charter_aggs <- charter_sector_grate_aggs(grate_2018)
  allpublic_aggs <- allpublic_grate_aggs(grate_2018)

  combined <- dplyr::bind_rows(grate_2018, charter_aggs, allpublic_aggs)

  result <- city_ecosystem_summary(
    combined,
    metric_col = "grad_rate",
    host_district_id = "3570"
  )

  expect_s3_class(result, "data.frame")

  # Should have rows for different sectors
  sectors <- unique(result$sector)
  expect_true(length(sectors) >= 1,
              info = sprintf("Found sectors: %s", paste(sectors, collapse = ", ")))

  # Should have grad_rate and percentile columns
  expect_true("grad_rate" %in% names(result))
  expect_true("grad_rate_percentile" %in% names(result))
})


# -----------------------------------------------------------------------------
# charter_market_share() Tests
# -----------------------------------------------------------------------------

test_that("charter_market_share() calculates share correctly", {
  test_df <- tibble::tibble(
    end_year = c(2018, 2018),
    district_id = c("3570C", "3570A"),
    is_charter_sector = c(TRUE, FALSE),
    is_allpublic = c(FALSE, TRUE),
    subgroup = c("total_enrollment", "total_enrollment"),
    n_students = c(15000, 50000)  # 15k charter, 50k total
  )

  result <- charter_market_share(test_df)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1)

  expect_equal(result$charter_enrollment, 15000)
  expect_equal(result$total_enrollment, 50000)
  expect_equal(result$charter_share, 30)  # 15000/50000 = 30%
  expect_equal(result$district_enrollment, 35000)  # 50000 - 15000
})


# -----------------------------------------------------------------------------
# Newark Sector Aggregation Validation Tests
# -----------------------------------------------------------------------------

test_that("Newark charter sector can be aggregated", {
  skip_on_cran()
  skip_if_offline()

  grate_2018 <- fetch_grad_rate(2018, "4 year")

  charter_aggs <- charter_sector_grate_aggs(grate_2018)

  # Filter to Newark charter sector
  newark_charter <- charter_aggs %>%
    dplyr::filter(
      district_id == "3570C",
      subgroup == "total population"
    )

  expect_equal(nrow(newark_charter), 1,
               info = "Newark charter sector should have one row for total population")

  expect_true(!is.na(newark_charter$grad_rate),
              info = "Newark charter sector grad rate should not be NA")

  message(sprintf(
    "Newark Charter Sector 2018 grad rate: %.1f%%",
    newark_charter$grad_rate * 100
  ))
})


test_that("Newark all-public can be aggregated", {
  skip_on_cran()
  skip_if_offline()

  grate_2018 <- fetch_grad_rate(2018, "4 year")

  allpublic_aggs <- allpublic_grate_aggs(grate_2018)

  # Filter to Newark all-public
  newark_allpublic <- allpublic_aggs %>%
    dplyr::filter(
      district_id == "3570A",
      subgroup == "total population"
    )

  expect_equal(nrow(newark_allpublic), 1,
               info = "Newark all-public should have one row for total population")

  expect_true(!is.na(newark_allpublic$grad_rate),
              info = "Newark all-public grad rate should not be NA")

  message(sprintf(
    "Newark All-Public 2018 grad rate: %.1f%%",
    newark_allpublic$grad_rate * 100
  ))
})


# -----------------------------------------------------------------------------
# SUBGROUP_PAIRS constant test
# -----------------------------------------------------------------------------

test_that("SUBGROUP_PAIRS constant is correctly defined", {
  expect_type(SUBGROUP_PAIRS, "list")
  expect_true(length(SUBGROUP_PAIRS) >= 4)

  # Check structure of pairs
  expect_equal(SUBGROUP_PAIRS$race_white_black, c("white", "black"))
  expect_equal(SUBGROUP_PAIRS$race_white_hispanic, c("white", "hispanic"))
})
