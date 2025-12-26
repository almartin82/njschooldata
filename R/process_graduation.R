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
    "Graduation Rate"
  )] <- "grad_rate"
  names(df)[names(df) %in% c("Four Year Adjusted Cohort Count", "FOUR_YR_ADJ_COHORT_COUNT")] <- "cohort_count"
  names(df)[names(df) %in% c("Four Year Graduates Count", "GRADUATED_COUNT")] <- "graduated_count"

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
              stringr::str_detect(.data[[i]], "\\*|N|-"),
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
      school_id = dplyr::case_when(
        school_id == "999.000000" ~ "999",
        school_id == "888" & end_year == 2019 ~ "999",
        TRUE ~ school_id
      )
    )

  df$district_id <- ifelse(df$district_id == "9999.000000", "999", df$district_id)

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
#' @param df Output of get_grad_rate
#' @param end_year Ending academic year
#' @param methodology One of c('4 year', '5 year')
#' @return Data frame with normalized grad rate variables
#' @keywords internal
process_grad_rate <- function(df, end_year, methodology) {
  # Just a stub for now
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
    group %in% c(
      "economically_disadvantaged",
      "economically disadvantaged students"
    ) ~ "economically disadvantaged",
    group %in% c("english learners", "limited_english_proficiency") ~ "limited english proficiency",
    group %in% c("two or more race", "two_or_more_races", "two or more races") ~ "multiracial",
    group %in% c("native hawaiian or pacific islander", "pacific_islander", "native_hawaiian") ~ "pacific islander",
    group %in% c("asian, native hawaiian, or pacific islander") ~ "asian",
    group %in% c("students with disabilities", "students_with_disability") ~ "students with disability",
    group %in% c(
      "districtwide", "schoolwide",
      "statewide total", "statewide_total", "statewide",
      "total_population"
    ) ~ "total population",
    TRUE ~ group
  )
}
