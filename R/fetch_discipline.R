# ==============================================================================
# Discipline & Climate Data Fetching Functions
# ==============================================================================
#
# Functions for downloading and extracting school discipline and climate
# indicators from the NJ DOE School Performance Reports databases.
#
# Covers: Violence/vandalism, HIB investigations, police notifications,
# disciplinary removals, suspensions, and expulsion data.
#
# ==============================================================================

# -----------------------------------------------------------------------------
# Violence, Vandalism, HIB Incidents
# -----------------------------------------------------------------------------

#' Fetch Violence, Vandalism, HIB, and Substance Incidents
#'
#' Downloads and extracts incident data including violence, vandalism,
#' harassment/intimidation/bullying (HIB), and substance offenses from
#' the SPR database.
#'
#' @param end_year A school year (2017-2024). Year is the end of the academic
#'   year - eg 2020-21 school year is end_year '2021'.
#' @param level One of "school" or "district". "school" returns school-level
#'   data, "district" returns district and state-level data.
#'
#' @return Data frame with incident data including:
#'   \itemize{
#'     \item end_year, county_id, county_name, district_id, district_name
#'     \item school_id, school_name (for school-level data)
#'     \item subgroup - Student group (total population, racial/ethnic groups, etc.)
#'     \item [Incident count columns - varies by year]
#'     \item Aggregation flags (is_state, is_county, is_district, is_school, is_charter)
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Get school-level incident data
#' incidents <- fetch_violence_vandalism_hib(2024)
#'
#' # Get district-level data
#' incidents_dist <- fetch_violence_vandalism_hib(2024, level = "district")
#'
#' # Analyze total incidents
#' incidents %>%
#'   filter(subgroup == "total population") %>%
#'   select(school_name, contains("incident"), contains("Incident"))
#' }
fetch_violence_vandalism_hib <- function(end_year, level = "school") {
  # Use generic extractor
  df <- fetch_spr_data(
    sheet_name = "ViolenceVandalismHIBSubstanceOf",
    end_year = end_year,
    level = level
  )

  df
}


# -----------------------------------------------------------------------------
# HIB Investigations
# -----------------------------------------------------------------------------

#' Fetch HIB Investigation Data
#'
#' Downloads and extracts Harassment, Intimidation, and Bullying (HIB)
#' investigation data from the SPR database. Includes investigation
#' counts, outcomes, and timing data.
#'
#' @param end_year A school year (2017-2024). Year is the end of the academic
#'   year - eg 2020-21 school year is end_year '2021'.
#' @param level One of "school" or "district". "school" returns school-level
#'   data, "district" returns district and state-level data.
#'
#' @return Data frame with HIB investigation data
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Get HIB investigation data
#' hib <- fetch_hib_investigations(2024)
#'
#' # Analyze investigation outcomes
#' hib %>%
#'   filter(is_school == TRUE) %>%
#'   select(school_name, contains("investigation"), contains("Investigation"))
#' }
fetch_hib_investigations <- function(end_year, level = "school") {
  # Use generic extractor
  df <- fetch_spr_data(
    sheet_name = "HIBInvestigations",
    end_year = end_year,
    level = level
  )

  df
}


# -----------------------------------------------------------------------------
# Police Notifications
# -----------------------------------------------------------------------------

#' Fetch Police Notification Data
#'
#' Downloads and extracts police notification data from the SPR database.
#' Police notifications are reported for specific serious incidents.
#'
#' @param end_year A school year (2017-2024). Year is the end of the academic
#'   year - eg 2020-21 school year is end_year '2021'.
#' @param level One of "school" or "district". "school" returns school-level
#'   data, "district" returns district and state-level data.
#' @param by_subgroup If TRUE, fetches data by student subgroup (requires
#'   different sheet). Defaults to FALSE.
#'
#' @return Data frame with police notification data
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Get police notification data
#' police <- fetch_police_notifications(2024)
#'
#' # Get by subgroup
#' police_subgroup <- fetch_police_notifications(2024, by_subgroup = TRUE)
#'
#' # Analyze notification rates
#' police %>%
#'   filter(is_school == TRUE) %>%
#'   select(school_name, contains("notification"), contains("Notification"))
#' }
fetch_police_notifications <- function(end_year, level = "school", by_subgroup = FALSE) {
  # Choose sheet based on subgroup parameter
  sheet_name <- if (by_subgroup) {
    "PoliceNotificationByStuGroup"
  } else {
    "PoliceNotifications"
  }

  # Use generic extractor
  df <- fetch_spr_data(
    sheet_name = sheet_name,
    end_year = end_year,
    level = level
  )

  df
}


