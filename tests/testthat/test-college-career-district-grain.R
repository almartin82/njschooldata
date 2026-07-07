# ==============================================================================
# District-level column mapping for the college/career SPR fetchers
# ==============================================================================
#
# Regression coverage for the district-grain (level = "district") path of the
# three college/career fetchers whose district SPR sheets spell their value
# columns differently than the school workbook:
#
#   * fetch_sat_performance      (PSAT-SAT-ACTPerformance: district_avg / bt_pct)
#   * fetch_cte_participation    (CTEParticipationByStudentGroup:
#                                 district_cteparticipants for 2020-2024)
#   * fetch_industry_credentials (IndustryValuedCredentialsEarned:
#                                 students_enrolled for 2018-2024)
#
# Before the district column mapping was added, these threw
# "Can't rename columns that don't exist" for most years at level = "district".
# The school workbook already used the standardized carrier names, so the school
# path is unaffected and is not re-tested here.
#
# The SPR source is fetched over the network (and disk-cached by fetch_spr_data).
# If the NJ DOE SPR source is unreachable these tests SKIP; they never fail on a
# network problem.

# Fetch one district-grain year per fetcher once and reuse. If the SPR source is
# unreachable, have_data stays FALSE and every test below skips.
cc_probe <- tryCatch(
  list(
    sat  = fetch_sat_performance(2023, level = "district"),
    cte  = fetch_cte_participation(2023, level = "district"),
    cred = fetch_industry_credentials(2023, level = "district")
  ),
  error = function(e) NULL
)
have_data <- !is.null(cc_probe) &&
  all(vapply(cc_probe, function(x) is.data.frame(x) && nrow(x) > 0, logical(1)))

# Years each sheet is published at district grain (source coverage):
#   SAT performance:      2017-2025 (all years)
#   CTE participation:    2019-2025 (sheet absent 2017-2018)
#   Industry credentials: 2018-2025 (the enrollment column is absent in 2017)
sat_years  <- 2017:2025
cte_years  <- 2019:2025
cred_years <- 2018:2025


test_that("fetch_sat_performance parses every year at district grain", {
  skip_if_not(have_data, "NJ DOE SPR source unavailable")

  for (y in sat_years) {
    df <- fetch_sat_performance(y, level = "district")
    expect_s3_class(df, "data.frame")
    expect_true(sum(df$is_district, na.rm = TRUE) > 0,
                info = paste("SAT performance district rows, year", y))
    expect_true(all(c("school_avg", "state_avg",
                      "pct_benchmark", "state_pct_benchmark") %in% names(df)),
                info = paste("SAT performance columns, year", y))
  }
})

test_that("fetch_cte_participation parses every published year at district grain", {
  skip_if_not(have_data, "NJ DOE SPR source unavailable")

  for (y in cte_years) {
    df <- fetch_cte_participation(y, level = "district")
    expect_s3_class(df, "data.frame")
    expect_true(sum(df$is_district, na.rm = TRUE) > 0,
                info = paste("CTE district rows, year", y))
    expect_true(sum(df$is_state, na.rm = TRUE) > 0,
                info = paste("CTE state row, year", y))
    expect_true(all(c("cte_participants", "cte_concentrators",
                      "state_cte_participants") %in% names(df)),
                info = paste("CTE columns, year", y))
  }
})

test_that("fetch_industry_credentials parses every published year at district grain", {
  skip_if_not(have_data, "NJ DOE SPR source unavailable")

  for (y in cred_years) {
    df <- fetch_industry_credentials(y, level = "district")
    expect_s3_class(df, "data.frame")
    expect_true(sum(df$is_district, na.rm = TRUE) > 0,
                info = paste("credentials district rows, year", y))
    expect_true(sum(df$is_state, na.rm = TRUE) > 0,
                info = paste("credentials state row, year", y))
    expect_true(all(c("students_enrolled", "earned_one_credential",
                      "credentials_earned") %in% names(df)),
                info = paste("credentials columns, year", y))
  }
})

test_that("latest-year district output carries non-empty key columns", {
  skip_if_not(have_data, "NJ DOE SPR source unavailable")

  sat <- fetch_sat_performance(2025, level = "district")
  expect_true(any(!is.na(sat$school_avg[sat$is_district])))
  expect_true(any(!is.na(sat$state_avg)))

  cte <- fetch_cte_participation(2025, level = "district")
  expect_true(any(!is.na(cte$cte_participants[cte$is_district])))

  cred <- fetch_industry_credentials(2025, level = "district")
  expect_true(any(!is.na(cred$students_enrolled[cred$is_district])))
})

test_that("district value columns wire to district (not state) values", {
  skip_if_not(have_data, "NJ DOE SPR source unavailable")

  # district_id 3880 is a real district with a high school; the mapped
  # district-grain value must equal the raw district column, and the is_state
  # row must equal the state column (state row carries the state value, not NA).
  raw <- njschooldata::fetch_spr_data(
    "CTEParticipationByStudentGroup", 2023, "district"
  )
  mapped <- fetch_cte_participation(2023, level = "district")

  raw_d <- raw$district_cteparticipants[
    raw$district_id == "3880" & raw$subgroup == "total population"
  ]
  map_d <- mapped$cte_participants[
    mapped$district_id == "3880" & mapped$subgroup == "total population"
  ]
  expect_equal(map_d, raw_d)

  raw_state <- unique(raw$state_cteparticipants[
    raw$is_state & raw$subgroup == "total population"
  ])
  map_state <- unique(mapped$cte_participants[
    mapped$is_state & mapped$subgroup == "total population"
  ])
  expect_equal(map_state, raw_state)
})
