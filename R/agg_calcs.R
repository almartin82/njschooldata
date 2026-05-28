# ==============================================================================
# Aggregation Calculation Functions
# ==============================================================================
#
# Functions for calculating aggregate statistics across different data types.
# Used by charter sector and ward aggregation functions in charter.R.
#
# ==============================================================================

# -----------------------------------------------------------------------------
# Name Collapsing Utility
# -----------------------------------------------------------------------------

#' Ensure an apportionment \code{share} column exists
#'
#' \code{\link{id_charter_hosts}} adds a \code{share} column (the multi-campus
#' charter apportionment weight; 1.0 for single-host charters and non-charters).
#' Aggregation helpers multiply summed counts by \code{share} so an apportioned
#' charter contributes \code{share} of its NJ-reported total to each host city,
#' preserving the charter total exactly. Some inputs never pass through
#' \code{id_charter_hosts} (e.g. \code{calculate_agg_parcc_prof}); for those this
#' helper supplies \code{share = 1}, leaving counts unchanged. The
#' grouping/grouped-ness of the input is preserved.
#'
#' @param df data frame (possibly grouped) being summarized
#' @return df with a \code{share} column guaranteed present
#' @keywords internal
ensure_appt_share <- function(df) {
  if ('share' %in% names(df)) return(df)
  dplyr::mutate(df, share = 1)
}


#' Collapse repeated names in aggregation output
#'
#' When aggregating across schools/districts, \code{toString()} produces
#' long strings with duplicated names (e.g., the same school repeated for
#' each grade). This function deduplicates: if all names are the same, returns
#' the single name; if names differ, returns each unique name with its count.
#'
#' @param name_vector Character vector of names to collapse
#' @return Single collapsed string
#' @export
#' @examples
#' \dontrun{
#' # Same school across grades
#' collapse_agg_names(c("School A", "School A", "School A"))
#' # => "School A"
#'
#' # Multiple schools
#' collapse_agg_names(c("School A", "School A", "School B"))
#' # => "School A (2), School B (1)"
#' }
collapse_agg_names <- function(name_vector) {
  counts <- table(name_vector)

  if (length(counts) == 1) {
    # All the same name — just return it once
    return(names(counts)[1])
  }

  # Multiple unique names — include counts, sorted by frequency descending
  counts <- sort(counts, decreasing = TRUE)
  paste0(names(counts), " (", counts, ")", collapse = ", ")
}


# -----------------------------------------------------------------------------
# Graduation Rate Aggregation
# -----------------------------------------------------------------------------

#' Aggregate multiple grad rate rows and produce summary statistics
#'
#' @param df grouped df of grate data
#'
#' @return df with aggregate stats for whatever grouping was provided
#' @export
grate_aggregate_calcs <- function(df) {
  df %>%
    ensure_appt_share() %>%
    dplyr::mutate(
      grad_rate = as.numeric(grad_rate)
    ) %>%
    dplyr::summarize(
      cohort_count = sum(cohort_count * share, na.rm = TRUE),
      graduated_count = sum(graduated_count * share, na.rm = TRUE),
      districts = collapse_agg_names(district_name),
      schools = collapse_agg_names(school_name),
      n_charter_rows = sum(is_charter, na.rm = TRUE)
    ) %>%
    dplyr::mutate(
      grad_rate = round(graduated_count / cohort_count, 3),
      districts = districts,
      schools = schools
    )
}


#' Aggregate multiple grad count rows and produce summary statistics
#'
#' @param df grouped df of gcount data
#'
#' @return df with aggregate stats for whatever grouping was provided
#' @export
gcount_aggregate_calcs <- function(df) {
  df %>%
    ensure_appt_share() %>%
    dplyr::summarize(
      cohort_count = sum(cohort_count * share, na.rm = TRUE),
      graduated_count = sum(graduated_count * share, na.rm = TRUE),
      districts = collapse_agg_names(district_name),
      schools = collapse_agg_names(school_name),
      n_charter_rows = sum(is_charter, na.rm = TRUE)
    )
}


# -----------------------------------------------------------------------------
# PARCC/NJSLA Assessment Aggregation
# -----------------------------------------------------------------------------

#' PARCC counts by performance level
#'
#' Calculates the count of students at each performance level based on
#' percentages and total valid scores.
#'
#' @param df dataframe, output of fetch_parcc
#'
#' @return df with counts of students by performance level
#' @export
parcc_perf_level_counts <- function(df) {
  df %>%
    dplyr::mutate(
      num_l1 = round((pct_l1 / 100) * number_of_valid_scale_scores, 0),
      num_l2 = round((pct_l2 / 100) * number_of_valid_scale_scores, 0),
      num_l3 = round((pct_l3 / 100) * number_of_valid_scale_scores, 0),
      num_l4 = round((pct_l4 / 100) * number_of_valid_scale_scores, 0),
      num_l5 = round((pct_l5 / 100) * number_of_valid_scale_scores, 0)
    )
}


