# ==============================================================================
# Graduation Data Recovery and Validation
# ==============================================================================
#
# Functions to recover suppressed graduation data from school-level aggregates
# and validate district-level data against school-level sums.
#
# ==============================================================================

#' Recover suppressed district graduation rates from school data
#'
#' When NJ DOE suppresses district-level graduation rates (showing them as NA),
#' this function attempts to calculate them from school-level data. This is
#' useful when district data is suppressed but school-level data is available
#' for the same subgroup.
#'
#' @param df Graduation rate data frame with both school and district level data.
#'   Must include columns: district_id, school_id, subgroup, grad_rate,
#'   cohort_count, end_year, is_district, is_school
#' @param min_schools Minimum number of schools required to calculate district
#'   rate. Default is 1.
#' @param min_cohort Minimum total cohort size required. Default is 10.
#' @param log_dir Directory for log files. Default is tempdir().
#'
#' @return Data frame with recovered district rates where possible. Adds columns:
#'   - `grad_rate_recovered`: TRUE if the rate was recovered from school data
#'   - `grad_rate_original`: Original (suppressed) value before recovery
#'   - `recovered_n_schools`: Number of schools used in calculation
#'   - `recovered_cohort`: Total cohort used in calculation
#'
#' @details
#' The function calculates district rates as the weighted average of school
#' rates, weighted by cohort count. This matches NJ DOE's methodology.
#'
#' Recovery only occurs when:
#' - District-level grad_rate is NA (suppressed)
#' - At least `min_schools` schools have non-NA rates for that subgroup
#' - Total cohort is at least `min_cohort`
#'
#' A log file is written with details of all recoveries.
#'
#' @export
recover_suppressed_grate <- function(df, min_schools = 1, min_cohort = 10,
                                      log_dir = tempdir()) {

  # Validate required columns
  required_cols <- c("district_id", "school_id", "subgroup", "grad_rate",
                     "end_year", "is_district", "is_school")
  missing_cols <- setdiff(required_cols, names(df))
  if (length(missing_cols) > 0) {
    stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
  }

  # Add cohort_count if missing
  if (!"cohort_count" %in% names(df)) {
    df$cohort_count <- NA_integer_
  }

  # Initialize recovery tracking columns
  df$grad_rate_recovered <- FALSE
  df$grad_rate_original <- df$grad_rate
  df$recovered_n_schools <- NA_integer_
  df$recovered_cohort <- NA_integer_

  # Find suppressed district-level records
  suppressed_districts <- df %>%
    dplyr::filter(is_district, is.na(grad_rate)) %>%
    dplyr::select(end_year, district_id, district_name, subgroup) %>%
    dplyr::distinct()

  if (nrow(suppressed_districts) == 0) {
    return(df)
  }

  # Calculate school-level aggregates for each suppressed district/year/subgroup
  school_aggs <- df %>%
    dplyr::filter(is_school, !is.na(grad_rate)) %>%
    dplyr::semi_join(
      suppressed_districts,
      by = c("end_year", "district_id", "subgroup")
    ) %>%
    dplyr::group_by(end_year, district_id, subgroup) %>%
    dplyr::summarize(
      n_schools = dplyr::n(),
      total_cohort = sum(cohort_count, na.rm = TRUE),
      school_names = paste(school_name, collapse = ", "),
      # Weighted average by cohort count
      calculated_rate = if (all(is.na(cohort_count))) {
        mean(grad_rate, na.rm = TRUE)
      } else {
        stats::weighted.mean(grad_rate, cohort_count, na.rm = TRUE)
      },
      .groups = "drop"
    ) %>%
    # Apply minimum thresholds
    dplyr::filter(
      n_schools >= min_schools,
      total_cohort >= min_cohort | is.na(total_cohort)
    )

  if (nrow(school_aggs) == 0) {
    return(df)
  }

  # Write recovery log
  log_file <- file.path(log_dir, sprintf("grate_recovery_%s.log",
                                          format(Sys.time(), "%Y%m%d_%H%M%S")))

  log_content <- c(
    "================================================================================",
    "GRADUATION RATE DATA RECOVERY LOG",
    sprintf("Generated: %s", Sys.time()),
    "================================================================================",
    "",
    "This log documents district-level graduation rates that were suppressed",
    "(shown as * or NA) in the NJ DOE source files but have been recovered",
    "by calculating weighted averages from school-level data.",
    "",
    "Methodology: Weighted average of school rates, weighted by cohort count.",
    sprintf("Minimum schools required: %d", min_schools),
    sprintf("Minimum cohort required: %d", min_cohort),
    "",
    "--------------------------------------------------------------------------------",
    "RECOVERED RATES",
    "--------------------------------------------------------------------------------",
    ""
  )

  # Add details for each recovery
  recovery_details <- school_aggs %>%
    dplyr::left_join(
      suppressed_districts %>%
        dplyr::select(end_year, district_id, district_name) %>%
        dplyr::distinct(),
      by = c("end_year", "district_id")
    )

  for (i in seq_len(nrow(recovery_details))) {
    row <- recovery_details[i, ]
    log_content <- c(log_content,
      sprintf("Year: %d | District: %s (%s) | Subgroup: %s",
              row$end_year, row$district_name, row$district_id, row$subgroup),
      sprintf("  Recovered rate: %.1f%%", row$calculated_rate * 100),
      sprintf("  Based on %d schools with total cohort of %d students",
              row$n_schools, row$total_cohort),
      sprintf("  Schools: %s", row$school_names),
      ""
    )
  }

  writeLines(log_content, log_file)

  # Join and update
  df <- df %>%
    dplyr::left_join(
      school_aggs %>%
        dplyr::select(end_year, district_id, subgroup,
                      calculated_rate, n_schools, total_cohort),
      by = c("end_year", "district_id", "subgroup")
    ) %>%
    dplyr::mutate(
      grad_rate = dplyr::if_else(
        is_district & is.na(grad_rate_original) & !is.na(calculated_rate),
        calculated_rate,
        grad_rate
      ),
      grad_rate_recovered = is_district & is.na(grad_rate_original) & !is.na(calculated_rate),
      recovered_n_schools = dplyr::if_else(grad_rate_recovered, n_schools, NA_integer_),
      recovered_cohort = dplyr::if_else(grad_rate_recovered, as.integer(total_cohort), NA_integer_)
    ) %>%
    dplyr::select(-calculated_rate, -n_schools, -total_cohort)

  n_recovered <- sum(df$grad_rate_recovered, na.rm = TRUE)
  message(sprintf("INFO: Recovered %d suppressed district graduation rates from school-level data. Details logged to: %s",
                  n_recovered, log_file))

  df
}


