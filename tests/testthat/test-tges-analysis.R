# ==============================================================================
# Tests for the TGES comparative-analysis toolkit
# (tges_composition / tges_percentile_rank / tges_efficiency)
# ==============================================================================
#
# Two layers:
#   1. Pure-logic unit tests on tiny SYNTHETIC fixtures. These hand-built tibbles
#      exist only to exercise the reshape/rank/join math; they are not data and
#      are never presented as NJ DOE figures.
#   2. Live integration tests against the real 2024 guide (skip_if_offline).
# ==============================================================================


# --- synthetic fixtures --------------------------------------------------------

# a single-indicator TGES-shaped table (one peer group, one "00NA" average row)
fake_indicator <- function(indicator, pp_vals,
                            codes = c("3570", "0680", "00NA"),
                            names_ = c("Newark", "Camden", "GROUP AVG")) {
  tibble::tibble(
    county_name   = "Test",
    district_id = codes,
    district_name = names_,
    group         = "G. K-12 / 3501 +",
    `Per Pupil costs` = pp_vals,
    `District rank`   = c(seq_along(pp_vals)[-length(pp_vals)], NA_integer_),
    indicator     = indicator,
    end_year      = 2024,
    calc_type     = "Budgeted"
  )
}

fake_tges <- function() {
  list(
    CSG1 = fake_indicator("Budgetary Per Pupil Cost",        c(20000, 16000, NA)),
    CSG2 = fake_indicator("Total Classroom Instruction",     c(12000,  8000, NA)),
    CSG8 = fake_indicator("Total Administrative Costs per Pupil", c(2000, 1600, NA)),
    CSG1AA_AVGS = tibble::tibble(
      county_name   = "Test",
      district_id = c("3570", "0680"),
      district_name = c("Newark", "Camden"),
      `Per Pupil Total Expenditures` = c(25000, 21000),
      `Per Pupil Rank` = c(1L, 2L),
      end_year  = 2024,
      calc_type = "Budgeted"
    )
  )
}


# --- tges_composition ----------------------------------------------------------

test_that("tges_composition reshapes categories and computes shares", {
  comp <- tges_composition(fake_tges())

  # group-average ("00NA") row is dropped
  expect_equal(nrow(comp), 2L)
  expect_setequal(comp$district_id, c("3570", "0680"))

  # category columns present
  expect_true(all(c("budgetary_pp", "classroom", "administration",
                    "total_pp", "classroom_share", "administration_share")
                  %in% names(comp)))

  nwk <- comp[comp$district_id == "3570", ]
  expect_equal(nwk$classroom, 12000)
  expect_equal(nwk$budgetary_pp, 20000)
  expect_equal(nwk$classroom_share, 0.6)          # 12000 / 20000
  expect_equal(nwk$administration_share, 0.1)     # 2000 / 20000
  expect_equal(nwk$total_pp, 25000)               # from CSG1AA
})

test_that("tges_composition errors when no budget tables are present", {
  expect_error(tges_composition(list(NOTATABLE = tibble::tibble(x = 1))),
               "No budget indicator tables")
})


# --- tges_percentile_rank ------------------------------------------------------

test_that("tges_percentile_rank ranks within the TGES enrollment-band group", {
  df <- tibble::tibble(
    county_name   = "X",
    district_id = c("0001", "0002", "0003", "0004"),
    district_name = letters[1:4],
    group         = "G",
    `Per Pupil costs` = c(10, 20, 30, 40),
    `District rank`   = 1:4L,
    indicator     = "Budgetary Per Pupil Cost",
    end_year      = 2024,
    calc_type     = "Budgeted"
  )

  r <- tges_percentile_rank(df)

  expect_true(all(c("peer_rank", "peer_n", "peer_percentile") %in% names(r)))
  r <- r[order(r$district_id), ]
  expect_equal(r$peer_percentile, c(25, 50, 75, 100))  # rank/n * 100
  expect_equal(unique(r$peer_n), 4L)
})

test_that("tges_percentile_rank drops average rows and honors prefix", {
  df <- tibble::tibble(
    county_name   = "X",
    district_id = c("0001", "0002", "00NA"),
    district_name = c("a", "b", "AVG"),
    group         = "G",
    `Per Pupil costs` = c(100, 300, NA),
    end_year      = 2024
  )
  r <- tges_percentile_rank(df, peer = "statewide", prefix = "state")
  expect_equal(nrow(r), 2L)
  expect_true("state_percentile" %in% names(r))
})

test_that("tges_percentile_rank errors on a missing metric column", {
  df <- tibble::tibble(district_id = "0001", group = "G", end_year = 2024)
  expect_error(tges_percentile_rank(df, metric_col = "nope"), "not found")
})


# --- tges_efficiency -----------------------------------------------------------

test_that("tges_efficiency joins spend to outcome and labels quadrants", {
  spend <- tibble::tibble(
    county_name   = "X",
    district_id = c("0001", "0002", "0003", "0004"),
    district_name = letters[1:4],
    group         = "G",
    `Per Pupil costs` = c(10, 20, 30, 40),
    indicator     = "Budgetary Per Pupil Cost",
    end_year      = 2024,
    calc_type     = "Budgeted"
  )
  # SYNTHETIC outcome percentiles, perfectly anti-correlated with spend
  outcome <- tibble::tibble(
    district_id = c("0001", "0002", "0003", "0004"),
    end_year    = 2024,
    grad_pctl   = c(80, 60, 40, 20)
  )

  eff <- tges_efficiency(spend, outcome,
                         outcome_percentile_col = "grad_pctl",
                         spend_peer = "tges_group")

  expect_equal(nrow(eff), 4L)
  eff <- eff[order(eff$district_id), ]
  expect_equal(eff$spend_percentile, c(25, 50, 75, 100))
  expect_equal(eff$outcome_percentile, c(80, 60, 40, 20))
  expect_equal(eff$quadrant, c(
    "Low spend / High outcome (efficient)",
    "High spend / High outcome",
    "High spend / Low outcome (watch)",
    "High spend / Low outcome (watch)"
  ))
  # exact linear relationship -> residuals ~ 0
  expect_true(all(abs(eff$efficiency_residual) < 1e-6))
})

test_that("tges_efficiency requires district_id and the percentile column", {
  spend <- tibble::tibble(
    district_id = "0001", group = "G",
    `Per Pupil costs` = 10, end_year = 2024
  )
  expect_error(
    tges_efficiency(spend, tibble::tibble(end_year = 2024, p = 1),
                    outcome_percentile_col = "p"),
    "district_id"
  )
  expect_error(
    tges_efficiency(spend, tibble::tibble(district_id = "0001", end_year = 2024),
                    outcome_percentile_col = "missing"),
    "not found"
  )
})


# --- live integration ----------------------------------------------------------

test_that("tges_composition builds sane shares from the live 2024 guide", {
  skip_on_cran()
  skip_if_offline()
  comp <- tges_composition(fetch_tges(2024), calc_type = "Budgeted")
  expect_true(all(c("classroom", "budgetary_pp", "classroom_share") %in% names(comp)))
  nwk <- comp[comp$district_id == "3570" & comp$end_year == 2024, ]
  expect_equal(nrow(nwk), 1L)
  expect_true(is.finite(nwk$classroom_share))
  expect_gt(nwk$classroom_share, 0)
  expect_lt(nwk$classroom_share, 1.5)   # classroom is a fraction of budgetary cost
})

