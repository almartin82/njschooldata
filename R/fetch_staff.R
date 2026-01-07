# ==============================================================================
# Staff Demographics & Experience Analysis Functions
# ==============================================================================
#
# Analysis functions for staff data. These functions process data from
# fetch_teacher_experience(), fetch_staff_demographics(), fetch_staff_ratios(),
# fetch_staff_counts(), and fetch_staff_retention() to calculate ratios,
# diversity indices, and retention patterns.
#
# ==============================================================================

# -----------------------------------------------------------------------------
# Student-Staff Ratio Analysis
# -----------------------------------------------------------------------------

#' Calculate and Analyze Student-Staff Ratios
#'
#' Calculates student-to-staff ratios with categorization and state comparisons.
#' Analyzes ratios for overall staff, teachers, administrators, and support staff.
#'
#' @param df A data frame from \code{\link{fetch_staff_ratios}} or similar.
#'   Should contain staff count and student enrollment columns.
#' @param ratio_type One of "overall" (default), "teachers", "administrators",
#'   or "support". Specifies which staff category to analyze.
#'
#' @return Data frame with original columns plus:
#'   \itemize{
#'     \item ratio_type - The type of ratio calculated
#'     \item student_staff_ratio - Students per staff member (higher = more students per staff)
#'     \item ratio_category - "low" (< 10), "medium" (10-20), or "high" (> 20) based on benchmarks
#'     \item percent_change_vs_state - Percent difference from state average (if state data available)
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Get staff ratio data
#' ratios <- fetch_staff_ratios(2024)
#'
#' # Calculate overall student-staff ratios
#' overall_ratios <- calc_student_staff_ratio(ratios, ratio_type = "overall")
#'
#' # Calculate teacher-specific ratios
#' teacher_ratios <- calc_student_staff_ratio(ratios, ratio_type = "teachers")
#'
#' # View schools with highest student-teacher ratios
#' teacher_ratios %>%
#'   dplyr::arrange(dplyr::desc(student_staff_ratio)) %>%
#'   dplyr::select(school_name, student_staff_ratio, ratio_category)
#' }
calc_student_staff_ratio <- function(df, ratio_type = "overall") {

  # Validate ratio_type
  valid_types <- c("overall", "teachers", "administrators", "support")
  if (!ratio_type %in% valid_types) {
    stop(paste("ratio_type must be one of:", paste(valid_types, collapse = ", ")))
  }

  # Try to find student enrollment column
  student_cols <- grep("student|enrollment", names(df), value = TRUE, ignore.case = TRUE)
  student_cols <- student_cols[!grepl("staff|teacher|admin", student_cols, ignore.case = TRUE)]

  if (length(student_cols) == 0) {
    stop("Cannot find student enrollment column in input data")
  }
  student_col <- student_cols[1]

  # Find appropriate staff column based on ratio_type
  if (ratio_type == "overall") {
    staff_cols <- grep("^staff|^number_staff|^total_staff", names(df),
                      value = TRUE, ignore.case = TRUE)
  } else if (ratio_type == "teachers") {
    staff_cols <- grep("teacher", names(df), value = TRUE, ignore.case = TRUE)
    staff_cols <- staff_cols[!grepl("admin|support|student", staff_cols, ignore.case = TRUE)]
  } else if (ratio_type == "administrators") {
    staff_cols <- grep("admin", names(df), value = TRUE, ignore.case = TRUE)
    staff_cols <- staff_cols[!grepl("teacher|support|student", staff_cols, ignore.case = TRUE)]
  } else if (ratio_type == "support") {
    staff_cols <- grep("support", names(df), value = TRUE, ignore.case = TRUE)
    staff_cols <- staff_cols[!grepl("teacher|admin|student", staff_cols, ignore.case = TRUE)]
  }

  if (length(staff_cols) == 0) {
    stop(paste("Cannot find", ratio_type, "staff column in input data"))
  }
  staff_col <- staff_cols[1]

  # Ensure numeric
  df[[student_col]] <- as.numeric(df[[student_col]])
  df[[staff_col]] <- as.numeric(df[[staff_col]])

  # Calculate student-staff ratio
  df$student_staff_ratio <- df[[student_col]] / df[[staff_col]]

  # Add ratio_type column
  df$ratio_type <- ratio_type

  # Categorize ratios based on benchmarks
  # These are general benchmarks - adjust based on NJ standards
  # Low: < 10 students per staff (favorable)
  # Medium: 10-20 students per staff (typical)
  # High: > 20 students per staff (high workload)
  df$ratio_category <- dplyr::case_when(
    df$student_staff_ratio < 10 ~ "low",
    df$student_staff_ratio >= 10 & df$student_staff_ratio <= 20 ~ "medium",
    df$student_staff_ratio > 20 ~ "high",
    TRUE ~ "unknown"
  )

  # Calculate percent change vs state if state data is available
  if ("is_state" %in% names(df) && any(df$is_state == TRUE)) {

    # Get state average for this ratio_type
    state_avg <- df %>%
      dplyr::filter(is_state == TRUE) %>%
      dplyr::pull(student_staff_ratio) %>%
      mean(na.rm = TRUE)

    # Calculate percent difference
    df$percent_change_vs_state <- ((df$student_staff_ratio - state_avg) / state_avg) * 100

    # Handle edge cases
    df$percent_change_vs_state[!is.finite(df$percent_change_vs_state)] <- NA

  } else {
    df$percent_change_vs_state <- NA_real_
  }

  # Handle edge cases for ratio (e.g., zero staff)
  df$student_staff_ratio[!is.finite(df$student_staff_ratio)] <- NA

  df
}


