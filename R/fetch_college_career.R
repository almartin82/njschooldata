# ==============================================================================
# College & Career Readiness Data Fetching Functions
# ==============================================================================
#
# Functions for downloading and extracting college and career readiness data
# from the NJ DOE School Performance Reports (SPR) databases. These include
# SAT/ACT data, AP/IB coursework, CTE participation, industry credentials,
# work-based learning, apprenticeships, and biliteracy seals.
#
# ==============================================================================

# -----------------------------------------------------------------------------
# SAT/ACT Participation
# -----------------------------------------------------------------------------

#' Fetch SAT/ACT/PSAT Participation Data
#'
#' Downloads and extracts college entrance exam participation rates from the
#' SPR database. Includes SAT, ACT, and PSAT participation percentages.
#'
#' @param end_year A school year (2017-2025). Year is the end of the academic
#'   year - eg 2020-21 school year is end_year '2021'.
#' @param level One of "school" or "district". "school" returns school-level
#'   data, "district" returns district and state-level data.
#'
#' @return Data frame with SAT/ACT/PSAT participation rates including:
#'   \itemize{
#'     \item end_year, county_id, county_name, district_id, district_name
#'     \item school_id, school_name (for school-level data)
#'     \item sat_participation - Percentage of students taking SAT
#'     \item act_participation - Percentage of students taking ACT
#'     \item psat_participation - Percentage of students taking PSAT
#'     \item state_sat - State SAT participation rate (comparison)
#'     \item state_act - State ACT participation rate (comparison)
#'     \item state_psat - State PSAT participation rate (comparison)
#'     \item Aggregation flags (is_state, is_county, is_district, is_school, is_charter)
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Get 2024 SAT/ACT participation
#' sat <- fetch_sat_participation(2024)
#'
#' # Analyze SAT participation gaps
#' sat %>%
#'   filter(sat_participation < 50) %>%
#'   select(school_name, sat_participation, state_sat)
#' }
fetch_sat_participation <- function(end_year, level = "school") {
  # Sheet renamed in 2024-25:
  #   2017-2024: PSAT-SAT-ACTParticipation
  #   2025+:     PSATSATACT_Participation
  sheet_name <- spr_sheet_for_year(
    end_year, "PSAT-SAT-ACTParticipation", "PSATSATACT_Participation"
  )

  df <- njschooldata::fetch_spr_data(
    sheet_name = sheet_name,
    end_year = end_year,
    level = level
  )

  # The 2024-25 sheet is a multi-year trend table (SchoolYear 2020-21..2024-25).
  # Keep only the requested academic year so the output matches the historical
  # single-year shape (one row per school).
  df <- filter_spr_to_year(df, end_year)

  # fetch_spr_data() has already snake_cased the column names, so the school /
  # state participation columns arrive lowercased. Standardize to the canonical
  # sat/act/psat + state_* names across years.
  # 2017-2024 (cleaned): sat, act, psat, state_sat, state_act, state_psat
  # 2025+     (cleaned): sat_school, act_school, psat_school, sat_state, ...
  if ("sat_school" %in% names(df)) {
    df <- df %>%
      dplyr::rename(
        sat = sat_school,
        act = act_school,
        psat = psat_school,
        state_sat = sat_state,
        state_act = act_state,
        state_psat = psat_state
      )
  }

  df <- df %>%
    dplyr::rename(
      sat_participation = sat,
      act_participation = act,
      psat_participation = psat
    ) %>%
    dplyr::select(
      end_year,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      sat_participation,
      act_participation,
      psat_participation,
      state_sat,
      state_act,
      state_psat,
      dplyr::any_of(c("subgroup")),
      is_state, is_county, is_district, is_school,
      is_charter, is_charter_sector, is_allpublic
    )

  df
}


# -----------------------------------------------------------------------------
# SAT/ACT Performance
# -----------------------------------------------------------------------------