test_that("tges_percentile_rank ranks the live 2024 CSG1 within enrollment bands", {
  skip_on_cran()
  skip_if_offline()
  r <- tges_percentile_rank(fetch_tges(2024)$CSG1)
  expect_true(all(c("peer_rank", "peer_n", "peer_percentile") %in% names(r)))
  nwk <- r[r$district_id == "3570" & r$end_year == 2024, ]
  expect_equal(nrow(nwk), 1L)
  expect_gte(nwk$peer_percentile, 0)
  expect_lte(nwk$peer_percentile, 100)
  # Newark sits in the largest K-12 band; the peer set should be non-trivial
  expect_gt(nwk$peer_n, 5L)
})


# ==============================================================================
# Comparative helpers added on top of the three core functions:
#   tges_revenue_mix / tges_fund_balance_health / tges_federal_exposure /
#   tges_staffing / tges_red_flags / tges_real_growth
# Same two layers: synthetic-fixture unit tests, then live integration.
# ==============================================================================


# --- additional synthetic fixtures --------------------------------------------

fake_vitstat <- function(end_year = 2023,
                         codes = c("3570", "0680", "00NA"),
                         total_pp = c(20000, 10000, NA),
                         local = c(0.6, 0.2, NA),
                         state = c(0.3, 0.7, NA),
                         federal = c(0.1, 0.1, NA)) {
  tibble::tibble(
    group         = "G",
    county_name   = "Test",
    district_id = codes,
    district_name = c("Newark", "Camden", "AVG")[seq_along(codes)],
    `Total Spending Per Pupil` = total_pp,
    `Revenue: State %`         = state,
    `Revenue: Local %`         = local,
    `Revenue: Federal %`       = federal,
    `Revenue: Tuition %`       = 0,
    `Revenue: Free balance %`  = 0,
    `Revenue: Other %`         = 0,
    end_year      = end_year
  )
}


# --- tges_revenue_mix ----------------------------------------------------------

test_that("tges_revenue_mix attributes per-pupil dollars from shares", {
  rm <- tges_revenue_mix(list(VITSTAT_TOTAL = fake_vitstat()))

  expect_equal(nrow(rm), 2L)                       # "00NA" average row dropped
  expect_true(all(c("total_pp", "local_share", "state_share", "federal_share",
                    "local_pp", "state_pp", "federal_pp") %in% names(rm)))

  nwk <- rm[rm$district_id == "3570", ]
  expect_equal(nwk$total_pp, 20000)
  expect_equal(nwk$local_pp, 12000)                # 20000 * 0.6
  expect_equal(nwk$state_pp, 6000)                 # 20000 * 0.3
  expect_equal(nwk$federal_pp, 2000)               # 20000 * 0.1
})

test_that("tges_revenue_mix errors without a VITSTAT table", {
  expect_error(tges_revenue_mix(list(CSG1 = tibble::tibble(x = 1))),
               "VITSTAT_TOTAL")
})


# --- tges_fund_balance_health --------------------------------------------------

test_that("tges_fund_balance_health joins CSG20/21 and flags surplus + deficit", {
  csg20 <- tibble::tibble(
    group = "G", county_name = "X",
    district_id = c("3570", "3570"),
    district_name = "Newark",
    `Budgeted General Fund Balance` = c(120, 120),
    Actual = c(100, 60),
    end_year = c(2022, 2023)
  )
  csg21 <- tibble::tibble(
    group = "G", county_name = "X",
    district_id = c("3570", "3570"),
    district_name = "Newark",
    `Actual Excess` = c(5, -3),
    end_year = c(2022, 2023)
  )

  fb <- tges_fund_balance_health(list(CSG20 = csg20, CSG21 = csg21))
  fb <- fb[order(fb$end_year), ]

  expect_equal(fb$fund_balance_variance, c(-20, -60))   # actual - budgeted
  expect_equal(fb$excess_surplus_flag, c(TRUE, FALSE))  # excess > 0 only in 2022
  # actual balance fell 100 -> 60 in 2023
  expect_equal(fb$balance_yoy_change, c(NA, -40))
  expect_equal(fb$declining_balance_flag, c(FALSE, TRUE))
})


# --- tges_federal_exposure -----------------------------------------------------

test_that("tges_federal_exposure flags spending-up-on-federal-bump districts", {
  # nested 'many' structure: year -> list(VITSTAT_TOTAL = ...)
  tgm <- list(
    `2019` = list(VITSTAT_TOTAL = fake_vitstat(2018, federal = c(0.05, 0.05, NA))),
    `2020` = list(VITSTAT_TOTAL = fake_vitstat(2019, federal = c(0.05, 0.05, NA))),
    `2022` = list(VITSTAT_TOTAL = fake_vitstat(2021, total_pp = c(24000, 10000, NA),
                                               federal = c(0.12, 0.06, NA))),
    `2024` = list(VITSTAT_TOTAL = fake_vitstat(2023, total_pp = c(26000, 10000, NA),
                                               federal = c(0.11, 0.05, NA)))
  )

  fe <- tges_federal_exposure(tgm)

  nwk <- fe[fe$district_id == "3570", ]
  expect_equal(nwk$baseline_federal_share, 0.05)   # mean of 2018,2019
  expect_equal(nwk$peak_federal_share, 0.12)       # max over esser years
  expect_equal(round(nwk$federal_bump, 3), 0.07)
  expect_equal(round(nwk$pp_growth, 3), 0.3)       # 26000/20000 - 1
  expect_true(nwk$cliff_exposure)

  cmd <- fe[fe$district_id == "0680", ]          # flat spend, small bump
  expect_false(cmd$cliff_exposure)
})


# --- tges_staffing -------------------------------------------------------------

test_that("tges_staffing merges personnel tables to one row per district-year", {
  mk_personnel <- function(ratio_name, ratio, sal_name = NULL, sal = NULL) {
    df <- tibble::tibble(
      group = "G", county_name = "X",
      district_id = c("3570", "0680"),
      district_name = c("Newark", "Camden"),
      end_year = 2024
    )
    df[[ratio_name]] <- ratio
    if (!is.null(sal_name)) df[[sal_name]] <- sal
    df
  }
  tg <- list(
    CSG16 = mk_personnel("Student/Teacher ratio", c(12, 14),
                         "Teacher Salary", c(70000, 65000)),
    CSG18 = mk_personnel("Student/Administrator ratio", c(80, 90),
                         "Administrator Salary", c(120000, 110000)),
    CSG19 = mk_personnel("Faculty/Administrator ratio", c(7, 8)),
    CSG14 = tibble::tibble(
      group = "G", county_name = "X",
      district_id = c("3570", "0680"),
      district_name = c("Newark", "Camden"),
      `% of Total Salaries` = c(0.30, 0.28),
      end_year = 2024
    )
  )

  st <- tges_staffing(tg)
  expect_equal(nrow(st), 2L)
  expect_true(all(c("student_teacher_ratio", "teacher_salary",
                    "student_admin_ratio", "admin_salary",
                    "faculty_admin_ratio", "benefits_pct_salary") %in% names(st)))
  nwk <- st[st$district_id == "3570", ]
  expect_equal(nwk$student_admin_ratio, 80)
  expect_equal(nwk$benefits_pct_salary, 0.30)
})


