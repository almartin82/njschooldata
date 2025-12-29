# ==============================================================================
# Percentile Rank Functions
# ==============================================================================
#
# Generic percentile rank calculations for any metric. These functions extend
# the assessment-specific peer_percentiles.R to work with any data type
# (graduation rates, enrollment, etc.).
#
# Inspired by MarGrady Research methodology:
# https://margrady.com/movingup/
# https://margrady.com/newbaseline/
#
# ==============================================================================

# -----------------------------------------------------------------------------
# Core Percentile Rank Primitive
# -----------------------------------------------------------------------------

#' Add percentile rank columns for any metric
#'
#' @description The fundamental building block for percentile rank calculations.
#' Given a grouped dataframe and a metric column, calculates the percentile rank
#' within each group. Percentile rank is defined as the percent of comparison
#' entities with lesser or equal performance.
#'
#' This function respects existing grouping on the dataframe. If you want to
#' calculate percentile rank within specific peer groups (e.g., DFG, county),
#' group your data appropriately before calling this function, or use
#' \code{define_peer_group()} to set up the grouping.
#'
#' Note: This differs from the simpler \code{percentile_rank(x, xo)} in util.R
#' which calculates percentile rank of a single value within a vector. This
#' function operates on dataframe columns and adds rank/percentile columns.
#'
#' @param df A dataframe, optionally grouped. Grouping defines the comparison set.
#' @param metric_col Character. The column name to rank on.
#' @param prefix Character. Optional prefix for output column names. If NULL,
#'   uses metric_col as prefix. Default NULL.
#'
#' @return df with added columns:
#'   \itemize{
#'     \item \code{{prefix}_rank}: The rank within the group (1 = lowest)
#'     \item \code{{prefix}_n}: Number of valid observations in the group
#'     \item \code{{prefix}_percentile}: Percentile rank (0-100)
#'   }
#'
#' @examples
#' \dontrun{
#' # Simple statewide percentile
#' grate %>%
#'   group_by(end_year, subgroup) %>%
#'   add_percentile_rank("grad_rate")
#'
#' # DFG peer percentile
#' grate %>%
#'   group_by(end_year, dfg, subgroup) %>%
#'   add_percentile_rank("grad_rate", prefix = "dfg")
#' }
#'
#' @export
add_percentile_rank <- function(df, metric_col, prefix = NULL) {

 if (!metric_col %in% names(df)) {
    stop(sprintf("Column '%s' not found in dataframe", metric_col))
  }

  # Use metric_col as prefix if not specified
  if (is.null(prefix)) {
    prefix <- metric_col
  }

  metric_sym <- rlang::sym(metric_col)
  rank_col <- paste0(prefix, "_rank")
  n_col <- paste0(prefix, "_n")
  pctl_col <- paste0(prefix, "_percentile")

  df %>%
    dplyr::mutate(
      .metric_valid = is.finite(!!metric_sym),
      !!rank_col := dplyr::min_rank(!!metric_sym),
      !!n_col := sum(.metric_valid, na.rm = TRUE),
      !!pctl_col := dplyr::if_else(
        .metric_valid,
        round((!!rlang::sym(rank_col) / !!rlang::sym(n_col)) * 100, 1),
        NA_real_
      )
    ) %>%
    dplyr::select(-.metric_valid)
}


# -----------------------------------------------------------------------------
# Peer Group Definition
# -----------------------------------------------------------------------------
#' Define a peer comparison group
#'
#' @description Creates grouping on a dataframe that defines which entities
#' are compared to each other for percentile rank calculations. The returned
#' df can be piped directly to \code{percentile_rank()}.
#'
#' @param df Dataframe with entity identifiers
#' @param peer_type Character. One of:
#'   \itemize{
#'     \item "statewide": Compare to all districts/schools in state
#'     \item "dfg": Compare within District Factor Group
#'     \item "county": Compare within county
#'     \item "custom": Compare to custom list of district_ids
#'   }
#' @param custom_ids Character vector of district_ids for custom peer groups.
#'   Only used when peer_type = "custom".
#' @param level Character. One of "district" or "school" - what level to compare.
#' @param year_col Character. Name of the year column. Default "end_year".
#' @param additional_groups Character vector. Additional columns to group by
#'   (e.g., "subgroup", "grade", "test_name").
#'
#' @return Grouped dataframe ready for \code{add_percentile_rank()}
#'
#' @examples
#' \dontrun{
#' # DFG peer group for districts
#' grate %>%
#'   define_peer_group("dfg", level = "district") %>%
#'   add_percentile_rank("grad_rate")
#'
#' # Custom peer group (DFG A districts)
#' grate %>%
#'   define_peer_group("custom", custom_ids = dfg_a_districts, level = "district") %>%
#'   add_percentile_rank("grad_rate")
#' }
#'
#' @export
define_peer_group <- function(
    df,
    peer_type = c("statewide", "dfg", "county", "custom"),
    custom_ids = NULL,
    level = c("district", "school"),
    year_col = "end_year",
    additional_groups = NULL
) {

  peer_type <- match.arg(peer_type)
  level <- match.arg(level)

  # Determine the level filter column
  level_col <- paste0("is_", level)

 # Filter to appropriate level if the column exists
  if (level_col %in% names(df)) {
    df <- df %>% dplyr::filter(!!rlang::sym(level_col))
  }

  # Filter to custom peer group if specified
  if (peer_type == "custom") {
    if (is.null(custom_ids)) {
      stop("custom_ids must be provided when peer_type = 'custom'")
    }
    df <- df %>% dplyr::filter(district_id %in% custom_ids)
  }

  # Define base grouping based on peer type
  group_cols <- switch(peer_type,
    "statewide" = c(year_col),
    "dfg" = c(year_col, "dfg"),
    "county" = c(year_col, "county_id"),
    "custom" = c(year_col)
  )

  # Add any additional grouping columns
  if (!is.null(additional_groups)) {
    group_cols <- c(group_cols, additional_groups)
  }

  # Only group by columns that exist
  group_cols <- intersect(group_cols, names(df))

  df %>%
    dplyr::ungroup() %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(group_cols)))
}


