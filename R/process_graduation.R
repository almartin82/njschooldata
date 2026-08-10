# ==============================================================================
# Graduation Data Processing Functions
# ==============================================================================
#
# This file contains functions for processing raw graduation data into a
# clean, standardized format.
#
# ==============================================================================

#' Process graduation rate data
#'
#' Does cleanup of the grad rate ('grate') file.
#'
#' @param df The output of get_raw_grad_file
#' @param end_year A school year. Year is the end of the academic year - eg 2006-07
#' school year is year '2007'. Valid values are 1998-2024.
#' @return Cleaned graduation data frame
#' @keywords internal
process_grate <- function(df, end_year) {
  # Clean up names
  names(df)[names(df) %in% c("COUNTY", "CO", "CO NAME", "CO_NAME", "County Name", "COUNTY_NAME")] <- "county_name"
  names(df)[names(df) %in% c("DISTRICT", "DIST", "DIST NAME", "DIS_NAME", "District Name", "DISTRICT_NAME")] <- "district_name"
  names(df)[names(df) %in% c("SCHOOL", "SCH", "SCH NAME", "SCH_NAME", "School Name", "SCHOOL_NAME")] <- "school_name"

  # In 1998 and 1999 PROG_CODE is program code. In 2008 PROG_CODE is...
  # actually PROG_NAME.
  if (end_year == 2008) {
    names(df)[names(df) %in% c("PROG_CODE")] <- "program_name"
  } else {
    names(df)[names(df) %in% c("PROG CODE", "PROG_CODE")] <- "program_code"
  }
  names(df)[names(df) %in% c("PROGNAME", "PROG", "PROG NAME")] <- "program_name"

  names(df)[names(df) %in% c("COUNTY_CODE", "CO CODE", "County", "County Code", "COUNTY_ID", "Co Code")] <- "county_id"
  names(df)[names(df) %in% c("DISTRICT_CODE", "DIST CODE", "District", "District Code", "DISTRICT_ID", "Dist Code")] <- "district_id"
  names(df)[names(df) %in% c("SCHOOL_CODE", "SCH CODE", "School", "School Code", "SCHOOL_CODE")] <- "school_id"

  # Errata
  names(df)[names(df) %in% c("HISP_MALE")] <- "hispanic_m"
  names(df)[names(df) %in% c("NAT_AM-F", "NAT_F", "NAT_AM_F(NON_HISP)")] <- "native_american_f"
  names(df)[names(df) %in% c("NAT_M", "NAT_AM_M(NON_HISP)")] <- "native_american_m"

  # 2007 errata
  names(df)[names(df) %in% c("ROWTOT")] <- "rowtotal"
  names(df)[names(df) %in% c("WH_M")] <- "white_m"
  names(df)[names(df) %in% c("WH_F")] <- "white_f"
  names(df)[names(df) %in% c("BL_M")] <- "black_m"
  names(df)[names(df) %in% c("BL_F")] <- "black_f"
  names(df)[names(df) %in% c("HISP_M", "HISPANIC_M")] <- "hispanic_m"
  names(df)[names(df) %in% c("HISP_F", "HISPANIC_F")] <- "hispanic_f"
  names(df)[names(df) %in% c("NAT_AM_M")] <- "native_american_m"
  names(df)[names(df) %in% c("NAT_AM_F")] <- "native_american_f"
  names(df)[names(df) %in% c("ASIAN_M(NON_HISP)")] <- "asian_m"
  names(df)[names(df) %in% c("ASIAN_F(NON_HISP)")] <- "asian_f"
  names(df)[names(df) %in% c("HAW_NTV_M(NON_HISP)", "HWN_NAT_M")] <- "pacific_islander_m"
  names(df)[names(df) %in% c("HAW_NTV_F(NON_HISP)", "HWN_NAT_F")] <- "pacific_islander_f"
  names(df)[names(df) %in% c("2/MORE_RACES_M(NON_HISP)", "2_MORE_M")] <- "multiracial_m"
  names(df)[names(df) %in% c("2/MORE_RACES_F(NON_HISP)", "2_MORE_F")] <- "multiracial_f"

  names(df)[names(df) %in% c("SUBGROUP", "Subgroup", "Student Group")] <- "group"
  names(df)[names(df) %in% c(
    "Four Year Graduation Rate",
    "2011 Adjusted Cohort Grad Rate",
    "2012 Adjusted Cohort Grad Rate",
    "FOUR_YR_GRAD_RATE",
    "Graduation Rate",
    # 2024-25 (Cohort2025) renamed the rate column
    "Adjusted Cohort Graduation Rate"
  )] <- "grad_rate"
  # 2021+ files use "Cohort Count" and "Graduated" instead of full names;
  # 2024-25 (Cohort2025) renamed "Cohort Count" -> "Adjusted Cohort Count"
  names(df)[names(df) %in% c("Four Year Adjusted Cohort Count", "FOUR_YR_ADJ_COHORT_COUNT", "Cohort Count", "Adjusted Cohort Count")] <- "cohort_count"
  names(df)[names(df) %in% c("Four Year Graduates Count", "GRADUATED_COUNT", "Graduated")] <- "graduated_count"

  names(df) <- names(df) %>% tolower()

  numeric_cols <- c(
    "rowtotal", "female", "male",
    "white", "black", "hispanic", "native_american",
    "asian", "pacific_islander", "multiracial",
    "white_m", "white_f", "black_m", "black_f",
    "hispanic_m", "hispanic_f", "native_american_m", "native_american_F",
    "asian_m", "asian_f", "pacific_islander_m", "pacific_islander_f",
    "multiracial_m", "multiracial_f",
    "instate", "outstate",
    "grad_rate", "cohort_count", "graduated_count"
  )

  for (i in numeric_cols) {
    if (i %in% names(df)) {
      df <- df %>%
        dplyr::mutate(
          {{ i }} := as.numeric(
            dplyr::if_else(
              # Match suppressed data indicators: *, N, -, <, > (e.g., "<10%", ">90%")
              stringr::str_detect(.data[[i]], "\\*|N|-|<|>"),
              NA_character_,
              .data[[i]]
            )
          )
        )
    }
  }

  # County, district, school codes
  if (end_year <= 2008) {
    # county_id and county_name
    int_matrix <- stringr::str_split_fixed(df$county_name, "-", 2)
    df$county_id <- int_matrix[, 1]
    df$county_name <- int_matrix[, 2]

    # district_id and district_name
    int_matrix <- stringr::str_split_fixed(df$district_name, "-", 2)
    df$district_id <- int_matrix[, 1]
    df$district_name <- int_matrix[, 2]

    # school_id and school_name
    int_matrix <- stringr::str_split_fixed(df$school_name, "-", 2)
    df$school_id <- int_matrix[, 1]
    df$school_name <- int_matrix[, 2]
  }

  # Missing program names
  if (end_year %in% c(1998, 1999)) {
    old_codes <- data.frame(
      program_code = c("1", "2", "3", "4", "5", "6", "7", "8", "9"),
      program_name = c(
        "4 Year College", "2 Year College", "Other College", "Post-Secondary",
        "Employment", "Unemployment", "Other", "Status Unknown", "Total"
      ),
      stringsAsFactors = FALSE
    )
    df$program_code <- df$program_code %>% as.character()
    df <- df %>% dplyr::left_join(old_codes, by = "program_code")
  }

  # Clean up values
  if ("program_name" %in% names(df)) {
    df$program_name <- ifelse(df$program_name %in% c("Total", "TOTAL"), "Total", df$program_name)
  }

  df <- df %>%
    dplyr::mutate(
      # ID-SOURCE: NJDOE graduation files, SCHOOL_CODE / "SCH CODE" / "School
      #   Code" field. "999" is NJDOE's own published district-total / statewide
      #   school code, printed with its own label in every vintage checked:
      #   legacy STAT_GRD.CSV grd06 and grd09 publish "999-STATE TOTAL" on the
      #   statewide row; grd10 grd.xls publishes SCH CODE "999" with SCH NAME
      #   "DISTRICT TOTAL"/"STATE TOTAL" (2,365 rows); ACGR2012_gradrate.xls
      #   publishes School "999" / SCH_NAME "DISTRICT TOTAL" on district rows and
      #   "STATE TOTAL" on the statewide row; SCHOOL_CODE "999" is present in
      #   every ACGR / Cohort file 2012-2025.
      # The 2019 arm harmonizes a published code onto another published code
      #   rather than inventing one: the 2019 file (ACGR2019_Cohort2019...xlsx)
      #   publishes School Code "888" labelled "District" on 4,650 rows and
      #   "999" labelled "State" on 15, so 2019 alone names the district total
      #   "888" where 2011-2018 name it "999". Both codes are NJDOE's; both are
      #   accepted by is_district in fetch_graduation.R, and is_state keys on
      #   district_id/county_id, not school_id, so the statewide row is
      #   unaffected by the remap.
      school_id = dplyr::case_when(
        school_id == "999.000000" ~ "999",
        school_id == "888" & end_year == 2019 ~ "999",
        TRUE ~ school_id
      )
    )

  # Both lines strip a float-formatted id back to NJDOE's own published code.
  # The district line previously mapped "9999.000000" to "999" -- the statewide
  # SCHOOL code, copied down from the school_id case_when above -- which drops a
  # digit off the statewide DISTRICT code and makes the row fail
  # is_state (district_id == "9999" & county_id == "99", R/entity_flags.R).
  # ID-SOURCE: NJDOE graduation files, DISTRICT_ID / "DIST CODE" field. The
  #   statewide row is county 99 / district 9999 / school 999 in every vintage
  #   checked: legacy STAT_GRD.CSV grd06 and grd09 (10 rows each, published as
  #   "99-NEW JERSEY","9999-NEW JERSEY","999-STATE TOTAL"); grd10 grd.xls
  #   (CO CODE 99 / DIST CODE 9999 / SCH CODE 999, 10 rows); and the ACGR /
  #   Cohort series 2011-2025 (ACGR2012_gradrate.xls carries a single
  #   County 99 "STATE" / District 9999 "STATE TOTAL" / School 999 row; the
  #   modern files carry 11-17 statewide rows each).
  # LIMITATION: no currently reachable source year emits the dotted
  #   "9999.000000" form -- every 2011-2025 file parses district_id as text
  #   ("9999"), so this normalization is inert today. It is kept because the
  #   package still registers pre-2011 raw graduation years, whose float-
  #   formatted vintage is what the literal was written for.
  df$district_id <- ifelse(df$district_id == "9999.000000", "9999", df$district_id)

  if ("grad_rate" %in% names(df)) {
    if (all(df$grad_rate <= 1 | is.na(df$grad_rate))) {
      df$grad_rate <- df$grad_rate * 100
    }
    df$grad_rate <- df$grad_rate / 100 %>% round(2)
  }

  return(df)
}