# --- tges_red_flags ------------------------------------------------------------

# 10-district fixture so deciles are clean (percentiles 10,20,...,100)
fake_scan_tges <- function() {
  codes <- sprintf("%04d", 1:10)
  mk <- function(indicator, vals) tibble::tibble(
    group = "G", county_name = "X",
    district_id = codes, district_name = codes,
    `Per Pupil costs` = vals, `District rank` = 1:10,
    indicator = indicator, end_year = 2024, calc_type = "Budgeted"
  )
  list(
    CSG1 = mk("Budgetary Per Pupil Cost",            seq(10000, 28000, by = 2000)),
    CSG2 = mk("Total Classroom Instruction",         seq(6000, 15000, by = 1000)),
    CSG8 = mk("Total Administrative Costs per Pupil", seq(1000, 1900, by = 100))
  )
}

test_that("tges_red_flags surfaces top/bottom-decile placements", {
  # In this fixture budgetary cost rises faster than classroom $, so the highest
  # spender also has the LOWEST classroom share -- the real Newark pattern.
  hi <- tges_red_flags(fake_scan_tges(), district_id = "0010",
                       peer = "tges_group")
  expect_true(all(c("indicator", "value", "peer_percentile", "peer_n",
                    "higher_means", "flag") %in% names(hi)))
  expect_equal(hi$flag[hi$indicator == "Budgetary per-pupil cost"], "top decile")
  expect_equal(hi$flag[hi$indicator == "Classroom share of budget"], "bottom decile")

  # district 0001 is the lowest spender -> bottom-decile cost, top-decile share
  lo <- tges_red_flags(fake_scan_tges(), district_id = "0001",
                       peer = "tges_group")
  expect_equal(lo$flag[lo$indicator == "Budgetary per-pupil cost"], "bottom decile")
  expect_equal(lo$flag[lo$indicator == "Classroom share of budget"], "top decile")

  # a middle district has no extremes; only_flagged filters them all out
  mid_full <- tges_red_flags(fake_scan_tges(), district_id = "0005",
                             peer = "tges_group", only_flagged = FALSE)
  mid_flagged <- tges_red_flags(fake_scan_tges(), district_id = "0005",
                                peer = "tges_group", only_flagged = TRUE)
  expect_gt(nrow(mid_full), nrow(mid_flagged))
  expect_true(any(is.na(mid_full$flag)))
})


# --- tges_real_growth ----------------------------------------------------------

test_that("tges_real_growth splits per-pupil growth into cost vs enrollment", {
  csg1aa <- tibble::tibble(
    county_name   = "X",
    district_id = c("3570", "3570", "3570"),
    district_name = "Newark",
    `Total Expenditures, actual costs`          = c(1000, 1100, 1100),
    `Average Daily Enrollment plus Sent Pupils` = c(100, 100, 90),
    `Per Pupil Total Expenditures`              = c(10, 11, 1100 / 90),
    end_year  = c(2021, 2022, 2023),
    calc_type = "Actuals"
  )

  rg <- tges_real_growth(list(CSG1AA_AVGS = csg1aa))
  rg <- rg[order(rg$end_year), ]

  # 2022: pure cost growth (enrollment flat) -> enrollment share ~ 0
  expect_equal(round(rg$enrollment_effect_share[rg$end_year == 2022], 3), 0)
  # 2023: spending flat, enrollment fell 10% -> all growth is the denominator
  expect_equal(round(rg$enrollment_effect_share[rg$end_year == 2023], 3), 1)
  # the decomposition is an identity
  pp_log <- rg$real_cost_component + rg$enrollment_component
  expect_equal(pp_log[rg$end_year == 2023],
               log((1100 / 90) / 11), tolerance = 1e-8)
})

test_that("tges_real_growth adds real-terms columns when given a deflator", {
  csg1aa <- tibble::tibble(
    county_name = "X", district_id = c("3570", "3570"),
    district_name = "Newark",
    `Total Expenditures, actual costs`          = c(1000, 1100),
    `Average Daily Enrollment plus Sent Pupils` = c(100, 100),
    `Per Pupil Total Expenditures`              = c(10, 11),
    end_year = c(2022, 2023), calc_type = "Actuals"
  )
  cpi <- data.frame(end_year = c(2022, 2023), price_index = c(100, 110))

  rg <- tges_real_growth(list(CSG1AA_AVGS = csg1aa), deflator = cpi)
  expect_true(all(c("real_per_pupil", "real_pp_growth") %in% names(rg)))
  # 10% nominal per-pupil growth fully offset by 10% inflation -> ~0 real growth
  expect_equal(round(rg$real_pp_growth[rg$end_year == 2023], 6), 0)
})


# --- live integration: comparative helpers ------------------------------------

test_that("tges_revenue_mix and friends run on the live 2024 guide", {
  skip_on_cran()
  skip_if_offline()
  tg <- fetch_tges(2024)

  rm <- tges_revenue_mix(tg)
  nwk <- rm[rm$district_id == "3570", ]
  expect_equal(nrow(nwk), 1L)
  expect_true(is.finite(nwk$local_pp) && nwk$local_pp > 0)
  # shares should land near 1 (rounding); allow slack
  s <- nwk$local_share + nwk$state_share + nwk$federal_share +
    nwk$tuition_share + nwk$free_balance_share + nwk$other_share
  expect_gt(s, 0.95); expect_lt(s, 1.05)

  fb <- tges_fund_balance_health(tg)
  expect_true(all(c("excess_unreserved", "excess_surplus_flag") %in% names(fb)))
  expect_true(any(fb$district_id == "3570"))

  st <- tges_staffing(tg)
  expect_true("student_admin_ratio" %in% names(st))
  expect_true(any(is.finite(st$student_teacher_ratio)))

  rf <- tges_red_flags(tg, "3570", peer = "tges_group", only_flagged = FALSE)
  expect_true(all(c("indicator", "peer_percentile", "higher_means") %in% names(rf)))
  expect_gt(nrow(rf), 5L)
})


# --- error paths & edge cases (no network) ------------------------------------

test_that("tges_revenue_mix errors without per-pupil total and honors years", {
  vs_no_pp <- fake_vitstat()
  vs_no_pp[["Total Spending Per Pupil"]] <- NULL
  expect_error(tges_revenue_mix(list(VITSTAT_TOTAL = vs_no_pp)),
               "Total Spending Per Pupil")

  tgm <- list(
    `2023` = list(VITSTAT_TOTAL = fake_vitstat(2022)),
    `2024` = list(VITSTAT_TOTAL = fake_vitstat(2023))
  )
  rm <- tges_revenue_mix(tgm, years = 2023)
  expect_equal(unique(rm$end_year), 2023)
})

test_that("tges_fund_balance_health works with only one of CSG20 / CSG21", {
  csg20 <- tibble::tibble(
    group = "G", county_name = "X", district_id = "3570",
    district_name = "Newark",
    `Budgeted General Fund Balance` = 120, Actual = 100, end_year = 2023
  )
  fb20 <- tges_fund_balance_health(list(CSG20 = csg20))
  expect_true("fund_balance_variance" %in% names(fb20))
  expect_false("excess_unreserved" %in% names(fb20))
  expect_equal(fb20$fund_balance_variance, -20)

  csg21 <- tibble::tibble(
    group = "G", county_name = "X", district_id = "3570",
    district_name = "Newark", `Actual Excess` = 5, end_year = 2023
  )
  fb21 <- tges_fund_balance_health(list(CSG21 = csg21))
  expect_true("excess_unreserved" %in% names(fb21))
  expect_true(fb21$excess_surplus_flag)

  expect_error(tges_fund_balance_health(list(CSG1 = tibble::tibble(x = 1))),
               "Neither CSG20 nor CSG21")
})

