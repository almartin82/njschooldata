# ==============================================================================
# Advanced-Coursework Access & Equity
# ==============================================================================
#
# A single front door, fetch_advanced_course_access(), over three School
# Performance Report (SPR) sheet families that together answer the rigor-access /
# tracking-equity question - not "how many students took AP" (already covered by
# fetch_ap_participation()), but "does the school even OFFER advanced courses, who
# gets into AP/IB/dual-enrollment by student group, and how many students reach a
# Structured Learning Experience (SLE)":
#
#   type = "courses_offered"        -> APIBCoursesOffered  (2017-2024)
#                                      ABIBCoursesOffered   (2025; the A-B-IB typo
#                                      is the real 2025 sheet name)
#                                      One row per school per advanced course.
#
#   type = "participation_by_group" -> APIBDualEnrPartByStudentGrp (2021-2024;
#                                      absent 2017-2020)
#                                      AP_IB_Dual_PartStudentGroup (2025; a
#                                      multi-year trend table inside the 2025
#                                      workbook - filtered to the requested year)
#                                      One row per entity per student group.
#
#   type = "sle"                    -> CTE_SLEParticipation (2017-2023; many
#                                      CTE/IVC columns - only the SLE columns are
#                                      surfaced here; CTE participation and
#                                      industry-valued credentials are already
#                                      covered by fetch_cte_participation() /
#                                      fetch_industry_credentials())
#                                      SLE_Participation (2024-2025)
#                                      One row per school.
#
# Every rate/count is coerced with spr_value_numeric(), which strips "%" and
# thousands commas and maps suppression / text-bleed strings (e.g. "There is no
# data available for this school year.", "Enrollment for this group was less than
# 10 students.") to NA - never to a guessed number. A real published 0 stays 0.
# All values come from the NJ DOE SPR workbooks; nothing is fabricated.
# ==============================================================================


# -----------------------------------------------------------------------------
# courses_offered
# -----------------------------------------------------------------------------

#' Harmonize the AP/IB courses-offered sheet across the schema drift
#' @param end_year School year end.
#' @param level One of \code{"school"} or \code{"district"}.
#' @param coerce_values Whether to coerce published value tokens to numeric.
#' @keywords internal
.advanced_courses_offered <- function(end_year, level, coerce_values = TRUE) {
  # Sheet renamed in 2024-25 (the A-B-IB typo is the real 2025 sheet name):
  #   2017-2024: APIBCoursesOffered
  #   2025+:     ABIBCoursesOffered
  sheet_name <- spr_sheet_for_year(
    end_year, "APIBCoursesOffered", "ABIBCoursesOffered"
  )

  df <- njschooldata::fetch_spr_data(
    sheet_name = sheet_name, end_year = end_year, level = level
  )
  # The 2025 sheet carries a single-year school_year column; keep the requested
  # year so the output preserves the historical one-row-per-course shape.
  df <- filter_spr_to_year(df, end_year)
  # The 2017 sheets ship only the CDS-code ids and omit the county/district/
  # school NAME columns; fill any missing name as NA (the ids remain the real
  # join keys - a missing name is left NA, never fabricated).
  df <- ensure_name_columns(df)

  # Harmonize the count columns across layouts.
  #   2017-2024: student_enroll_count, student_tested_count
  #   2025+:     students_enrolled,    students_tested
  if ("student_enroll_count" %in% names(df)) {
    df <- dplyr::rename(
      df,
      students_enrolled = student_enroll_count,
      students_tested = student_tested_count
    )
  }

  if (isTRUE(coerce_values)) {
    df$students_enrolled <- spr_value_numeric(df$students_enrolled)
    df$students_tested <- spr_value_numeric(df$students_tested)
  }

  df %>%
    dplyr::select(
      end_year,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      dplyr::any_of("school_year"),
      course_name, students_enrolled, students_tested,
      is_state, is_county, is_district, is_school,
      is_charter, is_charter_sector, is_allpublic
    )
}


# -----------------------------------------------------------------------------
# participation_by_group
# -----------------------------------------------------------------------------

