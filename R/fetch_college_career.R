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
#' @param end_year A school year (2017-2024). Year is the end of the academic
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
  df <- njschooldata::fetch_spr_data(
    sheet_name = "PSAT-SAT-ACTParticipation",
    end_year = end_year,
    level = level
  )

  # Rename participation columns (they come as SAT, ACT, PSAT)
  df <- df %>%
    dplyr::rename(
      sat_participation = SAT,
      act_participation = ACT,
      psat_participation = PSAT,
      state_sat = STATE_SAT,
      state_act = STATE_ACT,
      state_psat = STATE_PSAT
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
#' @param end_year A school year (2017-2024). Year is the end of the academic
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
  df <- njschooldata::fetch_spr_data(
    sheet_name = "PSAT-SAT-ACTPerformance",
    end_year = end_year,
    level = level
  )

  # Rename and clean columns
  df <- df %>%
    dplyr::rename(
      test_type = Test,
      subject = Subject,
      school_avg = School_Avg,
      state_avg = State_avg,
      benchmark = Benchmark,
      pct_benchmark = BT_PCT,
      state_pct_benchmark = STATE_BT_PCT
    ) %>%
    # Filter by test type if specified
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
#' @param end_year A school year (2017-2024). Year is the end of the academic
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
  df <- njschooldata::fetch_spr_data(
    sheet_name = "APIBCourseworkPartPerf",
    end_year = end_year,
    level = level
  )

  # Rename columns (after clean_name_vector conversion)
  # APIB_COURSE_SCHOOL → apib_course_school
  # AP3_IB4_SCHOOL → ap_3_ib_4_school
  # DUAL_SCHOOL → dual_school
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
    ) %>%
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
#' @param end_year A school year (2017-2024)
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
#' @param end_year A school year (2017-2024). Year is the end of the academic
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
#' @param end_year A school year (2017-2024). Year is the end of the academic
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

  # Rename columns (after clean_name_vector conversion)
  # SchoolCTEParticipants → school_cteparticipants
  # SchoolCTEConcentrators → school_cteconcentrators
  # StateCTEParticipants → state_cteparticipants
  # StateCTEConcentrators → state_cteconcentrators
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
#' @param end_year A school year (2017-2024). Year is the end of the academic
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
  df <- njschooldata::fetch_spr_data(
    sheet_name = "IndustryValuedCredentialsEarned",
    end_year = end_year,
    level = level
  )

  # Rename columns (after clean_name_vector conversion)
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
#' @param end_year A school year (2017-2024). Year is the end of the academic
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
  df <- njschooldata::fetch_spr_data(
    sheet_name = "WorkbasedLearningByCareerClust",
    end_year = end_year,
    level = level
  )

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
#' @param end_year A school year (2017-2024). Year is the end of the academic
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

  # Apprenticeship sheet has year columns 2016-2023
  # After clean_name_vector, they become x_2016, x_2017, etc.
  # Rename them to year_2016, year_2017, etc.
  year_cols <- grep("^x_20(1[6-9]|2[0-3])$", names(df), value = TRUE)
  new_names <- gsub("^x_", "year_", year_cols)

  df <- df %>%
    dplyr::rename(!!setNames(new_names, year_cols))

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
#' @param end_year A school year (2017-2024). Year is the end of the academic
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
  df <- njschooldata::fetch_spr_data(
    sheet_name = "SealofBiliteracy",
    end_year = end_year,
    level = level
  )

  # Rename columns
  df <- df %>%
    dplyr::rename(
      language = Language,
      seals_earned = SealsEarned,
      pct_12th_graders = Perc12Graders
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