#' Process Grad Count Data
#'
#' Creates composite subgroups like black (black_m + black_f).
#'
#' @param df Output of get_grad_count
#' @param end_year End of the academic year
#' @return Data frame with composite subgroups
#' @keywords internal
process_grad_count <- function(df, end_year) {

  if (end_year <= 2010) {
    sg <- function(cols) {
      cols_exist <- purrr::map_lgl(cols, ~ .x %in% names(df)) %>% all()
      ifelse(cols_exist, paste(cols, collapse = " + "), "NA")
    }

    possible_m <- c(
      "white_m", "black_m", "hispanic_m",
      "asian_m", "native_american_m", "pacific_islander_m", "multiracial_m"
    )
    valid_m <- possible_m[possible_m %in% names(df)]
    valid_m <- paste(valid_m, collapse = "+")

    possible_f <- c(
      "white_f", "black_f", "hispanic_f",
      "asian_f", "native_american_f", "pacific_islander_f", "multiracial_f"
    )
    valid_f <- possible_f[possible_f %in% names(df)]
    valid_f <- paste(valid_f, collapse = "+")

    out <- df %>%
      dplyr::group_by(
        end_year,
        county_id, county_name,
        district_id, district_name,
        school_id, school_name
      ) %>%
      dplyr::filter(program_name == "Total") %>%
      dplyr::mutate(
        male = !!rlang::parse_expr(valid_m),
        female = !!rlang::parse_expr(valid_f),

        white = !!rlang::parse_expr(sg(c("white_m", "white_f"))),
        black = !!rlang::parse_expr(sg(c("black_m", "black_f"))),
        hispanic = !!rlang::parse_expr(sg(c("hispanic_m", "hispanic_f"))),
        asian = !!rlang::parse_expr(sg(c("asian_m", "asian_f"))),
        native_american = !!rlang::parse_expr(sg(c("native_american_m", "native_american_f"))),
        pacific_islander = !!rlang::parse_expr(sg(c("pacific_islander_m", "pacific_islander_f"))),
        multiracial = !!rlang::parse_expr(sg(c("multiracial_m", "multiracial_f")))
      ) %>%
      dplyr::rename(row_total = rowtotal)

    if ("instate" %in% names(out)) out <- out %>% dplyr::select(-instate)
    if ("outstate" %in% names(out)) out <- out %>% dplyr::select(-outstate)
  } else {
    out <- df
  }

  out
}