#' Harmonize the AP/IB/dual participation-by-group sheet across the schema drift
#' @param end_year School year end.
#' @param level One of \code{"school"} or \code{"district"}.
#' @param coerce_values Whether to coerce published value tokens to numeric.
#' @keywords internal
.advanced_participation_by_group <- function(end_year, level,
                                             coerce_values = TRUE) {
  # Sheet renamed in 2024-25; absent before 2021.
  #   2021-2024: APIBDualEnrPartByStudentGrp
  #   2025+:     AP_IB_Dual_PartStudentGroup (multi-year trend table)
  sheet_name <- spr_sheet_for_year(
    end_year, "APIBDualEnrPartByStudentGrp", "AP_IB_Dual_PartStudentGroup"
  )

  df <- njschooldata::fetch_spr_data(
    sheet_name = sheet_name, end_year = end_year, level = level
  )
  # The 2025 sheet is a multi-year trend table (school_year 2020-21..2024-25);
  # keep only the requested academic year so the output is one row per entity per
  # student group, matching the historical single-year shape.
  df <- filter_spr_to_year(df, end_year)
  df <- ensure_name_columns(df)

  # Harmonize to a stable schema:
  #   apib_pct_school, apib_pct_state, dual_pct_school, dual_pct_state always;
  #   apib_pct_district, dual_pct_district exist only in 2025.
  if ("percent_enrolled_in_one_or_more_apor_ibcourse" %in% names(df)) {
    # 2021-2024 legacy layout. The school-percent column carries this entity's
    # own rate (school in the school workbook, district in the district
    # workbook); the state_percent_* columns carry the statewide rate.
    df <- dplyr::rename(
      df,
      apib_pct_school = percent_enrolled_in_one_or_more_apor_ibcourse,
      dual_pct_school = percent_enrolled_in_one_or_more_dual_enrollment_course,
      apib_pct_state = state_percent_percent_enrolled_in_one_or_more_apor_ibcourse,
      dual_pct_state = state_percent_enrolled_in_one_or_more_dual_enrollment_course
    )
  } else {
    # 2025 layout. The school workbook carries *_school + *_district + *_state;
    # the district workbook omits the *_school columns (no school context).
    if ("apib_enrolled_school" %in% names(df)) {
      df <- dplyr::rename(
        df,
        apib_pct_school = apib_enrolled_school,
        dual_pct_school = dual_school
      )
    }
    df <- dplyr::rename(
      df,
      apib_pct_district = apib_enrolled_district,
      apib_pct_state = apib_enrolled_state,
      dual_pct_district = dual_district,
      dual_pct_state = dual_state
    )
  }

  # Defensive guard: if the 2025 trend filter ever fails to collapse to one row
  # per (entity, student group) - the failure mode of the known-malformed
  # AP_IB_Dual_Participation sheet - stop with a clear message rather than emit
  # duplicated/garbage rows. We never guess a collapse key.
  if (end_year >= 2025) {
    key <- paste(df$county_id, df$district_id, df$school_id, df$subgroup)
    if (nrow(df) > 0 && max(table(key)) > 1) {
      stop(
        "fetch_advanced_course_access(type = \"participation_by_group\") found ",
        "duplicate rows per (entity, student group) after filtering the ",
        end_year, " AP_IB_Dual_PartStudentGroup sheet to its academic year. ",
        "The source sheet appears malformed; refusing to emit ambiguous rows.",
        call. = FALSE
      )
    }
  }

  pct_cols <- c(
    "apib_pct_school", "apib_pct_district", "apib_pct_state",
    "dual_pct_school", "dual_pct_district", "dual_pct_state"
  )
  if (isTRUE(coerce_values)) {
    for (col in pct_cols) {
      if (col %in% names(df)) df[[col]] <- spr_value_numeric(df[[col]])
    }
  }

  df %>%
    dplyr::select(
      end_year,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      dplyr::any_of("school_year"),
      subgroup,
      dplyr::any_of(c("apib_pct_school", "apib_pct_district")), apib_pct_state,
      dplyr::any_of(c("dual_pct_school", "dual_pct_district")), dual_pct_state,
      is_state, is_county, is_district, is_school,
      is_charter, is_charter_sector, is_allpublic
    )
}


# -----------------------------------------------------------------------------
# sle (Structured Learning Experience)
# -----------------------------------------------------------------------------