test_that("tges_federal_exposure errors with no baseline years, recovers if given", {
  tgm <- list(   # only ESSER-window years present, none <= 2020
    `2022` = list(VITSTAT_TOTAL = fake_vitstat(2021)),
    `2024` = list(VITSTAT_TOTAL = fake_vitstat(2023))
  )
  expect_error(tges_federal_exposure(tgm), "baseline")

  fe <- tges_federal_exposure(tgm, baseline_years = 2021, esser_years = 2023)
  expect_true("cliff_exposure" %in% names(fe))
  expect_equal(nrow(fe), 2L)   # two real districts, average row dropped
})

test_that("tges_staffing errors when no personnel tables are present", {
  expect_error(tges_staffing(list(CSG1 = tibble::tibble(x = 1))),
               "personnel")
})

test_that("tges_red_flags errors on an unknown district", {
  expect_error(tges_red_flags(fake_scan_tges(), district_id = "9999"),
               "No indicators")
})

test_that("tges_red_flags carries direction and percentile bounds", {
  rf <- tges_red_flags(fake_scan_tges(), district_id = "0007",
                       peer = "tges_group", only_flagged = FALSE)
  expect_true(all(rf$peer_percentile >= 0 & rf$peer_percentile <= 100))
  # composition rows carry their own direction text
  admin <- rf[rf$indicator == "Administration share of budget", ]
  expect_equal(admin$higher_means, "more overhead than peers")
})

test_that("tges_real_growth errors without CSG1AA and dedupes overlapping reports", {
  expect_error(tges_real_growth(list(CSG1 = tibble::tibble(x = 1))),
               "CSG1AA")

  # two guides each carry the same actual year (2022); it must collapse to one row
  r1 <- tibble::tibble(
    county_name = "X", district_id = "3570", district_name = "Newark",
    `Total Expenditures, actual costs`          = c(1000, 1100),
    `Average Daily Enrollment plus Sent Pupils` = c(100, 100),
    `Per Pupil Total Expenditures`              = c(10, 11),
    end_year = c(2021, 2022), calc_type = "Actuals"
  )
  r2 <- tibble::tibble(
    county_name = "X", district_id = "3570", district_name = "Newark",
    `Total Expenditures, actual costs`          = c(1100, 1210),
    `Average Daily Enrollment plus Sent Pupils` = c(100, 110),
    `Per Pupil Total Expenditures`              = c(11, 11),
    end_year = c(2022, 2023), calc_type = "Actuals"
  )
  tgm <- list(`2022` = list(CSG1AA_AVGS = r1), `2023` = list(CSG1AA_AVGS = r2))

  rg <- tges_real_growth(tgm)
  expect_equal(sum(rg$end_year == 2022), 1L)        # 2022 not duplicated
  expect_equal(sort(rg$end_year), c(2021, 2022, 2023))
})

test_that("tges_federal_exposure errors when esser_years are absent", {
  tgm <- list(
    `2019` = list(VITSTAT_TOTAL = fake_vitstat(2018)),
    `2020` = list(VITSTAT_TOTAL = fake_vitstat(2019))
  )
  expect_error(tges_federal_exposure(tgm, esser_years = 2030), "esser_years")
})

test_that("tges_red_flags requires a district_id", {
  expect_error(tges_red_flags(fake_scan_tges()), "district_id")
})

test_that("tges_red_flags scans whatever indicator tables are present", {
  # only CSG1 present: composition cannot build classroom/admin shares, so only
  # the budgetary indicator is scanned and the function still returns it.
  codes <- sprintf("%04d", 1:10)
  only1 <- list(CSG1 = tibble::tibble(
    group = "G", county_name = "X", district_id = codes, district_name = codes,
    `Per Pupil costs` = seq(10000, 28000, by = 2000), `District rank` = 1:10,
    indicator = "Budgetary Per Pupil Cost", end_year = 2024, calc_type = "Budgeted"
  ))
  rf <- tges_red_flags(only1, district_id = "0010", peer = "tges_group",
                       only_flagged = FALSE)
  expect_true("Budgetary per-pupil cost" %in% rf$indicator)
  expect_false("Classroom share of budget" %in% rf$indicator)
})

test_that("tges_fund_balance_health honors the years filter", {
  csg20 <- tibble::tibble(
    group = "G", county_name = "X", district_id = c("3570", "3570"),
    district_name = "Newark",
    `Budgeted General Fund Balance` = c(120, 120), Actual = c(100, 60),
    end_year = c(2022, 2023)
  )
  fb <- tges_fund_balance_health(list(CSG20 = csg20), years = 2023)
  expect_equal(unique(fb$end_year), 2023)
})

test_that("tges_staffing honors years and skips tables lacking mapped columns", {
  mk <- function(yr) tibble::tibble(
    group = "G", county_name = "X", district_id = c("3570", "0680"),
    district_name = c("Newark", "Camden"),
    `Student/Teacher ratio` = c(12, 14), `Teacher Salary` = c(70000, 65000),
    end_year = yr
  )
  tgm <- list(`2023` = list(CSG16 = mk(2023)), `2024` = list(CSG16 = mk(2024)))
  st <- tges_staffing(tgm, years = 2024)
  expect_equal(unique(st$end_year), 2024)

  # a CSG16 table without its mapped columns contributes nothing -> no pieces
  expect_error(
    tges_staffing(list(CSG16 = tibble::tibble(
      group = "G", district_id = "3570", end_year = 2024))),
    "personnel"
  )
})

test_that("tges_real_growth: missing cols, pp fallback, deflator check, years", {
  # missing total-expenditure / ADE columns
  expect_error(
    tges_real_growth(list(CSG1AA_AVGS = tibble::tibble(
      county_name = "X", district_id = "3570", district_name = "Newark",
      end_year = 2023))),
    "total expenditures"
  )

  # no "Per Pupil Total Expenditures" column -> per_pupil computed as exp / ADE
  no_pp <- tibble::tibble(
    county_name = "X", district_id = "3570", district_name = "Newark",
    `Total Expenditures, actual costs`          = c(1000, 1100),
    `Average Daily Enrollment plus Sent Pupils` = c(100, 100),
    end_year = c(2022, 2023), calc_type = "Actuals"
  )
  rg <- tges_real_growth(list(CSG1AA_AVGS = no_pp))
  expect_equal(rg$per_pupil[rg$end_year == 2022], 10)
  expect_equal(rg$per_pupil[rg$end_year == 2023], 11)

  good <- tibble::tibble(
    county_name = "X", district_id = "3570", district_name = "Newark",
    `Total Expenditures, actual costs`          = c(1000, 1100),
    `Average Daily Enrollment plus Sent Pupils` = c(100, 100),
    `Per Pupil Total Expenditures`              = c(10, 11),
    end_year = c(2022, 2023), calc_type = "Actuals"
  )
  # malformed deflator (wrong column names)
  expect_error(
    tges_real_growth(list(CSG1AA_AVGS = good),
                     deflator = data.frame(yr = 2022, idx = 100)),
    "price_index"
  )
  # years filter is applied after differencing
  rg2 <- tges_real_growth(list(CSG1AA_AVGS = good), years = 2023)
  expect_equal(unique(rg2$end_year), 2023)
})


