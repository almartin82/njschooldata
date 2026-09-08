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
#' @return A long data.frame of tidied enrollment data. Carries a `value_source`
#'   column: `"published"` for race/gender/total_enrollment subgroups (always a
#'   real published headcount) and for free_lunch/reduced_lunch/lep/migrant in
#'   pre-2020 files; `"derived_from_pct"` or `"published_pct_only"` for
#'   free_lunch/reduced_lunch/lep/migrant from 2020+ files, where NJ DOE
#'   publishes only a percentage and the count is computed as
#'   `pct / 100 * row_total` (see `fetch_enrollment.R`'s `pct_cols` loop; this
#'   value is NOT rounded to a whole student); `free_reduced_lunch` inherits
#'   the weaker of its two component labels since it sums them.
#' @export
tidy_enr <- function(df) {

  # invariant cols
  invariants <- c(
    "end_year", "cds_code",
    "county_id", "county_name",
    "district_id", "district_name",
    "school_id", "school_name",
    "nces_dist", "nces_sch",
    "program_code", "program_name", "grade_level"
  )

  # Keep only invariants present in df, so callers that did not attach NCES ids
  # (e.g. legacy callers of tidy_enr on a raw frame) still work.
  invariants <- invariants[invariants %in% names(df)]

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
  # Race/gender subgroups are always a real published headcount (summed from
  # published m/f component counts upstream in enr_aggs()), never derived from
  # a percentage -- value_source is unconditionally "published".
  tidy_subgroups <- purrr::map_df(
    to_tidy,
    function(.x) {
      df %>%
        dplyr::rename(n_students = dplyr::all_of(.x)) %>%
        dplyr::select(dplyr::one_of(invariants, "n_students", "row_total")) %>%
        dplyr::mutate(
          subgroup = .x,
          pct = n_students / row_total,
          value_source = "published"
        ) %>%
        dplyr::select(dplyr::one_of(invariants, "subgroup", "n_students", "pct", "value_source"))
    }
  )

  # also extract row total as a "subgroup" -- always a real published count
  tidy_total_enr <- df %>%
    dplyr::select(dplyr::one_of(invariants, "row_total")) %>%
    dplyr::mutate(
      n_students = row_total,
      subgroup = "total_enrollment",
      pct = n_students / row_total,
      value_source = "published"
    ) %>%
    dplyr::select(dplyr::one_of(invariants, "subgroup", "n_students", "pct", "value_source"))

  # some subgroups are only reported for school totals
  # just total counts, for extracting total enr, free, reduced, migrant etc
  total_counts <- df %>%
    dplyr::filter(program_code == "55") %>%
    # create free and reduced group
    #
    # free + reduced is a two-component total. If either component is unknown
    # the combined total is UNKNOWN, so it is published as NA. `na.rm = TRUE`
    # treated a withheld component as a zero, which understated the total when
    # one component was missing and reported a flat 0 when both were -- a
    # fabricated headcount for a district the source had declined to report.
    dplyr::rowwise() %>%
    dplyr::mutate(
      free_reduced_lunch = if (anyNA(c(free_lunch, reduced_lunch))) {
        NA_real_
      } else {
        sum(free_lunch, reduced_lunch)
      }
    )

  total_subgroups <- c("free_lunch", "reduced_lunch", "lep", "migrant", "free_reduced_lunch")
  total_subgroups <- total_subgroups[total_subgroups %in% names(total_counts)]

  # iterate over cols to tidy, do calculations
  #
  # free_lunch/reduced_lunch/lep/migrant carry a per-field "<field>_value_source"
  # column from fetch_enrollment.R's pct_cols loop for 2020+ files ("derived_from_pct"
  # or "published_pct_only"). Pre-2020 files never create that column because the
  # count there is a real published headcount, never derived from a percent --
  # value_source defaults to "published" whenever the marker is absent.
  # free_reduced_lunch has no marker of its own (it is a same-row sum of the two
  # already-labelled components computed above); it inherits the weaker label.
  tidy_total_subgroups <- purrr::map_df(
    total_subgroups,
    function(.x) {
      source_col <- paste0(.x, "_value_source")

      df_i <- total_counts %>%
        dplyr::rename(n_students = dplyr::all_of(.x))

      if (source_col %in% names(df_i)) {
        df_i <- df_i %>%
          dplyr::rename(value_source = dplyr::all_of(source_col)) %>%
          # The marker is only ever set for rows that went through the
          # pct_cols derivation loop (district/school, 2020+). Rows that
          # never went through it -- the statewide row, bound in separately
          # from the State worksheet, which publishes these as real counts
          # with no percentage column at all -- carry NA here, not because
          # provenance is unknown but because no derivation was attempted.
          dplyr::mutate(value_source = dplyr::coalesce(value_source, "published"))
      } else if (identical(.x, "free_reduced_lunch") &&
                   all(c("free_lunch_value_source", "reduced_lunch_value_source") %in% names(df_i))) {
        df_i <- df_i %>%
          dplyr::mutate(
            value_source = dplyr::case_when(
              free_lunch_value_source == "published_pct_only" |
                reduced_lunch_value_source == "published_pct_only" ~ "published_pct_only",
              free_lunch_value_source == "derived_from_pct" |
                reduced_lunch_value_source == "derived_from_pct" ~ "derived_from_pct",
              TRUE ~ "published"
            )
          )
      } else {
        df_i <- df_i %>% dplyr::mutate(value_source = "published")
      }

      df_i %>%
        dplyr::select(dplyr::one_of(invariants, "n_students", "row_total", "value_source")) %>%
        dplyr::mutate(
          subgroup = .x,
          pct = n_students / row_total
        ) %>%
        dplyr::select(dplyr::one_of(invariants, "subgroup", "n_students", "pct", "value_source"))
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
  input_cols <- names(df)

  assign_entity_flags(
    df,
    district_school_ids = c("999"),
    recognize_state_label = FALSE
  ) %>%
    dplyr::mutate(
      is_district = school_id == "999" & !is_state,
      is_school = !school_id == "999" & !is_state,
      is_subprogram = !program_code == "55"
    ) %>%
    dplyr::select(
      dplyr::all_of(input_cols),
      is_state, is_county, is_district,
      is_charter, is_charter_sector, is_allpublic,
      is_school, is_subprogram
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

  # NCES ids are constant per cds_code; include them in the grouping when present
  # (via any_of) so the federal ids survive the grade-level rollups.
  gr_aggs_group_logic <- . %>%
    dplyr::group_by(
      end_year,
      cds_code,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      dplyr::across(dplyr::any_of(c("nces_dist", "nces_sch"))),
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
      end_year, cds_code,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      dplyr::any_of(c("nces_dist", "nces_sch")),
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
