# ==============================================================================
# Constants for NJ School Data
# ==============================================================================
#
# This file centralizes magic numbers and codes used throughout the package.
#
# ==============================================================================

# -----------------------------------------------------------------------------
# School/District/County Code Constants
# -----------------------------------------------------------------------------

#' State aggregate indicator codes
#' Source: NJDOE IDEA-618 "District Rates" sheet, County Code column, Statewide
#' Total row (dev-docs/sped-phase-1-findings.md, verified live 2026-06-13).
#' @keywords internal
STATE_COUNTY_ID <- "99"

#' State aggregate indicator codes
#' Source: NJDOE publishes "9999" as the statewide district code, labelled as
#' such, across both of this package's oldest source families. Enrollment:
#' STAT_ENR.CSV (enrollment_0405.zip, SY2004-05 doedata release), DISTRICT
#' field, "9999-STATE TOTAL" on 33 rows (and "9999-COUNTY TOTAL" on 658 county
#' rows). Graduation: STAT_GRD.CSV (grd06, grd09), DISTRICT field,
#' "9999-NEW JERSEY" on 10 rows each; grd10 grd.xls, DIST CODE "9999" with
#' DIST NAME "STATE TOTAL"; and DISTRICT_ID "9999" ("STATE TOTAL") in every
#' ACGR / Cohort file 2011-2025. Also present as the statewide district code
#' in the NJDOE doedata staff-evaluation files (2014-2015; see this package's
#' CLAUDE.md "Valid Filter Values (staff evaluations...)").
#' @keywords internal
STATE_DISTRICT_ID <- "9999"

#' District total school code
#' Source: NJDOE publishes "999" as the district-total / statewide school code,
#' labelled as such. Enrollment: STAT_ENR.CSV (enrollment_0405.zip), SCHOOL
#' field, "999-DISTRICT TOTAL" on 8,909 rows and "999-STATE TOTAL" on 33.
#' Graduation: STAT_GRD.CSV (grd06, grd09) "999-STATE TOTAL"; grd10 grd.xls
#' SCH CODE "999" with SCH NAME "DISTRICT TOTAL"/"STATE TOTAL" (2,365 rows);
#' School Code "999" in every ACGR / Cohort file 2011-2025. Corroborated by the
#' Newark (county 13/district 3570) school_id "999" anchor verified against the
#' bundled NJ CDS->NCES crosswalk in tests/testthat/test-id-preservation.R.
#' @keywords internal
DISTRICT_TOTAL_SCHOOL_ID <- "999"

#' Alternative school code (used in some graduation files)
#' Source: literal raw school_id "997" matched in pre-2011 grad-count files
#' (R/tidy_graduation.R case_when, mapped to "districtwide").
#' @keywords internal
ALT_SCHOOL_ID <- "997"

#' Charter county code (all charters are assigned to county 80)
#' Source: NJDOE IDEA-618 "District Rates" sheet, county_id 80 = "Charters"
#' (dev-docs/sped-phase-1-findings.md, verified live 2026-06-13);
#' corroborated by the NJASK legacy layout's County_Code valid_values, where
#' numeric county code "80" tags the charter sector (R/fetch_nj_assess.R).
#' @keywords internal
CHARTER_COUNTY_ID <- "80"

# -----------------------------------------------------------------------------
# Program Code Constants
# -----------------------------------------------------------------------------

#' Program code for school/district totals
#' @keywords internal
TOTAL_PROGRAM_CODE <- "55"

#' Pre-K program codes
#' @keywords internal
PREK_PROGRAM_CODES <- c("PH", "PF", "01", "02")

#' Kindergarten program codes
#' @keywords internal
KINDER_PROGRAM_CODES <- c("KH", "KF", "03", "04")

# -----------------------------------------------------------------------------
# Aggregation Suffixes
# -----------------------------------------------------------------------------

#' Suffix for charter sector aggregations
#' @keywords internal
CHARTER_SECTOR_SUFFIX <- "C"

#' Suffix for all public aggregations
#' @keywords internal
ALLPUBLIC_SUFFIX <- "A"

#' Suffix for ward aggregations
#' @keywords internal
WARD_SUFFIX <- "W"

# -----------------------------------------------------------------------------
# Grade Level Constants
# -----------------------------------------------------------------------------

#' Elementary grades (K-5)
#' @keywords internal
ELEMENTARY_GRADES <- c("K", "01", "02", "03", "04", "05")

#' Middle school grades (6-8)
#' @keywords internal
MIDDLE_GRADES <- c("06", "07", "08")

#' High school grades (9-12)
#' @keywords internal
HIGH_SCHOOL_GRADES <- c("09", "10", "11", "12")

#' K-12 grades (excluding pre-K)
#' @keywords internal
K12_GRADES <- c("K", "01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12")

# -----------------------------------------------------------------------------
# Assessment Constants
# -----------------------------------------------------------------------------

#' PARCC/NJSLA performance levels
#' @keywords internal
PARCC_LEVELS <- c("L1", "L2", "L3", "L4", "L5")

#' Proficient levels (L4 and L5)
#' @keywords internal
PROFICIENT_LEVELS <- c("L4", "L5")

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------

#' Check if a school is a district total
#'
#' @param school_id School ID to check
#' @return Logical
#' @keywords internal
is_district_total <- function(school_id) {
  school_id %in% c(DISTRICT_TOTAL_SCHOOL_ID, ALT_SCHOOL_ID)
}

#' Check if a record is a state aggregate
#'
#' @param county_id County ID
#' @param district_id District ID
#' @return Logical
#' @keywords internal
is_state_aggregate <- function(county_id, district_id) {
  county_id == STATE_COUNTY_ID & district_id == STATE_DISTRICT_ID
}

#' Check if a district is a charter
#'
#' @param county_id County ID
#' @return Logical
#' @keywords internal
is_charter_district <- function(county_id) {
  county_id == CHARTER_COUNTY_ID
}