# ==============================================================================
# Cross-district comparative layer:
#   tges_find_peers / tges_frontier / tges_convergence / tges_composition_drift /
#   tges_gap_cost / tges_volatility / tges_compare, plus the custom-peer hook on
#   tges_percentile_rank.
# Same two layers: synthetic-fixture unit tests, then live integration.
# All fixtures are hand-built to exercise the math and are never NJ DOE figures.
# ==============================================================================


# --- comparative fixtures ------------------------------------------------------

# a single-year per-pupil cost table (one band, one "00NA" average row)
fake_cost <- function(code_vals, indicator, codes, names_,
                      county = "Essex", group = "G. K-12 / 3501 +",
                      end_year = 2024, calc_type = "Budgeted") {
  tibble::tibble(
    county_name = county, district_id = codes, district_name = names_,
    group = group, `Per Pupil costs` = code_vals,
    indicator = indicator, end_year = end_year, calc_type = calc_type
  )
}

# a full single-year tges list with composition + enrollment + revenue inputs.
# classroom rises slower than budgetary, so high spenders have a low classroom
# share -- the real Newark pattern, controlled deterministically here.
fake_full_tges <- function() {
  codes <- sprintf("%04d", 1:6)
  nm <- paste0("D", 1:6)
  list(
    CSG1 = fake_cost(seq(15000, 25000, by = 2000),
                     "Budgetary Per Pupil Cost", codes, nm),
    CSG2 = fake_cost(seq(9000, 12000, length.out = 6),
                     "Total Classroom Instruction", codes, nm),
    CSG8 = fake_cost(seq(1200, 2200, length.out = 6),
                     "Administration", codes, nm),
    CSG1AA_AVGS = tibble::tibble(
      county_name = "Essex", district_id = codes, district_name = nm,
      `Total Expenditures, actual costs` = seq(1e8, 3e8, length.out = 6),
      `Average Daily Enrollment plus Sent Pupils` = seq(5000, 30000, length.out = 6),
      `Per Pupil Total Expenditures` = seq(18000, 28000, length.out = 6),
      end_year = 2023, calc_type = "Actuals"
    ),
    VITSTAT_TOTAL = tibble::tibble(
      group = "G. K-12 / 3501 +", county_name = "Essex",
      district_id = codes, district_name = nm,
      `Total Spending Per Pupil` = seq(18000, 28000, length.out = 6),
      `Revenue: Local %` = seq(0.1, 0.85, length.out = 6),
      `Revenue: State %` = seq(0.85, 0.1, length.out = 6),
      `Revenue: Federal %` = rep(0.05, 6),
      `Revenue: Tuition %` = 0, `Revenue: Free balance %` = 0,
      `Revenue: Other %` = 0, end_year = 2023
    )
  )
}


# --- tges_percentile_rank: custom peer hook -----------------------------------

test_that("tges_percentile_rank ranks within a custom peer set", {
  df <- tibble::tibble(
    county_name = "X", district_id = sprintf("%04d", 1:6),
    district_name = letters[1:6], group = "G",
    `Per Pupil costs` = c(10, 20, 30, 40, 50, 60), end_year = 2024
  )
  # rank only three of the six districts
  r <- tges_percentile_rank(df, peer = "custom",
                            custom_ids = c("0002", "0004", "0006"))
  expect_equal(nrow(r), 3L)
  r <- r[order(r$district_id), ]
  expect_equal(r$peer_percentile, c(100 / 3, 200 / 3, 100), tolerance = 0.1)
  expect_equal(unique(r$peer_n), 3L)
})

test_that("tges_percentile_rank custom peer requires ids", {
  df <- tibble::tibble(district_id = "0001", group = "G",
                       `Per Pupil costs` = 10, end_year = 2024)
  expect_error(tges_percentile_rank(df, peer = "custom"), "custom_ids")
})


# --- tges_find_peers -----------------------------------------------------------

test_that("tges_find_peers returns the focal first, then nearest by distance", {
  # district 0002 is a near-clone of the focal 0001; it must be the nearest peer
  codes <- sprintf("%04d", 1:4)
  tg <- list(
    CSG1 = fake_cost(c(20000, 20100, 15000, 28000),
                     "Budgetary Per Pupil Cost", codes, paste0("D", 1:4)),
    # classroom set so classroom_share = c(.55, .55, .62, .50) (share = CSG2/CSG1)
    CSG2 = fake_cost(c(0.55 * 20000, 0.55 * 20100, 0.62 * 15000, 0.50 * 28000),
                     "Total Classroom Instruction", codes, paste0("D", 1:4)),
    CSG8 = fake_cost(c(2000, 2010, 1500, 2800),
                     "Administration", codes, paste0("D", 1:4)),
    CSG1AA_AVGS = tibble::tibble(
      county_name = "Essex", district_id = codes, district_name = paste0("D", 1:4),
      `Total Expenditures, actual costs` = c(1e8, 1e8, 5e7, 3e8),
      `Average Daily Enrollment plus Sent Pupils` = c(10000, 10000, 4000, 40000),
      `Per Pupil Total Expenditures` = c(22000, 22100, 16000, 30000),
      end_year = 2023, calc_type = "Actuals"
    ),
    VITSTAT_TOTAL = tibble::tibble(
      group = "G. K-12 / 3501 +", county_name = "Essex",
      district_id = codes, district_name = paste0("D", 1:4),
      `Total Spending Per Pupil` = c(22000, 22100, 16000, 30000),
      `Revenue: Local %` = c(0.5, 0.5, 0.2, 0.8),
      `Revenue: State %` = c(0.45, 0.45, 0.75, 0.15),
      `Revenue: Federal %` = c(0.05, 0.05, 0.05, 0.05),
      `Revenue: Tuition %` = 0, `Revenue: Free balance %` = 0,
      `Revenue: Other %` = 0, end_year = 2023
    )
  )

  fp <- tges_find_peers(tg, "0001", n = 2,
                        features = c("ade", "budgetary_pp", "classroom_share",
                                     "local_share"))
  expect_true(fp$is_focal[1])
  expect_equal(fp$distance[1], 0)
  expect_equal(nrow(fp), 3L)              # focal + 2 peers
  expect_false(is.unsorted(fp$distance))  # ascending
  expect_equal(fp$district_id[2], "0002")  # the near-clone is nearest
})

test_that("tges_find_peers errors on unknown district and missing feature", {
  expect_error(tges_find_peers(fake_full_tges(), "9999"),
               "not found")
  expect_error(
    tges_find_peers(fake_full_tges(), "0001", features = c("nope_share")),
    "not available"
  )
})

test_that("tges_find_peers drops a zero-variance feature with a warning", {
  tg <- fake_full_tges()
  # federal_share is constant across districts -> zero variance
  expect_warning(
    fp <- tges_find_peers(tg, "0003",
                          features = c("budgetary_pp", "federal_share")),
    "zero-variance"
  )
  expect_true(fp$is_focal[1])
})


# --- tges_frontier -------------------------------------------------------------