# -----------------------------------------------------------------------------
# Disciplinary Removals
# -----------------------------------------------------------------------------

#' Fetch Disciplinary Removal Data
#'
#' Downloads and extracts disciplinary removal (suspension/expulsion) data
#' from the SPR database. Includes both in-school and out-of-school suspensions.
#'
#' @param end_year A school year (2017-2024). Year is the end of the academic
#'   year - eg 2020-21 school year is end_year '2021'.
#' @param level One of "school" or "district". "school" returns school-level
#'   data, "district" returns district and state-level data.
#'
#' @return Data frame with disciplinary removal data
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Get disciplinary removal data
#' removals <- fetch_disciplinary_removals(2024)
#'
#' # Analyze suspension rates
#' removals %>%
#'   filter(subgroup == "total population") %>%
#'   select(school_name, contains("suspension"), contains("Suspension"))
#' }
fetch_disciplinary_removals <- function(end_year, level = "school") {
  # Use generic extractor
  df <- fetch_spr_data(
    sheet_name = "DisciplinaryRemovalsByStudgroup",
    end_year = end_year,
    level = level
  )

  df
}


# -----------------------------------------------------------------------------
# Days Missed Due to Suspensions
# -----------------------------------------------------------------------------

#' Fetch Days Missed Due to Suspensions
#'
#' Downloads and extracts data on days of school missed due to out-of-school
#' suspensions from the SPR database.
#'
#' @param end_year A school year (2017-2024). Year is the end of the academic
#'   year - eg 2020-21 school year is end_year '2021'.
#' @param level One of "school" or "district". "school" returns school-level
#'   data, "district" returns district and state-level data.
#'
#' @return Data frame with days missed due to suspensions
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Get days missed data
#' days_missed <- fetch_days_missed_suspensions(2024)
#'
#' # Calculate total instructional time lost
#' days_missed %>%
#'   filter(is_school == TRUE) %>%
#'   select(school_name, contains("days"), contains("Days"))
#' }
fetch_days_missed_suspensions <- function(end_year, level = "school") {
  # Use generic extractor
  df <- fetch_spr_data(
    sheet_name = "DaysMissedOSSuspensions",
    end_year = end_year,
    level = level
  )

  df
}


# ==============================================================================
# Analysis & Enrichment Functions
# ==============================================================================