# -----------------------------------------------------------------------------
# Staff Diversity Metrics
# -----------------------------------------------------------------------------

#' Calculate Staff Diversity Metrics
#'
#' Calculates diversity indices for staff demographics using Simpson's
#' Diversity Index. Computes racial and gender diversity scores with
#' percentile rankings.
#'
#' @param df A data frame from \code{\link{fetch_staff_demographics}}.
#'   Should contain staff demographic breakdowns with counts.
#' @param metrics Character vector specifying which diversity metrics to calculate.
#'   Options: "racial" (default), "gender", or both c("racial", "gender").
#'
#' @return Data frame with:
#'   \itemize{
#'     \item location_id - Combined location identifier
#'     \item diversity_index - Overall Simpson's Diversity Index (0-1 scale, higher = more diverse)
#'     \item racial_diversity_score - Racial diversity score (0-1 scale)
#'     \item gender_diversity_score - Gender diversity score (0-1 scale)
#'     \item diversity_percentile_rank - Percentile rank vs all schools (0-100)
#'     \item diversity_quintile - Quintile rank (1-5, 5 = most diverse)
#'   }
#'
#' @details
#' Simpson's Diversity Index is calculated as:
#' \deqn{D = 1 - \sum(p_i^2)}
#'
#' where \eqn{p_i} is the proportion of staff in category \eqn{i}.
#'
#' Values range from 0 (no diversity - all staff in one category) to
#' 1 (maximum diversity - staff evenly distributed across all categories).
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Get staff demographics data
#' demographics <- fetch_staff_demographics(2024)
#'
#' # Calculate racial diversity
#' racial_div <- calc_staff_diversity_metrics(demographics, metrics = "racial")
#'
#' # Calculate both racial and gender diversity
#' all_div <- calc_staff_diversity_metrics(demographics,
#'                                          metrics = c("racial", "gender"))
#'
#' # View most diverse schools
#' all_div %>%
#'   dplyr::arrange(dplyr::desc(diversity_index)) %>%
#'   dplyr::select(school_name, diversity_index, diversity_quintile)
#' }
calc_staff_diversity_metrics <- function(df, metrics = c("racial")) {

  # Validate metrics
  valid_metrics <- c("racial", "gender")
  metrics <- match.arg(metrics, valid_metrics, several.ok = TRUE)

  # Create location identifier
  location_cols <- c("county_id", "district_id")
  if ("school_id" %in% names(df)) {
    location_cols <- c(location_cols, "school_id")
  }

  # Find demographic category column
  category_cols <- grep("subgroup|category|group|demographic", names(df),
                        value = TRUE, ignore.case = TRUE)

  if (length(category_cols) == 0) {
    stop("Cannot find demographic category column in input data")
  }
  category_col <- category_cols[1]

  # Find count column
  count_cols <- grep("number|count|n_|staff|teachers", names(df),
                     value = TRUE, ignore.case = TRUE)
  count_cols <- count_cols[!grepl("student|enrollment", count_cols, ignore.case = TRUE)]

  if (length(count_cols) == 0) {
    stop("Cannot find staff count column in input data")
  }
  count_col <- count_cols[1]

  # Ensure numeric
  df[[count_col]] <- as.numeric(df[[count_col]])

  # Calculate diversity by location
  diversity_df <- df %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(location_cols))) %>%
    dplyr::mutate(
      location_id = paste(!!!syms(location_cols), sep = "-")
    ) %>%
    dplyr::ungroup()

  # Initialize diversity score columns
  diversity_df$racial_diversity_score <- NA_real_
  diversity_df$gender_diversity_score <- NA_real_

  # Calculate racial diversity if requested
  if ("racial" %in% metrics) {
    # Identify racial categories (exclude gender and total categories)
    racial_keywords <- c("black|african", "hispanic|latino", "white", "asian",
                         "native", "pacific", "island", "two|more|multi", "race")

    racial_data <- diversity_df %>%
      dplyr::filter(
        grepl(paste(racial_keywords, collapse = "|"),
              !!dplyr::sym(category_col), ignore.case = TRUE)
      )

    if (nrow(racial_data) > 0) {
      racial_div <- racial_data %>%
        dplyr::group_by(location_id) %>%
        dplyr::mutate(
          total_staff = sum(!!dplyr::sym(count_col), na.rm = TRUE),
          prop = !!dplyr::sym(count_col) / total_staff
        ) %>%
        dplyr::summarise(
          racial_diversity_score = 1 - sum(prop^2, na.rm = TRUE),
          .groups = "drop"
        )

      # Remove the NA column before joining
      diversity_df$racial_diversity_score <- NULL

      diversity_df <- diversity_df %>%
        dplyr::left_join(racial_div, by = "location_id")
    }
  }

  # Calculate gender diversity if requested
  if ("gender" %in% metrics) {
    # Identify gender categories
    gender_keywords <- c("male", "female", "gender")

    gender_data <- diversity_df %>%
      dplyr::filter(
        grepl(paste(gender_keywords, collapse = "|"),
              !!dplyr::sym(category_col), ignore.case = TRUE)
      )

    if (nrow(gender_data) > 0) {
      gender_div <- gender_data %>%
        dplyr::group_by(location_id) %>%
        dplyr::mutate(
          total_staff = sum(!!dplyr::sym(count_col), na.rm = TRUE),
          prop = !!dplyr::sym(count_col) / total_staff
        ) %>%
        dplyr::summarise(
          gender_diversity_score = 1 - sum(prop^2, na.rm = TRUE),
          .groups = "drop"
        )

      # Remove the NA column before joining
      diversity_df$gender_diversity_score <- NULL

      # Join
      gender_div_only <- gender_div %>%
        dplyr::select(location_id, gender_diversity_score)

      diversity_df <- diversity_df %>%
        dplyr::left_join(gender_div_only, by = "location_id")
    }
  }

  # Calculate overall diversity index (average of available scores)
  # First, get unique locations with their scores
  unique_div <- diversity_df %>%
    dplyr::select(dplyr::any_of(c(location_cols, "location_id",
                                  "racial_diversity_score",
                                  "gender_diversity_score"))) %>%
    dplyr::distinct()

  # Calculate overall index as average of available metrics
  # Use pmin/pmax to handle NA values properly
  unique_div <- unique_div %>%
    dplyr::mutate(
      diversity_index = rowMeans(
        dplyr::select(., dplyr::any_of(c("racial_diversity_score",
                                            "gender_diversity_score"))),
        na.rm = TRUE
      )
    )

  # Handle edge cases
  unique_div$diversity_index[!is.finite(unique_div$diversity_index)] <- NA

  # Calculate percentile ranks
  unique_div <- unique_div %>%
    dplyr::mutate(
      diversity_percentile_rank = dplyr::percent_rank(diversity_index) * 100,
      diversity_quintile = dplyr::ntile(diversity_index, 5)
    )

  # Handle NA values in percentile/quintile
  unique_div$diversity_percentile_rank[is.na(unique_div$diversity_index)] <- NA
  unique_div$diversity_quintile[is.na(unique_div$diversity_index)] <- NA

  # Return result with one row per location
  result <- unique_div %>%
    dplyr::select(
      dplyr::any_of(c(location_cols, "location_id", "diversity_index",
                      "racial_diversity_score", "gender_diversity_score",
                      "diversity_percentile_rank", "diversity_quintile"))
    ) %>%
    dplyr::arrange(dplyr::desc(diversity_index))

  result
}