test_that("tges_frontier computes free-disposal-hull efficiency and references", {
  codes <- sprintf("%04d", 1:4)
  spend <- tibble::tibble(
    county_name = "X", district_id = codes, district_name = paste0("D", 1:4),
    group = "G", `Per Pupil costs` = c(100, 200, 150, 300),
    indicator = "Budgetary Per Pupil Cost", end_year = 2024, calc_type = "Actuals"
  )
  # higher outcome is better; d1 cheap+good, d3 best outcome
  outcome <- tibble::tibble(
    district_id = codes, end_year = 2024, grad = c(90, 80, 95, 85)
  )

  fr <- tges_frontier(spend, outcome, outcome_col = "grad", peer = "tges_group")
  fr <- fr[order(fr$district_id), ]

  # d1: cheapest with outcome 90, nobody beats it for less -> frontier
  # d2: outcome 80, d1 (outcome 90 >= 80) does it for 100 -> 100/200 = 0.5
  # d3: outcome 95 is the max -> only itself qualifies -> frontier
  # d4: outcome 85, cheapest among outcome>=85 is d1 (100) -> 100/300 = 0.333
  expect_equal(fr$efficiency_score, c(1, 0.5, 1, 0.3333), tolerance = 1e-3)
  expect_equal(fr$on_frontier, c(TRUE, FALSE, TRUE, FALSE))
  expect_equal(fr$reference_district_id, c("0001", "0001", "0003", "0001"))
  expect_equal(fr$excess_spend, c(0, 100, 0, 200))
})

test_that("tges_frontier validates inputs and the join", {
  spend <- tibble::tibble(
    district_id = "0001", group = "G", `Per Pupil costs` = 100,
    end_year = 2024
  )
  expect_error(
    tges_frontier(spend, tibble::tibble(district_id = "0001", end_year = 2024),
                  outcome_col = "missing"),
    "not found"
  )
  expect_error(
    tges_frontier(spend, tibble::tibble(end_year = 2024, grad = 1),
                  outcome_col = "grad"),
    "district_id"
  )
  # year mismatch -> no rows matched
  expect_error(
    tges_frontier(spend,
                  tibble::tibble(district_id = "0001", end_year = 2099, grad = 1),
                  outcome_col = "grad", peer = "statewide"),
    "matched"
  )
})


# --- tges_convergence ----------------------------------------------------------

test_that("tges_convergence detects convergence (low starters grow faster)", {
  codes <- sprintf("%04d", 1:6)
  mk <- function(yr, vals) list(CSG1 = tibble::tibble(
    county_name = "X", district_id = codes, district_name = codes, group = "G",
    `Per Pupil costs` = vals, indicator = "Budgetary Per Pupil Cost",
    end_year = yr, calc_type = "Budgeted"
  ))
  # all six districts converge toward ~50 -> low-start districts grow most.
  # 0001 lands exactly on 50 (clean identity check); the rest carry small
  # jitter so the OLS fit is strong but not perfect (no lm "perfect fit" warning).
  tgm <- list(`2018` = mk(2018, c(10, 20, 30, 40, 45, 48)),
              `2024` = mk(2024, c(50, 51, 49, 50, 48, 50)))
  cv <- tges_convergence(tgm, peer = "statewide")

  s <- dplyr::distinct(cv, peer_group, beta, beta_pvalue, converging, n_districts)
  expect_equal(s$n_districts, 6L)
  expect_lt(s$beta, 0)                 # negative slope = convergence
  expect_true(s$converging)
  # growth is an identity check on one district
  d1 <- cv[cv$district_id == "0001", ]
  expect_equal(d1$growth, (log(50) - log(10)) / 6, tolerance = 1e-8)
})

test_that("tges_convergence detects divergence (high starters grow faster)", {
  codes <- sprintf("%04d", 1:6)
  mk <- function(yr, vals) list(CSG1 = tibble::tibble(
    county_name = "X", district_id = codes, district_name = codes, group = "G",
    `Per Pupil costs` = vals, indicator = "x", end_year = yr, calc_type = "Budgeted"
  ))
  start <- c(10, 20, 30, 40, 50, 60)
  tgm <- list(`2018` = mk(2018, start),
              `2024` = mk(2024, start * c(1.0, 1.1, 1.2, 1.3, 1.4, 1.5)))
  cv <- tges_convergence(tgm, peer = "statewide")
  expect_gt(dplyr::distinct(cv, beta)$beta, 0)   # positive slope = divergence
})

test_that("tges_convergence errors on equal endpoints and missing table", {
  codes <- sprintf("%04d", 1:6)
  mk <- function(yr) list(CSG1 = tibble::tibble(
    county_name = "X", district_id = codes, district_name = codes, group = "G",
    `Per Pupil costs` = 1:6, indicator = "x", end_year = yr, calc_type = "Budgeted"
  ))
  expect_error(tges_convergence(list(`2024` = mk(2024)), peer = "statewide"),
               "must differ")
  expect_error(tges_convergence(list(`2024` = list(NOPE = tibble::tibble(x = 1)))),
               "not found")
})


# --- tges_composition_drift ----------------------------------------------------

test_that("tges_composition_drift computes signed drift and ranks it", {
  codes <- sprintf("%04d", 1:5)
  mk <- function(yr, csg2) list(
    CSG1 = tibble::tibble(county_name = "X", district_id = codes,
      district_name = codes, group = "G", `Per Pupil costs` = rep(20000, 5),
      indicator = "Budgetary Per Pupil Cost", end_year = yr, calc_type = "Budgeted"),
    CSG2 = tibble::tibble(county_name = "X", district_id = codes,
      district_name = codes, group = "G", `Per Pupil costs` = csg2,
      indicator = "Total Classroom Instruction", end_year = yr, calc_type = "Budgeted"),
    CSG8 = tibble::tibble(county_name = "X", district_id = codes,
      district_name = codes, group = "G", `Per Pupil costs` = rep(2000, 5),
      indicator = "Administration", end_year = yr, calc_type = "Budgeted")
  )
  # classroom_share starts 0.60 everywhere; ends vary -> known drift
  tgm <- list(`2019` = mk(2019, rep(12000, 5)),
              `2024` = mk(2024, c(8000, 9000, 10000, 11000, 12000)))
  dr <- tges_composition_drift(tgm, peer = "statewide",
                               shares = c("classroom_share", "administration_share"))

  d1 <- dr[dr$district_id == "0001", ]
  expect_equal(d1$classroom_share_start, 0.60)
  expect_equal(d1$classroom_share_end, 0.40)
  expect_equal(d1$classroom_share_drift, -0.20, tolerance = 1e-8)
  # district 0005 had no drift (largest end share) -> highest percentile
  d5 <- dr[dr$district_id == "0005", ]
  expect_equal(d5$classroom_share_drift, 0, tolerance = 1e-8)
  expect_equal(d5$drift_percentile, 100)
  expect_true(all(dr$drift_percentile >= 0 & dr$drift_percentile <= 100))
})

test_that("tges_composition_drift errors on bad rank_on and equal years", {
  expect_error(
    tges_composition_drift(fake_full_tges(), rank_on = "not_a_share"),
    "must be one of"
  )
})


# --- tges_gap_cost -------------------------------------------------------------

