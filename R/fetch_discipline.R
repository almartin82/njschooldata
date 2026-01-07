# ==============================================================================
# Discipline & Climate Analysis Functions
# ==============================================================================
#
# Analysis functions for discipline and school climate data. These functions
# process data from fetch_disciplinary_removals(), fetch_violence_vandalism_hib(),
# fetch_police_notifications(), and fetch_hib_investigations() to calculate
# rates, trends, and disproportionality metrics.
#
# ==============================================================================

# -----------------------------------------------------------------------------
# Discipline Rate Calculations by Subgroup
# -----------------------------------------------------------------------------

#' Calculate Discipline Rates by Subgroup
#'
#' Calculates discipline rates by subgroup for disproportionality analysis.
#' Computes rates per specified base (default 1000 students) and calculates
#' risk ratios compared to total population.
#'
#' @param df A data frame from \code{\link{fetch_disciplinary_removals}},
#'   \code{\link{fetch_violence_vandalism_hib}}, or similar discipline data.
#'   Must contain subgroup column and a count/number column.
#' @param rate_per Base for rate calculation (default: 1000). For example,
#'   rate_per = 1000 calculates incidents per 1000 students.
#'
#' @return Data frame with discipline rates including:
#'   \itemize{
#'     \item All original columns from input data
#'     \item discipline_rate - Incidents per rate_per students
#'     \item percent_by_subgroup - Percentage of total incidents by subgroup
#'     \item risk_ratio - Ratio of subgroup rate to total population rate
#'       (values > 1 indicate higher risk than total population)
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Get disciplinary removals data
#' discipline <- fetch_disciplinary_removals(2024)
#'
#' # Calculate rates per 1000 students
#' rates <- calc_discipline_rates_by_subgroup(discipline, rate_per = 1000)
#'
#' # View disproportionality for racial subgroups
#' rates %>%
#'   dplyr::filter(subgroup %in% c("black", "hispanic", "white")) %>%
#'   dplyr::select(school_name, subgroup, discipline_rate, risk_ratio)
#' }
calc_discipline_rates_by_subgroup <- function(df, rate_per = 1000) {

  # Validate input
  if (!"subgroup" %in% names(df)) {
    stop("Input data must contain 'subgroup' column")
  }

  # Try to find a count/number column (may vary by data source)
  # Common names: number, count, n_students, students, enrollment
  count_cols <- grep("number|count|n_|students|enrollment", names(df),
                     value = TRUE, ignore.case = TRUE)

  # Filter out columns that are clearly not student counts
  count_cols <- count_cols[!grepl("district|school|county|state", count_cols, ignore.case = TRUE)]

  if (length(count_cols) == 0) {
    stop("Cannot find count/number column in input data")
  }

  # Use the first matching count column
  count_col <- count_cols[1]

  # Try to find an incidents column
  incident_cols <- grep("incident|removal|suspension|expulsion|violence|vandalism",
                        names(df), value = TRUE, ignore.case = TRUE)

  # If no incident column found, try to find a numeric column that could be incidents
  if (length(incident_cols) == 0) {
    # Look for numeric columns that might be incident counts
    numeric_cols <- names(df)[sapply(df, function(x) is.numeric(x) || is.integer(x))]
    # Exclude standard identifier columns and the count column
    incident_cols <- numeric_cols[!numeric_cols %in%
                                    c("end_year", "county_id", "district_id", "school_id",
                                      count_col, "is_state", "is_county", "is_district",
                                      "is_school", "is_charter", "is_charter_sector", "is_allpublic")]
  }

  if (length(incident_cols) == 0) {
    stop("Cannot find incident/removal column in input data")
  }

  incident_col <- incident_cols[1]

  # Ensure numeric
  df[[count_col]] <- as.numeric(df[[count_col]])
  df[[incident_col]] <- as.numeric(df[[incident_col]])

  # Calculate discipline rate
  df$discipline_rate <- (df[[incident_col]] / df[[count_col]]) * rate_per

  # Calculate percent of total incidents by location
  # Group by location (school or district) and year
  location_cols <- c("end_year", "county_id", "district_id")
  if ("school_id" %in% names(df)) {
    location_cols <- c(location_cols, "school_id")
  }

  # Total incidents per location/year
  total_incidents <- df %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(location_cols))) %>%
    dplyr::summarise(
      total_incidents = sum(!!dplyr::sym(incident_col), na.rm = TRUE),
      .groups = "drop"
    )

  # Calculate percent_by_subgroup
  df <- df %>%
    dplyr::left_join(total_incidents, by = location_cols) %>%
    dplyr::mutate(
      percent_by_subgroup = (!!dplyr::sym(incident_col) / total_incidents) * 100
    ) %>%
    dplyr::select(-total_incidents)

  # Note: percent_by_subgroup represents the percentage of TOTAL incidents
  # accounted for by this subgroup, NOT the percentage of students in this subgroup

  # Calculate risk ratio (vs total population)
  # Get total population rate for each location/year
  total_pop_rate <- df %>%
    dplyr::filter(subgroup == "total population") %>%
    dplyr::select(dplyr::all_of(c(location_cols, "discipline_rate"))) %>%
    dplyr::rename(total_pop_rate = discipline_rate)

  # Join and calculate risk ratio
  df <- df %>%
    dplyr::left_join(total_pop_rate, by = location_cols) %>%
    dplyr::mutate(
      risk_ratio = discipline_rate / total_pop_rate
    ) %>%
    dplyr::select(-total_pop_rate)

  # Handle edge cases
  df$risk_ratio[!is.finite(df$risk_ratio)] <- NA

  df
}