# -----------------------------------------------------------------------------
# Percentile Rank Trend (Temporal Tracking)
# -----------------------------------------------------------------------------

#' Calculate percentile rank change over time
#'
#' @description Given a dataframe with percentile ranks by year, calculates
#' year-over-year and cumulative change. This enables the "39th to 78th
#' percentile" style analysis from MarGrady Research.
#'
#' @param df Dataframe with a percentile column and year column
#' @param percentile_col Character. Name of the percentile column to track.
#' @param year_col Character. Name of year column. Default "end_year".
#' @param entity_cols Character vector. Columns identifying entities to track
#'   over time (e.g., c("district_id", "subgroup")).
#'
#' @return df with added columns:
#'   \itemize{
#'     \item \code{{percentile_col}_yoy_change}: Year-over-year change
#'     \item \code{{percentile_col}_cumulative_change}: Change from first year
#'     \item \code{{percentile_col}_baseline}: Value in the first year
#'   }
#'
#' @examples
#' \dontrun{
#' # Track Newark's percentile rank over time
#' grate_ranked %>%
#'   filter(district_id == "3570") %>%
#'   percentile_rank_trend(
#'     percentile_col = "grad_rate_percentile",
#'     entity_cols = c("district_id", "subgroup")
#'   )
#' }
#'
#' @export
percentile_rank_trend <- function(
    df,
    percentile_col,
    year_col = "end_year",
    entity_cols = c("district_id")
) {

  if (!percentile_col %in% names(df)) {
    stop(sprintf("Column '%s' not found in dataframe", percentile_col))
  }

  pctl_sym <- rlang::sym(percentile_col)
  year_sym <- rlang::sym(year_col)

  yoy_col <- paste0(percentile_col, "_yoy_change")
  cumul_col <- paste0(percentile_col, "_cumulative_change")
  baseline_col <- paste0(percentile_col, "_baseline")

  df %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(entity_cols))) %>%
    dplyr::arrange(!!year_sym) %>%
    dplyr::mutate(
      !!baseline_col := dplyr::first(!!pctl_sym),
      !!yoy_col := !!pctl_sym - dplyr::lag(!!pctl_sym),
      !!cumul_col := !!pctl_sym - dplyr::first(!!pctl_sym)
    ) %>%
    dplyr::ungroup()
}


# -----------------------------------------------------------------------------
# Data-Type Specific Wrappers
# -----------------------------------------------------------------------------

#' Graduation rate percentile rank
#'
#' @description Convenience wrapper for calculating percentile rank of
#' graduation rates within a peer group.
#'
#' @param df Output of \code{fetch_grad_rate()} or similar graduation data
#' @param peer_type Character. Peer group type. See \code{define_peer_group()}.
#' @param custom_ids Character vector. Custom peer group district IDs.
#' @param by_subgroup Logical. Calculate separate percentiles by subgroup?
#'   Default TRUE.
#' @param by_methodology Logical. Calculate separate percentiles by methodology
#'   (4-year, 5-year)? Default TRUE.
#'
#' @return df with grad_rate_rank, grad_rate_n, grad_rate_percentile columns
#'
#' @export
grate_percentile_rank <- function(
    df,
    peer_type = "statewide",
    custom_ids = NULL,
    by_subgroup = TRUE,
    by_methodology = TRUE
) {

  additional_groups <- c()
  if (by_subgroup && "subgroup" %in% names(df)) {
    additional_groups <- c(additional_groups, "subgroup")
  }
  if (by_methodology && "methodology" %in% names(df)) {
    additional_groups <- c(additional_groups, "methodology")
  }

  df %>%
    define_peer_group(
      peer_type = peer_type,
      custom_ids = custom_ids,
      level = "district",
      additional_groups = additional_groups
    ) %>%
    add_percentile_rank("grad_rate") %>%
    dplyr::ungroup()
}