#' Aggregate multiple PARCC rows and produce summary statistics
#'
#' @param df grouped df of PARCC data
#'
#' @return df with aggregate stats for whatever grouping was provided
#' @export
parcc_aggregate_calcs <- function(df) {
  df %>%
    ensure_appt_share() %>%
    dplyr::mutate(
      scale_score_mean = as.numeric(scale_score_mean),
      scale_score_numerator = scale_score_mean * number_of_valid_scale_scores
    ) %>%
    dplyr::summarize(
      number_enrolled = sum(number_enrolled * share, na.rm = TRUE),
      number_not_tested = sum(number_not_tested * share, na.rm = TRUE),
      number_of_valid_scale_scores = sum(number_of_valid_scale_scores * share, na.rm = TRUE),
      scale_score_mean = sum(scale_score_numerator * share, na.rm = TRUE),
      num_l1 = sum(num_l1 * share, na.rm = TRUE),
      num_l2 = sum(num_l2 * share, na.rm = TRUE),
      num_l3 = sum(num_l3 * share, na.rm = TRUE),
      num_l4 = sum(num_l4 * share, na.rm = TRUE),
      num_l5 = sum(num_l5 * share, na.rm = TRUE),
      districts = collapse_agg_names(district_name),
      schools = collapse_agg_names(school_name),
      n_charter_rows = sum(is_charter, na.rm = TRUE)
    ) %>%
    dplyr::mutate(
      pct_l1 = round((num_l1 / number_of_valid_scale_scores) * 100, 1),
      pct_l2 = round((num_l2 / number_of_valid_scale_scores) * 100, 1),
      pct_l3 = round((num_l3 / number_of_valid_scale_scores) * 100, 1),
      pct_l4 = round((num_l4 / number_of_valid_scale_scores) * 100, 1),
      pct_l5 = round((num_l5 / number_of_valid_scale_scores) * 100, 1),
      scale_score_mean = round(scale_score_mean / number_of_valid_scale_scores, 2),
      proficient_above = round(((num_l4 + num_l5) / number_of_valid_scale_scores) * 100, 2),
      districts = districts,
      schools = schools
    )
}


#' Aggregate PARCC results across multiple grade levels
#'
#' @description a wrapper around fetch_parcc and parcc_aggregate_calcs that simplifies
#' the calculation of multi-grade PARCC aggregations
#'
#' @param end_year school year / testing year
#' @param subj one of 'ela' or 'math'
#' @param gradespan one of c('3-11', '3-8', '9-11').  default is '3-11'
#'
#' @return dataframe
#' @export
calculate_agg_parcc_prof <- function(end_year, subj, gradespan = "3-11") {
  # grade and subjects to map over
  if (subj == "ela" & gradespan == "3-11" & end_year >= 2019) {
    grades <- c(3:10)
  } else if (subj == "ela" & gradespan == "3-11" & end_year < 2019) {
    grades <- c(3:11)
  } else if (subj == "ela" & gradespan == "3-8") {
    grades <- c(3:8)
  } else if (subj == "ela" & gradespan == "9-11" & end_year >= 2019) {
    grades <- c(9:10)
  } else if (subj == "ela" & gradespan == "9-11" & end_year < 2019) {
    grades <- c(9:11)
  } else if (subj == "math" & gradespan == "3-11") {
    grades <- c("03", "04", "05", "06", "07", "08", "ALG1", "GEO", "ALG2")
  } else if (subj == "math" & gradespan == "3-8") {
    grades <- c(3:8)
  } else if (subj == "math" & gradespan == "9-11") {
    grades <- c("ALG1", "GEO", "ALG2")
  } else {
    stop("invalid subject")
  }

  # get relevant PARCC files
  all_grades <- purrr::map_df(
    grades,
    function(x) {
      fetch_parcc(
        end_year = end_year,
        grade_or_subj = x,
        subj = subj,
        tidy = TRUE
      )
    }
  )

  # get the counts from percentages
  all_grades <- parcc_perf_level_counts(all_grades)

  # group, aggregate, return
  all_grades %>%
    dplyr::filter(!is.na(county_id)) %>%
    dplyr::group_by(
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      subgroup,
      subgroup_type,
      testing_year,
      assess_name,
      test_name,
      is_state, is_dfg,
      is_district, is_school, is_charter,
      is_charter_sector,
      is_allpublic
    ) %>%
    parcc_aggregate_calcs() %>%
    dplyr::ungroup() %>%
    dplyr::mutate(
      grade = gradespan
    )
}


# -----------------------------------------------------------------------------
# Matriculation Aggregation
# -----------------------------------------------------------------------------

#' Aggregate multiple postsecondary matriculation rows and produce
#' summary statistics
#'
#' @param df grouped df of postsecondary matriculation data
#'
#' @return data_frame
#' @export
matric_aggregate_calcs <- function(df) {
  df %>%
    ensure_appt_share() %>%
    dplyr::summarize(
      graduated_count = sum(graduated_count * share, na.rm = TRUE),
      cohort_count = sum(cohort_count * share, na.rm = TRUE),
      enroll_any_count = sum(enroll_any_count * share, na.rm = TRUE),
      enroll_2yr_count = sum(enroll_2yr_count * share, na.rm = TRUE),
      enroll_4yr_count = sum(enroll_4yr_count * share, na.rm = TRUE),
      n_charter_rows = sum(is_charter, na.rm = TRUE)
    ) %>%
    dplyr::mutate(
      enroll_any = round(enroll_any_count / graduated_count * 100, 1),
      enroll_2yr = round(enroll_2yr_count / enroll_any_count * 100, 1),
      enroll_4yr = round(enroll_4yr_count / enroll_any_count * 100, 1)
    ) %>%
    dplyr::ungroup() %>%
    return()
}


