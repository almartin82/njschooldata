# ==============================================================================
# Charter provenance, against the real NJ DOE sources
# ==============================================================================
#
# The offline contract lives in test-charter-provenance.R. These assertions
# check that the contract survives contact with the published files, and pin
# the NJ vocabulary itself so a source-side change is visible rather than
# silent. Live-gated: set NJSCHOOLDATA_LIVE_TESTS=true.
#
# Vocabulary evidence, measured 2026-08-10:
#   * fetch_enr(2019): all 842 rows whose LEA name contains "Charter" carry
#     county 80, and NO name-charter LEA sits outside county 80. County 80
#     additionally holds 768 rows whose names do not say "charter", so the code
#     is both stricter and broader than any name guess. NJ DOE labels the county
#     "Charters" in its own County column.
#   * The convention is VINTAGE-DEPENDENT: county 80 appears in enrollment only
#     from end_year 2010. In 2006-2009, charters carry their host county code
#     (01, 07, 13, 21, 25) and county 80 does not occur at all.
#   * fetch_certificated_staff(level = "state"): the STATE SUM row publishes no
#     county code in 2000-2002 and 2020-2026 (it publishes "99" in 2003-2008).
#   * fetch_staff_evaluations and the 2000-2008 certificated CSVs contain no
#     charter LEA at all -- 0 county-80 rows and 0 name-charter LEAs.
# ==============================================================================


test_that("live: NJ DOE codes the charter sector as county 80, and only county 80", {
  skip_if_no_live_tests()

  enr <- fetch_enr(2019, tidy = FALSE)
  name_says_charter <- grepl("charter", enr$district_name, ignore.case = TRUE)

  expect_gt(sum(name_says_charter), 0)
  # Every LEA the source NAMES as a charter is coded 80. If this ever fails,
  # county 80 has stopped being the charter sector and every is_charter
  # derivation in the package needs re-deriving, not patching.
  expect_true(all(enr$county_id[name_says_charter] == "80"))
  # And county 80 is broader than the name test -- the reason the code, not the
  # name, is the evidence.
  expect_gt(sum(enr$county_id == "80" & !name_says_charter), 0)
})


test_that("live: county 80 is absent before end_year 2010", {
  skip_if_no_live_tests()

  enr <- fetch_enr(2008, tidy = FALSE)
  name_says_charter <- grepl("charter", enr$district_name, ignore.case = TRUE)

  expect_gt(sum(name_says_charter), 0)
  expect_false(any(enr$county_id == "80", na.rm = TRUE))
  # Those charters carry a HOST county code, which is exactly why county 80 may
  # only ever be read as affirmative evidence and never as the sole denial.
  expect_true(all(enr$county_id[name_says_charter] != "80"))
})


test_that("live: charter host aggregation keeps a county-80 charter the roster missed", {
  skip_if_no_live_tests()

  enr <- fetch_enr(2026, tidy = FALSE)
  county_80 <- setdiff(unique(enr$district_id[enr$county_id == "80"]), "9999")
  unrostered <- setdiff(county_80, charter_city$district_id)

  skip_if(
    length(unrostered) == 0,
    "charter_city currently covers every county-80 LEA in this vintage"
  )

  hosted <- id_charter_hosts(enr[enr$district_id %in% unrostered, ])
  flags <- charter_flag_host_aware(hosted)

  # These are real NJ charters that the bundled host map has not caught up with.
  # Roster membership must never be able to deny them.
  expect_identical(flags, rep(TRUE, length(flags)))
})


test_that("live: certificated-staff STATE rows abstain, district rows answer", {
  skip_if_no_live_tests()

  for (end_year in c(2000, 2026)) {
    state <- fetch_certificated_staff(end_year, level = "state")
    expect_gt(nrow(state), 0)
    # NJ publishes no county code on the statewide row in these vintages, so
    # charter status is unknown. It used to ship as a fabricated FALSE.
    expect_true(all(is.na(state$county_id)))
    expect_true(all(is.na(state$is_charter)))
  }

  # 2003-2008 DO publish "99" on the statewide row: a published code is an
  # answer, and must stay a sourced FALSE rather than being swept into NA.
  state_2004 <- fetch_certificated_staff(2004, level = "state")
  expect_true(all(state_2004$county_id == "99"))
  expect_identical(unique(state_2004$is_charter), FALSE)
})


test_that("live: certificated-staff school rows agree with the county code exactly", {
  skip_if_no_live_tests()

  cert <- fetch_certificated_staff(2026, level = "school")

  expect_gt(sum(cert$county_id == "80", na.rm = TRUE), 0)
  # The flag IS the county code, row for row -- so a published code can never
  # be discarded into NA, and an absent one can never be invented into FALSE.
  expect_identical(cert$is_charter, cert$county_id == "80")
})


test_that("live: the pre-2010 certificated CSVs contain no charter sector at all", {
  skip_if_no_live_tests()

  cert <- fetch_certificated_staff(2008, level = "school")

  # Verified: NJ excludes charters from this file family entirely. Every FALSE
  # is therefore a real published county placement, not a guess.
  expect_false(any(cert$county_id == "80", na.rm = TRUE))
  expect_false(any(grepl("charter", cert$district_name, ignore.case = TRUE)))
  expect_identical(cert$is_charter, cert$county_id == "80")
})


test_that("live: statewide SPED by-disability rows abstain on charter status", {
  skip_if_no_live_tests()

  state <- fetch_sped(2025, level = "state")

  expect_gt(nrow(state), 0)
  expect_false("county_id" %in% names(state))
  # No county column means no charter evidence of any kind. Formerly FALSE.
  expect_true(all(is.na(state$is_charter)))
})


test_that("live: district SPED answers from the county code in both directions", {
  skip_if_no_live_tests()

  district <- fetch_sped(2025, level = "district")

  expect_gt(sum(district$is_charter %in% TRUE), 0)
  expect_gt(sum(district$is_charter %in% FALSE), 0)
  expect_identical(district$is_charter, district$county_id == "80")
})


test_that("live: legacy assessment carries county 80 and never a silent NA collapse", {
  skip_if_no_live_tests()

  assess <- fetch_old_nj_assess(2013, 4, tidy = TRUE)
  cc <- toupper(as.character(assess$county_code))

  expect_gt(sum(cc == "80", na.rm = TRUE), 0)
  expect_identical(assess$is_charter, cc == "80")
  # The aggregate encodings ("ST" statewide, DFG letters) are published codes
  # and stay sourced FALSE.
  expect_true("ST" %in% cc)
  expect_identical(unique(assess$is_charter[cc == "ST"]), FALSE)
})