#' Fetch SAT/ACT/PSAT Performance Data
#'
#' Downloads and extracts college entrance exam performance scores from the
#' SPR database. Includes average scores and benchmark achievement rates.
#'
#' @param end_year A school year (2017-2025). Year is the end of the academic
#'   year - eg 2020-21 school year is end_year '2021'.
#' @param level One of "school" or "district". "school" returns school-level
#'   data, "district" returns district and state-level data.
#' @param test_type Filter by test type. Options are "SAT", "ACT", "PSAT", or "all"
#'   (default: "all")
#'
#' @return Data frame with SAT/ACT/PSAT performance scores including:
#'   \itemize{
#'     \item end_year, county_id, county_name, district_id, district_name
#'     \item school_id, school_name (for school-level data)
#'     \item test_type - Type of test (SAT, ACT, or PSAT)
#'     \item subject - Test subject (e.g., "Math", "Evidence-Based Reading and Writing")
#'     \item school_avg - Average score for this school
#'     \item state_avg - State average score (comparison)
#'     \item benchmark - Whether school meets benchmark (if applicable)
#'     \item pct_benchmark - Percentage meeting benchmark (if applicable)
#'     \item state_pct_benchmark - State benchmark percentage (comparison)
#'     \item Aggregation flags (is_state, is_county, is_district, is_school, is_charter)
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Get 2024 SAT performance
#' sat_perf <- fetch_sat_performance(2024)
#'
#' # Filter for SAT Math scores only
#' sat_math <- sat_perf %>%
#'   filter(test_type == "SAT", subject == "Math") %>%
#'   select(school_name, school_avg, state_avg)
#'
#' # Get only SAT data
#' sat_only <- fetch_sat_performance(2024, test_type = "SAT")
#' }
fetch_sat_performance <- function(end_year, level = "school", test_type = "all") {
  if (end_year >= 2025) {
    # 2024-25 split the single performance sheet into two:
    #   PSATSATACT_AverageScore: Test, Subject, AverageScore_School/District/State
    #   PSATSATACT_Benchmark:    Test, Subject, Benchmark,
    #                            StudentsMeetingBenchmark_School/District/State
    # Recombine them on the location + Test + Subject keys to reproduce the
    # historical one-row-per-test/subject shape.
    avg <- njschooldata::fetch_spr_data(
      sheet_name = "PSATSATACT_AverageScore", end_year = end_year, level = level
    )
    avg <- filter_spr_to_year(avg, end_year) %>%
      dplyr::rename(
        test_type = test,
        subject = subject,
        school_avg = average_score_school,
        state_avg = average_score_state
      )

    bm <- njschooldata::fetch_spr_data(
      sheet_name = "PSATSATACT_Benchmark", end_year = end_year, level = level
    )
    bm <- filter_spr_to_year(bm, end_year) %>%
      dplyr::rename(
        test_type = test,
        subject = subject,
        pct_benchmark = students_meeting_benchmark_school,
        state_pct_benchmark = students_meeting_benchmark_state
      ) %>%
      dplyr::select(
        dplyr::any_of(c("county_id", "district_id", "school_id", "school_year",
                        "test_type", "subject", "benchmark",
                        "pct_benchmark", "state_pct_benchmark"))
      )

    join_keys <- intersect(
      c("county_id", "district_id", "school_id", "school_year", "test_type", "subject"),
      intersect(names(avg), names(bm))
    )
    df <- dplyr::left_join(avg, bm, by = join_keys)
  } else {
    # 2017-2024: single sheet, snake_cased columns from fetch_spr_data()
    df <- njschooldata::fetch_spr_data(
      sheet_name = "PSAT-SAT-ACTPerformance",
      end_year = end_year,
      level = level
    ) %>%
      dplyr::rename(
        test_type = test,
        subject = subject,
        school_avg = school_avg,
        state_avg = state_avg,
        benchmark = benchmark,
        pct_benchmark = bt_pct,
        state_pct_benchmark = state_bt_pct
      )
  }

  # Filter by test type if specified
  df <- df %>%
    dplyr::filter(
      test_type %in% c(test_type, "All", toupper(test_type))
    )

  df
}


# -----------------------------------------------------------------------------
# AP/IB Coursework
# -----------------------------------------------------------------------------

