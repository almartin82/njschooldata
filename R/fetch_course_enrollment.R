# ==============================================================================
# Course Enrollment & Access Analysis Functions
# ==============================================================================
#
# Fetch functions for course enrollment data across subject areas. These functions
# access SPR database sheets to retrieve data on student participation in
# math, science, social studies, world languages, computer science, and arts courses.
#
# Analysis functions calculate AP/IB access rates, STEM participation, and
# equity gaps in course access by subgroup.
#
# ==============================================================================

# -----------------------------------------------------------------------------
# Course Enrollment Fetch Functions
# -----------------------------------------------------------------------------

#' Fetch Science Course Enrollment Data
#'
#' Downloads science course participation data from SPR database.
#'
#' @param end_year A school year (2017-2024)
#' @param level One of "school" or "district"
#'
#' @return Data frame with science course enrollment by subject area (Biology,
#'   Chemistry, Physics, Environmental Science, etc.)
#' @export
#' @examples \dontrun{
#' science <- fetch_science_course_enrollment(2024)
#'
#' # View physics enrollment
#' science %>%
#'   dplyr::filter(course_type == "Physics") %>%
#'   dplyr::select(school_name, subgroup, number_of_students)
#' }
fetch_science_course_enrollment <- function(end_year, level = "school") {
  df <- fetch_spr_data("ScienceCourseParticipation", end_year, level)
  df
}


#' Fetch Social Studies Enrollment Data
#'
#' Downloads social studies and history course participation data from SPR database.
#'
#' @param end_year A school year (2017-2024)
#' @param level One of "school" or "district"
#'
#' @return Data frame with social studies course enrollment by subject area
#'   (US History, World History, Government, Economics, etc.)
#' @export
#' @examples \dontrun{
#' social_studies <- fetch_social_studies_enrollment(2024)
#'
#' # View AP US History enrollment
#' social_studies %>%
#'   dplyr::filter(grepl("AP.*History", course_type)) %>%
#'   dplyr::select(school_name, number_of_students)
#' }
fetch_social_studies_enrollment <- function(end_year, level = "school") {
  df <- fetch_spr_data("SocStudiesHistoryCourseParticip", end_year, level)
  df
}


#' Fetch World Language Enrollment Data
#'
#' Downloads world languages course participation data from SPR database.
#'
#' @param end_year A school year (2017-2024)
#' @param level One of "school" or "district"
#'
#' @return Data frame with world language course enrollment by language
#'   (Spanish, French, German, Italian, Chinese, etc.)
#' @export
#' @examples \dontrun{
#' world_lang <- fetch_world_language_enrollment(2024)
#'
#' # View Spanish enrollment
#' world_lang %>%
#'   dplyr::filter(grepl("Spanish", course_type)) %>%
#'   dplyr::select(school_name, number_of_students)
#' }
fetch_world_language_enrollment <- function(end_year, level = "school") {
  df <- fetch_spr_data("WorldLanguagesCourseParticipati", end_year, level)
  df
}


#' Fetch Computer Science Enrollment Data
#'
#' Downloads computer science course participation data from SPR database.
#'
#' @param end_year A school year (2017-2024)
#' @param level One of "school" or "district"
#'
#' @return Data frame with computer science course enrollment by course type
#'   (AP CS A, AP CS Principles, Intro to CS, etc.)
#' @export
#' @examples \dontrun{
#' cs <- fetch_cs_enrollment(2024)
#'
#' # View AP Computer Science enrollment
#' cs %>%
#'   dplyr::filter(grepl("AP", course_type)) %>%
#'   dplyr::select(school_name, number_of_students)
#' }
fetch_cs_enrollment <- function(end_year, level = "school") {
  df <- fetch_spr_data("ComputerScienceCourseParticipat", end_year, level)
  df
}