#' Calculate Discipline Rates by Subgroup
#'
#' Calculates discipline rates by subgroup and identifies disproportionality.
#' Compares subgroup rates to the overall population rate to identify
#' disparities in disciplinary actions.
#'
#' @param discipline_data Data frame from \code{\link{fetch_disciplinary_removals}},
#'   \code{\link{fetch_violence_vandalism_hib}}, or similar discipline data frame
#' @param enrollment_data Optional enrollment data frame from \code{\link{fetch_enr}}.
#'   If NULL, enrollment will be fetched automatically. Must be tidy format
#'   (use \code{fetch_enr(end_year, tidy = TRUE)}).
#' @param rate_col Name of the column containing discipline counts.
#'   Defaults to NULL, which will auto-detect the first numeric rate column.
#' @param threshold Disproportionality threshold. Subgroups with rates
#'   threshold times higher than the population average will be flagged.
#'   Defaults to 2.0 (2x the rate).
#'
#' @return Data frame with discipline rates by subgroup including:
#'   \itemize{
#'     \item All original columns from discipline data
#'     \item enrollment_count - Number of enrolled students in subgroup
#'     \item discipline_rate - Disciplinary incidents per 100 students
#'     \item population_rate - Overall population disciplinary rate
#'     \item disparity_ratio - Subgroup rate / population rate
#'     \item is_disproportionate - TRUE if disparity_ratio >= threshold
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Get disciplinary data
#' removals <- fetch_disciplinary_removals(2024)
#'
#' # Calculate disproportionality
#' rates <- calc_discipline_rates_by_subgroup(removals)
#'
#' # Find disproportionately disciplined subgroups
#' rates %>%
#'   filter(is_disproportionate == TRUE) %>%
#'   arrange(desc(disparity_ratio))
#' }
calc_discipline_rates_by_subgroup <- function(discipline_data,
                                               enrollment_data = NULL,
                                               rate_col = NULL,
                                               threshold = 2.0) {
  # Get year from discipline data
  end_year <- discipline_data$end_year[1]

  # Fetch enrollment if not provided
  if (is.null(enrollment_data)) {
    enrollment_data <- fetch_enr(end_year, tidy = TRUE)
  }

  # Filter enrollment to school-level totals
  enr_total <- enrollment_data %>%
    dplyr::filter(!is_subprogram) %>%
    dplyr::filter(grade_level == "TOTAL" | program_code == "55")

  # Create subgroup mapping
  subgroup_map <- c(
    "total population" = "total_enrollment",
    "american indian" = "native_american",
    "black" = "black",
    "hispanic" = "hispanic",
    "asian" = "asian",
    "multiracial" = "multiracial",
    "pacific islander" = "pacific_islander",
    "white" = "white",
    "economically disadvantaged" = "free_reduced_lunch",
    "limited english proficiency" = "lep",
    "students with disability" = NULL
  )

  # Add enrollment subgroup column
  disc_with_enr <- discipline_data %>%
    dplyr::mutate(
      enr_subgroup = subgroup_map[subgroup]
    )

  # Join with enrollment data
  join_keys <- c("end_year", "county_id", "district_id", "school_id")

  result <- disc_with_enr %>%
    dplyr::left_join(
      enr_total %>%
        dplyr::select(
          end_year, county_id, district_id, school_id,
          subgroup, n_students
        ) %>%
        dplyr::rename(enr_subgroup = subgroup, enrollment_count = n_students),
      by = c(join_keys, "enr_subgroup")
    ) %>%
    dplyr::select(-enr_subgroup)

  # Auto-detect rate column if not specified
  if (is.null(rate_col)) {
    # Look for first numeric column that could be a count
    numeric_cols <- names(result)[sapply(result, is.numeric)]
    # Exclude identifier columns and aggregation flags
    possible_cols <- numeric_cols[!grepl("^is_|end_year|county_id|district_id|school_id", numeric_cols)]

    if (length(possible_cols) > 0) {
      rate_col <- possible_cols[1]
    } else {
      stop("Could not auto-detect discipline rate column. Please specify rate_col parameter.")
    }
  }

  # Calculate rates
  result <- result %>%
    dplyr::mutate(
      discipline_rate = (dplyr::across(any_of(rate_col)) / enrollment_count) * 100
    )

  # Get population average rate for each school
  pop_rates <- result %>%
    dplyr::filter(subgroup == "total population", !is.na(enrollment_count)) %>%
    dplyr::select(county_id, district_id, school_id, population_rate = discipline_rate)

  # Join population rates and calculate disparity
  result <- result %>%
    dplyr::left_join(
      pop_rates,
      by = c("county_id", "district_id", "school_id")
    ) %>%
    dplyr::mutate(
      disparity_ratio = ifelse(
        is.na(population_rate) | population_rate == 0,
        NA_real_,
        discipline_rate / population_rate
      ),
      is_disproportionate = disparity_ratio >= threshold & !is.na(disparity_ratio)
    )

  result
}