# -----------------------------------------------------------------------------
# Multi-Year Trend Analysis
# -----------------------------------------------------------------------------

#' Compare Discipline Across Years
#'
#' Compares discipline metrics across multiple years, calculating year-over-year
#' changes and identifying long-term trends.
#'
#' @param df_list A named list of data frames from different years. Each element
#'   should be named by its end_year (e.g., list("2022" = df_2022, "2024" = df_2024)).
#'   Data frames should be from \code{\link{fetch_disciplinary_removals}},
#'   \code{\link{fetch_violence_vandalism_hib}}, or similar.
#' @param metrics Character vector of metrics to compare. If NULL (default),
#'   attempts to auto-detect numeric metric columns. Metrics should match
#'   column names in the data (e.g., "discipline_rate" if calculated).
#'
#' @return Data frame with year-over-year comparisons including:
#'   \itemize{
#'     \item year - Year identifier
#'     \item location_id - Combined location identifier
#'     \item metric_name - Name of the metric
#'     \item metric_value - Value of the metric in this year
#'     \item year_over_year_change - Change from previous year
#'     \item year_over_year_pct_change - Percentage change from previous year
#'     \item multi_year_trend - Trend classification: "increasing", "decreasing",
#'       "stable", or "insufficient_data"
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Fetch data for multiple years
#' disc_2022 <- fetch_disciplinary_removals(2022)
#' disc_2023 <- fetch_disciplinary_removals(2023)
#' disc_2024 <- fetch_disciplinary_removals(2024)
#'
#' # Combine into named list
#' df_list <- list(
#'   "2022" = disc_2022,
#'   "2023" = disc_2023,
#'   "2024" = disc_2024
#' )
#'
#' # Compare trends
#' trends <- compare_discipline_across_years(df_list)
#'
#' # View schools with increasing discipline rates
#' trends %>%
#'   dplyr::filter(metric_name == "discipline_rate", multi_year_trend == "increasing")
#' }
compare_discipline_across_years <- function(df_list, metrics = NULL) {

  # Validate input
  if (!is.list(df_list) || is.data.frame(df_list)) {
    stop("df_list must be a list of data frames")
  }

  if (is.null(names(df_list)) || any(names(df_list) == "")) {
    stop("df_list must be a named list with years as names")
  }

  # Add year column to each data frame
  df_list <- lapply(names(df_list), function(year_name) {
    df <- df_list[[year_name]]
    df$year <- as.numeric(year_name)
    df
  })
  names(df_list) <- names(df_list)

  # Combine all years
  combined <- dplyr::bind_rows(df_list)

  # Auto-detect metrics if not specified
  if (is.null(metrics)) {
    # Look for numeric columns that aren't identifiers or flags
    exclude_cols <- c("end_year", "year", "county_id", "district_id", "school_id",
                      "is_state", "is_county", "is_district", "is_school",
                      "is_charter", "is_charter_sector", "is_allpublic")
    potential_metrics <- names(combined)[sapply(combined, function(x) is.numeric(x) || is.integer(x))]
    metrics <- potential_metrics[!potential_metrics %in% exclude_cols]
  }

  # Validate metrics exist
  missing_metrics <- metrics[!metrics %in% names(combined)]
  if (length(missing_metrics) > 0) {
    warning(paste("Metrics not found in data:", paste(missing_metrics, collapse = ", ")))
    metrics <- metrics[metrics %in% names(combined)]
  }

  if (length(metrics) == 0) {
    stop("No valid metrics found in data")
  }

  # Create location identifier
  location_cols <- c("county_id", "district_id")
  if ("school_id" %in% names(combined)) {
    location_cols <- c(location_cols, "school_id")
  }

  # Reshape to long format with one row per year-location-metric
  long_df <- combined %>%
    dplyr::select(dplyr::all_of(c(location_cols, "year", metrics))) %>%
    tidyr::pivot_longer(
      cols = dplyr::all_of(metrics),
      names_to = "metric_name",
      values_to = "metric_value"
    ) %>%
    dplyr::mutate(location_id = paste(!!!syms(location_cols), sep = "-"))

  # Sort by location and year
  long_df <- long_df %>%
    dplyr::arrange(location_id, metric_name, year)

  # Calculate year-over-year changes
  yoy_changes <- long_df %>%
    dplyr::group_by(location_id, metric_name) %>%
    dplyr::arrange(year) %>%
    dplyr::mutate(
      prev_value = dplyr::lag(metric_value),
      year_over_year_change = metric_value - prev_value,
      year_over_year_pct_change = ((metric_value - prev_value) / prev_value) * 100
    ) %>%
    dplyr::select(-prev_value) %>%
    dplyr::ungroup()

  # Calculate multi-year trend
  # Trend classification: increasing, decreasing, stable, or insufficient_data
  trends <- yoy_changes %>%
    dplyr::group_by(location_id, metric_name) %>%
    dplyr::mutate(
      n_unique_years = length(unique(year)),
      # Simple linear regression slope
      # Use tryCatch to handle cases with insufficient data points
      trend_slope = tryCatch(
        stats::lm(metric_value ~ year)$coefficients[2],
        error = function(e) NA_real_
      ),
      # Classify trend
      multi_year_trend = dplyr::case_when(
        n_unique_years < 2 ~ "insufficient_data",
        is.na(trend_slope) ~ "stable",
        trend_slope > 0 ~ "increasing",
        trend_slope < 0 ~ "decreasing",
        TRUE ~ "stable"
      )
    ) %>%
    dplyr::select(-trend_slope, -n_unique_years) %>%
    dplyr::ungroup()

  # Handle edge cases for percentage change
  # When prev_value is 0 or NA
  trends$year_over_year_pct_change[!is.finite(trends$year_over_year_pct_change)] <- NA

  # Return final data frame
  trends %>%
    dplyr::select(
      year,
      location_id,
      metric_name,
      metric_value,
      year_over_year_change,
      year_over_year_pct_change,
      multi_year_trend
    ) %>%
    dplyr::arrange(location_id, metric_name, year)
}