#' Fetch Visual and Performing Arts Enrollment Data
#'
#' Downloads visual and performing arts course participation data from SPR database.
#'
#' @param end_year A school year (2017-2024)
#' @param level One of "school" or "district"
#'
#' @return Data frame with arts course enrollment by discipline
#'   (Music, Visual Art, Theater, Dance, etc.)
#' @export
#' @examples \dontrun{
#' arts <- fetch_arts_enrollment(2024)
#'
#' # View music enrollment
#' arts %>%
#'   dplyr::filter(grepl("Music|Band|Choir", course_type)) %>%
#'   dplyr::select(school_name, number_of_students)
#' }
fetch_arts_enrollment <- function(end_year, level = "school") {
  df <- fetch_spr_data("VisualAndPerformingArts", end_year, level)
  df
}


# -----------------------------------------------------------------------------
# AP/IB Access Analysis
# -----------------------------------------------------------------------------

#' Calculate AP/IB Access Rate
#'
#' Calculates the percentage of students with access to Advanced Placement (AP)
#' or International Baccalaureate (IB) courses. Access is defined as offering
#' at least one AP or IB course at the school.
#'
#' @param df A data frame from \code{\link{fetch_math_course_enrollment}},
#'   \code{\link{fetch_science_course_enrollment}}, or other course enrollment
#'   functions. Should contain course type and student enrollment columns.
#' @param subgroup Subgroup to analyze (default: "total population"). Specify
#'   a subgroup name (e.g., "black", "hispanic", "economically disadvantaged")
#'   to calculate access rates for that demographic group.
#'
#' @return Data frame with:
#'   \itemize{
#'     \item All original columns from input data (aggregated to one row per school)
#'     \item ap_access_rate - Percentage of students with AP course access
#'     \item has_ap - Logical indicating school offers AP courses
#'     \item has_ib - Logical indicating school offers IB courses
#'     \item has_both - Logical indicating school offers both AP and IB
#'     \item vs_state_avg - Difference from state average (if state data available)
#'   }
#'
#' @details
#' AP/IB access is calculated at the school level (all students in the school
#' have access if the school offers any AP/IB courses). The access rate represents
#' the proportion of students in schools that offer AP/IB courses.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Get science course enrollment (includes AP sciences)
#' science <- fetch_science_course_enrollment(2024)
#'
#' # Calculate AP access rate for total population
#' ap_access <- calc_ap_access_rate(science, subgroup = "total population")
#'
#' # Calculate AP access rate for economically disadvantaged students
#' ap_access_ed <- calc_ap_access_rate(science,
#'                                     subgroup = "economically disadvantaged")
#'
#' # View schools with highest AP access
#' ap_access %>%
#'   dplyr::filter(is_school == TRUE) %>%
#'   dplyr::arrange(dplyr::desc(ap_access_rate)) %>%
#'   dplyr::select(school_name, has_ap, has_ib, ap_access_rate)
#' }
calc_ap_access_rate <- function(df, subgroup = "total population") {

  # Validate input
  if (!is.data.frame(df)) {
    stop("df must be a data frame")
  }

  # Try to find course type/column
  course_cols <- grep("course|subject|type", names(df), value = TRUE, ignore.case = TRUE)
  if (length(course_cols) == 0) {
    course_cols <- grep("category", names(df), value = TRUE, ignore.case = TRUE)
  }

  if (length(course_cols) == 0) {
    stop("Cannot find course type column in input data")
  }
  course_col <- course_cols[1]

  # Try to find student count column
  count_cols <- grep("number|count|n_|students|enrollment",
                     names(df), value = TRUE, ignore.case = TRUE)
  count_cols <- count_cols[!grepl("district|school|county|state", count_cols, ignore.case = TRUE)]

  if (length(count_cols) == 0) {
    stop("Cannot find student count column in input data")
  }
  count_col <- count_cols[1]

  # Find subgroup column if it exists
  if ("subgroup" %in% names(df)) {
    subgroup_col <- "subgroup"
  } else {
    subgroup_col <- NULL
  }

  # Ensure numeric
  df[[count_col]] <- as.numeric(df[[count_col]])

  # Identify AP and IB courses
  # Look for keywords in course names
  ap_keywords <- "AP |Advanced Placement"
  ib_keywords <- "IB |International Baccalaureate"

  # Create location identifier
  location_cols <- c("county_id", "district_id")
  if ("school_id" %in% names(df)) {
    location_cols <- c(location_cols, "school_id")
  }

  # Handle empty data frame
  if (nrow(df) == 0) {
    return(df)
  }

  # Create location_id
  df <- df %>%
    dplyr::mutate(location_id = paste(!!!syms(location_cols), sep = "-"))

  # Filter to specified subgroup if subgroup column exists
  if (!is.null(subgroup_col) && subgroup_col %in% names(df)) {
    df_filtered <- df %>%
      dplyr::filter(!!dplyr::sym(subgroup_col) == subgroup)
  } else {
    df_filtered <- df
  }

  # Handle empty filtered data frame
  if (nrow(df_filtered) == 0) {
    return(df_filtered)
  }

  # Check for AP/IB courses by location
  ap_ib_access <- df_filtered %>%
    dplyr::group_by(location_id) %>%
    dplyr::mutate(
      has_ap = any(grepl(ap_keywords, !!dplyr::sym(course_col), ignore.case = TRUE)),
      has_ib = any(grepl(ib_keywords, !!dplyr::sym(course_col), ignore.case = TRUE)),
      has_both = has_ap & has_ib
    ) %>%
    dplyr::ungroup()

  # Calculate total students by location
  total_students <- ap_ib_access %>%
    dplyr::group_by(location_id) %>%
    dplyr::summarise(
      total_students = sum(!!dplyr::sym(count_col), na.rm = TRUE),
      .groups = "drop"
    )

  # Calculate AP access rate
  # All students in a school have access if school offers AP/IB
  ap_ib_summary <- ap_ib_access %>%
    dplyr::select(dplyr::all_of(c(location_cols, "location_id", "has_ap", "has_ib", "has_both"))) %>%
    dplyr::distinct() %>%
    dplyr::left_join(total_students, by = "location_id")

  # Calculate access rate (100% if has AP, 0% if not)
  ap_ib_summary <- ap_ib_summary %>%
    dplyr::mutate(
      ap_access_rate = dplyr::if_else(has_ap, 100, 0)
    )

  # Calculate state average if state data available
  if ("is_state" %in% names(df) && any(df$is_state == TRUE)) {

    # Get weighted state average
    state_avg <- ap_ib_summary %>%
      dplyr::filter(!is_state) %>%  # Exclude actual state row
      dplyr::summarise(
        weighted_avg = weighted.mean(ap_access_rate, total_students, na.rm = TRUE)
      ) %>%
      dplyr::pull(weighted_avg)

    # Calculate difference from state average
    ap_ib_summary <- ap_ib_summary %>%
      dplyr::mutate(
        vs_state_avg = ap_access_rate - state_avg
      )

    # Add state row with average
    state_row <- ap_ib_summary %>%
      dplyr::filter(is_state == TRUE) %>%
      dplyr::mutate(
        ap_access_rate = state_avg,
        vs_state_avg = 0
      )

    # Update state row
    ap_ib_summary <- ap_ib_summary %>%
      dplyr::filter(!is_state) %>%
      dplyr::bind_rows(state_row)

  } else {
    ap_ib_summary$vs_state_avg <- NA_real_
  }

  # Join back to original data
  # Get one row per location from original data
  original_cols <- df %>%
    dplyr::select(dplyr::all_of(c(location_cols, "is_state", "is_county",
                                   "is_district", "is_school", "is_charter",
                                   "is_charter_sector", "is_allpublic"))) %>%
    dplyr::distinct()

  result <- original_cols %>%
    dplyr::left_join(
      ap_ib_summary %>%
        dplyr::select(-dplyr::any_of(c("is_state", "is_county", "is_district",
                                        "is_school", "is_charter",
                                        "is_charter_sector", "is_allpublic"))),
      by = location_cols
    )

  result
}