#' Assessment proficiency percentile rank
#'
#' @description Convenience wrapper for calculating percentile rank of
#' assessment proficiency within a peer group. This is the generic version
#' of the assessment-specific functions in peer_percentiles.R.
#'
#' @param df Output of \code{fetch_parcc()} or similar assessment data
#' @param peer_type Character. Peer group type. See \code{define_peer_group()}.
#' @param custom_ids Character vector. Custom peer group district IDs.
#' @param metric Character. Which metric to rank on. One of "proficient_above"
#'   or "scale_score_mean". Default "proficient_above".
#' @param by_grade Logical. Calculate separate percentiles by grade? Default TRUE.
#' @param by_subject Logical. Calculate separate percentiles by test/subject?
#'   Default TRUE.
#' @param by_subgroup Logical. Calculate separate percentiles by subgroup?
#'   Default TRUE.
#'
#' @return df with percentile rank columns for the specified metric
#'
#' @export
parcc_percentile_rank <- function(
    df,
    peer_type = "statewide",
    custom_ids = NULL,
    metric = c("proficient_above", "scale_score_mean"),
    by_grade = TRUE,
    by_subject = TRUE,
    by_subgroup = TRUE
) {

  metric <- match.arg(metric)

  additional_groups <- c()
  if (by_grade && "grade" %in% names(df)) {
    additional_groups <- c(additional_groups, "grade")
  }
  if (by_subject && "test_name" %in% names(df)) {
    additional_groups <- c(additional_groups, "test_name")
  }
  if (by_subgroup && "subgroup" %in% names(df)) {
    additional_groups <- c(additional_groups, "subgroup")
  }

  # Use year_col appropriate for assessment data
  year_col <- if ("testing_year" %in% names(df)) "testing_year" else "end_year"

  df %>%
    define_peer_group(
      peer_type = peer_type,
      custom_ids = custom_ids,
      level = "district",
      year_col = year_col,
      additional_groups = additional_groups
    ) %>%
    add_percentile_rank(metric) %>%
    dplyr::ungroup()
}


# -----------------------------------------------------------------------------
# Equity Access Metric
# -----------------------------------------------------------------------------