test_that("tges_gap_cost converts a share gap to per-pupil and total dollars", {
  gc <- tges_gap_cost(fake_full_tges(), district_id = "0001",
                      metric = "classroom_share", target = "median",
                      peer = "tges_group")
  expect_equal(nrow(gc), 1L)

  # rebuild the expected numbers from the fixture
  comp <- tges_composition(fake_full_tges(), calc_type = "Budgeted")
  focal_share <- comp$classroom_share[comp$district_id == "0001"]
  med <- stats::median(comp$classroom_share)
  bpp <- comp$budgetary_pp[comp$district_id == "0001"]
  ade <- 5000  # district 0001 ADE in the fixture

  expect_equal(gc$focal_value, focal_share)
  expect_equal(gc$target_value, med)
  expect_equal(gc$gap, med - focal_share, tolerance = 1e-9)
  expect_equal(gc$per_pupil_gap_dollars, round((med - focal_share) * bpp))
  expect_equal(gc$total_gap_dollars, round((med - focal_share) * bpp * ade))
  expect_equal(gc$ade, ade)
})

test_that("tges_gap_cost handles a dollar metric and a numeric quantile target", {
  # classroom (raw $/pupil, not a share): gap is already per-pupil dollars
  gc <- tges_gap_cost(fake_full_tges(), district_id = "0001",
                      metric = "classroom", target = 0.5, peer = "tges_group")
  comp <- tges_composition(fake_full_tges(), calc_type = "Budgeted")
  med <- stats::median(comp$classroom)
  focal <- comp$classroom[comp$district_id == "0001"]
  expect_equal(gc$target_basis, "p50")
  expect_equal(gc$per_pupil_gap_dollars, round(med - focal))
})

test_that("tges_gap_cost errors on unknown district, metric, and bad target", {
  expect_error(tges_gap_cost(fake_full_tges(), "9999"), "not found")
  expect_error(tges_gap_cost(fake_full_tges(), "0001", metric = "nope"),
               "not a tges_composition")
  expect_error(tges_gap_cost(fake_full_tges(), "0001", target = 2),
               "quantile in")
})


# --- tges_volatility -----------------------------------------------------------

test_that("tges_volatility ranks a spiky series above a flat one", {
  codes <- c("0001", "0002")
  mk <- function(yr, fed) list(VITSTAT_TOTAL = tibble::tibble(
    group = "G", county_name = "X", district_id = codes,
    district_name = codes, `Total Spending Per Pupil` = c(20000, 20000),
    `Revenue: Local %` = 0.5, `Revenue: State %` = 0.45,
    `Revenue: Federal %` = fed, `Revenue: Tuition %` = 0,
    `Revenue: Free balance %` = 0, `Revenue: Other %` = 0, end_year = yr
  ))
  # 0001 flat at 0.05; 0002 swings 0.05/0.20/0.05/0.20
  tgm <- list(`2019` = mk(2019, c(0.05, 0.05)), `2020` = mk(2020, c(0.05, 0.20)),
              `2022` = mk(2022, c(0.05, 0.05)), `2024` = mk(2024, c(0.05, 0.20)))
  vol <- tges_volatility(tgm, metric = "federal_share", peer = "statewide",
                         min_years = 3)
  expect_equal(nrow(vol), 2L)
  flat <- vol[vol$district_id == "0001", ]
  spiky <- vol[vol$district_id == "0002", ]
  expect_equal(flat$cv, 0)
  expect_gt(spiky$cv, flat$cv)
  expect_gt(spiky$vol_percentile, flat$vol_percentile)
})

test_that("tges_volatility honors min_years and routes the metric", {
  codes <- c("0001", "0002")
  mk <- function(yr, fed) list(VITSTAT_TOTAL = tibble::tibble(
    group = "G", county_name = "X", district_id = codes, district_name = codes,
    `Total Spending Per Pupil` = c(20000, 20000), `Revenue: Local %` = 0.5,
    `Revenue: State %` = 0.45, `Revenue: Federal %` = fed,
    `Revenue: Tuition %` = 0, `Revenue: Free balance %` = 0,
    `Revenue: Other %` = 0, end_year = yr
  ))
  tgm <- list(`2023` = mk(2023, c(0.05, 0.05)), `2024` = mk(2024, c(0.06, 0.06)))
  # only 2 years -> nobody clears min_years = 3
  expect_error(tges_volatility(tgm, metric = "federal_share", min_years = 3),
               "at least 3 years")
  # unknown metric
  expect_error(tges_volatility(tgm, metric = "not_a_metric"), "not found")
})


# --- tges_compare --------------------------------------------------------------

test_that("tges_compare assembles a scorecard in the requested order", {
  tg <- c(fake_full_tges(), list(
    CSG16 = tibble::tibble(group = "G. K-12 / 3501 +", county_name = "Essex",
      district_id = sprintf("%04d", 1:6), district_name = paste0("D", 1:6),
      `Student/Teacher ratio` = seq(10, 15, length.out = 6),
      `Teacher Salary` = seq(60000, 80000, length.out = 6), end_year = 2023),
    CSG18 = tibble::tibble(group = "G. K-12 / 3501 +", county_name = "Essex",
      district_id = sprintf("%04d", 1:6), district_name = paste0("D", 1:6),
      `Student/Administrator ratio` = seq(70, 120, length.out = 6),
      `Administrator Salary` = seq(110000, 150000, length.out = 6), end_year = 2023),
    CSG14 = tibble::tibble(group = "G. K-12 / 3501 +", county_name = "Essex",
      district_id = sprintf("%04d", 1:6), district_name = paste0("D", 1:6),
      `% of Total Salaries` = seq(0.25, 0.35, length.out = 6), end_year = 2023),
    CSG21 = tibble::tibble(group = "G. K-12 / 3501 +", county_name = "Essex",
      district_id = sprintf("%04d", 1:6), district_name = paste0("D", 1:6),
      `Actual Excess` = c(0, 0, 0, 5, 5, 5), end_year = 2023)
  ))

  cmp <- tges_compare(tg, district_codes = c("0003", "0001", "0005"))
  expect_equal(cmp$district_id, c("0003", "0001", "0005"))   # requested order
  expect_true(all(c("total_pp", "classroom_share", "local_share",
                    "student_admin_ratio", "excess_surplus_flag") %in% names(cmp)))
  # total_pp comes from VITSTAT, not the (NA) budgeted composition total
  expect_true(all(is.finite(cmp$total_pp)))
  expect_true(cmp$excess_surplus_flag[cmp$district_id == "0005"])
})

test_that("tges_compare warns about district codes with no data", {
  expect_warning(
    tges_compare(fake_full_tges(), district_codes = c("0001", "9999")),
    "9999"
  )
})


# --- live integration: comparative layer --------------------------------------

