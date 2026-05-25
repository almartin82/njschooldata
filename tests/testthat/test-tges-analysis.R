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
    district_code = codes,
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
      district_code = c("3570", "0680"),
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
  expect_setequal(comp$district_code, c("3570", "0680"))

  # category columns present
  expect_true(all(c("budgetary_pp", "classroom", "administration",
                    "total_pp", "classroom_share", "administration_share")
                  %in% names(comp)))

  nwk <- comp[comp$district_code == "3570", ]
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
    district_code = c("0001", "0002", "0003", "0004"),
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
  r <- r[order(r$district_code), ]
  expect_equal(r$peer_percentile, c(25, 50, 75, 100))  # rank/n * 100
  expect_equal(unique(r$peer_n), 4L)
})

test_that("tges_percentile_rank drops average rows and honors prefix", {
  df <- tibble::tibble(
    county_name   = "X",
    district_code = c("0001", "0002", "00NA"),
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
  df <- tibble::tibble(district_code = "0001", group = "G", end_year = 2024)
  expect_error(tges_percentile_rank(df, metric_col = "nope"), "not found")
})


# --- tges_efficiency -----------------------------------------------------------

test_that("tges_efficiency joins spend to outcome and labels quadrants", {
  spend <- tibble::tibble(
    county_name   = "X",
    district_code = c("0001", "0002", "0003", "0004"),
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
  eff <- eff[order(eff$district_code), ]
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
    district_code = "0001", group = "G",
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
  nwk <- comp[comp$district_code == "3570" & comp$end_year == 2024, ]
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
  nwk <- r[r$district_code == "3570" & r$end_year == 2024, ]
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
    district_code = codes,
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

  nwk <- rm[rm$district_code == "3570", ]
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
    district_code = c("3570", "3570"),
    district_name = "Newark",
    `Budgeted General Fund Balance` = c(120, 120),
    Actual = c(100, 60),
    end_year = c(2022, 2023)
  )
  csg21 <- tibble::tibble(
    group = "G", county_name = "X",
    district_code = c("3570", "3570"),
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

  nwk <- fe[fe$district_code == "3570", ]
  expect_equal(nwk$baseline_federal_share, 0.05)   # mean of 2018,2019
  expect_equal(nwk$peak_federal_share, 0.12)       # max over esser years
  expect_equal(round(nwk$federal_bump, 3), 0.07)
  expect_equal(round(nwk$pp_growth, 3), 0.3)       # 26000/20000 - 1
  expect_true(nwk$cliff_exposure)

  cmd <- fe[fe$district_code == "0680", ]          # flat spend, small bump
  expect_false(cmd$cliff_exposure)
})


# --- tges_staffing -------------------------------------------------------------

test_that("tges_staffing merges personnel tables to one row per district-year", {
  mk_personnel <- function(ratio_name, ratio, sal_name = NULL, sal = NULL) {
    df <- tibble::tibble(
      group = "G", county_name = "X",
      district_code = c("3570", "0680"),
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
      district_code = c("3570", "0680"),
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
  nwk <- st[st$district_code == "3570", ]
  expect_equal(nwk$student_admin_ratio, 80)
  expect_equal(nwk$benefits_pct_salary, 0.30)
})


# --- tges_red_flags ------------------------------------------------------------

# 10-district fixture so deciles are clean (percentiles 10,20,...,100)
fake_scan_tges <- function() {
  codes <- sprintf("%04d", 1:10)
  mk <- function(indicator, vals) tibble::tibble(
    group = "G", county_name = "X",
    district_code = codes, district_name = codes,
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
  hi <- tges_red_flags(fake_scan_tges(), district_code = "0010",
                       peer = "tges_group")
  expect_true(all(c("indicator", "value", "peer_percentile", "peer_n",
                    "higher_means", "flag") %in% names(hi)))
  expect_equal(hi$flag[hi$indicator == "Budgetary per-pupil cost"], "top decile")
  expect_equal(hi$flag[hi$indicator == "Classroom share of budget"], "bottom decile")

  # district 0001 is the lowest spender -> bottom-decile cost, top-decile share
  lo <- tges_red_flags(fake_scan_tges(), district_code = "0001",
                       peer = "tges_group")
  expect_equal(lo$flag[lo$indicator == "Budgetary per-pupil cost"], "bottom decile")
  expect_equal(lo$flag[lo$indicator == "Classroom share of budget"], "top decile")

  # a middle district has no extremes; only_flagged filters them all out
  mid_full <- tges_red_flags(fake_scan_tges(), district_code = "0005",
                             peer = "tges_group", only_flagged = FALSE)
  mid_flagged <- tges_red_flags(fake_scan_tges(), district_code = "0005",
                                peer = "tges_group", only_flagged = TRUE)
  expect_gt(nrow(mid_full), nrow(mid_flagged))
  expect_true(any(is.na(mid_full$flag)))
})


# --- tges_real_growth ----------------------------------------------------------

test_that("tges_real_growth splits per-pupil growth into cost vs enrollment", {
  csg1aa <- tibble::tibble(
    county_name   = "X",
    district_code = c("3570", "3570", "3570"),
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
    county_name = "X", district_code = c("3570", "3570"),
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
  nwk <- rm[rm$district_code == "3570", ]
  expect_equal(nrow(nwk), 1L)
  expect_true(is.finite(nwk$local_pp) && nwk$local_pp > 0)
  # shares should land near 1 (rounding); allow slack
  s <- nwk$local_share + nwk$state_share + nwk$federal_share +
    nwk$tuition_share + nwk$free_balance_share + nwk$other_share
  expect_gt(s, 0.95); expect_lt(s, 1.05)

  fb <- tges_fund_balance_health(tg)
  expect_true(all(c("excess_unreserved", "excess_surplus_flag") %in% names(fb)))
  expect_true(any(fb$district_code == "3570"))

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
    group = "G", county_name = "X", district_code = "3570",
    district_name = "Newark",
    `Budgeted General Fund Balance` = 120, Actual = 100, end_year = 2023
  )
  fb20 <- tges_fund_balance_health(list(CSG20 = csg20))
  expect_true("fund_balance_variance" %in% names(fb20))
  expect_false("excess_unreserved" %in% names(fb20))
  expect_equal(fb20$fund_balance_variance, -20)

  csg21 <- tibble::tibble(
    group = "G", county_name = "X", district_code = "3570",
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
  expect_error(tges_red_flags(fake_scan_tges(), district_code = "9999"),
               "No indicators")
})

test_that("tges_red_flags carries direction and percentile bounds", {
  rf <- tges_red_flags(fake_scan_tges(), district_code = "0007",
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
    county_name = "X", district_code = "3570", district_name = "Newark",
    `Total Expenditures, actual costs`          = c(1000, 1100),
    `Average Daily Enrollment plus Sent Pupils` = c(100, 100),
    `Per Pupil Total Expenditures`              = c(10, 11),
    end_year = c(2021, 2022), calc_type = "Actuals"
  )
  r2 <- tibble::tibble(
    county_name = "X", district_code = "3570", district_name = "Newark",
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

test_that("tges_red_flags requires a district_code", {
  expect_error(tges_red_flags(fake_scan_tges()), "district_code")
})

test_that("tges_red_flags scans whatever indicator tables are present", {
  # only CSG1 present: composition cannot build classroom/admin shares, so only
  # the budgetary indicator is scanned and the function still returns it.
  codes <- sprintf("%04d", 1:10)
  only1 <- list(CSG1 = tibble::tibble(
    group = "G", county_name = "X", district_code = codes, district_name = codes,
    `Per Pupil costs` = seq(10000, 28000, by = 2000), `District rank` = 1:10,
    indicator = "Budgetary Per Pupil Cost", end_year = 2024, calc_type = "Budgeted"
  ))
  rf <- tges_red_flags(only1, district_code = "0010", peer = "tges_group",
                       only_flagged = FALSE)
  expect_true("Budgetary per-pupil cost" %in% rf$indicator)
  expect_false("Classroom share of budget" %in% rf$indicator)
})

test_that("tges_fund_balance_health honors the years filter", {
  csg20 <- tibble::tibble(
    group = "G", county_name = "X", district_code = c("3570", "3570"),
    district_name = "Newark",
    `Budgeted General Fund Balance` = c(120, 120), Actual = c(100, 60),
    end_year = c(2022, 2023)
  )
  fb <- tges_fund_balance_health(list(CSG20 = csg20), years = 2023)
  expect_equal(unique(fb$end_year), 2023)
})

test_that("tges_staffing honors years and skips tables lacking mapped columns", {
  mk <- function(yr) tibble::tibble(
    group = "G", county_name = "X", district_code = c("3570", "0680"),
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
      group = "G", district_code = "3570", end_year = 2024))),
    "personnel"
  )
})

test_that("tges_real_growth: missing cols, pp fallback, deflator check, years", {
  # missing total-expenditure / ADE columns
  expect_error(
    tges_real_growth(list(CSG1AA_AVGS = tibble::tibble(
      county_name = "X", district_code = "3570", district_name = "Newark",
      end_year = 2023))),
    "total expenditures"
  )

  # no "Per Pupil Total Expenditures" column -> per_pupil computed as exp / ADE
  no_pp <- tibble::tibble(
    county_name = "X", district_code = "3570", district_name = "Newark",
    `Total Expenditures, actual costs`          = c(1000, 1100),
    `Average Daily Enrollment plus Sent Pupils` = c(100, 100),
    end_year = c(2022, 2023), calc_type = "Actuals"
  )
  rg <- tges_real_growth(list(CSG1AA_AVGS = no_pp))
  expect_equal(rg$per_pupil[rg$end_year == 2022], 10)
  expect_equal(rg$per_pupil[rg$end_year == 2023], 11)

  good <- tibble::tibble(
    county_name = "X", district_code = "3570", district_name = "Newark",
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