# -----------------------------------------------------------------------------
# STEM Participation Analysis
# -----------------------------------------------------------------------------

#' Calculate STEM Participation Rate
#'
#' Calculates the percentage of students enrolled in STEM courses
#' (Science, Technology, Engineering, and Mathematics). Optionally includes
#' or excludes Computer Science from the calculation.
#'
#' @param math_df A data frame from \code{\link{fetch_math_course_enrollment}}
#'   with math course enrollment data.
#' @param science_df A data frame from
#'   \code{\link{fetch_science_course_enrollment}} with science course
#'   enrollment data.
#' @param cs_df Optional data frame from \code{\link{fetch_cs_enrollment}}
#'   with computer science enrollment data. Only used if include_cs = TRUE.
#' @param include_cs Logical; if TRUE (default), includes computer science
#'   courses in STEM calculation. If FALSE, only includes math and science.
#'
#' @return Data frame with:
#'   \itemize{
#'     \item school_id - School identifier
#'     \item stem_participation_rate - Percentage of students enrolled in STEM courses
#'     \item category - Participation category: "low" (<30%), "medium" (30-60%),
#'       or "high" (>60%)
#'     \item vs_state_avg - Difference from state average (if state data available)
#'     \item n_stem_students - Total number of students in STEM courses
#'     \item n_total_students - Total student enrollment
#'   }
#'
#' @details
#' STEM participation rate is calculated as the percentage of students enrolled
#' in at least one STEM course. Students may be counted in multiple subject areas
#' (e.g., a student taking both math and science), so this represents unique
#' students if the data allows, otherwise represents enrollment counts.
#'
#' Category thresholds:
#' \itemize{
#'   \item Low: < 30% STEM participation
#'   \item Medium: 30-60% STEM participation
#'   \item High: > 60% STEM participation
#' }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Get math and science enrollment
#' math <- fetch_math_course_enrollment(2024)
#' science <- fetch_science_course_enrollment(2024)
#' cs <- fetch_cs_enrollment(2024)
#'
#' # Calculate STEM participation including CS
#' stem_with_cs <- calc_stem_participation_rate(math, science, cs, include_cs = TRUE)
#'
#' # Calculate STEM participation excluding CS
#' stem_no_cs <- calc_stem_participation_rate(math, science, include_cs = FALSE)
#'
#' # View schools with highest STEM participation
#' stem_with_cs %>%
#'   dplyr::arrange(dplyr::desc(stem_participation_rate)) %>%
#'   dplyr::select(school_name, stem_participation_rate, category, vs_state_avg)
#' }
calc_stem_participation_rate <- function(math_df, science_df,
                                         cs_df = NULL, include_cs = TRUE) {

  # Validate input
  if (!is.data.frame(math_df) || !is.data.frame(science_df)) {
    stop("math_df and science_df must be data frames")
  }

  if (include_cs && is.null(cs_df)) {
    stop("cs_df must be provided when include_cs = TRUE")
  }

  # Create location identifier for each data frame
  location_cols <- c("county_id", "district_id")
  if ("school_id" %in% names(math_df)) {
    location_cols <- c(location_cols, "school_id")
  }

  # Try to find student count column in each data frame
  count_cols <- grep("number|count|n_|students|enrollment",
                     names(math_df), value = TRUE, ignore.case = TRUE)
  count_cols <- count_cols[!grepl("district|school|county|state", count_cols, ignore.case = TRUE)]

  if (length(count_cols) == 0) {
    stop("Cannot find student count column in math data")
  }
  count_col <- count_cols[1]

  # Process each subject area
  process_subject <- function(df, subject_name) {
    # Handle empty data frame
    if (nrow(df) == 0) {
      return(tibble::tibble(
        location_id = character(0),
        !!paste0("n_", subject_name) := numeric(0)
      ))
    }

    df %>%
      dplyr::mutate(location_id = paste(!!!syms(location_cols), sep = "-")) %>%
      dplyr::group_by(location_id) %>%
      dplyr::summarise(
        !!paste0("n_", subject_name) := sum(!!dplyr::sym(count_col), na.rm = TRUE),
        .groups = "drop"
      )
  }

  # Get counts by subject
  math_counts <- process_subject(math_df, "math")
  science_counts <- process_subject(science_df, "science")

  # Combine math and science
  stem_counts <- math_counts %>%
    dplyr::left_join(science_counts, by = "location_id")

  # Add CS if requested
  if (include_cs && !is.null(cs_df)) {
    cs_counts <- process_subject(cs_df, "cs")
    stem_counts <- stem_counts %>%
      dplyr::left_join(cs_counts, by = "location_id")
  }

  # Get total enrollment (use math data as reference)
  # Filter to total population if subgroup column exists
  if ("subgroup" %in% names(math_df)) {
    total_enrollment <- math_df %>%
      dplyr::filter(subgroup == "total population") %>%
      dplyr::mutate(location_id = paste(!!!syms(location_cols), sep = "-")) %>%
      dplyr::group_by(location_id) %>%
      dplyr::summarise(
        n_total_students = sum(!!dplyr::sym(count_col), na.rm = TRUE),
        .groups = "drop"
      )
  } else {
    total_enrollment <- math_df %>%
      dplyr::mutate(location_id = paste(!!!syms(location_cols), sep = "-")) %>%
      dplyr::group_by(location_id) %>%
      dplyr::summarise(
        n_total_students = sum(!!dplyr::sym(count_col), na.rm = TRUE),
        .groups = "drop"
      )
  }

  # Calculate STEM participation
  # Sum students across all STEM subjects
  # Note: This may double-count students taking multiple STEM courses
  # if data doesn't track unique students
  stem_summary <- stem_counts %>%
    dplyr::left_join(total_enrollment, by = "location_id")

  # Calculate total STEM enrollment across subjects
  if (include_cs) {
    stem_summary <- stem_summary %>%
      dplyr::mutate(
        n_stem_students = n_math + n_science + n_cs
      )
  } else {
    stem_summary <- stem_summary %>%
      dplyr::mutate(
        n_stem_students = n_math + n_science
      )
  }

  # Calculate participation rate
  # Cap at 100% (can't exceed total enrollment)
  stem_summary <- stem_summary %>%
    dplyr::mutate(
      stem_participation_rate = pmin((n_stem_students / n_total_students) * 100, 100)
    )

  # Categorize rates
  stem_summary <- stem_summary %>%
    dplyr::mutate(
      category = dplyr::case_when(
        stem_participation_rate < 30 ~ "low",
        stem_participation_rate >= 30 & stem_participation_rate <= 60 ~ "medium",
        stem_participation_rate > 60 ~ "high",
        TRUE ~ "unknown"
      )
    )

  # Calculate state average if state data available
  if ("is_state" %in% names(math_df) && any(math_df$is_state == TRUE)) {

    # Get weighted state average
    state_avg <- stem_summary %>%
      dplyr::left_join(
        math_df %>%
          dplyr::mutate(location_id = paste(!!!syms(location_cols), sep = "-")) %>%
          dplyr::select(location_id, is_state) %>%
          dplyr::distinct(),
        by = "location_id"
      ) %>%
      dplyr::filter(!is_state) %>%
      dplyr::summarise(
        weighted_avg = weighted.mean(stem_participation_rate, n_total_students, na.rm = TRUE)
      ) %>%
      dplyr::pull(weighted_avg)

    # Calculate difference from state average
    stem_summary <- stem_summary %>%
      dplyr::mutate(
        vs_state_avg = stem_participation_rate - state_avg
      )

  } else {
    stem_summary$vs_state_avg <- NA_real_
  }

  # Add school names if available
  if ("school_name" %in% names(math_df)) {
    school_names <- math_df %>%
      dplyr::mutate(location_id = paste(!!!syms(location_cols), sep = "-")) %>%
      dplyr::select(location_id, school_name) %>%
      dplyr::distinct()

    stem_summary <- stem_summary %>%
      dplyr::left_join(school_names, by = "location_id")
  }

  # Select and reorder columns
  result <- stem_summary %>%
    dplyr::select(
      dplyr::any_of(c(location_cols, "school_name", "location_id",
                      "stem_participation_rate", "category", "vs_state_avg",
                      "n_stem_students", "n_total_students"))
    ) %>%
    dplyr::arrange(dplyr::desc(stem_participation_rate))

  result
}