#' Calculate equity access rate
#'
#' @description Calculates the share of students (overall or by subgroup)
#' attending schools that meet or exceed a performance threshold. This
#' replicates the MarGrady metric: "the share of Black students in Newark
#' attending a school that beat the state proficiency average."
#'
#' @param df_enrollment School-level enrollment data with demographic counts
#' @param df_performance School-level performance data
#' @param performance_metric Character. Column in df_performance to use as
#'   the performance measure. Default "proficient_above".
#' @param threshold_type Character. How to define "high-performing":
#'   \itemize{
#'     \item "state_avg": Above the state average for that year/grade/subject
#'     \item "absolute": Above a fixed numeric threshold
#'     \item "percentile": Above a percentile threshold within peers
#'   }
#' @param threshold_value Numeric. The threshold value. Required for "absolute"
#'   and "percentile" types. For "state_avg", this is ignored.
#' @param enrollment_col Character. Column in df_enrollment containing student
#'   counts. Default "n_students".
#' @param subgroup Character. Which subgroup to calculate access for. If NULL,
#'   calculates for total enrollment. Default NULL.
#' @param join_cols Character vector. Columns to join enrollment and performance
#'   data on. Default c("end_year", "county_id", "district_id", "school_id").
#'
#' @return Dataframe with columns:
#'   \itemize{
#'     \item Year and entity identifiers
#'     \item \code{n_students_total}: Total students in subgroup
#'     \item \code{n_students_above}: Students in above-threshold schools
#'     \item \code{pct_access}: Percent with access to high-performing schools
#'   }
#'
#' @export
calculate_access_rate <- function(
    df_enrollment,
    df_performance,
    performance_metric = "proficient_above",
    threshold_type = c("state_avg", "absolute", "percentile"),
    threshold_value = NULL,
    enrollment_col = "n_students",
    subgroup = NULL,
    join_cols = c("end_year", "county_id", "district_id", "school_id")
) {

  threshold_type <- match.arg(threshold_type)

  # Validate inputs
  if (threshold_type %in% c("absolute", "percentile") && is.null(threshold_value)) {
    stop("threshold_value must be provided for threshold_type '", threshold_type, "'")
  }

  perf_sym <- rlang::sym(performance_metric)
  enroll_sym <- rlang::sym(enrollment_col)

  # Calculate threshold based on type
  if (threshold_type == "state_avg") {
    # Get state average by year (and grade/subject if present)
    group_cols <- intersect(c("end_year", "testing_year", "grade", "test_name"), names(df_performance))

    state_avg <- df_performance %>%
      dplyr::filter(is_state) %>%
      dplyr::select(dplyr::all_of(c(group_cols, performance_metric))) %>%
      dplyr::rename(threshold = !!perf_sym)

    # Join threshold to school data
    df_performance <- df_performance %>%
      dplyr::filter(is_school) %>%
      dplyr::left_join(state_avg, by = group_cols) %>%
      dplyr::mutate(is_above_threshold = !!perf_sym >= threshold)

  } else if (threshold_type == "absolute") {
    df_performance <- df_performance %>%
      dplyr::filter(is_school) %>%
      dplyr::mutate(
        threshold = threshold_value,
        is_above_threshold = !!perf_sym >= threshold_value
      )

  } else if (threshold_type == "percentile") {
    # Calculate percentile threshold within peer group
    df_performance <- df_performance %>%
      dplyr::filter(is_school) %>%
      dplyr::group_by(end_year) %>%
      dplyr::mutate(
        threshold = stats::quantile(!!perf_sym, probs = threshold_value / 100, na.rm = TRUE),
        is_above_threshold = !!perf_sym >= threshold
      ) %>%
      dplyr::ungroup()
  }

  # Filter enrollment to subgroup if specified
  if (!is.null(subgroup)) {
    df_enrollment <- df_enrollment %>%
      dplyr::filter(subgroup == !!subgroup)
  }

  # Ensure we're at school level for enrollment
  if ("is_school" %in% names(df_enrollment)) {
    df_enrollment <- df_enrollment %>% dplyr::filter(is_school)
  }

  # Join performance threshold flags to enrollment
  perf_slim <- df_performance %>%
    dplyr::select(dplyr::all_of(join_cols), is_above_threshold, threshold) %>%
    dplyr::distinct()

  df_joined <- df_enrollment %>%
    dplyr::inner_join(perf_slim, by = join_cols)

  # Aggregate to calculate access rate
  # Group by district (or city) to get "share of students in high-performing schools"
  result <- df_joined %>%
    dplyr::group_by(end_year, county_id, district_id) %>%
    dplyr::summarize(
      n_students_total = sum(!!enroll_sym, na.rm = TRUE),
      n_students_above = sum(
        dplyr::if_else(is_above_threshold, !!enroll_sym, 0L),
        na.rm = TRUE
      ),
      n_schools_total = dplyr::n(),
      n_schools_above = sum(is_above_threshold, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    dplyr::mutate(
      pct_students_access = round(n_students_above / n_students_total * 100, 1),
      pct_schools_above = round(n_schools_above / n_schools_total * 100, 1)
    )

  return(result)
}


# -----------------------------------------------------------------------------
# Sector Comparison Helpers
# -----------------------------------------------------------------------------

#' Compare percentile ranks across sectors
#'
#' @description Calculates and compares percentile ranks for charter sector,
#' district sector, and all-public aggregates. Useful for MarGrady-style
#' sector comparisons.
#'
#' @param df Dataframe containing both charter and district data with
#'   is_charter_sector, is_district, is_allpublic flags
#' @param metric_col Character. The metric to calculate percentile ranks for.
#' @param host_district_id Character. Optional. Filter to specific host district.
#' @param year_col Character. Year column name. Default "end_year".
#'
#' @return Dataframe with sector comparison including percentile ranks
#'
#' @export
sector_percentile_comparison <- function(
    df,
    metric_col,
    host_district_id = NULL,
    year_col = "end_year"
) {

  # Filter to host district if specified
  if (!is.null(host_district_id)) {
    # Need to handle both charter sector (with host) and regular district
    df <- df %>%
      dplyr::filter(
        stringr::str_detect(district_id, paste0("^", host_district_id)) |
          district_id == host_district_id
      )
  }

  # Identify sector type
  df <- df %>%
    dplyr::mutate(
      sector = dplyr::case_when(
        is_charter_sector ~ "Charter Sector",
        is_allpublic ~ "All Public",
        is_district ~ "Traditional District",
        TRUE ~ "Other"
      )
    ) %>%
    dplyr::filter(sector != "Other")

  # Calculate percentile rank statewide for each sector
  df %>%
    dplyr::group_by(!!rlang::sym(year_col)) %>%
    add_percentile_rank(metric_col) %>%
    dplyr::ungroup() %>%
    dplyr::select(
      dplyr::all_of(year_col),
      district_id, district_name, sector,
      dplyr::all_of(metric_col),
      dplyr::ends_with("_rank"),
      dplyr::ends_with("_n"),
      dplyr::ends_with("_percentile")
    )
}


# =============================================================================
# Extension #1: Subgroup Trajectory Divergence Analysis
# =============================================================================
#
# Functions for tracking achievement gaps between subgroups over time.
# Enables analysis like "Is the Black-White achievement gap narrowing in
# Newark faster than in peer districts?"
#
# =============================================================================

#' Standard subgroup pairs for gap analysis
#'
#' @description Pre-defined pairs of subgroups commonly used for achievement
#' gap calculations. Each pair consists of c(reference_group, comparison_group)
#' where gap = reference - comparison.
#'
#' @export
SUBGROUP_PAIRS <- list(
  race_white_black = c("white", "black"),
  race_white_hispanic = c("white", "hispanic"),
  gender = c("male", "female"),
  ses = c("total_population", "economically_disadvantaged"),
  disability = c("total_population", "iep"),
  ell = c("total_population", "lep")
)


#' Calculate achievement gap between two subgroups
#'
#' @description Calculates the difference in a metric between two subgroups
#' within each entity (district/school) and year. The gap is calculated as
#' subgroup_a - subgroup_b, so positive values mean subgroup_a outperforms.
#'
#' @param df Dataframe with a 'subgroup' column and the metric of interest
#' @param metric_col Character. The column containing the metric to compare.
#' @param subgroup_a Character. The reference subgroup (typically majority/advantaged).
#' @param subgroup_b Character. The comparison subgroup (typically minority/disadvantaged).
#' @param year_col Character. Year column name. Default "end_year".
#' @param entity_cols Character vector. Columns identifying the entity
#'   (e.g., c("district_id") or c("county_id", "district_id", "school_id")).
#'
#' @return Dataframe with one row per entity-year containing:
#'   \itemize{
#'     \item Original entity and year columns
#'     \item \code{{metric}_a}: Value for subgroup_a
#'     \item \code{{metric}_b}: Value for subgroup_b
#'     \item \code{{metric}_gap}: Absolute gap (a - b)
#'     \item \code{{metric}_gap_pct}: Relative gap as percent of subgroup_a
#'   }
#'
#' @examples
#' \dontrun{
#' # Calculate Black-White graduation rate gap
#' grate %>%
#'   filter(subgroup %in% c("white", "black")) %>%
#'   calculate_subgroup_gap(
#'     metric_col = "grad_rate",
#'     subgroup_a = "white",
#'     subgroup_b = "black"
#'   )
#' }
#'
#' @export
calculate_subgroup_gap <- function(
    df,
    metric_col,
    subgroup_a,
    subgroup_b,
    year_col = "end_year",
    entity_cols = "district_id"
) {

  if (!metric_col %in% names(df)) {
    stop(sprintf("Column '%s' not found in dataframe", metric_col))
  }
  if (!"subgroup" %in% names(df)) {
    stop("Dataframe must contain a 'subgroup' column")
  }

  # Filter to the two subgroups of interest
  df_filtered <- df %>%
    dplyr::filter(subgroup %in% c(subgroup_a, subgroup_b))

  # Check that both subgroups exist
  subgroups_present <- unique(df_filtered$subgroup)
  if (!subgroup_a %in% subgroups_present) {
    stop(sprintf("Subgroup '%s' not found in data", subgroup_a))
  }
  if (!subgroup_b %in% subgroups_present) {
    stop(sprintf("Subgroup '%s' not found in data", subgroup_b))
  }

  metric_sym <- rlang::sym(metric_col)
  year_sym <- rlang::sym(year_col)

  # Column names for output
  col_a <- paste0(metric_col, "_a")
  col_b <- paste0(metric_col, "_b")
  col_gap <- paste0(metric_col, "_gap")
  col_gap_pct <- paste0(metric_col, "_gap_pct")

  # Pivot wider to get both subgroup values in same row
  id_cols <- c(entity_cols, year_col)

  # Select only needed columns to avoid pivot issues
  df_slim <- df_filtered %>%
    dplyr::select(dplyr::all_of(c(id_cols, "subgroup", metric_col)))

  df_wide <- df_slim %>%
    tidyr::pivot_wider(
      id_cols = dplyr::all_of(id_cols),
      names_from = subgroup,
      values_from = dplyr::all_of(metric_col)
    )

  # Calculate gap
  a_sym <- rlang::sym(subgroup_a)
  b_sym <- rlang::sym(subgroup_b)

  df_wide %>%
    dplyr::rename(
      !!col_a := !!a_sym,
      !!col_b := !!b_sym
    ) %>%
    dplyr::mutate(
      !!col_gap := !!rlang::sym(col_a) - !!rlang::sym(col_b),
      !!col_gap_pct := dplyr::if_else(
        is.finite(!!rlang::sym(col_a)) & !!rlang::sym(col_a) != 0,
        round((!!rlang::sym(col_gap) / !!rlang::sym(col_a)) * 100, 2),
        NA_real_
      ),
      subgroup_pair = paste0(subgroup_a, "_vs_", subgroup_b)
    )
}


#' Rank entities by achievement gap within peer group
#'
#' @description Calculates percentile rank of achievement gaps. By default,
#' smaller gaps receive higher percentile ranks (better equity = higher rank).
#' This enables questions like "Which DFG A districts have the smallest
#' Black-White achievement gaps?"
#'
#' @param df Output of \code{calculate_subgroup_gap()} or any dataframe with
#'   a gap column
#' @param gap_col Character. The column containing gap values. Default "metric_gap".
#' @param peer_type Character. Peer group type. See \code{define_peer_group()}.
#' @param year_col Character. Year column name. Default "end_year".
#' @param smaller_is_better Logical. If TRUE (default), smaller gaps get higher
#'   percentile ranks. Set to FALSE if larger gaps are preferred.
#'
#' @return df with added gap percentile columns
#'
#' @examples
#' \dontrun{
#' grate %>%
#'   calculate_subgroup_gap("grad_rate", "white", "black") %>%
#'   gap_percentile_rank(gap_col = "grad_rate_gap", peer_type = "dfg")
#' }
#'
#' @export
gap_percentile_rank <- function(
    df,
    gap_col,
    peer_type = "statewide",
    year_col = "end_year",
    smaller_is_better = TRUE
) {

  if (!gap_col %in% names(df)) {
    stop(sprintf("Column '%s' not found in dataframe", gap_col))
  }

  gap_sym <- rlang::sym(gap_col)

  # For ranking, we may need to invert the gap if smaller is better
  # because add_percentile_rank ranks higher values higher
  if (smaller_is_better) {
    # Create inverted gap column for ranking
    df <- df %>%
      dplyr::mutate(.gap_for_rank = -1 * abs(!!gap_sym))

    rank_col <- ".gap_for_rank"
  } else {
    rank_col <- gap_col
  }

  # Define peer group and calculate percentile
  result <- df %>%
    define_peer_group(
      peer_type = peer_type,
      level = "district",
      year_col = year_col
    ) %>%
    add_percentile_rank(rank_col, prefix = paste0(gap_col, "_equity")) %>%
    dplyr::ungroup()

  # Clean up temp column if created

if (smaller_is_better) {
    result <- result %>% dplyr::select(-.gap_for_rank)
  }

  result
}


#' Track achievement gap trends over time
#'
#' @description Combines gap calculation with trend tracking to show how
#' achievement gaps have changed over time for specific entities. Answers
#' questions like "How has Newark's Black-White gap changed from 2015 to 2023?"
#'
#' @param df Dataframe with subgroups and metrics over multiple years
#' @param metric_col Character. The metric to track.
#' @param subgroup_a Character. Reference subgroup.
#' @param subgroup_b Character. Comparison subgroup.
#' @param year_col Character. Year column. Default "end_year".
#' @param entity_cols Character vector. Columns identifying entity to track.
#'
#' @return df with gap values and trend columns:
#'   \itemize{
#'     \item \code{{metric}_gap_yoy_change}: Year-over-year change in gap
#'     \item \code{{metric}_gap_cumulative_change}: Change from baseline year
#'     \item \code{{metric}_gap_baseline}: Gap value in first year
#'   }
#'
#' @examples
#' \dontrun{
#' # Track Newark's Black-White grad rate gap over time
#' grate %>%
#'   filter(district_id == "3570") %>%
#'   gap_trajectory(
#'     metric_col = "grad_rate",
#'     subgroup_a = "white",
#'     subgroup_b = "black"
#'   )
#' }
#'
#' @export
gap_trajectory <- function(
    df,
    metric_col,
    subgroup_a,
    subgroup_b,
    year_col = "end_year",
    entity_cols = "district_id"
) {

  # First calculate the gaps
  gap_df <- calculate_subgroup_gap(
    df = df,
    metric_col = metric_col,
    subgroup_a = subgroup_a,
    subgroup_b = subgroup_b,
    year_col = year_col,
    entity_cols = entity_cols
  )

  gap_col <- paste0(metric_col, "_gap")

  # Now track the trend using existing percentile_rank_trend function
  # but adapted for gap column
  gap_sym <- rlang::sym(gap_col)
  year_sym <- rlang::sym(year_col)

  yoy_col <- paste0(gap_col, "_yoy_change")
  cumul_col <- paste0(gap_col, "_cumulative_change")
  baseline_col <- paste0(gap_col, "_baseline")

  gap_df %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(entity_cols))) %>%
    dplyr::arrange(!!year_sym) %>%
    dplyr::mutate(
      !!baseline_col := dplyr::first(!!gap_sym),
      !!yoy_col := !!gap_sym - dplyr::lag(!!gap_sym),
      !!cumul_col := !!gap_sym - dplyr::first(!!gap_sym)
    ) %>%
    dplyr::ungroup()
}


