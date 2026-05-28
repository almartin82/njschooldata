# Tests for multi-campus charter host-city apportionment (GitHub issue #104).
#
# These are deterministic / offline: they exercise the bundled
# `charter_host_apportionment` table and the share-weighted host resolution in
# `id_charter_hosts()` against small, clearly-commented SYNTHETIC inputs. The
# synthetic n_students values are TEST-ONLY logic inputs (they verify the
# apportionment math) and are never saved to data/. Real METS totals come from
# NJ DOE; only the Jersey-City-vs-Newark allocation is a documented placeholder.

library(dplyr)

# ---------------------------------------------------------------------------
# Apportionment table integrity
# ---------------------------------------------------------------------------

test_that("apportionment shares sum to 1.0 per district_id per end_year", {
  totals <- charter_host_apportionment %>%
    group_by(district_id, end_year) %>%
    summarize(total_share = sum(share), .groups = "drop")

  expect_true(all(abs(totals$total_share - 1.0) < 1e-9))
})


test_that("apportionment table has expected columns and types", {
  expect_true(all(c(
    "district_id", "end_year",
    "host_county_id", "host_county_name",
    "host_district_id", "host_district_name",
    "share", "share_basis"
  ) %in% names(charter_host_apportionment)))

  expect_type(charter_host_apportionment$share, "double")
  expect_type(charter_host_apportionment$end_year, "integer")
})


test_that("each district_id/end_year/host_district_id row is unique", {
  key <- charter_host_apportionment[
    c("district_id", "end_year", "host_district_id")
  ]
  expect_equal(sum(duplicated(key)), 0)
})


test_that("METS (6068) splits 0.5 Jersey City + 0.5 Newark from 2018", {
  mets_2018 <- charter_host_apportionment %>%
    filter(district_id == "6068", end_year == 2018) %>%
    arrange(host_district_name)

  expect_equal(nrow(mets_2018), 2)
  expect_equal(mets_2018$host_district_name, c("Jersey City", "Newark"))
  expect_equal(mets_2018$share, c(0.5, 0.5))
  expect_equal(sort(mets_2018$host_district_id), c("2390", "3570"))

  # pre-Newark years are 100% Jersey City
  mets_2016 <- charter_host_apportionment %>%
    filter(district_id == "6068", end_year == 2016)
  expect_equal(nrow(mets_2016), 1)
  expect_equal(mets_2016$host_district_name, "Jersey City")
  expect_equal(mets_2016$share, 1.0)
})


# ---------------------------------------------------------------------------
# id_charter_hosts() share-weighted expansion
# ---------------------------------------------------------------------------

test_that("id_charter_hosts no longer errors on a multi-host charter", {
  # synthetic METS row (TEST-ONLY): the multi-host charter used to fail the
  # old row-count guard. It must now expand without error.
  synth <- tibble::tibble(
    end_year    = 2018L,
    district_id = "6068",
    county_id   = "80",
    n_students  = 1000
  )

  expect_silent(res <- id_charter_hosts(synth))
  expect_s3_class(res, "data.frame")
  # expanded into two host-city rows
  expect_equal(nrow(res), 2)
  expect_true(all(c("share", "is_apportioned") %in% names(res)))
  expect_true(all(res$is_apportioned))
  expect_equal(sort(res$host_district_name), c("Jersey City", "Newark"))
})


test_that("id_charter_hosts leaves single-host charters and the row count alone", {
  # 6082 = BelovED Community Charter School, single host (Jersey City).
  synth <- tibble::tibble(
    end_year    = 2018L,
    district_id = "6082",
    county_id   = "80",
    n_students  = 300
  )

  res <- id_charter_hosts(synth)
  expect_equal(nrow(res), 1)
  expect_equal(res$host_district_name, "Jersey City")
  expect_equal(res$share, 1.0)
  expect_false(res$is_apportioned)
})


test_that("id_charter_hosts is year-aware: pre-2018 METS is Jersey City only", {
  synth <- tibble::tibble(
    end_year    = 2016L,
    district_id = "6068",
    county_id   = "80",
    n_students  = 800
  )

  res <- id_charter_hosts(synth)
  expect_equal(nrow(res), 1)
  expect_equal(res$host_district_name, "Jersey City")
  expect_equal(res$share, 1.0)
})


test_that("apportionment preserves enrollment per original charter row", {
  # synthetic METS totals (TEST-ONLY): the share-weighted sum across host cities
  # MUST equal the original NJ-reported total.
  synth <- tibble::tibble(
    end_year    = c(2018L, 2016L),
    district_id = c("6068", "6068"),
    county_id   = c("80", "80"),
    n_students  = c(1000, 800)
  )

  res <- id_charter_hosts(synth)

  preserved <- res %>%
    group_by(end_year, district_id) %>%
    summarize(weighted_total = sum(n_students * share), .groups = "drop")

  expect_equal(
    preserved$weighted_total[preserved$end_year == 2018L], 1000
  )
  expect_equal(
    preserved$weighted_total[preserved$end_year == 2016L], 800
  )
})


# ---------------------------------------------------------------------------
# charter_sector_enr_aggs() end-to-end enrollment preservation
# ---------------------------------------------------------------------------

test_that("charter_sector_enr_aggs splits METS 50/50 and preserves the total", {
  # synthetic 2018 charter enrollment (TEST-ONLY logic input):
  #   METS (6068) = 1000 students, BelovED (6082) = 300 students.
  # Both are district-level rollups (school_id 999) in county 80.
  synth <- tibble::tibble(
    end_year      = 2018L,
    county_id     = "80",
    county_name   = "Charters",
    district_id   = c("6068", "6082"),
    district_name = c("M.E.T.S. CHARTER SCHOOL", "BelovED Community Charter School"),
    school_id     = "999",
    school_name   = "x",
    program_code  = "55",
    program_name  = "All Students",
    grade_level   = "TOTAL",
    subgroup      = "total_enrollment",
    n_students    = c(1000, 300),
    pct_total_enr = 1,
    is_state = FALSE, is_county = FALSE, is_district = TRUE, is_school = FALSE,
    is_charter = TRUE, is_charter_sector = FALSE, is_allpublic = FALSE,
    is_citywide = FALSE, is_subprogram = FALSE
  )

  aggs <- charter_sector_enr_aggs(synth) %>%
    filter(subgroup == "total_enrollment", grade_level == "TOTAL")

  newark <- aggs %>% filter(district_name == "Newark Charters")
  jersey <- aggs %>% filter(district_name == "Jersey City Charters")

  # METS half goes to Newark
  expect_equal(newark$n_students, 500)
  expect_equal(newark$n_schools, 0.5)

  # METS half + all of BelovED goes to Jersey City
  expect_equal(jersey$n_students, 800)
  expect_equal(jersey$n_schools, 1.5)

  # grand total preserved: 1000 (METS) + 300 (BelovED)
  expect_equal(sum(aggs$n_students), 1300)
})