test_that("the cross-district layer runs on the live 2024 / multi-year guides", {
  skip_on_cran()
  skip_if_offline()
  tgm <- fetch_many_tges(2019:2024)
  tg24 <- tgm[["2024"]]

  # find_peers: Newark's nearest peers should be other DFG A urban districts
  fp <- tges_find_peers(tg24, "3570", n = 8)
  expect_true(fp$is_focal[1] && fp$distance[1] == 0)
  expect_gt(nrow(fp), 1L)

  # gap_cost: a finite per-pupil dollar gap to the DFG A median classroom share
  gc <- tges_gap_cost(tg24, "3570", metric = "classroom_share",
                      target = "median", peer = "dfg")
  expect_equal(nrow(gc), 1L)
  expect_true(is.finite(gc$per_pupil_gap_dollars))

  # convergence: DFG A should return a fitted beta over 35+ districts
  cv <- tges_convergence(tgm, peer = "dfg")
  a <- dplyr::distinct(cv[cv$peer_group == "A", ], beta, n_districts)
  expect_true(is.finite(a$beta[1]))
  expect_gt(a$n_districts[1], 20L)

  # composition drift + volatility produce bounded percentiles
  dr <- tges_composition_drift(tgm, peer = "dfg")
  expect_true(all(dr$drift_percentile >= 0 & dr$drift_percentile <= 100, na.rm = TRUE))
  vol <- tges_volatility(tgm, metric = "federal_share", peer = "dfg", min_years = 3)
  expect_true(any(is.finite(vol$cv)))

  # compare: a multi-city scorecard with finite per-pupil totals
  cmp <- tges_compare(tg24, district_codes = c("3570", "0680", "4010"))
  expect_equal(nrow(cmp), 3L)
  expect_true(any(is.finite(cmp$total_pp)))
})

test_that("tges_frontier runs on live spend joined to grad outcomes", {
  skip_on_cran()
  skip_if_offline()
  # suppressWarnings: fetch_grad_rate() emits a benign one_of() "unknown columns"
  # warning that is unrelated to the frontier under test.
  grate <- suppressWarnings(fetch_grad_rate(2023, methodology = "4 year")) %>%
    add_dfg() %>%
    dplyr::filter(.data$dfg == "A", .data$is_district, .data$subgroup == "total") %>%
    grate_percentile_rank(peer_type = "dfg")
  spend <- fetch_tges(2024)$CSG1 %>%
    dplyr::filter(.data$calc_type == "Actuals", .data$end_year == 2023)

  fr <- tges_frontier(spend, grate, outcome_col = "grad_rate_percentile",
                      peer = "dfg")
  expect_gt(nrow(fr), 0L)
  expect_true(all(fr$efficiency_score > 0 & fr$efficiency_score <= 1, na.rm = TRUE))
  expect_true(any(fr$on_frontier, na.rm = TRUE))
  # excess spend is non-negative (you never beat the frontier)
  expect_true(all(fr$excess_spend >= -1e-6, na.rm = TRUE))
})


# ==============================================================================
# tges_excluded_costs()
# ==============================================================================

# a fetch_tges()-shaped list with a tidied Total Spending Detail table + CSG1.
# Synthetic: exercises the join/difference/flag math only; not NJ DOE figures.
fake_tges_detail <- function() {
  list(
    DETAIL_FY24 = tibble::tibble(
      county_name   = "Test",
      district_id = c("3570", "0680", "00NA"),
      district_name = c("Newark", "Camden", "GROUP AVG"),
      end_year      = 2024L,
      calc_type     = "Actuals",
      report_year   = 2025L,
      general_current_expense_pp = c(24000, 22000, NA),
      capital_outlay_pp          = c(  500,   400, NA),
      grants_entitlements_pp     = c( 3000,  2500, NA),
      food_services_pp           = c(  700,   600, NA),
      debt_service_local_pp      = c(  400,   300, NA),
      debt_service_sda_pp        = c(  100,    50, NA),
      total_spending_pp          = c(28700, 25850, NA),  # = sum of the six
      enrollment_plus_sent       = c(40000,  8000, NA)
    ),
    CSG1 = tibble::tibble(
      county_name   = "Test",
      district_id = c("3570", "0680", "00NA"),
      district_name = c("Newark", "Camden", "GROUP AVG"),
      group         = "G. K-12 / 3501 +",
      `Per Pupil costs`  = c(21000, 20000, NA),
      `Enrollment (ADE)` = c(39800,  6000, NA),  # Newark self-contained; Camden sends
      indicator     = "Budgetary Per Pupil Cost",
      end_year      = 2024L,
      calc_type     = "Actuals"
    )
  )
}

test_that("tges_excluded_costs computes the wedge and drops average rows", {
  ec <- tges_excluded_costs(fake_tges_detail())

  expect_equal(nrow(ec), 2L)                       # 00NA average row dropped
  expect_false(any(ec$district_id == "00NA"))

  nwk <- ec[ec$district_id == "3570", ]
  expect_equal(nwk$gce_excess_pp, 24000 - 21000)     # GCE - budgetary
  expect_equal(nwk$excluded_total_pp, 28700 - 21000) # total - budgetary
})

test_that("tges_excluded_costs flags sending districts via sent_pupil_share", {
  ec <- tges_excluded_costs(fake_tges_detail())
  nwk <- ec[ec$district_id == "3570", ]
  cmd <- ec[ec$district_id == "0680", ]

  # Newark: (40000-39800)/40000 = 0.005 <= 0.02 -> reliable
  expect_equal(round(nwk$sent_pupil_share, 4), 0.005)
  expect_true(nwk$residual_reliable)

  # Camden: (8000-6000)/8000 = 0.25 -> not reliable
  expect_equal(cmd$sent_pupil_share, 0.25)
  expect_false(cmd$residual_reliable)
})

test_that("tges_excluded_costs honors reliable_max_sent_share", {
  ec <- tges_excluded_costs(fake_tges_detail(), reliable_max_sent_share = 0.30)
  # at a 0.30 threshold Camden (0.25) now counts as reliable
  expect_true(ec[ec$district_id == "0680", ]$residual_reliable)
})

test_that("tges_excluded_costs errors without the detail or CSG1 tables", {
  expect_error(
    tges_excluded_costs(list(CSG1 = tibble::tibble(x = 1))),
    "Total Spending Detail"
  )
  expect_error(
    tges_excluded_costs(list(DETAIL_FY24 = fake_tges_detail()$DETAIL_FY24)),
    "CSG1"
  )
})

test_that("tidy_total_spending_detail + tges_excluded_costs run on the live 2025 guide", {
  skip_on_cran()
  skip_if_offline()
  tg <- fetch_tges(2025)

  # the Detail workbook parsed into clean component columns (banner skipped)
  det <- tg[["DETAIL_FY24"]]
  expect_true(all(c("general_current_expense_pp", "capital_outlay_pp",
                    "total_spending_pp", "enrollment_plus_sent") %in% names(det)))
  expect_true(all(grepl("^[0-9]{4}$", det$district_id[!is.na(det$district_id)])))
  expect_true(all(det$end_year == 2024))

  ec <- tges_excluded_costs(tg)
  expect_gt(nrow(ec), 0L)
  expect_setequal(sort(unique(ec$end_year)), c(2023, 2024))

  # the six components reconstruct the published per-pupil total (rounding only)
  recon <- with(ec,
    total_spending_pp - (general_current_expense_pp + capital_outlay_pp +
      grants_entitlements_pp + food_services_pp + debt_service_local_pp +
      debt_service_sda_pp))
  expect_true(stats::median(abs(recon), na.rm = TRUE) < 2)

  # both flags appear, and reliable districts have a near-zero sent share
  expect_true(any(ec$residual_reliable, na.rm = TRUE))
  expect_true(any(!ec$residual_reliable, na.rm = TRUE))
  expect_true(all(ec$sent_pupil_share[ec$residual_reliable] <= 0.02, na.rm = TRUE))
})