#' Validate graduation rate aggregation
#'
#' Compares district-level graduation rates against weighted averages calculated
#' from school-level data. Flags discrepancies that exceed a threshold, which
#' may indicate data quality issues in the source files.
#'
#' @param df Graduation rate data frame with both school and district level data
#' @param tolerance Maximum allowed difference (in percentage points) between
#'   reported district rate and calculated rate. Default is 2 (2 percentage points).
#' @param log_dir Directory for log files. Default is tempdir().
#'
#' @return Data frame with validation columns added:
#'   - `calculated_from_schools`: Rate calculated from school-level data
#'   - `rate_discrepancy_pp`: Difference in percentage points
#'   - `aggregation_flag`: "OK", "DISCREPANCY", "MISSING_SCHOOL_DATA", or "SUPPRESSED"
#'
#' @details
#' This function helps identify potential data quality issues where:
#' - District totals don't match sum of school data
#' - Rates are mathematically inconsistent
#' - Data may have been incorrectly entered or processed
#'
#' A detailed log file is written documenting all discrepancies found.
#'
#' @export
validate_grate_aggregation <- function(df, tolerance = 2, log_dir = tempdir()) {

  # Validate required columns
  required_cols <- c("district_id", "school_id", "subgroup", "grad_rate",
                     "end_year", "is_district", "is_school")
  missing_cols <- setdiff(required_cols, names(df))
  if (length(missing_cols) > 0) {
    stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
  }

  # Add cohort_count if missing
  if (!"cohort_count" %in% names(df)) {
    df$cohort_count <- NA_integer_
  }

  # Calculate school-level aggregates for all districts
  school_aggs <- df %>%
    dplyr::filter(is_school, !is.na(grad_rate)) %>%
    dplyr::group_by(end_year, district_id, subgroup) %>%
    dplyr::summarize(
      n_schools_with_data = dplyr::n(),
      school_total_cohort = sum(cohort_count, na.rm = TRUE),
      school_names = paste(school_name, collapse = "; "),
      calculated_from_schools = if (all(is.na(cohort_count))) {
        mean(grad_rate, na.rm = TRUE)
      } else {
        stats::weighted.mean(grad_rate, cohort_count, na.rm = TRUE)
      },
      .groups = "drop"
    )

  # Join to district data
  df <- df %>%
    dplyr::left_join(
      school_aggs,
      by = c("end_year", "district_id", "subgroup")
    ) %>%
    dplyr::mutate(
      # Calculate discrepancy in percentage points (rates are 0-1)
      rate_discrepancy_pp = dplyr::if_else(
        is_district & !is.na(grad_rate) & !is.na(calculated_from_schools),
        (grad_rate - calculated_from_schools) * 100,
        NA_real_
      ),
      # Flag status
      aggregation_flag = dplyr::case_when(
        !is_district ~ NA_character_,
        is.na(grad_rate) & is.na(calculated_from_schools) ~ "SUPPRESSED",
        is.na(grad_rate) & !is.na(calculated_from_schools) ~ "RECOVERABLE",
        !is.na(grad_rate) & is.na(calculated_from_schools) ~ "MISSING_SCHOOL_DATA",
        abs(rate_discrepancy_pp) > tolerance ~ "DISCREPANCY",
        TRUE ~ "OK"
      )
    )

  # Get discrepancies for logging
  discrepancies <- df %>%
    dplyr::filter(aggregation_flag == "DISCREPANCY") %>%
    dplyr::select(end_year, district_id, district_name, subgroup,
                  grad_rate, calculated_from_schools, rate_discrepancy_pp,
                  n_schools_with_data, school_total_cohort, school_names) %>%
    dplyr::arrange(dplyr::desc(abs(rate_discrepancy_pp)))

  n_discrepancies <- nrow(discrepancies)

  if (n_discrepancies > 0) {
    # Write detailed log file
    log_file <- file.path(log_dir, sprintf("grate_validation_%s.log",
                                            format(Sys.time(), "%Y%m%d_%H%M%S")))

    log_content <- c(
      "================================================================================",
      "GRADUATION RATE VALIDATION LOG - MATHEMATICAL INCONSISTENCIES",
      sprintf("Generated: %s", Sys.time()),
      "================================================================================",
      "",
      "This log documents mathematical inconsistencies found in NJ DOE graduation",
      "rate data where the reported district-level rate does not match the weighted",
      "average calculated from school-level data.",
      "",
      sprintf("Tolerance threshold: %.1f percentage points", tolerance),
      sprintf("Total discrepancies found: %d", n_discrepancies),
      "",
      "These inconsistencies may be caused by:",
      "  - Data entry errors in source files",
      "  - Students in alternative programs not assigned to specific schools",
      "  - Suppressed school data not visible in public files",
      "  - Rounding differences in source calculations",
      "",
      "--------------------------------------------------------------------------------",
      "DETAILED DISCREPANCY REPORT",
      "--------------------------------------------------------------------------------",
      ""
    )

    for (i in seq_len(nrow(discrepancies))) {
      row <- discrepancies[i, ]
      log_content <- c(log_content,
        sprintf("DISCREPANCY #%d", i),
        sprintf("  Year: %d", row$end_year),
        sprintf("  District: %s (ID: %s)", row$district_name, row$district_id),
        sprintf("  Subgroup: %s", row$subgroup),
        "",
        sprintf("  Reported district rate:  %.1f%%", row$grad_rate * 100),
        sprintf("  Calculated from schools: %.1f%%", row$calculated_from_schools * 100),
        sprintf("  DISCREPANCY: %+.1f percentage points", row$rate_discrepancy_pp),
        "",
        sprintf("  Calculation based on %d schools with %d total students:",
                row$n_schools_with_data, row$school_total_cohort),
        sprintf("  Schools: %s", row$school_names),
        "",
        "--------------------------------------------------------------------------------",
        ""
      )
    }

    # Add summary by year
    log_content <- c(log_content,
      "",
      "SUMMARY BY YEAR",
      "---------------"
    )

    year_summary <- discrepancies %>%
      dplyr::group_by(end_year) %>%
      dplyr::summarize(
        count = dplyr::n(),
        avg_discrepancy = mean(abs(rate_discrepancy_pp)),
        .groups = "drop"
      )

    for (i in seq_len(nrow(year_summary))) {
      row <- year_summary[i, ]
      log_content <- c(log_content,
        sprintf("  %d: %d discrepancies (avg %.1f pp)",
                row$end_year, row$count, row$avg_discrepancy)
      )
    }

    writeLines(log_content, log_file)

    message(sprintf("INFO: Found %d mathematical inconsistencies in graduation rate data. Details logged to: %s",
                    n_discrepancies, log_file))
  } else {
    message("INFO: No mathematical inconsistencies found in graduation rate aggregations.")
  }

  df
}


#' Get graduation rate validation summary
#'
#' Generates a summary report of graduation rate data quality.
#'
#' @param df Graduation rate data frame (output of validate_grate_aggregation)
#' @return Data frame summarizing validation results by year
#'
#' @export
grate_validation_summary <- function(df) {

  if (!"aggregation_flag" %in% names(df)) {
    stop("Data must be validated first. Run validate_grate_aggregation() first.")
  }

  df %>%
    dplyr::filter(is_district) %>%
    dplyr::group_by(end_year) %>%
    dplyr::summarize(
      total_records = dplyr::n(),
      ok = sum(aggregation_flag == "OK", na.rm = TRUE),
      discrepancies = sum(aggregation_flag == "DISCREPANCY", na.rm = TRUE),
      recoverable = sum(aggregation_flag == "RECOVERABLE", na.rm = TRUE),
      suppressed = sum(aggregation_flag == "SUPPRESSED", na.rm = TRUE),
      missing_school_data = sum(aggregation_flag == "MISSING_SCHOOL_DATA", na.rm = TRUE),
      pct_ok = round(ok / total_records * 100, 1),
      .groups = "drop"
    )
}
