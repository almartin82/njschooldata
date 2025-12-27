# ==============================================================================
# Enrollment Data Tidying Functions
# ==============================================================================
#
# This file contains functions for transforming enrollment data from wide
# format to long (tidy) format and identifying aggregation levels.
#
# ==============================================================================

#' Tidy enrollment data
#'
#' Transforms wide enrollment data to long format with subgroup column.
#'
#' @param df A wide data.frame of processed enrollment data - eg output of `fetch_enr`
#' @return A long data.frame of tidied enrollment data
#' @export
tidy_enr <- function(df) {

  # invariant cols
  invariants <- c(
    "end_year", "CDS_Code",
    "county_id", "county_name",
    "district_id", "district_name",
    "school_id", "school_name",
    "program_code", "program_name", "grade_level"
  )

  # cols to tidy
  to_tidy <- c(
    "male", "female",
    "white", "black", "hispanic",
    "asian", "native_american", "pacific_islander", "multiracial",
    "white_m", "white_f",
    "black_m", "black_f",
    "hispanic_m", "hispanic_f",
    "asian_m", "asian_f",
    "native_american_m", "native_american_f",
    "pacific_islander_m", "pacific_islander_f",
    "multiracial_m", "multiracial_f"
  )

  # limit to cols in df
  to_tidy <- to_tidy[to_tidy %in% names(df)]

  # iterate over cols to tidy, do calculations
  tidy_subgroups <- purrr::map_df(
    to_tidy,
    function(.x) {
      df %>%
        dplyr::rename(n_students = .x) %>%
        dplyr::select(dplyr::one_of(invariants, "n_students", "row_total")) %>%
        dplyr::mutate(
          subgroup = .x,
          pct = n_students / row_total
        ) %>%
        dplyr::select(dplyr::one_of(invariants, "subgroup", "n_students", "pct"))
    }
  )

  # also extract row total as a "subgroup"
  tidy_total_enr <- df %>%
    dplyr::select(dplyr::one_of(invariants, "row_total")) %>%
    dplyr::mutate(
      n_students = row_total,
      subgroup = "total_enrollment",
      pct = n_students / row_total
    ) %>%
    dplyr::select(dplyr::one_of(invariants, "subgroup", "n_students", "pct"))

  # some subgroups are only reported for school totals
  # just total counts, for extracting total enr, free, reduced, migrant etc
  total_counts <- df %>%
    dplyr::filter(program_code == "55") %>%
    # create free and reduced group
    dplyr::rowwise() %>%
    dplyr::mutate(free_reduced_lunch = sum(free_lunch, reduced_lunch, na.rm = TRUE))

  total_subgroups <- c("free_lunch", "reduced_lunch", "lep", "migrant", "free_reduced_lunch")
  total_subgroups <- total_subgroups[total_subgroups %in% names(total_counts)]

  # iterate over cols to tidy, do calculations
  tidy_total_subgroups <- purrr::map_df(
    total_subgroups,
    function(.x) {
      total_counts %>%
        dplyr::rename(n_students = .x) %>%
        dplyr::select(dplyr::one_of(invariants, "n_students", "row_total")) %>%
        dplyr::mutate(
          subgroup = .x,
          pct = n_students / row_total
        ) %>%
        dplyr::select(dplyr::one_of(invariants, "subgroup", "n_students", "pct"))
    }
  )

  # put it all together in a long data frame
  dplyr::bind_rows(tidy_total_enr, tidy_total_subgroups, tidy_subgroups) %>%
    dplyr::filter(!is.na(n_students) | !is.na(pct))
}


#' Identify enrollment aggregation levels
#'
#' Adds boolean flags to identify state, county, district, and school level records.
#'
#' @param df Enrollment dataframe, output of tidy_enr
#' @return data.frame with boolean aggregation flags
#' @export
id_enr_aggs <- function(df) {
  df %>%
    dplyr::mutate(
      is_state = district_id == "9999" & county_id == "99",
      is_county = district_id == "9999" & !county_id == "99",
      is_district = school_id == "999" & !is_state,
      is_charter_sector = FALSE,
      is_allpublic = FALSE,
      is_school = !school_id == "999" & !is_state,
      is_subprogram = !program_code == "55"
    )
}