#' Harmonize the SLE-participation sheet across the schema drift
#' @param end_year School year end.
#' @param level One of \code{"school"} or \code{"district"}.
#' @param coerce_values Whether to coerce published value tokens to numeric.
#' @keywords internal
.advanced_sle_participation <- function(end_year, level,
                                        coerce_values = TRUE) {
  # Sheet renamed in 2023-24 (note: the boundary is 2024, NOT 2025):
  #   2017-2023: CTE_SLEParticipation (carries CTE / IVC columns too - only the
  #              SLE columns are surfaced here)
  #   2024-2025: SLE_Participation
  sheet_name <- if (end_year >= 2024) "SLE_Participation" else "CTE_SLEParticipation"

  df <- njschooldata::fetch_spr_data(
    sheet_name = sheet_name, end_year = end_year, level = level
  )
  # The 2025 sheet carries a single-year school_year column; keep it for safety.
  df <- filter_spr_to_year(df, end_year)
  df <- ensure_name_columns(df)

  # Harmonize the SLE columns to: sle_pct_state (always), plus the entity's own
  # rate - sle_pct_school in the School workbook, sle_pct_district in the District
  # workbook. The 2025 School workbook carries BOTH (a per-school rate and its
  # district's rate), so both columns appear there.
  #
  # The published column names drift across years AND levels:
  #   2017      : sleperc (entity), slestate_perc (state)            [both levels]
  #   2018-2024 : sleschool (school) / sledistrict (district), slestate (state)
  #   2025      : sle_school (school), sle_district (district), sle_state (state)
  # Detect-and-rename so every layout lands on the same stable schema.
  entity_label <- if (level == "district") "sle_pct_district" else "sle_pct_school"
  nm <- names(df)
  nm[nm %in% c("slestate", "sle_state", "slestate_perc")] <- "sle_pct_state"
  nm[nm %in% c("sleschool", "sle_school")] <- "sle_pct_school"
  nm[nm %in% c("sledistrict", "sle_district")] <- "sle_pct_district"
  # The undifferentiated 2017 column maps to the entity rate for the workbook.
  nm[nm %in% c("sleperc")] <- entity_label
  names(df) <- nm

  if (isTRUE(coerce_values)) {
    for (col in c("sle_pct_school", "sle_pct_district", "sle_pct_state")) {
      if (col %in% names(df)) df[[col]] <- spr_value_numeric(df[[col]])
    }
  }

  df %>%
    dplyr::select(
      end_year,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      dplyr::any_of("school_year"),
      dplyr::any_of(c("sle_pct_school", "sle_pct_district")), sle_pct_state,
      is_state, is_county, is_district, is_school,
      is_charter, is_charter_sector, is_allpublic
    )
}


# -----------------------------------------------------------------------------
# fetch_advanced_course_access()  (front door)
# -----------------------------------------------------------------------------

