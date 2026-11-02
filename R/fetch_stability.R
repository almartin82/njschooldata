#' Fetch NJ high school cohort persistence
#'
#' Reads state-published high school persistence from bundled text extracts of
#' the 2023-24 and 2024-25 School Performance Reports school databases.
#' NJDOE defines it as the percentage of students
#' in a graduation cohort who either graduated with a state-endorsed diploma
#' or remained enrolled six years after entering high school. This is a
#' cohort-persistence proxy, not annual same-school stability, mobility or
#' fall-to-fall attrition. The definition is repeated in every row.
#'
#' The 2024-25 accountability release uses Cohort 2022 six-year data from
#' 2023-24. It is distinct from the current-cohort persistence in the
#' GraduationCohortProfile sheet. Groups with fewer than 10 students are
#' unavailable; accountability calculations require at least 20 students.
#' Published markers are retained in source_value. Specialized receiving
#' schools are attributed to sending schools for accountability, per the
#' SPR Reference Guide. No count or annual retention rate is inferred.
#' The 2023-24 six-year profile names its measure HighSchoolPersistance;
#' the 2024-25 profile names it Persisting. Those current-cohort rows are kept
#' separately from HS Persistence accountability rows by measure and period.
#'
#' @param end_year Report school year end, 2024 or 2025.
#' @return A tibble with end_year, entity_level, district_id, school_id,
#'   district_name, school_name, measure, student_group, value (percent),
#'   source_value, value_lo, value_hi, numerator, denominator, period,
#'   count_date, definition and source_file. Counts are unpublished and NA.
#' @export
#' @examples
#' x <- fetch_stability(2025)
#' subset(x, student_group == "Students with Disabilities")
#' subset(x, district_id == "3570", select = c(school_name, student_group, value))
fetch_stability <- function(end_year) {
  .nj_landing_year(end_year, 2024:2025, "stability")
  .nj_landing_artifact("spr-reference-guide")
  sheet <- if (end_year == 2024L) "6YrGraduationCohortProfile" else "GraduationCohortProfile"
  profile <- .nj_landing_spr_extract(sheet, end_year)
  source <- attr(profile, "source_file")
  if (end_year == 2025L) profile <- profile[profile$CohortType %in% "6-Year", ]
  profile <- profile[!is.na(profile$DistrictCode) &
    tolower(profile$StudentGroup) %in% c("schoolwide", "all students", "students with disabilities"), ]
  profile$Indicator <- if (end_year == 2024L) "HighSchoolPersistance" else "Persisting"
  profile$IndicatorPerformance <- if (end_year == 2024L) profile$HighSchoolPersistance else profile$Persisting_School
  profile$period <- sprintf("Cohort %d, six-year outcomes in %d-%02d", end_year - 2L, end_year - 1L, end_year %% 100L)
  x <- profile
  if (end_year == 2025L) {
    targets <- .nj_landing_spr("HSPersistenceTargets")
    targets <- targets[targets$StudentGroup %in% c("All Students", "Students with Disabilities"), ]
    targets$period <- "Cohort 2022, six-year outcomes in 2023-24; 2024-25 accountability"
    cols <- c("DistrictCode", "SchoolCode", "DistrictName", "SchoolName",
              "Indicator", "StudentGroup", "IndicatorPerformance", "period")
    x <- rbind(profile[cols], targets[cols])
  }
  rates <- .nj_landing_percent(x$IndicatorPerformance)
  tibble::tibble(
    end_year = as.integer(end_year), entity_level = "school",
    district_id = x$DistrictCode, school_id = x$SchoolCode,
    district_name = x$DistrictName, school_name = x$SchoolName,
    measure = x$Indicator, student_group = x$StudentGroup,
    value = rates$value, source_value = x$IndicatorPerformance,
    value_lo = rates$lo, value_hi = rates$hi,
    numerator = NA_real_, denominator = NA_real_, count_date = NA_character_,
    period = x$period,
    definition = paste("Percentage of students in a graduation cohort who either",
      "graduated with a state-endorsed diploma or remained enrolled six years",
      "after entering high school."),
    source_file = source
  )
}