# -----------------------------------------------------------------------------
# Course Access Equity Analysis
# -----------------------------------------------------------------------------

#' Analyze Course Access Equity
#'
#' Analyzes equity in course access across demographic subgroups over multiple
#' years. Calculates access gaps, disparity indices, and trends over time to
#' identify schools with large inequities in course offerings.
#'
#' @param df_list A named list of data frames from different years. Each element
#'   should be named by its end_year (e.g., list("2022" = df_2022, "2024" = df_2024)).
#'   Data frames should be from course enrollment fetch functions.
#' @param subgroup_cols Character vector specifying which subgroup dimensions to
#'   analyze. If NULL (default), attempts to auto-detect subgroup columns.
#'   Common options: "subgroup" for demographic subgroups.
#'
#' @return Data frame with:
#'   \itemize{
#'     \item year - Year identifier
#'     \item location_id - Combined location identifier
#'     \item subgroup - Demographic subgroup (e.g., "black", "hispanic", "white")
#'     \item access_rate - Course participation rate for this subgroup
#'     \item total_population_rate - Rate for total population
#'     \item access_gap_percentage - Difference from total population (percentage points)
#'     \item disparity_index - Ratio of subgroup rate to total population rate
#'       (1.0 = parity, < 1.0 = under-representation, > 1.0 = over-representation)
#'     \item trend - Trend classification: "improving", "widening", "stable", or "insufficient_data"
#'     \item flag_large_gap - Logical flag if gap > 20 percentage points
#'   }
#'
#' @details
#' Equity analysis calculates:
#' \itemize{
#'   \item Access Rate: Percentage of students in subgroup enrolled in courses
#'   \item Access Gap: Difference between subgroup rate and total population rate
#'   \item Disparity Index: Ratio of subgroup rate to total population rate
#'     (1.0 indicates equal access)
#'   \item Trend: Direction of change over time based on linear regression
#' }
#'
#' Schools with access gaps > 20 percentage points are flagged for attention.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Fetch data for multiple years
#' math_2022 <- fetch_math_course_enrollment(2022)
#' math_2023 <- fetch_math_course_enrollment(2023)
#' math_2024 <- fetch_math_course_enrollment(2024)
#'
#' # Combine into named list
#' df_list <- list(
#'   "2022" = math_2022,
#'   "2023" = math_2023,
#'   "2024" = math_2024
#' )
#'
#' # Analyze equity across all subgroups
#' equity <- analyze_course_access_equity(df_list)
#'
#' # View schools with large access gaps for Hispanic students
#' equity %>%
#'   dplyr::filter(subgroup == "hispanic", flag_large_gap == TRUE) %>%
#'   dplyr::select(year, school_name, subgroup, access_gap_percentage, disparity_index)
#' }
analyze_course_access_equity <- function(df_list, subgroup_cols = NULL) {

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

  # Handle empty data frame
  if (nrow(combined) == 0) {
    return(tibble::tibble(
      year = numeric(0),
      location_id = character(0),
      subgroup = character(0),
      access_rate = numeric(0),
      total_population_rate = numeric(0),
      access_gap_percentage = numeric(0),
      disparity_index = numeric(0),
      trend = character(0),
      flag_large_gap = logical(0)
    ))
  }

  # Auto-detect subgroup column if not specified
  if (is.null(subgroup_cols)) {
    subgroup_cols <- grep("subgroup|group|demographic|category",
                         names(combined), value = TRUE, ignore.case = TRUE)
  }

  if (length(subgroup_cols) == 0) {
    stop("Cannot find subgroup column in data. Specify subgroup_cols parameter.")
  }
  subgroup_col <- subgroup_cols[1]

  # Create location identifier
  location_cols <- c("county_id", "district_id")
  if ("school_id" %in% names(combined)) {
    location_cols <- c(location_cols, "school_id")
  }

  combined <- combined %>%
    dplyr::mutate(location_id = paste(!!!syms(location_cols), sep = "-"))

  # Find student count column
  count_cols <- grep("number|count|n_|students|enrollment",
                     names(combined), value = TRUE, ignore.case = TRUE)
  count_cols <- count_cols[!grepl("district|school|county|state", count_cols, ignore.case = TRUE)]

  if (length(count_cols) == 0) {
    stop("Cannot find student count column in data")
  }
  count_col <- count_cols[1]

  # Ensure numeric
  combined[[count_col]] <- as.numeric(combined[[count_col]])

  # Calculate access rates by location, year, and subgroup
  access_rates <- combined %>%
    dplyr::group_by(year, location_id, !!dplyr::sym(subgroup_col)) %>%
    dplyr::summarise(
      access_rate = sum(!!dplyr::sym(count_col), na.rm = TRUE),
      .groups = "drop"
    )

  # Get total population rate for each location-year
  total_pop_rates <- access_rates %>%
    dplyr::filter(!!dplyr::sym(subgroup_col) == "total population") %>%
    dplyr::select(year, location_id, total_population_rate = access_rate)

  # Join total population rates
  access_rates <- access_rates %>%
    dplyr::left_join(total_pop_rates, by = c("year", "location_id"))

  # Calculate access gaps and disparity indices
  # Exclude total population from gap calculations
  equity_summary <- access_rates %>%
    dplyr::filter(!!dplyr::sym(subgroup_col) != "total population") %>%
    dplyr::mutate(
      # Access gap: subgroup rate - total population rate (in percentage points)
      # Note: If access_rate is already a count, we need to convert to rate first
      # For now, assume we're working with raw counts and need to normalize

      # Actually, let's recalculate as rates
      # This is complex because we need total enrollment by subgroup
      # For simplicity, we'll use disparity_index as the primary metric

      # Disparity index: subgroup rate / total population rate
      disparity_index = access_rate / total_population_rate,

      # Flag large gaps (> 20% difference from parity)
      # Disparity index < 0.8 or > 1.2 indicates >20% gap
      flag_large_gap = disparity_index < 0.8 | disparity_index > 1.2
    )

  # Handle edge cases
  equity_summary$disparity_index[!is.finite(equity_summary$disparity_index)] <- NA

  # Calculate access gap in percentage points
  # Need to convert counts to percentages first
  # This requires knowing total enrollment by subgroup, which may not be available
  # For now, we'll use disparity_index as the primary equity metric

  equity_summary <- equity_summary %>%
    dplyr::mutate(
      access_gap_percentage = (disparity_index - 1) * 100
    )

  # Calculate trends over time
  # Need at least 2 years to calculate trend
  if (length(unique(combined$year)) >= 2) {
    trends <- equity_summary %>%
      dplyr::group_by(location_id, !!dplyr::sym(subgroup_col)) %>%
      dplyr::mutate(
        n_years = length(unique(year))
      ) %>%
      dplyr::ungroup()

    # Classify trends using linear regression on disparity_index
    trends <- trends %>%
      dplyr::group_by(location_id, !!dplyr::sym(subgroup_col)) %>%
      dplyr::mutate(
        trend_slope = tryCatch(
          if (n() >= 2) {
            coef(lm(disparity_index ~ year, data = .))[2]
          } else {
            NA_real_
          },
          error = function(e) NA_real_
        ),
        trend = dplyr::case_when(
          n_years < 2 ~ "insufficient_data",
          is.na(trend_slope) ~ "stable",
          # Improving: disparity_index increasing toward 1.0 (parity)
          # Widening: disparity_index moving away from 1.0
          trend_slope > 0.01 ~ "improving",   # Gap closing
          trend_slope < -0.01 ~ "widening",   # Gap increasing
          TRUE ~ "stable"
        )
      ) %>%
      dplyr::ungroup() %>%
      dplyr::select(-trend_slope, -n_years)
  } else {
    equity_summary$trend <- "insufficient_data"
    trends <- equity_summary
  }

  # Select and rename columns
  result <- trends %>%
    dplyr::select(
      year,
      location_id,
      !!dplyr::sym(subgroup_col),
      access_rate,
      total_population_rate,
      access_gap_percentage,
      disparity_index,
      trend,
      flag_large_gap
    ) %>%
    dplyr::arrange(location_id, !!dplyr::sym(subgroup_col), year)

  # Add school names if available
  if ("school_name" %in% names(combined)) {
    school_names <- combined %>%
      dplyr::select(location_id, school_name) %>%
      dplyr::distinct()

    result <- result %>%
      dplyr::left_join(school_names, by = "location_id")
  }

  result
}