# =============================================================================
# Extension #3: Sector Ecosystem Dynamics
# =============================================================================
#
# Functions for analyzing charter/district sector interactions within cities
# and tracking combined "all-public" performance vs peer cities.
#
# =============================================================================

#' Calculate performance gap between charter and district sectors
#'
#' @description Calculates the difference in performance between the charter
#' sector aggregate and traditional district for host cities. Positive values
#' indicate charter sector outperforms district.
#'
#' @param df Dataframe with charter sector and district rows, including
#'   is_charter_sector, is_district, and is_allpublic flags
#' @param metric_col Character. Performance metric column.
#' @param year_col Character. Year column. Default "end_year".
#'
#' @return Dataframe with one row per city-year containing:
#'   \itemize{
#'     \item \code{charter_value}: Charter sector metric value
#'     \item \code{district_value}: Traditional district metric value
#'     \item \code{sector_gap}: charter_value - district_value
#'     \item \code{sector_leader}: "charter", "district", or "tie"
#'   }
#'
#' @examples
#' \dontrun{
#' # Get sector gaps for all host cities
#' grate_with_aggs %>%
#'   sector_gap(metric_col = "grad_rate")
#' }
#'
#' @export
sector_gap <- function(
    df,
    metric_col,
    year_col = "end_year"
) {

  if (!metric_col %in% names(df)) {
    stop(sprintf("Column '%s' not found in dataframe", metric_col))
  }

  metric_sym <- rlang::sym(metric_col)
  year_sym <- rlang::sym(year_col)

  # Extract charter sector rows (district_id ends with 'C')
  charter_df <- df %>%
    dplyr::filter(is_charter_sector) %>%
    dplyr::mutate(
      host_district_id = gsub("C$", "", district_id)
    ) %>%
    dplyr::select(
      !!year_sym, host_district_id,
      charter_value = !!metric_sym
    )

  # Extract traditional district rows
  district_df <- df %>%
    dplyr::filter(is_district & !is_charter_sector & !is_allpublic) %>%
    dplyr::select(
      !!year_sym,
      host_district_id = district_id,
      district_value = !!metric_sym
    )

  # Join and calculate gap
  # Note: threshold of 0.01 (1 percentage point) for metrics on 0-1 scale
  charter_df %>%
    dplyr::inner_join(district_df, by = c(year_col, "host_district_id")) %>%
    dplyr::mutate(
      sector_gap = charter_value - district_value,
      sector_leader = dplyr::case_when(
        sector_gap > 0.01 ~ "charter",
        sector_gap < -0.01 ~ "district",
        TRUE ~ "tie"
      )
    )
}