#' Fetch AP/IB Participation and Performance Data
#'
#' Downloads and extracts Advanced Placement (AP) and International Baccalaureate (IB)
#' coursework participation and exam performance from the SPR database.
#'
#' @param end_year A school year (2017-2025). Year is the end of the academic
#'   year - eg 2020-21 school year is end_year '2021'.
#' @param level One of "school" or "district". "school" returns school-level
#'   data, "district" returns district and state-level data.
#'
#' @return Data frame with AP/IB participation and performance including:
#'   \itemize{
#'     \item end_year, county_id, county_name, district_id, district_name
#'     \item school_id, school_name (for school-level data)
#'     \item apib_coursework_school - Percentage students in AP/IB coursework
#'     \item apib_coursework_state - State percentage in AP/IB coursework
#'     \item apib_exam_school - Percentage taking AP/IB exams
#'     \item apib_exam_state - State percentage taking AP/IB exams
#'     \item ap3_ib4_school - Percentage scoring AP 3+ or IB 4+
#'     \item ap3_ib4_state - State percentage scoring AP 3+ or IB 4+
#'     \item dual_enrollment_school - Dual enrollment participation
#'     \item dual_enrollment_state - State dual enrollment percentage
#'     \item Aggregation flags (is_state, is_county, is_district, is_school, is_charter)
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Get 2024 AP/IB data
#' apib <- fetch_ap_participation(2024)
#'
#' # Compare exam participation vs performance
#' apib %>%
#'   select(school_name, apib_exam_school, ap3_ib4_school)
#' }
fetch_ap_participation <- function(end_year, level = "school") {
  if (end_year >= 2025) {
    # FOLLOW-UP / NOT YET SUPPORTED FOR 2025.
    #
    # The 2024-25 redesign replaced APIBCourseworkPartPerf with two sheets,
    # AP_IB_Dual_Participation and AP_IB_Dual_PartStudentGroup. The
    # AP_IB_Dual_Participation sheet is *malformed* at the school level: it
    # declares a single 19-column table (CountyCode..Dual_State, no extra
    # dimension column) yet emits thousands of rows per school per year where
    # APIB_Enrolled_School is constant but APIB_Exams_School / AP3_IB4_School /
    # Dual_School vary with no column to disambiguate them (e.g. Newark school
    # 010, SY2024-25: 4,913 rows, 2,448 distinct value tuples). Without a
    # verifiable key to collapse those rows to one-per-school, reconstructing
    # the historical output would require guessing, which would fabricate data.
    # Leaving the 2025 path unimplemented until the source sheet is corrected or
    # a documented grouping key is identified.
    stop(
      "fetch_ap_participation() is not yet available for end_year 2025. ",
      "The 2024-25 AP_IB_Dual_Participation SPR sheet is malformed at the ",
      "school level (many rows per school with no disambiguating column), so a ",
      "reliable one-row-per-school mapping cannot be derived. This is a known ",
      "follow-up; 2017-2024 are unaffected."
    )
  }

  df <- njschooldata::fetch_spr_data(
    sheet_name = "APIBCourseworkPartPerf",
    end_year = end_year,
    level = level
  )

  # Rename columns (after clean_name_vector conversion)
  # APIB_COURSE_SCHOOL -> apib_course_school
  # AP3_IB4_SCHOOL     -> ap_3_ib_4_school
  # DUAL_SCHOOL        -> dual_school
  df <- df %>%
    dplyr::rename(
      apib_coursework_school = apib_course_school,
      apib_coursework_state = apib_course_state,
      apib_exam_school = apib_exam_school,
      apib_exam_state = apib_exam_state,
      ap3_ib4_school = ap_3_ib_4_school,
      ap3_ib4_state = ap_3_ib_4_state,
      dual_enrollment_school = dual_school,
      dual_enrollment_state = dual_state
    )

  df <- df %>%
    dplyr::select(
      end_year,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      apib_coursework_school,
      apib_coursework_state,
      apib_exam_school,
      apib_exam_state,
      ap3_ib4_school,
      ap3_ib4_state,
      dual_enrollment_school,
      dual_enrollment_state,
      is_state, is_county, is_district, is_school,
      is_charter, is_charter_sector, is_allpublic
    )

  df
}


#' Fetch AP/IB Performance Data (Alias)
#'
#' Alias for \code{\link{fetch_ap_participation}}. Returns both participation
#' and performance data for AP/IB coursework.
#'
#' @param end_year A school year (2017-2025)
#' @param level One of "school" or "district"
#'
#' @return Data frame with AP/IB participation and performance metrics
#'
#' @export
#'
#' @examples
#' \dontrun{
#' ap_perf <- fetch_ap_performance(2024)
#' }
fetch_ap_performance <- function(end_year, level = "school") {
  fetch_ap_participation(end_year = end_year, level = level)
}


# -----------------------------------------------------------------------------
# IB Participation (Separate from AP)
# -----------------------------------------------------------------------------

#' Fetch IB Participation Data
#'
#' Downloads and extracts International Baccalaureate participation from the
#' SPR database. Note: Most IB data is included in the AP/IB sheet, use
#' \code{\link{fetch_ap_participation}} for comprehensive data.
#'
#' @param end_year A school year (2017-2025). Year is the end of the academic
#'   year - eg 2020-21 school year is end_year '2021'.
#' @param level One of "school" or "district". "school" returns school-level
#'   data, "district" returns district and state-level data.
#'
#' @return Data frame with IB participation metrics
#'
#' @export
#'
#' @examples
#' \dontrun{
#' ib <- fetch_ib_participation(2024)
#' }
fetch_ib_participation <- function(end_year, level = "school") {
  # IB data is in the AP/IB sheet
  fetch_ap_participation(end_year = end_year, level = level)
}


# -----------------------------------------------------------------------------
# CTE Participation
# -----------------------------------------------------------------------------

