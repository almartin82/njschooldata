# NJDOE Local Special Education Profiles, retrieved 2026-11-01.
# https://www.nj.gov/education/specialed/monitor/dataandresources/
# https://public.tableau.com/workbooks/SPPAPRLocalProfiles.twb?showVizHome=no
# Source labels: REPORT_YEAR 2023-2026, SCHOOL_YEAR 2021-22 through 2024-25.
# Complete statewide workbook is bundled, including the published state row.
# The CSV is a reproducible projection of IND_5C from its embedded Hyper table.

#' Fetch NJ IDEA Indicator 5C by LEA
#'
#' Reads NJDOE's published Local Special Education Profiles, indicator IND_5C:
#' students with IEPs ages 5 in kindergarten through 21 served in separate
#' schools, residential facilities, or homebound/hospital placements. This
#' reads the published profile rate, not a sum of rounded placement percentages.
#' Correctional facilities and parentally placed private students are not 5C
#' component settings. The profile's published denominator is retained without
#' substituting classification or public-IEP enrollment totals.
#'
#' end_year follows SCHOOL_YEAR, not REPORT_YEAR: report 2026 has school year
#' 2024-25 and is returned as end_year 2025. The complete NJDOE Tableau workbook
#' and a reproducible IND_5C projection are bundled and both are verified on
#' every call. No live fallback occurs. LOCAL is the displayed percent text;
#' nonnumeric markers such as N remain NA with source_value unchanged. No
#' unsuppressed hidden rate is substituted. State rows are included only where
#' present in the source (2025 in this snapshot), with the state's own 9999 id.
#'
#' @param end_year School year end, 2023 through 2025. 2026 is not published.
#' @return A tibble, one row per LEA, indicator and year, with district_id,
#'   district_name, indicator, value_pct (0-100), value_count, n_students
#'   (the published denominator), source_value, age_group, source_file,
#'   report_year, school_year, entity_level and definition. value_count is the
#'   published numerator. A marker prevents returning either count.
#' @export
#' @examples
#' fetch_sped_environment(2025)
#' subset(fetch_sped_environment(2024), district_id == "3570")
#' lapply(2023:2025, fetch_sped_environment)
fetch_sped_environment <- function(end_year) {
  .nj_landing_year(end_year, 2023:2025, "sped_environment")
  .nj_landing_artifact("environment-indicator5-definition")
  parent <- .nj_landing_artifact("environment-profiles")
  a <- .nj_landing_artifact("environment-5c-table")
  x <- utils::read.csv(a$path, colClasses = "character", na.strings = "",
                       check.names = FALSE, stringsAsFactors = FALSE)
  label <- sprintf("%d-%02d", end_year - 1L, end_year %% 100L)
  x <- x[x$SCHOOL_YEAR == label & !is.na(x$SCHOOL_YEAR), , drop = FALSE]
  # The source also includes county aggregates sharing district code 0000.
  # This interface returns LEAs and the published state row only.
  x <- x[x$DISTRICT_NAME != "County Level", , drop = FALSE]
  if (anyDuplicated(x[c("DISTRICT_CODE", "INDICATOR")] )) {
    stop("Duplicate LEA indicator rows in bundled profiles.", call. = FALSE)
  }
  rate <- .nj_landing_percent(x$LOCAL)$value
  count <- suppressWarnings(as.numeric(x$NUMERATOR))
  denominator <- suppressWarnings(as.numeric(x$DENOMINATOR))
  count[is.na(rate)] <- denominator[is.na(rate)] <- NA_real_
  tibble::tibble(
    end_year = as.integer(end_year), district_id = x$DISTRICT_CODE,
    district_name = x$DISTRICT_NAME, indicator = "5C",
    value_pct = rate, value_count = count, n_students = denominator,
    source_value = x$LOCAL, age_group = "5 in kindergarten through 21",
    source_file = parent$url, report_year = as.integer(x$REPORT_YEAR),
    school_year = x$SCHOOL_YEAR,
    entity_level = ifelse(x$DISTRICT_CODE == "9999", "state", "district"),
    definition = paste("Percent of students with IEPs ages 5 in kindergarten",
      "through 21 served in separate schools, residential facilities,",
      "or homebound/hospital placements.")
  )
}
