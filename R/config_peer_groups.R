# ==============================================================================
# Peer Group Configuration
# ==============================================================================
#
# Defines peer groups for percentile rank comparisons, including the
# District Factor Group (DFG) classifications used by NJ DOE.
#
# DFG A = highest-need communities (used in MarGrady Newark analysis)
# DFG B through J = progressively lower-need communities
#
# ==============================================================================

#' Get districts in a specific District Factor Group
#'
#' @description Returns the district IDs for all districts in a specific
#' District Factor Group. DFG A represents the highest-need communities
#' in New Jersey and is commonly used as a peer group for urban districts.
#'
#' This function fetches the DFG data from NJ DOE and filters to the

#' requested group.
#'
#' @param dfg_code Character. The DFG code to filter to (e.g., "A", "B", "CD").
#' @param revision Numeric. Which DFG revision to use (2000 or 1990). Default 2000.
#'
#' @return Character vector of district_ids in the specified DFG
#'
#' @examples
#' \dontrun{
#' # Get all DFG A districts (highest need)
#' dfg_a <- get_dfg_districts("A")
#'
#' # Use as peer group for percentile ranking
#' grate %>%
#'   define_peer_group("custom", custom_ids = dfg_a) %>%
#'   add_percentile_rank("grad_rate")
#' }
#'
#' @export
get_dfg_districts <- function(dfg_code, revision = 2000) {
  dfg_data <- fetch_dfg(revision = revision)

  dfg_data %>%
    dplyr::filter(dfg == dfg_code) %>%
    dplyr::mutate(
      district_id = paste0(county_code, district_code)
    ) %>%
    dplyr::pull(district_id)
}


#' Get DFG A districts (highest-need peer group)
#'
#' @description Convenience function to get all DFG A districts.
#' DFG A represents the 37 highest-need communities in New Jersey,
#' including Newark, Camden, Trenton, Paterson, etc.
#'
#' This is the peer group used in MarGrady Research's Newark analysis:
#' "Newark is in DFG A, which comprises cities or towns with the
#' highest-need populations in New Jersey."
#'
#' @return Character vector of district_ids in DFG A
#'
#' @references
#' MarGrady Research. "Moving Up: Progress in Newark's Schools from 2010 to 2017"
#' \url{https://margrady.com/movingup/}
#'
#' @export
get_dfg_a_districts <- function() {
  get_dfg_districts("A")
}


#' Calculate DFG peer percentile for any metric
#'
#' @description Calculates percentile rank within District Factor Group
#' for any metric column. This is a convenience wrapper that combines
#' \code{define_peer_group()} and \code{add_percentile_rank()}.
#'
#' @param df Dataframe with district data including 'dfg' column
#' @param metric_col Character. The column to rank on.
#' @param year_col Character. The year column. Default "end_year".
#' @param additional_groups Character vector. Additional grouping columns.
#'
#' @return df with percentile rank columns
#'
#' @export
dfg_percentile_rank <- function(
    df,
    metric_col,
    year_col = "end_year",
    additional_groups = NULL
) {

  if (!"dfg" %in% names(df)) {
    stop("Dataframe must contain 'dfg' column. Join DFG data first using fetch_dfg().")
  }

  df %>%
    define_peer_group(
      peer_type = "dfg",
      level = "district",
      year_col = year_col,
      additional_groups = additional_groups
    ) %>%
    add_percentile_rank(metric_col, prefix = paste0("dfg_", metric_col)) %>%
    dplyr::ungroup()
}


#' Add DFG classification to district data
#'
#' @description Joins District Factor Group classification to any
#' district-level dataframe. Handles both full CDS format (county+district,
#' e.g., "133570") and district-only format (e.g., "3570").
#'
#' @param df Dataframe with district_id column
#' @param revision Numeric. DFG revision year (2000 or 1990). Default 2000.
#'
#' @return df with 'dfg' column added
#'
#' @export
add_dfg <- function(df, revision = 2000) {
  dfg_data <- fetch_dfg(revision = revision)

  # Create lookup with both full CDS format and district-only format
  dfg_slim <- dfg_data %>%
    dplyr::mutate(
      district_id_full = paste0(county_code, district_code),
      district_id_short = district_code
    ) %>%
    dplyr::select(district_id_full, district_id_short, dfg)

  # Try joining on full format first
  df_joined <- df %>%
    dplyr::left_join(
      dfg_slim %>% dplyr::select(district_id = district_id_full, dfg),
      by = "district_id"
    )

  # For rows that didn't match, try district-only format
  unmatched <- is.na(df_joined$dfg)
  if (any(unmatched)) {
    dfg_short <- dfg_slim %>%
      dplyr::select(district_id = district_id_short, dfg_short = dfg)

    df_joined <- df_joined %>%
      dplyr::left_join(dfg_short, by = "district_id") %>%
      dplyr::mutate(
        dfg = dplyr::coalesce(dfg, dfg_short)
      ) %>%
      dplyr::select(-dfg_short)
  }

  df_joined
}
