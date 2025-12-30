# ==============================================================================
# Assessment Data Processing Functions
# ==============================================================================
#
# This file contains functions for processing raw assessment data (PARCC,
# NJSLA, NJASK, HSPA, GEPA) into clean, standardized formats.
#
# ==============================================================================

# -----------------------------------------------------------------------------
# Legacy Assessment Processing (NJASK, HSPA, GEPA)
# -----------------------------------------------------------------------------

#' Process a NJ assessment file
#'
#' Does cleanup of the raw assessment file, primarily ensuring that
#' columns tagged as 'one implied' are displayed correctly.
#'
#' @param df A raw NJASK, HSPA, or GEPA data frame (eg output of `get_raw_njask`)
#' @param layout Which layout file to use to determine which columns are one implied
#' decimal.
#' @return Processed assessment data frame
#' @keywords internal
process_nj_assess <- function(df, layout) {
  # Build a mask
  mask <- layout$comments == "One implied decimal"

  # Make sure df is data frame (not dplyr data frame) so that normal subsetting
  df <- as.data.frame(df)

  # Get name of last column and kill \n characters
  last_col <- names(df)[ncol(df)]
  df[, last_col] <- gsub("\n", "", df[, last_col], fixed = TRUE)

  # Put some columns aside
  ignore <- df[, !mask]

  implied_decimal_fix <- function(x) {
    # Strip out anything that's not a number.
    x <- as.numeric(gsub("[^\\d]+", "", x, perl = TRUE))
    x / 10
  }

  # Process the columns that have an implied decimal
  processed <- df[, mask] %>%
    dplyr::mutate(dplyr::across(dplyr::everything(), implied_decimal_fix))

  # Put back together
  final <- cbind(ignore, processed)

  # Grade should be numeric
  if (c("Grade", "Grade_Level") %in% names(final) %>% any()) {
    grade_mask <- grepl("(Grade|Grade_Level)", names(final))
    names(final)[grade_mask] <- "Grade"
    final$Grade <- as.integer(final$Grade)

    # Also change in the original
    grade_orig <- grepl("(Grade|Grade_Level)", names(df))
    names(df)[grade_orig] <- "Grade"
  }

  # Reorder and return
  final %>%
    dplyr::select(dplyr::one_of(names(df)))
}


# -----------------------------------------------------------------------------
# PARCC/NJSLA Processing
# -----------------------------------------------------------------------------

#' PARCC column order
#'
#' Puts PARCC dataframe columns in coherent order.
#'
#' @param df Tidied PARCC dataframe. Called as final step in fetch_parcc when tidy=TRUE.
#' @return PARCC df with columns in coherent order
#' @keywords internal
parcc_column_order <- function(df) {
  df %>%
    dplyr::select(
      testing_year,
      assess_name,
      test_name,
      grade,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      dplyr::contains("dfg"),
      subgroup, subgroup_type,
      number_enrolled, number_not_tested,
      number_of_valid_scale_scores,
      scale_score_mean,
      pct_l1, pct_l2, pct_l3, pct_l4, pct_l5, proficient_above,
      num_l1, num_l2, num_l3, num_l4, num_l5,
      is_state, is_dfg,
      is_district, is_school, is_charter,
      is_charter_sector,
      is_allpublic
    )
}


