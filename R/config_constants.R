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
#' @keywords internal
STATE_COUNTY_ID <- "99"

#' State aggregate indicator codes
#' @keywords internal
STATE_DISTRICT_ID <- "9999"

#' District total school code
#' @keywords internal
DISTRICT_TOTAL_SCHOOL_ID <- "999"

#' Alternative school code (used in some graduation files)
#' @keywords internal
ALT_SCHOOL_ID <- "997"

#' Charter county code (all charters are assigned to county 80)
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