#' Matriculation column order
#'
#' Puts matriculation data frame columns in standard order.
#'
#' @param df Processed matriculation df
#' @return Data frame with columns in correct order
#' @export
matric_column_order <- function(df) {
  df %>%
    dplyr::select(
      end_year,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      subgroup,
      cohort_count, graduated_count,
      enroll_any_count, enroll_any,
      enroll_4yr_count, enroll_4yr,
      enroll_2yr_count, enroll_2yr,
      dplyr::one_of("n_charter_rows"),
      is_16mo,
      is_state,
      dplyr::one_of("is_county"),
      is_district,
      is_school,
      is_charter,
      is_charter_sector,
      is_allpublic
    )
}


#' Aggregates matriculation data by district
#'
#' Only school-level matriculation data reported before 2017. This function
#' approximates district level results. If schools within the district do not
#' report for certain subgroups, the approximation will be further off.
#'
#' @param df output of \code{enrich_matric_counts}
#'
#' @return A data frame of district aggregations
#' @export
district_matric_aggs <- function(df) {
  sum_df <- df %>%
    dplyr::filter(!is.nan(enroll_any) & !is.nan(enroll_4yr) & !is.nan(enroll_2yr)) %>%
    dplyr::group_by(
      end_year,
      county_id, county_name,
      district_id, district_name,
      subgroup,
      is_16mo
    ) %>%
    matric_aggregate_calcs() %>%
    dplyr::ungroup()

  sum_df %>%
    dplyr::mutate(
      # should aggregated districts be distinguished somehow?
      district_id = district_id,
      district_name = district_name,
      school_id = "999",
      school_name = "Aggregated District Total",
      is_state = FALSE,
      is_county = FALSE,
      is_district = TRUE,
      is_charter = FALSE,
      is_school = FALSE,
      is_charter_sector = FALSE,
      is_allpublic = FALSE
    ) %>%
    matric_column_order() %>%
    return()
}


# -----------------------------------------------------------------------------
# Special Populations Aggregation
# -----------------------------------------------------------------------------

#' Aggregate multiple special populations rows and produce summary
#' statistics
#'
#' @param df grouped df of special populations data
#'
#' @return data_frame
#' @export
spec_pop_aggregate_calcs <- function(df) {
  df %>%
    ensure_appt_share() %>%
    dplyr::summarize(
      n_students = sum(n_students * share, na.rm = TRUE),
      n_enrolled = sum(n_enrolled * share, na.rm = TRUE),
      n_charter_rows = sum(is_charter, na.rm = TRUE)
    ) %>%
    dplyr::mutate(
      percent = round(n_students / n_enrolled * 100, 1)
    ) %>%
    dplyr::ungroup() %>%
    return()
}

#' Helper function to return aggregate special populations columns in
#' correct order
#'
#' @param df aggregate special populations df
#'
#' @return data_frame
#' @export
agg_spec_pop_column_order <- function(df) {
  df %>%
    dplyr::select(
      dplyr::one_of(
        "end_year", "county_id", "county_name",
        "district_id", "district_name", "subgroup",
        "n_students", "n_enrolled", "percent"
      )
    ) %>%
    return()
}


# -----------------------------------------------------------------------------
# Special Education Aggregation
# -----------------------------------------------------------------------------

#' Aggregate multiple sped rows and produce summary statistics
#'
#' @param df grouped df of sped data
#'
#' @return df with aggregate stats for whatever grouping was provided
#' @export
sped_aggregate_calcs <- function(df) {
  df %>%
    ensure_appt_share() %>%
    dplyr::summarize(
      gened_num = sum(gened_num * share, na.rm = TRUE),
      sped_num = sum(sped_num * share, na.rm = TRUE),
      sped_num_no_speech = sum(sped_num_no_speech * share, na.rm = TRUE),
      n_charter_rows = sum(is_charter, na.rm = TRUE)
    ) %>%
    dplyr::mutate(
      sped_rate = round(sped_num / gened_num * 100, 2),
      sped_rate_no_speech = round(sped_num_no_speech / gened_num * 100, 2)
    )
}


#' Helper function to return aggregate sped columns in correct order
#'
#' @param df aggregate sped dataframe
#'
#' @return data.frame
#' @export
agg_sped_column_order <- function(df) {
  df %>%
    dplyr::select(
      dplyr::one_of(
        "end_year", "county_name", "district_id", "district_name",
        "gened_num", "sped_num", "sped_rate", "sped_num_no_speech",
        "sped_rate_no_speech"
      )
    ) %>%
    return()
}