#' Custom Enrollment Grade Level Aggregates
#'
#' Creates aggregations for common grade groupings: PK (Any), K (Any),
#' K-12, K-12UG, K-8, and HS.
#'
#' @param df A tidy enrollment df
#' @return df of aggregated enrollment data
#' @export
enr_grade_aggs <- function(df) {

  gr_aggs_group_logic <- . %>%
    dplyr::group_by(
      end_year,
      CDS_Code,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      subgroup,
      is_state, is_county, is_district,
      is_charter_sector, is_allpublic, is_school, is_subprogram
    ) %>%
    dplyr::summarize(
      n_students = sum(n_students, na.rm = TRUE),
      .groups = "drop"
    )

  gr_aggs_col_order <- . %>%
    dplyr::select(
      end_year, CDS_Code,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      program_code, program_name, grade_level,
      subgroup,
      n_students,
      pct,
      pct_total_enr,
      is_state, is_county,
      is_district, is_charter_sector, is_allpublic,
      is_school,
      is_subprogram
    )

  # Any PK
  pk_agg <- df %>%
    dplyr::filter(grade_level == "PK") %>%
    gr_aggs_group_logic() %>%
    dplyr::mutate(
      program_code = "PK",
      program_name = "Pre-Kindergarten (Full + Half)",
      grade_level = "PK (Any)",
      pct = NA_real_,
      pct_total_enr = NA_real_
    ) %>%
    gr_aggs_col_order()

  # Any K (half + full day K)
  k_agg <- df %>%
    dplyr::filter(grade_level == "K") %>%
    gr_aggs_group_logic() %>%
    dplyr::mutate(
      program_code = "0K",
      program_name = "Kindergarten (Full + Half)",
      grade_level = "K (Any)",
      pct = NA_real_,
      pct_total_enr = NA_real_
    ) %>%
    gr_aggs_col_order()

  # K-12 enrollment (exclude pre-k)
  k12_agg <- df %>%
    dplyr::filter(
      grade_level %in% c(
        "K",
        "01", "02", "03", "04",
        "05", "06", "07", "08",
        "09", "10", "11", "12"
      )
    ) %>%
    gr_aggs_group_logic() %>%
    dplyr::mutate(
      program_code = "K12",
      program_name = "K to 12 Total",
      grade_level = "K12",
      pct = NA_real_,
      pct_total_enr = NA_real_
    ) %>%
    gr_aggs_col_order()

  # All but PK enrollment (K12 + ungraded)
  nopk_agg <- df %>%
    dplyr::filter(
      grade_level %in% c(
        "K",
        "01", "02", "03", "04",
        "05", "06", "07", "08",
        "09", "10", "11", "12"
      ) |
        program_code == "UG"
    ) %>%
    gr_aggs_group_logic() %>%
    dplyr::mutate(
      program_code = "K12UG",
      program_name = "K to 12 Total, UG inclusive",
      grade_level = "K12UG",
      pct = NA_real_,
      pct_total_enr = NA_real_
    ) %>%
    gr_aggs_col_order()

  # K-8 enrollment
  k8_agg <- df %>%
    dplyr::filter(
      grade_level %in% c(
        "K",
        "01", "02", "03", "04",
        "05", "06", "07", "08"
      )
    ) %>%
    gr_aggs_group_logic() %>%
    dplyr::mutate(
      program_code = "K8",
      program_name = "K to 8 Total",
      grade_level = "K8",
      pct = NA_real_,
      pct_total_enr = NA_real_
    ) %>%
    gr_aggs_col_order()

  # HS
  hs_agg <- df %>%
    dplyr::filter(grade_level %in% c("09", "10", "11", "12")) %>%
    gr_aggs_group_logic() %>%
    dplyr::mutate(
      program_code = "HS",
      program_name = "HS (9-12) Total",
      grade_level = "HS",
      pct = NA_real_,
      pct_total_enr = NA_real_
    ) %>%
    gr_aggs_col_order()

  dplyr::bind_rows(pk_agg, k_agg, k12_agg, nopk_agg, k8_agg, hs_agg)
}