#' Fetch CTE Participation Data
#'
#' Downloads and extracts Career and Technical Education (CTE) participation
#' from the SPR database. Includes CTE participants and concentrators by subgroup.
#'
#' @param end_year A school year (2017-2025). Year is the end of the academic
#'   year - eg 2020-21 school year is end_year '2021'.
#' @param level One of "school" or "district". "school" returns school-level
#'   data, "district" returns district and state-level data.
#'
#' @return Data frame with CTE participation including:
#'   \itemize{
#'     \item end_year, county_id, county_name, district_id, district_name
#'     \item school_id, school_name (for school-level data)
#'     \item subgroup - Student group (total population, racial/ethnic groups, etc.)
#'     \item cte_participants - Number or percentage of CTE participants
#'     \item cte_concentrators - Number or percentage of CTE concentrators
#'     \item state_cte_participants - State CTE participants (comparison)
#'     \item state_cte_concentrators - State CTE concentrators (comparison)
#'     \item Aggregation flags (is_state, is_county, is_district, is_school, is_charter)
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Get 2024 CTE participation
#' cte <- fetch_cte_participation(2024)
#'
#' # Compare CTE participation across subgroups
#' cte %>%
#'   filter(school_id == "030") %>%
#'   select(subgroup, cte_participants)
#' }
fetch_cte_participation <- function(end_year, level = "school") {
  df <- njschooldata::fetch_spr_data(
    sheet_name = "CTEParticipationByStudentGroup",
    end_year = end_year,
    level = level
  )

  # Standardize column names across years (after clean_name_vector conversion).
  # 2017-2024: SchoolCTEParticipants  -> school_cteparticipants
  #            StateCTEConcentrators  -> state_cteconcentrators
  # 2024-25:   CTEParticipants_School -> cteparticipants_school
  #            CTEConcentrators_State -> cteconcentrators_state (+ _district)
  if ("cteparticipants_school" %in% names(df)) {
    df <- df %>%
      dplyr::rename(
        school_cteparticipants = cteparticipants_school,
        school_cteconcentrators = cteconcentrators_school,
        state_cteparticipants = cteparticipants_state,
        state_cteconcentrators = cteconcentrators_state
      )
  }

  df <- df %>%
    dplyr::rename(
      cte_participants = school_cteparticipants,
      cte_concentrators = school_cteconcentrators,
      state_cte_participants = state_cteparticipants,
      state_cte_concentrators = state_cteconcentrators
    ) %>%
    dplyr::select(
      end_year,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      subgroup,
      cte_participants,
      cte_concentrators,
      state_cte_participants,
      state_cte_concentrators,
      is_state, is_county, is_district, is_school,
      is_charter, is_charter_sector, is_allpublic
    )

  df
}


# -----------------------------------------------------------------------------
# Industry Credentials
# -----------------------------------------------------------------------------

#' Fetch Industry Valued Credentials Data
#'
#' Downloads and extracts industry-valued credentials earned by students
#' from the SPR database. Organized by career cluster.
#'
#' @param end_year A school year (2017-2025). Year is the end of the academic
#'   year - eg 2020-21 school year is end_year '2021'.
#' @param level One of "school" or "district". "school" returns school-level
#'   data, "district" returns district and state-level data.
#'
#' @return Data frame with industry credentials including:
#'   \itemize{
#'     \item end_year, county_id, county_name, district_id, district_name
#'     \item school_id, school_name (for school-level data)
#'     \item career_cluster - Career cluster area (e.g., "Health Sciences", "STEM")
#'     \item students_enrolled - Number of students enrolled in CTE program
#'     \item earned_one_credential - Students earning at least one credential
#'     \item credentials_earned - Total industry credentials earned
#'     \item Aggregation flags (is_state, is_county, is_district, is_school, is_charter)
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Get 2024 industry credentials
#' creds <- fetch_industry_credentials(2024)
#'
#' # Top schools by credentials earned
#' creds %>%
#'   group_by(school_name) %>%
#'   summarize(total_credentials = sum(credentials_earned, na.rm = TRUE)) %>%
#'   dplyr::arrange(desc(total_credentials))
#' }
fetch_industry_credentials <- function(end_year, level = "school") {
  # Sheet renamed in 2024-25. The credentials-by-career-cluster breakdown moved
  # to IndustryValuedCredClusters (the new IndustryValuedCredentials sheet only
  # carries an aggregate school/district/state count without the cluster split).
  #   2017-2024: IndustryValuedCredentialsEarned
  #   2025+:     IndustryValuedCredClusters
  sheet_name <- spr_sheet_for_year(
    end_year, "IndustryValuedCredentialsEarned", "IndustryValuedCredClusters"
  )

  df <- njschooldata::fetch_spr_data(
    sheet_name = sheet_name,
    end_year = end_year,
    level = level
  )

  # Columns are identical across years (after clean_name_vector conversion).
  df <- df %>%
    dplyr::rename(
      career_cluster = career_cluster,
      students_enrolled = students_enrolled_in_program,
      earned_one_credential = atleast_one_credential_earned,
      credentials_earned = industry_credentials_earned
    ) %>%
    dplyr::select(
      end_year,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      career_cluster,
      students_enrolled,
      earned_one_credential,
      credentials_earned,
      is_state, is_county, is_district, is_school,
      is_charter, is_charter_sector, is_allpublic
    )

  df
}


# -----------------------------------------------------------------------------
# Work-Based Learning
# -----------------------------------------------------------------------------