#' Process a raw PARCC data file
#'
#' All the logic needed to clean up the raw PARCC files.
#'
#' @param parcc_file Output of get_raw_parcc
#' @param end_year A school year. end_year is the end of the academic year - eg 2014-15
#' school year is end_year 2015. Valid values are 2015-2024.
#' @param grade Integer or character specifying grade level
#' @param subj PARCC subject. c('ela', 'math', or 'science')
#' @return A tbl_df / data frame
#' @keywords internal
process_parcc <- function(parcc_file, end_year, grade, subj) {

  subj <- tolower(subj)

  # Different assessment types have different performance levels:
  # - NJGPA: 2 levels (L1-L2) - pass/fail for graduation

  # - Science: 4 levels (L1-L4)
  # - ELA/Math: 5 levels (L1-L5)
  is_science <- subj == "science"
  is_njgpa <- grade == "GP"

  if (is_njgpa) {
    # NJGPA has only 2 performance levels (L1=not proficient, L2=proficient)
    # Column structure similar to Science (no DFG)
    parcc_name_vector <- c(
      "county_code", "county_name",
      "district_code", "district_name",
      "school_code", "school_name",
      "subgroup", "subgroup_type",
      "number_enrolled", "number_not_tested", "number_of_valid_scale_scores",
      "scale_score_mean", "pct_l1", "pct_l2"
    )
    names(parcc_file) <- parcc_name_vector
  } else if (is_science) {
    # Science files have different column structure
    parcc_name_vector <- c(
      "county_code", "county_name",
      "district_code", "district_name",
      "school_code", "school_name",
      "subgroup", "subgroup_type",
      "number_enrolled", "number_not_tested", "number_of_valid_scale_scores",
      "scale_score_mean", "pct_l1", "pct_l2", "pct_l3", "pct_l4"
    )
    names(parcc_file) <- parcc_name_vector
  } else {
    parcc_name_vector <- c(
      "county_code", "county_name",
      "district_code", "district_name",
      "school_code", "school_name",
      "dfg",
      "subgroup_type", "subgroup",
      "number_enrolled", "number_not_tested", "number_of_valid_scale_scores",
      "scale_score_mean", "pct_l1", "pct_l2", "pct_l3",
      "pct_l4", "pct_l5"
    )

    # NJSLA (2019+) dropped DFG column
    if (end_year >= 2019) {
      names(parcc_file) <- parcc_name_vector[c(1:6, 8:18)]
    } else {
      names(parcc_file) <- parcc_name_vector
    }
  }

  # Make some numeric
  parcc_file$number_enrolled <- as.numeric(parcc_file$number_enrolled)
  parcc_file$number_not_tested <- as.numeric(parcc_file$number_not_tested)
  parcc_file$number_of_valid_scale_scores <- as.numeric(parcc_file$number_of_valid_scale_scores)
  parcc_file$pct_l1 <- as.numeric(parcc_file$pct_l1)
  parcc_file$pct_l2 <- as.numeric(parcc_file$pct_l2)
  parcc_file$scale_score_mean <- as.numeric(parcc_file$scale_score_mean)

  # Handle pct_l3, pct_l4, pct_l5 based on assessment type
  # NJGPA: only L1-L2, Science: L1-L4, ELA/Math: L1-L5
  if (is_njgpa) {
    parcc_file$pct_l3 <- NA_real_
    parcc_file$pct_l4 <- NA_real_
    parcc_file$pct_l5 <- NA_real_
  } else if (is_science) {
    parcc_file$pct_l3 <- as.numeric(parcc_file$pct_l3)
    parcc_file$pct_l4 <- as.numeric(parcc_file$pct_l4)
    parcc_file$pct_l5 <- NA_real_
  } else {
    parcc_file$pct_l3 <- as.numeric(parcc_file$pct_l3)
    parcc_file$pct_l4 <- as.numeric(parcc_file$pct_l4)
    parcc_file$pct_l5 <- as.numeric(parcc_file$pct_l5)
  }

  # New columns
  parcc_file$testing_year <- end_year
  # Set assess_name based on assessment type
  if (is_njgpa) {
    parcc_file$assess_name <- "NJGPA"
  } else {
    parcc_file$assess_name <- ifelse(end_year >= 2019, "NJSLA", "PARCC")
  }
  parcc_file$grade <- as.character(grade)
  parcc_file$test_name <- subj

  # Calculate proficient_above
  # For NJGPA: L2 (L2 = proficient, only 2 levels)
  # For Science: L3 + L4 (proficient = L3, advanced = L4)
  # For ELA/Math: L4 + L5 (proficient = L4, advanced = L5)
  if (is_njgpa) {
    parcc_file <- parcc_file %>%
      dplyr::rowwise() %>%
      dplyr::mutate(
        proficient_above = ifelse(
          is.finite(pct_l2),
          pct_l2,
          NA_real_
        )
      )
  } else if (is_science) {
    parcc_file <- parcc_file %>%
      dplyr::rowwise() %>%
      dplyr::mutate(
        proficient_above = ifelse(
          is.finite(pct_l3),
          sum(pct_l3, pct_l4, na.rm = TRUE),
          NA_real_
        )
      )
  } else {
    parcc_file <- parcc_file %>%
      dplyr::rowwise() %>%
      dplyr::mutate(
        proficient_above = ifelse(
          is.finite(pct_l4),
          sum(pct_l4, pct_l5, na.rm = TRUE),
          NA_real_
        )
      )
  }

  # Remove random NA row that has the year and grade only
  parcc_file <- parcc_file %>% dplyr::filter(!is.na(county_code))

  # Remove footer/garbage rows (Excel footnotes that got included as data)
  parcc_file <- parcc_file %>%
    dplyr::filter(
      !grepl("suppressed|end of worksheet", county_code, ignore.case = TRUE)
    )

  # Tag subsets (case-insensitive for state since 2015 uses "STATE", 2019+ uses "State")
  parcc_file$is_state <- toupper(parcc_file$county_code) == "STATE"
  parcc_file$is_dfg <- toupper(parcc_file$county_code) == "DFG"
  parcc_file$is_district <- is.na(parcc_file$school_code) & !is.na(parcc_file$district_code)
  parcc_file$is_school <- !is.na(parcc_file$school_code)
  parcc_file$is_charter <- parcc_file$county_code == "80"

  parcc_file$is_charter_sector <- FALSE
  parcc_file$is_allpublic <- FALSE

  # Normalize state-level records to use standard codes
  # NJ DOE uses "STATE"/"State" but package convention is county_id="99"
  parcc_file <- parcc_file %>%
    dplyr::mutate(
      county_code = ifelse(is_state, "99", county_code),
      district_code = ifelse(is_state, "9999", district_code),
      school_code = ifelse(is_state, "999", school_code)
    )

  # Use district_id, etc
  parcc_file <- parcc_file %>%
    dplyr::rename(
      county_id = county_code,
      district_id = district_code,
      school_id = school_code
    )

  # Level counts
  parcc_file <- parcc_perf_level_counts(parcc_file)

  # Column order
  parcc_column_order(parcc_file)
}