# -----------------------------------------------------------------------------
# Staff Retention Pattern Analysis
# -----------------------------------------------------------------------------

#' Analyze Staff Retention Patterns
#'
#' Analyzes staff retention patterns across multiple years and demographic subgroups.
#' Calculates retention rates, turnover rates, and stability indices with trend detection.
#'
#' @param df_list A named list of data frames from different years. Each element
#'   should be named by its end_year (e.g., list("2022" = df_2022, "2024" = df_2024)).
#'   Data frames should be from \code{\link{fetch_staff_retention}} or similar
#'   containing staff retention data.
#' @param by_subgroup Logical; if TRUE (default), analyze retention patterns
#'   by demographic subgroups. If FALSE, aggregate across all staff.
#'
#' @return Data frame with:
#'   \itemize{
#'     \item year - Year identifier
#'     \item location_id - Combined location identifier
#'     \item subgroup - Demographic subgroup (if by_subgroup = TRUE)
#'     \item retention_rate - Percentage of staff who returned from previous year
#'     \item turnover_rate - Percentage of new staff in current year
#'     \item stability_index - Composite score combining retention and turnover (0-100)
#'     \item trend - Trend classification: "improving", "stable", "declining", or "insufficient_data"
#'   }
#'
#' @details
#' The stability index is calculated as:
#' \deqn{stability = (retention_rate + (100 - turnover_rate)) / 2}
#'
#' Higher values indicate greater staff stability (retained staff + low turnover).
#'
#' Trend classification uses linear regression on multi-year stability scores:
#' \itemize{
#'   \item improving - Positive slope (stability increasing over time)
#'   \item stable - Near-zero slope or insufficient data
#'   \item declining - Negative slope (stability decreasing over time)
#' }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Fetch retention data for multiple years
#' retain_2022 <- fetch_staff_retention(2022)
#' retain_2023 <- fetch_staff_retention(2023)
#' retain_2024 <- fetch_staff_retention(2024)
#'
#' # Combine into named list
#' df_list <- list(
#'   "2022" = retain_2022,
#'   "2023" = retain_2023,
#'   "2024" = retain_2024
#' )
#'
#' # Analyze overall retention patterns
#' overall_patterns <- analyze_retention_patterns(df_list, by_subgroup = FALSE)
#'
#' # Analyze by demographic subgroup
#' subgroup_patterns <- analyze_retention_patterns(df_list, by_subgroup = TRUE)
#'
#' # View schools with declining retention
#' subgroup_patterns %>%
#'   dplyr::filter(trend == "declining") %>%
#'   dplyr::select(school_name, year, subgroup, retention_rate, trend)
#' }
analyze_retention_patterns <- function(df_list, by_subgroup = TRUE) {

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

  # Find retention/turnover columns
  # Look for various naming patterns
  retention_cols <- grep("retention|retained|returning|returned",
                         names(combined), value = TRUE, ignore.case = TRUE)
  turnover_cols <- grep("turnover|new.*staff|attrition",
                        names(combined), value = TRUE, ignore.case = TRUE)

  # Use best matching columns
  retention_col <- if (length(retention_cols) > 0) retention_cols[1] else NULL
  turnover_col <- if (length(turnover_cols) > 0) turnover_cols[1] else NULL

  # If not found, try to calculate from other columns
  if (is.null(retention_col) || is.null(turnover_col)) {
    # Look for columns that might have staff counts
    staff_cols <- grep("staff|teacher|facs|faculty|headcount",
                       names(combined), value = TRUE, ignore.case = TRUE)
    staff_cols <- staff_cols[!grepl("student", staff_cols, ignore.case = TRUE)]

    if (length(staff_cols) >= 2) {
      # Assume first column is returning staff, second is total staff
      # This is a fallback - real data should have explicit retention/turnover columns
      warning("Could not find explicit retention/turnover columns. ",
              "Attempting to derive from staff count columns.")
    }
  }

  # Create location identifier
  location_cols <- c("county_id", "district_id")
  if ("school_id" %in% names(combined)) {
    location_cols <- c(location_cols, "school_id")
  }

  # Check if we should analyze by subgroup
  if (by_subgroup) {
    # Find subgroup column
    subgroup_cols <- grep("subgroup|group|demographic|category",
                          names(combined), value = TRUE, ignore.case = TRUE)

    if (length(subgroup_cols) == 0) {
      stop("Cannot find subgroup column in data. Set by_subgroup = FALSE for aggregate analysis.")
    }
    subgroup_col <- subgroup_cols[1]

    # Group by location and subgroup
    group_cols <- c("year", location_cols, subgroup_col)
  } else {
    # Analyze aggregate only
    subgroup_col <- NULL
    group_cols <- c("year", location_cols)
  }

  # Create location_id
  combined <- combined %>%
    dplyr::mutate(location_id = paste(!!!syms(location_cols), sep = "-"))

  # Calculate retention and turnover rates if columns exist
  if (!is.null(retention_col) && !is.null(turnover_col)) {
    # Ensure numeric
    combined[[retention_col]] <- as.numeric(combined[[retention_col]])
    combined[[turnover_col]] <- as.numeric(combined[[turnover_col]])

    # Some data might have counts, others might have percentages
    # Check if values are already percentages (0-100) or need conversion
    if (max(combined[[retention_col]], na.rm = TRUE) <= 1) {
      combined$retention_rate <- combined[[retention_col]] * 100
    } else {
      combined$retention_rate <- combined[[retention_col]]
    }

    if (max(combined[[turnover_col]], na.rm = TRUE) <= 1) {
      combined$turnover_rate <- combined[[turnover_col]] * 100
    } else {
      combined$turnover_rate <- combined[[turnover_col]]
    }

  } else {
    # If columns not found, set to NA with warning
    warning("Could not find retention/turnover columns. Setting rates to NA.")
    combined$retention_rate <- NA_real_
    combined$turnover_rate <- NA_real_
  }

  # Calculate stability index
  # Stability = average of retention rate and retention of existing staff (100 - turnover)
  # Higher = more stable
  combined <- combined %>%
    dplyr::mutate(
      stability_index = (retention_rate + (100 - turnover_rate)) / 2
    )

  # Handle edge cases
  combined$stability_index[!is.finite(combined$stability_index)] <- NA

  # Summarize by group (year, location, and optionally subgroup)
  summary_df <- combined %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(group_cols))) %>%
    dplyr::summarise(
      location_id = first(location_id),
      retention_rate = mean(retention_rate, na.rm = TRUE),
      turnover_rate = mean(turnover_rate, na.rm = TRUE),
      stability_index = mean(stability_index, na.rm = TRUE),
      .groups = "drop"
    )

  # Calculate trend across years
  # Need at least 2 years to calculate trend
  if (by_subgroup) {
    trends <- summary_df %>%
      dplyr::group_by(location_id, !!dplyr::sym(subgroup_col))
  } else {
    trends <- summary_df %>%
      dplyr::group_by(location_id)
  }

  trends <- trends %>%
    dplyr::mutate(
      n_years = length(unique(year))
    ) %>%
    dplyr::ungroup()

  # Classify trends using linear regression on stability_index
  if (by_subgroup) {
    trends <- trends %>%
      dplyr::group_by(location_id, !!dplyr::sym(subgroup_col))
  } else {
    trends <- trends %>%
      dplyr::group_by(location_id)
  }

  trends <- trends %>%
    dplyr::mutate(
      trend_slope = tryCatch(
        if (n() >= 2) {
          coef(lm(stability_index ~ year, data = .))[2]
        } else {
          NA_real_
        },
        error = function(e) NA_real_
      ),
      trend = dplyr::case_when(
        n_years < 2 ~ "insufficient_data",
        is.na(trend_slope) ~ "stable",
        trend_slope > 0.5 ~ "improving",   # Threshold: 0.5% improvement per year
        trend_slope < -0.5 ~ "declining",  # Threshold: 0.5% decline per year
        TRUE ~ "stable"
      )
    ) %>%
    dplyr::ungroup() %>%
    dplyr::select(-trend_slope, -n_years)

  # Reorder and rename columns
  if (by_subgroup) {
    result <- trends %>%
      dplyr::select(
        year,
        location_id,
        !!dplyr::sym(subgroup_col),
        retention_rate,
        turnover_rate,
        stability_index,
        trend
      ) %>%
      dplyr::arrange(location_id, !!dplyr::sym(subgroup_col), year)
  } else {
    result <- trends %>%
      dplyr::select(
        year,
        location_id,
        retention_rate,
        turnover_rate,
        stability_index,
        trend
      ) %>%
      dplyr::arrange(location_id, year)
  }

  result
}