#' Process Grad Rate
#'
#' Custom processing for grad rate data beyond generic process_grate.
#'
#' For 5-year methodology, the raw files contain both 4-year and 5-year
#' columns. This function ensures \code{grad_rate} contains the rate
#' matching the requested methodology, and preserves the other rate
#' as \code{four_yr_grad_rate} or \code{five_yr_grad_rate}.
#'
#' @param df Output of get_grad_rate (already passed through process_grate)
#' @param end_year Ending academic year
#' @param methodology One of c('4 year', '5 year')
#' @return Data frame with normalized grad rate variables
#' @keywords internal
process_grad_rate <- function(df, end_year, methodology) {

  if (methodology == "5 year") {
    # The 5-year files contain both 4yr and 5yr columns.
    # process_grate() already mapped "Four Year Graduation Rate" -> grad_rate.
    # We need to find the 5-year column and swap it in.

    five_yr_names <- c(
      "five_year_graduation_rate", "five_yr_grad_rate",
      "5_year_graduation_rate", "five_year_adjusted_cohort_graduation_rate",
      "x5_year_graduation_rate"
    )

    five_yr_col <- intersect(tolower(names(df)), five_yr_names)

    if (length(five_yr_col) > 0) {
      five_yr_col <- five_yr_col[1]

      # Preserve the 4-year rate that process_grate put in grad_rate
      df$four_yr_grad_rate <- df$grad_rate

      # Move the 5-year rate into grad_rate
      df$grad_rate <- as.numeric(
        dplyr::if_else(
          stringr::str_detect(as.character(df[[five_yr_col]]), "\\*|N|-|<|>"),
          NA_character_,
          as.character(df[[five_yr_col]])
        )
      )

      # Normalize scale: if values are > 1, they're percentages
      if (all(df$grad_rate <= 1 | is.na(df$grad_rate))) {
        df$grad_rate <- df$grad_rate * 100
      }
      df$grad_rate <- df$grad_rate / 100 %>% round(2)

      # Drop the raw 5yr column now that it's in grad_rate
      df[[five_yr_col]] <- NULL

    } else {
      # No separate 5yr column found — grad_rate may already be the 5yr rate
      # (some file formats put the 5yr rate in the main "Graduation Rate" column)
      # Preserve as-is but add an empty four_yr_grad_rate for consistency
      if (!"four_yr_grad_rate" %in% names(df)) {
        df$four_yr_grad_rate <- NA_real_
      }
    }
  } else if (methodology == "4 year") {
    # Check if there's a 5yr column in 4yr files (shouldn't be, but handle it)
    five_yr_names <- c(
      "five_year_graduation_rate", "five_yr_grad_rate",
      "5_year_graduation_rate", "five_year_adjusted_cohort_graduation_rate",
      "x5_year_graduation_rate"
    )
    five_yr_col <- intersect(tolower(names(df)), five_yr_names)
    if (length(five_yr_col) > 0) {
      # Preserve 5yr rate as bonus column
      df$five_yr_grad_rate <- as.numeric(
        dplyr::if_else(
          stringr::str_detect(as.character(df[[five_yr_col[1]]]), "\\*|N|-|<|>"),
          NA_character_,
          as.character(df[[five_yr_col[1]]])
        )
      )
      if (all(df$five_yr_grad_rate <= 1 | is.na(df$five_yr_grad_rate))) {
        df$five_yr_grad_rate <- df$five_yr_grad_rate * 100
      }
      df$five_yr_grad_rate <- df$five_yr_grad_rate / 100 %>% round(2)
      df[[five_yr_col[1]]] <- NULL
    }
  }

  df
}