#' Fetch Advanced-Coursework Access & Equity Data
#'
#' A single front door over three NJ DOE School Performance Report (SPR) sheet
#' families describing access to and equity of advanced coursework. Unlike
#' \code{\link{fetch_ap_participation}} (overall AP/IB participation), these
#' surface whether a school \emph{offers} advanced courses, AP/IB/dual-enrollment
#' participation broken out \emph{by student group}, and Structured Learning
#' Experience (SLE) participation.
#'
#' @details
#' The \code{type} argument selects one of three sheet families, each with its
#' own coverage window and schema drift across the 2024-25 SPR redesign:
#' \itemize{
#'   \item \code{"courses_offered"} -- one row per school per advanced course
#'     (\code{course_name}, \code{students_enrolled}, \code{students_tested}).
#'     Sheet \code{APIBCoursesOffered} for \strong{end_year 2017-2024}, renamed
#'     \code{ABIBCoursesOffered} for 2025 (the A-B-IB typo is the real 2025 sheet
#'     name). The 2025 sheet adds a single-value \code{school_year} column.
#'   \item \code{"participation_by_group"} -- one row per entity per student
#'     group (\code{subgroup}), with the percent of students enrolled in one or
#'     more AP/IB courses (\code{apib_pct_school}) and one or more
#'     dual-enrollment courses (\code{dual_pct_school}), plus the statewide rate
#'     for the same group (\code{apib_pct_state}, \code{dual_pct_state}). Sheet
#'     \code{APIBDualEnrPartByStudentGrp} for \strong{end_year 2021-2024}
#'     (\strong{absent 2017-2020}; earlier years error), renamed
#'     \code{AP_IB_Dual_PartStudentGroup} for 2025. The 2025 sheet is a
#'     multi-year trend table (\code{school_year} 2020-21..2024-25) filtered to
#'     the requested academic year, and additionally carries district-level rates
#'     (\code{apib_pct_district}, \code{dual_pct_district}), which exist only for
#'     2025.
#'   \item \code{"sle"} -- one row per school with the percent of students in a
#'     Structured Learning Experience. The entity's own rate is
#'     \code{sle_pct_school} (School workbook) or \code{sle_pct_district}
#'     (District workbook), alongside the statewide rate \code{sle_pct_state};
#'     the 2025 School workbook carries both \code{sle_pct_school} and its
#'     district's \code{sle_pct_district}. Sheet \code{CTE_SLEParticipation} for
#'     \strong{end_year 2017-2023} (only the SLE columns are surfaced; CTE
#'     participation and industry-valued credentials live in
#'     \code{\link{fetch_cte_participation}} /
#'     \code{\link{fetch_industry_credentials}}), renamed \code{SLE_Participation}
#'     for 2024-2025. The published column names drift across both year and level
#'     (e.g. \code{sleperc}/\code{sleschool}/\code{sledistrict}/\code{sle_school})
#'     and are harmonized onto the stable schema above.
#' }
#'
#' Every rate/count is coerced with \code{spr_value_numeric()}, which strips
#' \code{"\%"} and thousands commas and maps suppression / no-data strings (e.g.
#' \code{"There is no data available for this school year."}, \code{"Enrollment
#' for this group was less than 10 students."}) to \code{NA} -- never to a
#' guessed number. A genuine published \code{0} is preserved as \code{0}. All
#' values come from the NJ DOE SPR workbooks.
#'
#' @param end_year A school year. Year is the end of the academic year - e.g. the
#'   2023-24 school year is \code{end_year} 2024. Coverage depends on
#'   \code{type}: \code{"courses_offered"} and \code{"sle"} cover 2017-2025;
#'   \code{"participation_by_group"} covers 2021-2025 (earlier years error).
#' @param type One of \code{"courses_offered"}, \code{"participation_by_group"},
#'   or \code{"sle"}.
#' @param level One of \code{"school"} or \code{"district"}. \code{"district"}
#'   returns district and state-level rows (the statewide \code{is_state} row
#'   lives in the District workbook).
#'
#' @return Data frame with entity identifiers, \code{school_year} (when the sheet
#'   carries it), the type-specific data columns described above,
#'   \code{subgroup} (for \code{"participation_by_group"}), and the standard
#'   aggregation flags (\code{is_state}, \code{is_county}, \code{is_district},
#'   \code{is_school}, \code{is_charter}, \code{is_charter_sector},
#'   \code{is_allpublic}).
#'
#' @export
#'
#' @examples
#' \dontrun{
#' library(dplyr)
#'
#' # Which advanced courses does each school offer, and how many enroll?
#' courses <- fetch_advanced_course_access(2024, type = "courses_offered")
#' courses %>%
#'   filter(district_id == "3570") %>%
#'   slice_max(students_enrolled, n = 10) %>%
#'   select(school_name, course_name, students_enrolled, students_tested)
#'
#' # AP/IB access gap by student group, statewide (district workbook)
#' fetch_advanced_course_access(2024, type = "participation_by_group",
#'                              level = "district") %>%
#'   filter(is_state) %>%
#'   select(subgroup, apib_pct_state, dual_pct_state)
#'
#' # Structured Learning Experience participation, latest year
#' fetch_advanced_course_access(2025, type = "sle") %>%
#'   filter(is_school) %>%
#'   slice_max(sle_pct_school, n = 10) %>%
#'   select(district_name, school_name, sle_pct_school, sle_pct_state)
#' }
fetch_advanced_course_access <- function(end_year,
                                         type = c("courses_offered",
                                                  "participation_by_group",
                                                  "sle"),
                                         level = "school") {
  type <- match.arg(type)

  if (!level %in% c("school", "district")) {
    stop(
      "fetch_advanced_course_access(): level must be \"school\" or ",
      "\"district\".",
      call. = FALSE
    )
  }

  if (type == "participation_by_group") {
    if (end_year < 2021) {
      stop(
        "participation-by-group data is available for end_year >= 2021 (the ",
        "APIBDualEnrPartByStudentGrp sheet is absent from the 2017-2020 SPR ",
        "databases).",
        call. = FALSE
      )
    }
    return(.advanced_participation_by_group(end_year, level))
  }

  if (end_year < 2017) {
    stop(
      "advanced-coursework data is available for end_year >= 2017 (the SPR ",
      "databases do not go back further).",
      call. = FALSE
    )
  }

  switch(
    type,
    courses_offered = .advanced_courses_offered(end_year, level),
    sle = .advanced_sle_participation(end_year, level)
  )
}