#' Summarize sector performance within a city
#'
#' @description Creates a summary showing charter sector, traditional district,
#' and all-public performance for a specific host city, including peer
#' percentile ranks for each.
#'
#' @param df Combined data including sector aggregates (output of
#'   \code{*_aggs()} functions combined with base data)
#' @param metric_col Character. Metric to summarize.
#' @param host_district_id Character. The host district ID (e.g., "3570" for Newark).
#' @param peer_type Character. Peer group for percentile calculation.
#' @param year_col Character. Year column. Default "end_year".
#'
#' @return Summary dataframe with sectors as rows, metrics and percentiles as columns
#'
#' @examples
#' \dontrun{
#' # Newark ecosystem summary
#' city_ecosystem_summary(
#'   df = grate_with_aggs,
#'   metric_col = "grad_rate",
#'   host_district_id = "3570"
#' )
#' }
#'
#' @export
city_ecosystem_summary <- function(
    df,
    metric_col,
    host_district_id,
    peer_type = "statewide",
    year_col = "end_year"
) {

  metric_sym <- rlang::sym(metric_col)
  year_sym <- rlang::sym(year_col)

  # Define the district_id patterns for this host city
  charter_id <- paste0(host_district_id, "C")
  allpublic_id <- paste0(host_district_id, "A")

  # Filter to the three sectors for this city
  city_data <- df %>%
    dplyr::filter(
      district_id %in% c(host_district_id, charter_id, allpublic_id)
    ) %>%
    dplyr::mutate(
      sector = dplyr::case_when(
        district_id == host_district_id ~ "Traditional District",
        district_id == charter_id ~ "Charter Sector",
        district_id == allpublic_id ~ "All Public",
        TRUE ~ NA_character_
      )
    )

  # Calculate statewide percentile for comparison
  # First get the full peer group
  peer_data <- df %>%
    dplyr::filter(is_district | is_allpublic) %>%
    define_peer_group(peer_type = peer_type, level = "district", year_col = year_col) %>%
    add_percentile_rank(metric_col) %>%
    dplyr::ungroup()

  pctl_col <- paste0(metric_col, "_percentile")

  # Get percentiles for our city's sectors
  city_percentiles <- peer_data %>%
    dplyr::filter(district_id %in% c(host_district_id, charter_id, allpublic_id)) %>%
    dplyr::select(!!year_sym, district_id, !!metric_sym, dplyr::all_of(pctl_col))

  # Join sector labels
  city_percentiles %>%
    dplyr::mutate(
      sector = dplyr::case_when(
        district_id == host_district_id ~ "Traditional District",
        grepl("C$", district_id) ~ "Charter Sector",
        grepl("A$", district_id) ~ "All Public",
        TRUE ~ NA_character_
      )
    ) %>%
    dplyr::select(!!year_sym, sector, !!metric_sym, dplyr::all_of(pctl_col)) %>%
    dplyr::arrange(!!year_sym, sector)
}