#' Fetch Work-Based Learning Data
#'
#' Downloads and extracts work-based learning participation from the SPR
#' database. Organized by career cluster.
#'
#' @param end_year A school year (2017-2025). Year is the end of the academic
#'   year - eg 2020-21 school year is end_year '2021'.
#' @param level One of "school" or "district". "school" returns school-level
#'   data, "district" returns district and state-level data.
#'
#' @return Data frame with work-based learning participation including:
#'   \itemize{
#'     \item end_year, county_id, county_name, district_id, district_name
#'     \item school_id, school_name (for school-level data)
#'     \item career_cluster - Career cluster area
#'     \item students_participating - Number of students in work-based learning
#'     \item pct_participating - Percentage participating in this career cluster
#'     \item Aggregation flags (is_state, is_county, is_district, is_school, is_charter)
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Get 2024 work-based learning data
#' wbl <- fetch_work_based_learning(2024)
#'
#' # Schools with highest work-based learning participation
#' wbl %>%
#'   group_by(school_name) %>%
#'   summarize(avg_participation = mean(pct_participating, na.rm = TRUE)) %>%
#'   dplyr::arrange(desc(avg_participation))
#' }
fetch_work_based_learning <- function(end_year, level = "school") {
  # Sheet renamed in 2024-25:
  #   2017-2024: WorkbasedLearningByCareerClust
  #   2025+:     WorkBasedLearning
  sheet_name <- spr_sheet_for_year(
    end_year, "WorkbasedLearningByCareerClust", "WorkBasedLearning"
  )

  df <- njschooldata::fetch_spr_data(
    sheet_name = sheet_name,
    end_year = end_year,
    level = level
  )

  # Standardize the participation columns across years (after clean_name_vector).
  # 2017-2024: students_participating_in_work_based_learning,
  #            perc_students_participating_learning_by_cluster
  # 2024-25:   work_based_learning_count_school, work_based_learning_pct_school
  #            (+ _district / _state variants)
  if ("work_based_learning_count_school" %in% names(df)) {
    df <- df %>%
      dplyr::rename(
        students_participating_in_work_based_learning = work_based_learning_count_school,
        perc_students_participating_learning_by_cluster = work_based_learning_pct_school
      )
  }

  # Rename columns (after clean_name_vector conversion)
  df <- df %>%
    dplyr::rename(
      career_cluster = career_cluster,
      students_participating = students_participating_in_work_based_learning,
      pct_participating = perc_students_participating_learning_by_cluster
    ) %>%
    dplyr::select(
      end_year,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      career_cluster,
      students_participating,
      pct_participating,
      is_state, is_county, is_district, is_school,
      is_charter, is_charter_sector, is_allpublic
    )

  df
}


# -----------------------------------------------------------------------------
# Apprenticeship Data
# -----------------------------------------------------------------------------

#' Fetch Apprenticeship Data
#'
#' Downloads and extracts apprenticeship participation data from the SPR
#' database. Contains counts by year (2016-2023).
#'
#' @param end_year A school year (2017-2025). Year is the end of the academic
#'   year - eg 2020-21 school year is end_year '2021'.
#' @param level One of "school" or "district". "school" returns school-level
#'   data, "district" returns district and state-level data.
#'
#' @return Data frame with apprenticeship participation including:
#'   \itemize{
#'     \item end_year, county_id, county_name, district_id, district_name
#'     \item school_id, school_name (for school-level data)
#'     \item year_2016 through year_2023 - Number of apprentices by year
#'     \item Aggregation flags (is_state, is_county, is_district, is_school, is_charter)
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Get 2024 apprenticeship data
#' app <- fetch_apprenticeship_data(2024)
#'
#' # Reshape to long format for analysis
#' app_long <- app %>%
#'   tidyr::pivot_longer(
#'     cols = starts_with("year_"),
#'     names_to = "apprenticeship_year",
#'     values_to = "apprenticeship_count",
#'     names_prefix = "year_"
#'   ) %>%
#'   filter(!is.na(apprenticeship_count))
#' }
fetch_apprenticeship_data <- function(end_year, level = "school") {
  df <- njschooldata::fetch_spr_data(
    sheet_name = "Apprenticeship",
    end_year = end_year,
    level = level
  )

  # 2017-2024: the sheet had calendar-year columns 2016-2023 which
  # clean_name_vector turns into x_2016, x_2017, ... Rename them to
  # year_2016, year_2017, ... (dplyr::rename takes new_name = old_name).
  #
  # 2024-25: the sheet was restructured to a graduation-year layout
  # (GraduationYear + Apprenticeships_1yr..8yr); there are no x_20NN columns,
  # so this rename is a no-op and the restructured columns pass through as-is.
  year_cols <- grep("^x_20(1[6-9]|2[0-3])$", names(df), value = TRUE)
  if (length(year_cols) > 0) {
    new_names <- gsub("^x_", "year_", year_cols)
    df <- df %>%
      dplyr::rename(!!!setNames(year_cols, new_names))
  }

  df
}


# -----------------------------------------------------------------------------
# Seal of Biliteracy
# -----------------------------------------------------------------------------

