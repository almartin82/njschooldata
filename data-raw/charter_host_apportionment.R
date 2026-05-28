# Build script for the `charter_host_apportionment` package dataset.
#
# WHAT THIS IS
# ------------
# `charter_city` is a 1:1 map from a charter's NJ DOE `district_id` to a single
# host district/city. That works for the overwhelming majority of charters, but
# NJ DOE assigns ONE `district_id` per charter and does NOT report charter
# *campuses* separately. A handful of charters operate campuses in more than one
# host city under a single `district_id`. For those, attributing 100% of the
# charter's enrollment to one host city overstates that city's charter sector and
# erases the other host city entirely (GitHub issue #104).
#
# `charter_host_apportionment` is a year-aware companion table that splits a
# multi-campus charter's NJ-reported totals across its host cities by a `share`
# fraction. Single-city charters need NO entry here (their implicit share is 1.0
# via `charter_city`). Multi-city charters get N rows per `end_year` whose
# `share` values sum to 1.0.
#
# FABRICATION BOUNDARY (read repo CLAUDE.md)
# ------------------------------------------
# The charter TOTAL enrollment is REAL NJ DOE data. Only the *allocation* of that
# real total across host cities is an explicit, documented apportionment, used
# ONLY because NJ does not report charter campuses separately. This is
# apportionment of real data (analogous to interpolation between known points),
# NOT fabrication. To keep it transparent:
#   * every share lives in this inspectable table,
#   * the `share_basis` column documents WHY each share has the value it does,
#   * a 0.5/0.5 split is an explicit PLACEHOLDER, never an NJ-reported campus count.
# NO campus-level enrollment numbers are invented anywhere.
#
# VERIFIED MULTI-CITY CHARTERS ADDED
# ----------------------------------
# M.E.T.S. CHARTER SCHOOL (district_id 6068)
#   * NJ DOE reports it under the single district_id 6068, mapped in
#     `charter_city` to Jersey City (host_district_id 2390).
#   * It opened a second campus in Newark (host_district_id 3570) in 2017; the
#     NJ DOE enrollment file shows a single school_id (951) plus the district
#     rollup (999) in every year -- i.e. the two campuses are never reported
#     separately -- and total enrollment jumps from ~1,028 (2017) to ~1,504
#     (2018), consistent with the Newark campus coming online.
#   * Year model: through 2017 METS operated only the Jersey City campus, so its
#     host share is 100% Jersey City (no apportionment row needed -- but we add
#     an explicit 1.0 Jersey City row for those years so the table is
#     self-documenting and the year dimension is exercised). From 2018 onward we
#     split 50/50 Jersey City / Newark as a documented PLACEHOLDER, because NJ
#     does not report the campuses separately and no campus-level count exists.
#
# CANDIDATES INVESTIGATED BUT NOT ADDED (unverifiable -> documented, not guessed)
# ------------------------------------------------------------------------------
# KIPP TEAM Academy Charter School / KIPP Paterson (district_id 7325)
#   * KIPP New Jersey operates schools in Newark, Camden AND Paterson, and the
#     issue flagged that a Paterson campus "probably has the same problem."
#   * BUT the current NJ DOE school directory (fetch_directory()) shows district
#     7325 = TEAM Academy Charter School with its school located in NEWARK only,
#     and shows NO KIPP school in Paterson reporting under 7325 (KIPP Paterson
#     Prep was founded Aug 2023 and does not appear under 7325 in NJ DOE data).
#   * KIPP's Camden schools report under a DIFFERENT NJ district (1799, "KIPP:
#     Cooper Norcross"), i.e. KIPP uses separate charters per region. There is no
#     NJ DOE evidence that the Paterson campus reports under 7325's district_id.
#   * Per the fabrication boundary, we CANNOT trace a Paterson campus to district
#     7325 in NJ DOE data, so KIPP TEAM/Paterson is left as a documented CANDIDATE
#     rather than guessed. If/when NJ DOE enrollment shows Paterson enrollment
#     under 7325 (or a confirmed share), add a year-aware row here.
#
# RE-RUN: source this file from the package root, e.g.
#   Rscript data-raw/charter_host_apportionment.R

library(dplyr)

root <- tryCatch(
  rprojroot::find_root(rprojroot::has_file("DESCRIPTION")),
  error = function(e) "."
)

# ---------------------------------------------------------------------------
# Apportionment rows. `share` must sum to 1.0 per (district_id, end_year).
# `share_basis` documents the provenance of each share so consumers can tell a
# PLACEHOLDER split apart from any future NJ-grounded one.
# ---------------------------------------------------------------------------

# METS Jersey-City-only years (single campus, pre-Newark). Explicit 1.0 rows so
# the year dimension is self-documenting.
mets_pre_newark <- tibble::tibble(
  district_id        = "6068",
  end_year           = 2013:2017,
  host_county_id     = "17",
  host_county_name   = "Hudson",
  host_district_id   = "2390",
  host_district_name = "Jersey City",
  share              = 1.0,
  share_basis        = "single Jersey City campus (Newark campus not yet open)"
)

# METS two-campus years (Newark campus open). 50/50 documented PLACEHOLDER.
mets_two_campus <- tibble::tribble(
  ~end_year, ~host_county_id, ~host_county_name, ~host_district_id, ~host_district_name, ~share,
  # Jersey City campus
  2018, "17", "Hudson", "2390", "Jersey City", 0.5,
  2019, "17", "Hudson", "2390", "Jersey City", 0.5,
  # Newark campus (opened 2017)
  2018, "13", "Essex",  "3570", "Newark",      0.5,
  2019, "13", "Essex",  "3570", "Newark",      0.5
) %>%
  mutate(
    district_id = "6068",
    share_basis = "PLACEHOLDER 50/50 split; NJ does not report METS campuses separately"
  )

charter_host_apportionment <- bind_rows(mets_pre_newark, mets_two_campus) %>%
  select(
    district_id, end_year,
    host_county_id, host_county_name,
    host_district_id, host_district_name,
    share, share_basis
  ) %>%
  mutate(end_year = as.integer(end_year)) %>%
  arrange(district_id, end_year, host_district_id)

# ---------------------------------------------------------------------------
# Validation: shares must sum to exactly 1.0 per (district_id, end_year).
# ---------------------------------------------------------------------------
share_check <- charter_host_apportionment %>%
  group_by(district_id, end_year) %>%
  summarize(total_share = sum(share), .groups = "drop")

stopifnot(all(abs(share_check$total_share - 1.0) < 1e-9))

# Each (district_id, end_year, host_district_id) must be unique.
stopifnot(
  !any(duplicated(charter_host_apportionment[
    c("district_id", "end_year", "host_district_id")
  ]))
)

print(charter_host_apportionment, n = Inf)

save(
  charter_host_apportionment,
  file = file.path(root, "data", "charter_host_apportionment.rda")
)

message("Wrote data/charter_host_apportionment.rda with ",
        nrow(charter_host_apportionment), " rows.")