#' Track sector ecosystem dynamics over time
#'
#' @description Tracks charter market share, sector performance gap, and
#' all-public percentile over time for a host city. Answers questions like
#' "As Newark's charter share grew, how did overall city performance change?"
#'
#' @param df_enrollment Enrollment data (output of \code{fetch_enr()}) with
#'   sector aggregates
#' @param df_performance Performance data (e.g., graduation rates) with
#'   sector aggregates
#' @param host_district_id Character. Host district ID (e.g., "3570").
#' @param metric_col Character. Performance metric to track.
#' @param peer_type Character. Peer group for percentile. Default "statewide".
#' @param year_col Character. Year column. Default "end_year".
#'
#' @return Dataframe with yearly ecosystem metrics:
#'   \itemize{
#'     \item \code{charter_enrollment}: Students in charter sector
#'     \item \code{total_enrollment}: All public students in city
#'     \item \code{charter_share}: Percent of students in charters
#'     \item \code{sector_gap}: Charter - district performance difference
#'     \item \code{allpublic_percentile}: City's overall percentile rank
#'   }
#'
#' @export
ecosystem_trend <- function(
    df_enrollment,
    df_performance,
    host_district_id,
    metric_col,
    peer_type = "statewide",
    year_col = "end_year"
) {

  year_sym <- rlang::sym(year_col)
  metric_sym <- rlang::sym(metric_col)

  charter_id <- paste0(host_district_id, "C")
  allpublic_id <- paste0(host_district_id, "A")

  # Get enrollment by sector
  enr_charter <- df_enrollment %>%
    dplyr::filter(
      district_id == charter_id,
      subgroup == "total_enrollment"
    ) %>%
    dplyr::select(!!year_sym, charter_enrollment = n_students)

  enr_allpublic <- df_enrollment %>%
    dplyr::filter(
      district_id == allpublic_id,
      subgroup == "total_enrollment"
    ) %>%
    dplyr::select(!!year_sym, total_enrollment = n_students)

  # Join enrollment data
  enrollment <- enr_charter %>%
    dplyr::full_join(enr_allpublic, by = year_col) %>%
    dplyr::mutate(
      charter_share = round(charter_enrollment / total_enrollment * 100, 1)
    )

  # Get sector gap
  gaps <- sector_gap(df_performance, metric_col, year_col) %>%
    dplyr::filter(host_district_id == !!host_district_id) %>%
    dplyr::select(!!year_sym, sector_gap, sector_leader)

  # Get all-public percentile
  pctl_col <- paste0(metric_col, "_percentile")

  allpublic_pctl <- df_performance %>%
    dplyr::filter(is_allpublic | is_district) %>%
    define_peer_group(peer_type = peer_type, level = "district", year_col = year_col) %>%
    add_percentile_rank(metric_col) %>%
    dplyr::ungroup() %>%
    dplyr::filter(district_id == allpublic_id) %>%
    dplyr::select(!!year_sym, allpublic_value = !!metric_sym, allpublic_percentile = dplyr::all_of(pctl_col))

  # Combine all metrics
  enrollment %>%
    dplyr::left_join(gaps, by = year_col) %>%
    dplyr::left_join(allpublic_pctl, by = year_col) %>%
    dplyr::arrange(!!year_sym)
}


