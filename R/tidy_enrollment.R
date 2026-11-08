# ==============================================================================
# Enrollment Data Tidying Functions
# ==============================================================================
#
# This file contains functions for transforming enrollment data from wide
# format to long (tidy) format and identifying aggregation levels.
#
# ==============================================================================

.enr_program_subgroups <- c(
  "free_lunch", "reduced_lunch", "lep", "migrant", "free_reduced_lunch", "military", "homeless"
)

#' Tidy enrollment data
#'
#' Transforms wide enrollment data to long format with subgroup column.
#'
#' @param df A wide data.frame of processed enrollment data - eg output of `fetch_enr`
#' @return A long data frame with `value_source` describing count provenance.
#'   Published counts use `"published"`. Where a workbook supplies only a
#'   rate, the count uses `"derived_from_pct"` when the same row's published
#'   total is available and `"published_pct_only"` otherwise. The
#'   `free_reduced_lunch` subgroup inherits the weaker of its component
#'   labels. From 2023, published program counts are
#'   available by grade for the state and at all grades for districts and
#'   schools. `published_pct` contains a workbook's published program rate
#'   or statewide Non-Binary rate as a fraction where available.
#'   `pct` is the count divided by the row total. The 2024 statewide
#'   `non_binary` rows carry `value_source = "not_reported"` with `n_students`,
#'   `pct` and `published_pct` all `NA`: NJ DOE's 2023-24 file printed 0 in
#'   every Non-Binary cell, a category it did not collect that year.
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
  state <- if ("cds_code" %in% names(df)) df$cds_code == "999999999" else FALSE

  # cols to tidy
  to_tidy <- c(
    "male", "female", "non_binary",
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
      statewide_non_binary <- identical(.x, "non_binary")
      rows <- df
      source_pct <- NA_real_
      row_source <- "published"
      if (statewide_non_binary) {
        published <- !is.na(df$non_binary)
        if ("non_binary_value_source" %in% names(df)) {
          # "not_reported" rows (2024, see .enr_nonbinary_not_reported()) stay
          # in the output with n_students NA so the gap is visible, not absent.
          published <- published |
            df$non_binary_value_source %in% c("published", "not_reported")
        }
        if ("non_binary_published_pct" %in% names(df)) {
          published <- published | !is.na(df$non_binary_published_pct)
        }
        rows <- df[which(state & published), , drop = FALSE]
        if ("non_binary_published_pct" %in% names(rows)) {
          source_pct <- rows$non_binary_published_pct / 100
        }
        if ("non_binary_value_source" %in% names(rows)) {
          row_source <- dplyr::coalesce(rows$non_binary_value_source, "published")
        }
      }
      rows %>%
        dplyr::rename(n_students = dplyr::all_of(.x)) %>%
        dplyr::select(dplyr::one_of(invariants, "n_students", "row_total")) %>%
        dplyr::mutate(
          subgroup = .x,
          pct = n_students / row_total,
          value_source = row_source,
          published_pct = source_pct,
          .keep_unobserved = statewide_non_binary
        ) %>%
        dplyr::select(dplyr::one_of(invariants, "subgroup", "n_students", "pct", "value_source",
                                   "published_pct", ".keep_unobserved"))
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

  # Modern State sheets publish grade-level program counts. District and
  # School sheets publish programs only on their all-grades rows.
  has_grade_programs <- if ("end_year" %in% names(df)) .enr_has_grade_programs(df$end_year) else FALSE
  program_rows <- df$program_code == "55" | (has_grade_programs & state & !is.na(df$program_code))
  program_counts <- df[which(program_rows), , drop = FALSE] %>%
    # A missing component leaves the combined count unknown.
    dplyr::mutate(free_reduced_lunch = free_lunch + reduced_lunch)

  program_subgroups <- intersect(.enr_program_subgroups, names(program_counts))
  if (!any(has_grade_programs, na.rm = TRUE)) {
    program_subgroups <- setdiff(program_subgroups, c("military", "homeless"))
  }

  # iterate over cols to tidy, do calculations
  #
  # Program fields carry a per-field "<field>_value_source" column in modern
  # files. Earlier published counts can omit the marker.
  # free_reduced_lunch has no marker of its own (it is a same-row sum of the two
  # already-labelled components computed above); it inherits the weaker label.
  tidy_program_subgroups <- purrr::map_df(
    program_subgroups,
    function(.x) {
      source_col <- paste0(.x, "_value_source")
      pct_col <- paste0(.x, "_published_pct")

      df_i <- program_counts %>%
        dplyr::rename(n_students = dplyr::all_of(.x))
      if (.x %in% c("military", "homeless")) {
        df_i <- dplyr::filter(df_i, .enr_has_grade_programs(end_year))
      }
      df_i$published_pct <- if (pct_col %in% names(df_i)) {
        df_i[[pct_col]] / 100
      } else {
        rep(NA_real_, nrow(df_i))
      }
      modern_rows <- if ("end_year" %in% names(df_i)) .enr_has_grade_programs(df_i$end_year) else FALSE
      df_i$.keep_unobserved <- rep(FALSE, nrow(df_i))

      if (source_col %in% names(df_i)) {
        df_i$.keep_unobserved <- modern_rows & df_i[[source_col]] %in% "published"
        df_i <- df_i %>%
          dplyr::rename(value_source = dplyr::all_of(source_col)) %>%
          # The marker is only ever set for rows that went through the
          # pct_cols derivation loop (district/school, 2020+). Rows that
          # never went through it -- the statewide row, bound in separately
          # from the State worksheet, which publishes real counts
          # directly -- carry NA here, not because
          # provenance is unknown but because no derivation was attempted.
          dplyr::mutate(value_source = dplyr::coalesce(value_source, "published"))
      } else if (identical(.x, "free_reduced_lunch") &&
                   all(c("free_lunch_value_source", "reduced_lunch_value_source") %in% names(df_i))) {
        df_i$.keep_unobserved <- modern_rows &
          df_i$free_lunch_value_source %in% "published" &
          df_i$reduced_lunch_value_source %in% "published"
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
        dplyr::select(dplyr::one_of(invariants, "n_students", "row_total", "value_source", "published_pct",
                                    ".keep_unobserved")) %>%
        dplyr::mutate(
          subgroup = .x,
          pct = n_students / row_total
        ) %>%
        dplyr::select(dplyr::one_of(invariants, "subgroup", "n_students", "pct", "value_source", "published_pct",
                                    ".keep_unobserved"))
    }
  )

  # put it all together in a long data frame
  result <- dplyr::bind_rows(tidy_total_enr, tidy_program_subgroups, tidy_subgroups)
  if (!"published_pct" %in% names(result)) {
    result$published_pct <- rep(NA_real_, nrow(result))
  }
  if (!".keep_unobserved" %in% names(result)) {
    result$.keep_unobserved <- rep(FALSE, nrow(result))
  }
  result %>%
    dplyr::filter(!is.na(n_students) | !is.na(pct) | !is.na(published_pct) | .keep_unobserved) %>%
    dplyr::select(-.keep_unobserved)
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
      # isTRUE()/%in%: an empty group (eg HS for a K-8 district) has NA firsts.
      n_students = if (dplyr::first(subgroup) %in% "non_binary" ||
                       (isTRUE(.enr_has_grade_programs(dplyr::first(end_year))) &&
                        dplyr::first(subgroup) %in% .enr_program_subgroups)) {
        sum(n_students)
      } else {
        sum(n_students, na.rm = TRUE)
      },
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