#' Tidy PARCC subgroup names
#'
#' Standardizes subgroup names across years.
#'
#' @param sv Subgroup column from PARCC data file
#' @return Character vector with consistent subgroup names
#' @export
tidy_parcc_subgroup <- function(sv) {

  # 2018 is all proper case
  sv <- toupper(sv)

  sv <- gsub("ALL STUDENTS", "total_population", sv, fixed = TRUE)

  sv <- gsub("WHITE", "white", sv, fixed = TRUE)
  sv <- gsub("AFRICAN AMERICAN", "black", sv, fixed = TRUE)
  sv <- gsub("ASIAN", "asian", sv, fixed = TRUE)
  sv <- gsub("HISPANIC", "hispanic", sv, fixed = TRUE)
  sv <- gsub(
    "NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER|NATIVE HAWAIIAN", "pacific_islander",
    sv, fixed = FALSE
  )
  sv <- gsub("AMERICAN INDIAN", "american_indian", sv, fixed = TRUE)
  sv <- gsub("OTHER", "other", sv, fixed = TRUE)

  sv <- gsub("FEMALE", "female", sv, fixed = TRUE)
  sv <- gsub("MALE", "male", sv, fixed = TRUE)

  sv <- gsub(
    "STUDENTS WITH DISABLITIES|STUDENTS WITH DISABILITIES", "special_education",
    sv, fixed = FALSE
  )
  sv <- gsub("SE ACCOMMODATION", "sped_accomodations", sv, fixed = TRUE)

  sv <- gsub("ECONOMICALLY DISADVANTAGED", "ed", sv, fixed = TRUE)
  sv <- gsub(
    "NON ECON. DISADVANTAGED|NON-ECON. DISADVANTAGED", "non_ed", sv, fixed = FALSE
  )

  sv <- gsub("ENGLISH LANGUAGE LEARNERS", "lep_current_former", sv, fixed = TRUE)
  sv <- gsub("CURRENT - ELL", "lep_current", sv, fixed = TRUE)
  sv <- gsub("FORMER - ELL", "lep_former", sv, fixed = TRUE)

  sv <- gsub("GRADE - other", "grade_other", sv, fixed = TRUE)
  sv <- gsub("GRADE - 06", "grade_06", sv, fixed = TRUE)
  sv <- gsub("GRADE - 07", "grade_07", sv, fixed = TRUE)
  sv <- gsub("GRADE - 08", "grade_08", sv, fixed = TRUE)
  sv <- gsub("GRADE - 09", "grade_09", sv, fixed = TRUE)
  sv <- gsub("GRADE - 10", "grade_10", sv, fixed = TRUE)
  sv <- gsub("GRADE - 11", "grade_11", sv, fixed = TRUE)
  sv <- gsub("GRADE - 12", "grade_12", sv, fixed = TRUE)

  sv
}