#' Calculate charter market share for host cities
#'
#' @description Calculates the percentage of public school students enrolled
#' in charter schools for each host city over time.
#'
#' @param df_enrollment Enrollment data with charter sector and all-public
#'   aggregates (combine \code{fetch_enr()} output with \code{charter_sector_enr_aggs()}
#'   and \code{allpublic_enr_aggs()})
#' @param year_col Character. Year column. Default "end_year".
#'
#' @return Dataframe with charter market share by city and year
#'
#' @export
charter_market_share <- function(
    df_enrollment,
    year_col = "end_year"
) {

  year_sym <- rlang::sym(year_col)

  # Get charter sector enrollment (total_enrollment subgroup only)
  charter_enr <- df_enrollment %>%
    dplyr::filter(
      is_charter_sector,
      subgroup == "total_enrollment"
    ) %>%
    dplyr::mutate(
      host_district_id = gsub("C$", "", district_id)
    ) %>%
    dplyr::select(!!year_sym, host_district_id, charter_enrollment = n_students)

  # Get all-public enrollment
  allpublic_enr <- df_enrollment %>%
    dplyr::filter(
      is_allpublic,
      subgroup == "total_enrollment"
    ) %>%
    dplyr::mutate(
      host_district_id = gsub("A$", "", district_id)
    ) %>%
    dplyr::select(!!year_sym, host_district_id, total_enrollment = n_students)

  # Combine and calculate share
  charter_enr %>%
    dplyr::inner_join(allpublic_enr, by = c(year_col, "host_district_id")) %>%
    dplyr::mutate(
      charter_share = round(charter_enrollment / total_enrollment * 100, 1),
      district_enrollment = total_enrollment - charter_enrollment
    ) %>%
    dplyr::arrange(host_district_id, !!year_sym)
}