#' Grad file group cleanup
#'
#' Standardizes subgroup names across years.
#'
#' @param group Column of group (subgroup) data from NJ grad file
#' @return Column with cleaned up subgroup names
#' @keywords internal
grad_file_group_cleanup <- function(group) {
  dplyr::case_when(
    group %in% c("american indian or alaska native", "american_indian") ~ "american indian",
    group %in% c("black or african american") ~ "black",
    # 2024-25 (Cohort2025) renamed "Hispanic" -> "Hispanic/Latino"
    group %in% c("hispanic/latino", "hispanic_latino") ~ "hispanic",
    group %in% c(
      "economically_disadvantaged",
      "economically disadvantaged students"
    ) ~ "economically disadvantaged",
    group %in% c("english learners", "limited_english_proficiency") ~ "limited english proficiency",
    group %in% c("two or more race", "two_or_more_races", "two or more races") ~ "multiracial",
    group %in% c("native hawaiian or pacific islander", "pacific_islander", "native_hawaiian") ~ "pacific islander",
    group %in% c("asian, native hawaiian, or pacific islander") ~ "asian",
    group %in% c("students with disabilities", "students_with_disability") ~ "students with disabilities",
    # 2024-25 (Cohort2025) renamed the total row "Total" -> "All Students";
    # map to "total" to stay consistent with prior-year files
    group %in% c("all students", "all_students") ~ "total",
    group %in% c(
      "districtwide", "schoolwide",
      "statewide total", "statewide_total", "statewide",
      "total_population"
    ) ~ "total population",
    TRUE ~ group
  )
}