#' Compare Discipline Across Years
#'
#' Analyzes trends in disciplinary actions across multiple years.
#' Calculates year-over-year changes and identifies schools with
#' significant increases or decreases in disciplinary incidents.
#'
#' @param df_list Named list of data frames from \code{\link{fetch_disciplinary_removals}},
#'   \code{\link{fetch_violence_vandalism_hib}}, or similar for multiple years.
#'   Each element should be named by its end_year (e.g., \code{list("2021" = df_2021, "2022" = df_2022)})
#' @param subgroup_filter Optional subgroup to filter for (e.g., "total population").
#'   If NULL, calculates trends for all subgroups.
#' @param rate_col Name of the column containing discipline counts.
#'   Defaults to NULL, which will auto-detect the first numeric count column.
#' @param significant_change_threshold Percentage change considered significant.
#'   Defaults to 20 (20% change).
#'
#' @return Data frame with trend metrics including:
#'   \itemize{
#'     \item county_id, district_id, school_id, school_name - Location identifiers
#'     \item subgroup - Student subgroup (if subgroup_filter is NULL)
#'     \item n_years - Number of years of data
#'     \item first_year, last_year - Year range
#'     \item count_first, count_last - Incident counts in first/last year
#'     \item count_change - Absolute change in incidents
#'     \item count_pct_change - Percentage change in incidents
#'     \item trend_direction - "increasing", "decreasing", or "stable"
#'     \item is_significant - TRUE if change >= threshold
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Fetch multiple years
#' rem_2022 <- fetch_disciplinary_removals(2022)
#' rem_2023 <- fetch_disciplinary_removals(2023)
#' rem_2024 <- fetch_disciplinary_removals(2024)
#'
#' # Create named list
#' rem_list <- list(
#'   "2022" = rem_2022,
#'   "2023" = rem_2023,
#'   "2024" = rem_2024
#' )
#'
#' # Analyze trends
#' trends <- compare_discipline_across_years(
#'   rem_list,
#'   subgroup_filter = "total population"
#' )
#'
#' # Find schools with significant increases
#' trends %>%
#'   filter(trend_direction == "increasing", is_significant) %>%
#'   arrange(desc(count_pct_change))
#' }
compare_discipline_across_years <- function(df_list,
                                              subgroup_filter = NULL,
                                              rate_col = NULL,
                                              significant_change_threshold = 20) {
  # Validate input
  if (!is.list(df_list)) {
    stop("df_list must be a list of data frames")
  }

  if (length(df_list) < 2) {
    stop("df_list must contain at least 2 data frames")
  }

  # Ensure list is named by year
  if (is.null(names(df_list))) {
    warning("df_list should be named by end_year. Using list order.")
    names(df_list) <- seq_along(df_list)
  }

  # Combine all years into single data frame
  df_combined <- dplyr::bind_rows(df_list, .id = "end_year") %>%
    dplyr::mutate(end_year = as.numeric(end_year))

  # Filter by subgroup if specified
  if (!is.null(subgroup_filter)) {
    df_combined <- df_combined %>%
      dplyr::filter(subgroup == subgroup_filter)
  }

  # Filter for school-level data only
  df_school <- df_combined %>%
    dplyr::filter(is_school == TRUE)

  # Auto-detect count column if not specified
  if (is.null(rate_col)) {
    numeric_cols <- names(df_school)[sapply(df_school, is.numeric)]
    possible_cols <- numeric_cols[!grepl("^is_|end_year|county_id|district_id|school_id", numeric_cols)]

    if (length(possible_cols) > 0) {
      rate_col <- possible_cols[1]
    } else {
      stop("Could not auto-detect count column. Please specify rate_col parameter.")
    }
  }

  # Calculate trend metrics by school
  trends <- df_school %>%
    dplyr::group_by(county_id, district_id, school_id, school_name, subgroup) %>%
    dplyr::arrange(end_year, .by_group = TRUE) %>%
    dplyr::summarize(
      n_years = dplyr::n(),
      first_year = min(end_year),
      last_year = max(end_year),
      count_first = dplyr::first(!!dplyr::sym(rate_col)),
      count_last = dplyr::last(!!dplyr::sym(rate_col)),
      count_avg = mean(!!dplyr::sym(rate_col), na.rm = TRUE),
      count_min = ifelse(
        all(is.na(!!dplyr::sym(rate_col))),
        NA_real_,
        min(!!dplyr::sym(rate_col), na.rm = TRUE)
      ),
      count_max = ifelse(
        all(is.na(!!dplyr::sym(rate_col))),
        NA_real_,
        max(!!dplyr::sym(rate_col), na.rm = TRUE)
      ),
      .groups = "drop"
    ) %>%
    dplyr::mutate(
      count_change = count_last - count_first,
      count_pct_change = ifelse(
        is.na(count_first) | count_first == 0,
        NA_real_,
        (count_change / count_first) * 100
      ),
      trend_direction = dplyr::case_when(
        is.na(count_change) ~ NA_character_,
        abs(count_pct_change) < 5 ~ "stable",
        count_change < 0 ~ "decreasing",
        count_change > 0 ~ "increasing"
      ),
      is_significant = abs(count_pct_change) >= significant_change_threshold
    ) %>%
    # Remove rows where count_min > count_max (all NAs)
    dplyr::filter(is.na(count_min) | count_min <= count_max)

  # Reorder columns for readability
  trends <- trends %>%
    dplyr::select(
      county_id, district_id, school_id, school_name,
      subgroup,
      n_years, first_year, last_year,
      count_first, count_last, count_change, count_pct_change,
      count_avg, count_min, count_max,
      trend_direction, is_significant
    )

  trends
}


# ==============================================================================
# Convenience Aliases
# ==============================================================================

#' @describeIn fetch_violence_vandalism_hib Alias for fetch_violence_vandalism_hib
#' @export
fetch_violence_vandalism <- fetch_violence_vandalism_hib

#' @describeIn fetch_hib_investigations Alias for fetch_hib_investigations
#' @export
fetch_hib <- fetch_hib_investigations