#' Fetch Seal of Biliteracy Data
#'
#' Downloads and extracts Seal of Biliteracy data from the SPR database.
#' The Seal of Biliteracy recognizes students who attain proficiency in
#' English and one or more world languages.
#'
#' @param end_year A school year (2017-2025). Year is the end of the academic
#'   year - eg 2020-21 school year is end_year '2021'.
#' @param level One of "school" or "district". "school" returns school-level
#'   data, "district" returns district and state-level data.
#'
#' @return Data frame with Seal of Biliteracy data including:
#'   \itemize{
#'     \item end_year, county_id, county_name, district_id, district_name
#'     \item school_id, school_name (for school-level data)
#'     \item language - Language (e.g., "Spanish", "French", "Chinese")
#'     \item seals_earned - Number of seals earned in this language
#'     \item pct_12th_graders - Percentage of 12th graders earning seals
#'     \item Aggregation flags (is_state, is_county, is_district, is_school, is_charter)
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Get 2024 biliteracy seal data
#' biliteracy <- fetch_biliteracy_seal(2024)
#'
#' # Top languages by seal count
#' biliteracy %>%
#'   group_by(language) %>%
#'   summarize(total_seals = sum(seals_earned, na.rm = TRUE)) %>%
#'   dplyr::arrange(desc(total_seals))
#'
#' # Schools with most diverse language offerings
#' biliteracy %>%
#'   group_by(school_name) %>%
#'   summarize(num_languages = sum(seals_earned > 0, na.rm = TRUE)) %>%
#'   dplyr::arrange(desc(num_languages))
#' }
fetch_biliteracy_seal <- function(end_year, level = "school") {
  # Sheet split in 2024-25; the per-language detail moved to a dedicated sheet:
  #   2017-2024: SealofBiliteracy        (Language, SealsEarned, Perc12Graders)
  #   2025+:     SealofBiliteracy_Language (Language, NumberSealsEarned,
  #              PercentageSealsEarned)
  sheet_name <- spr_sheet_for_year(
    end_year, "SealofBiliteracy", "SealofBiliteracy_Language"
  )

  df <- njschooldata::fetch_spr_data(
    sheet_name = sheet_name,
    end_year = end_year,
    level = level
  )

  # fetch_spr_data() has already snake_cased the column names. Standardize the
  # seal-count / percentage columns across years.
  # 2017-2024 (cleaned): seals_earned, perc_12_graders
  # 2025+     (cleaned): number_seals_earned, percentage_seals_earned
  if ("number_seals_earned" %in% names(df)) {
    df <- df %>%
      dplyr::rename(
        seals_earned = number_seals_earned,
        perc_12_graders = percentage_seals_earned
      )
  }

  # Rename columns
  df <- df %>%
    dplyr::rename(
      language = language,
      seals_earned = seals_earned,
      pct_12th_graders = perc_12_graders
    ) %>%
    dplyr::select(
      end_year,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      language,
      seals_earned,
      pct_12th_graders,
      is_state, is_county, is_district, is_school,
      is_charter, is_charter_sector, is_allpublic
    )

  df
}


# -----------------------------------------------------------------------------
# Seal of Biliteracy - 2024-25 redesign sheets (summary / trends / by-group)
# -----------------------------------------------------------------------------
#
# The 2024-25 (end_year 2025) SPR redesign split the single legacy
# SealofBiliteracy sheet into four sheets. The per-language detail
# (SealofBiliteracy_Language) is covered by fetch_biliteracy_seal() above; the
# three genuinely-new summary/trend/equity views below exist ONLY in end_year
# 2025 (both school and district workbooks) and are absent from 2017-2024, so
# each of these three fetchers is 2025-only and errors for any other year.
#
# These add a school-completion lens (how many seals, how many languages, how
# many unique students), a multi-year trend (within the 2025 workbook itself),
# and an equity lens (seal-earning rate by student group). Suppression and
# text-bleed strings ("Fewer than 5 seals", "Enrollment for the group is <10
# students.", "Total Current and Former ML enrollment was less than 10
# students.") are coerced to NA by spr_value_numeric() - never to a guessed
# number. A real published 0 stays 0.
#
# The 2025-only error gate matches the precedent set by the other redesign
# fetchers (e.g. fetch_spr_tsi); the sheet simply does not exist earlier, so
# erroring is honest rather than fabricating coverage.

#' Numeric columns to coerce on each redesigned biliteracy sheet
#' @keywords internal
.biliteracy_summary_num_cols <- c(
  "total_seals_earned", "numberof_languages",
  "unique_students_earning_seals", "unique_students_earning_seals_pct",
  "multilingual_learners_earning_seals", "multilingual_learners_earning_seals_pct",
  # District-workbook-only extras (absent from the School workbook):
  "schools_earning_seals", "schools_earning_seals_pct",
  "districts_earning_seals", "districts_earning_seals_pct"
)

#' Validate a redesigned-biliteracy call (2025-only, school/district level)
#'
#' The three redesigned Seal-of-Biliteracy sheets exist only in the end_year
#' 2025 SPR workbooks. This helper enforces the supported \code{level} and the
#' 2025-only year gate with clear error messages, mirroring the gating used by
#' the other 2024-25 redesign fetchers.
#'
#' @param end_year Requested school year.
#' @param level Requested level ("school" or "district").
#' @param fn Function name, for the error message.
#' @keywords internal
.validate_biliteracy_redesign <- function(end_year, level, fn) {
  if (!level %in% c("school", "district")) {
    stop(
      fn, "(): level must be \"school\" or \"district\".",
      call. = FALSE
    )
  }
  if (!identical(as.numeric(end_year), 2025)) {
    stop(
      fn, "() covers end_year 2025 only: the redesigned ",
      "Seal-of-Biliteracy summary/trend/student-group sheets were introduced ",
      "in the 2024-25 SPR redesign and are absent from 2017-2024 workbooks. ",
      "For the per-language detail (2018-2025) use fetch_biliteracy_seal().",
      call. = FALSE
    )
  }
  invisible(TRUE)
}


#' Fetch Seal-of-Biliteracy Summary (2024-25)
#'
#' Downloads the \code{SealofBiliteracy_Summary} sheet from the redesigned
#' 2024-25 NJ DOE School Performance Reports. Each row reports, for one entity,
#' the total seals earned, the number of distinct languages, the count and
#' percentage of unique students earning a seal, and the count and percentage of
#' multilingual learners earning a seal.
#'
#' @details
#' This sheet exists \strong{only in end_year 2025} (both school and district
#' workbooks); 2017-2024 had a single combined \code{SealofBiliteracy} sheet, so
#' other years error. For the per-language detail across 2018-2025 use
#' \code{\link{fetch_biliteracy_seal}}.
#'
#' Percentages are published as strings (e.g. \code{"6.8\%"}) and counts may
#' carry thousands separators (e.g. \code{"12,644"}); both are coerced to
#' numeric. Some multilingual-learner cells bleed a suppression note into the
#' value column (e.g. \code{"Total Current and Former ML enrollment was less
#' than 10 students."} or \code{"Fewer than 5 students."}); these non-numeric
#' strings become \code{NA}, never a fabricated number. A genuine published
#' \code{0} is preserved as \code{0}.
#'
#' The District workbook additionally carries
#' \code{schools_earning_seals(_pct)} and \code{districts_earning_seals(_pct)}
#' columns (absent from the School workbook); they are passed through when
#' present.
#'
#' @param end_year Must be 2025 (the only year the sheet exists).
#' @param level One of \code{"school"} or \code{"district"}. \code{"district"}
#'   returns district and state rows.
#'
#' @return Data frame with entity identifiers, \code{school_year}, the summary
#'   metrics above (numeric), and the standard aggregation flags
#'   (\code{is_state}, \code{is_county}, \code{is_district}, \code{is_school},
#'   \code{is_charter}, \code{is_charter_sector}, \code{is_allpublic}).
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Summary for every school (2024-25)
#' bs <- fetch_biliteracy_summary(2025)
#'
#' # Statewide totals (district workbook carries the is_state row)
#' library(dplyr)
#' fetch_biliteracy_summary(2025, level = "district") %>%
#'   filter(is_state) %>%
#'   select(total_seals_earned, numberof_languages, unique_students_earning_seals)
#'
#' # Schools earning the most seals
#' fetch_biliteracy_summary(2025) %>%
#'   filter(is_school) %>%
#'   slice_max(total_seals_earned, n = 10) %>%
#'   select(district_name, school_name, total_seals_earned, numberof_languages)
#' }
fetch_biliteracy_summary <- function(end_year, level = "school") {
  .validate_biliteracy_redesign(end_year, level, "fetch_biliteracy_summary")

  df <- njschooldata::fetch_spr_data(
    sheet_name = "SealofBiliteracy_Summary",
    end_year = end_year,
    level = level
  )

  # Coerce every numeric metric present. spr_value_numeric() strips "%" and
  # thousands commas and maps suppression / text-bleed strings to NA, preserving
  # a real published 0.
  for (col in .biliteracy_summary_num_cols) {
    if (col %in% names(df)) df[[col]] <- spr_value_numeric(df[[col]])
  }

  df %>%
    dplyr::select(
      end_year,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      dplyr::any_of("school_year"),
      total_seals_earned, numberof_languages,
      unique_students_earning_seals, unique_students_earning_seals_pct,
      multilingual_learners_earning_seals, multilingual_learners_earning_seals_pct,
      dplyr::any_of(c(
        "schools_earning_seals", "schools_earning_seals_pct",
        "districts_earning_seals", "districts_earning_seals_pct"
      )),
      is_state, is_county, is_district, is_school,
      is_charter, is_charter_sector, is_allpublic
    )
}


#' Fetch Seal-of-Biliteracy Multi-Year Trend (2024-25)
#'
#' Downloads the \code{SealofBiliteracy_Trends} sheet from the redesigned
#' 2024-25 NJ DOE School Performance Reports. Unlike most SPR sheets this one is
#' \strong{multi-year within the single 2025 workbook}: each entity has one row
#' per \code{school_year} (\code{"2020-21"} through \code{"2024-25"}) carrying
#' the total seals earned that year.
#'
#' @details
#' The sheet exists \strong{only in end_year 2025} (both school and district
#' workbooks); other years error. All five \code{school_year} rows are returned
#' for each entity - the function does not filter to a single year.
#'
#' \code{total_seals_earned} is coerced to numeric. A real published \code{0}
#' (no seals that year) is preserved as \code{0}; the suppression string
#' \code{"Fewer than 5 seals"} becomes \code{NA}, never a guessed number.
#'
#' @param end_year Must be 2025 (the only year the sheet exists).
#' @param level One of \code{"school"} or \code{"district"}. \code{"district"}
#'   returns district and state rows.
#'
#' @return Data frame with entity identifiers, \code{school_year},
#'   \code{total_seals_earned} (numeric), and the standard aggregation flags.
#'   One row per entity per \code{school_year}.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Five-year seal trend for every school (2024-25 workbook)
#' bt <- fetch_biliteracy_trends(2025)
#'
#' # Statewide seal trend
#' library(dplyr)
#' fetch_biliteracy_trends(2025, level = "district") %>%
#'   filter(is_state) %>%
#'   select(school_year, total_seals_earned)
#'
#' # One school's five-year trajectory
#' fetch_biliteracy_trends(2025) %>%
#'   filter(district_id == "3570", school_id == "010") %>%
#'   select(school_name, school_year, total_seals_earned)
#' }
fetch_biliteracy_trends <- function(end_year, level = "school") {
  .validate_biliteracy_redesign(end_year, level, "fetch_biliteracy_trends")

  df <- njschooldata::fetch_spr_data(
    sheet_name = "SealofBiliteracy_Trends",
    end_year = end_year,
    level = level
  )

  # Coerce the single value column. A published 0 stays 0; "Fewer than 5 seals"
  # -> NA.
  df$total_seals_earned <- spr_value_numeric(df$total_seals_earned)

  df %>%
    dplyr::select(
      end_year,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      dplyr::any_of("school_year"),
      total_seals_earned,
      is_state, is_county, is_district, is_school,
      is_charter, is_charter_sector, is_allpublic
    )
}


#' Fetch Seal-of-Biliteracy Seal-Earning Rate by Student Group (2024-25)
#'
#' Downloads the \code{SealofBiliteracy_StudentGroup} sheet from the redesigned
#' 2024-25 NJ DOE School Performance Reports. Each row reports, for one entity
#' and one student group, the percentage of students in that group earning a
#' seal, alongside the district and state rates for the same group - an equity
#' lens on biliteracy attainment.
#'
#' @details
#' The sheet exists \strong{only in end_year 2025} (both school and district
#' workbooks); other years error. The School workbook carries the
#' \code{students_earning_seal_pct_school} column; the District workbook omits
#' it (there is no school context at the district level), so that column is
#' present only for \code{level = "school"}.
#'
#' Percentages are published as strings (e.g. \code{"6.8\%"}) and coerced to
#' numeric. Suppression strings (\code{"Enrollment for the group is <10
#' students."}, \code{"Fewer than 5 students earned a seal."}) become \code{NA},
#' never a fabricated number. Student-group labels are normalized by
#' \code{\link{clean_spr_subgroups}} (e.g. \code{"total population"},
#' \code{"economically disadvantaged"}, \code{"limited english proficiency"}).
#'
#' Note: the StudentGroup sheet has no statewide aggregate \emph{row}; the
#' state rate for each group is carried in the
#' \code{students_earning_seal_pct_state} column on every row.
#'
#' @param end_year Must be 2025 (the only year the sheet exists).
#' @param level One of \code{"school"} or \code{"district"}.
#'
#' @return Data frame with entity identifiers, \code{school_year},
#'   \code{subgroup}, the per-group seal-earning rates (\code{*_pct_school} for
#'   school level only, plus \code{*_pct_district} and \code{*_pct_state}), and
#'   the standard aggregation flags.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Seal-earning rate by student group for every school (2024-25)
#' bg <- fetch_biliteracy_by_group(2025)
#'
#' # Equity gap: economically disadvantaged vs total, statewide-by-district
#' library(dplyr)
#' fetch_biliteracy_by_group(2025, level = "district") %>%
#'   filter(subgroup %in% c("total population", "economically disadvantaged")) %>%
#'   select(district_name, subgroup, students_earning_seal_pct_district)
#'
#' # English-learner seal rate at one school
#' fetch_biliteracy_by_group(2025) %>%
#'   filter(district_id == "3570", subgroup == "limited english proficiency") %>%
#'   select(school_name, subgroup, students_earning_seal_pct_school)
#' }
fetch_biliteracy_by_group <- function(end_year, level = "school") {
  .validate_biliteracy_redesign(end_year, level, "fetch_biliteracy_by_group")

  df <- njschooldata::fetch_spr_data(
    sheet_name = "SealofBiliteracy_StudentGroup",
    end_year = end_year,
    level = level
  )

  pct_cols <- c(
    "students_earning_seal_pct_school",
    "students_earning_seal_pct_district",
    "students_earning_seal_pct_state"
  )
  for (col in pct_cols) {
    if (col %in% names(df)) df[[col]] <- spr_value_numeric(df[[col]])
  }

  df %>%
    dplyr::select(
      end_year,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      dplyr::any_of("school_year"),
      subgroup,
      dplyr::any_of(pct_cols),
      is_state, is_county, is_district, is_school,
      is_charter, is_charter_sector, is_allpublic
    )
}
