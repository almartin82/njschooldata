# ==============================================================================
# Enrollment Column Name Mappings
# ==============================================================================
#
# This file contains column name cleaning and mapping functions for enrollment
# data. The NJ DOE has used many different column naming conventions over the
# years, and this file normalizes them to a consistent format.
#
# ==============================================================================

#' Internal helper to map a column name
#'
#' @param df_names Column name to clean
#' @param clean_list Named list mapping old names to new names
#' @return Cleaned column name
#' @keywords internal
clean_name <- function(df_names, clean_list) {
  z <- clean_list[[df_names]]

  if (is.null(z)) {
    message(paste("Unknown column name:", df_names))
    return(df_names)
  }

  return(z)
}

#' Clean enrollment column names
#'
#' Give consistent names to the enrollment files across all years.
#'
#' @param df An enrollment data frame (eg output of `get_raw_enr`)
#' @return Data frame with standardized column names
#' @keywords internal
clean_enr_names <- function(df) {

  # Column name mapping dictionary
  clean <- list(
    # preserve these
    "end_year" = "end_year",
    "program_name" = "program_name",
    "program_code" = "program_code",
    "grade_level" = "grade_level",

    # county ids
    "COUNTY_ID" = "county_id",
    "COUNTY CODE" = "county_id",
    "Co code" = "county_id",
    "COUNTY_CODE" = "county_id",
    "County_ID" = "county_id",
    "County Code" = "county_id",

    # county names
    "COUNTY_NAME" = "county_name",
    "COUNTY NAME" = "county_name",
    "County Name" = "county_name",
    "CO" = "county_name",
    "COUNTY" = "county_name",
    "County_Name" = "county_name",

    # district ids
    "DIST_ID" = "district_id",
    "DISTRICT CODE" = "district_id",
    "District Id" = "district_id",
    "District ID" = "district_id",
    "DISTRICT_ID" = "district_id",
    "Dist_ID" = "district_id",
    "District Code" = "district_id",

    # district names
    "LEA_NAME" = "district_name",
    "DISTRICT NAME" = "district_name",
    "District Name" = "district_name",
    "DISTRICT_NAME" = "district_name",
    "DIST" = "district_name",
    "DISTRICT" = "district_name",
    "District_Name" = "district_name",

    # school ids
    "SCHOOL_ID" = "school_id",
    "SCHOOL CODE" = "school_id",
    "SCH_CODE" = "school_id",
    "School_ID" = "school_id",
    "School Code" = "school_id",

    # school name
    "SCHOOL_NAME" = "school_name",
    "SCHOOL NAME" = "school_name",
    "School Name" = "school_name",
    "SCH" = "school_name",
    "SCHOOL" = "school_name",
    "School_Name" = "school_name",

    # program code
    "PRGCODE" = "program_code",
    "PROGRAM_CODE" = "program_code",
    "PROG" = "program_code",
    "PROG_CODE" = "program_code",

    # program
    "PROGRAM_NAME" = "program_name",
    "PROGRAM" = "program_name",
    "PROG_NAME" = "program_name",

    # grade level
    "GRADE_LEVEL" = "grade_level",
    "Grade_Level" = "grade_level",
    "Grade" = "grade_level",

    # racial categories - white
    "WH_M" = "white_m",
    "WHITE_M" = "white_m",
    "WH_F" = "white_f",
    "WHITE_F" = "white_f",

    # racial categories - black
    "BL_M" = "black_m",
    "BLACK_M" = "black_m",
    "BL_F" = "black_f",
    "BLACK_F" = "black_f",

    # racial categories - hispanic
    "HI_M" = "hispanic_m",
    "HISP_M" = "hispanic_m",
    "HISP_MALE" = "hispanic_m",
    "HI_F" = "hispanic_f",
    "HISP_F" = "hispanic_f",

    # racial categories - asian
    "AS_M" = "asian_m",
    "ASIAN_M(NON_HISP)" = "asian_m",
    "ASIAN_M" = "asian_m",
    "AS_F" = "asian_f",
    "ASIAN_F(NON_HISP)" = "asian_f",
    "ASIAN_F" = "asian_f",

    # racial categories - native american
    "AM_M" = "native_american_m",
    "NAT_AM_M(NON_HISP)" = "native_american_m",
    "NAT_AM_M" = "native_american_m",
    "AM_F" = "native_american_f",
    "NAT_AM_F(NON_HISP)" = "native_american_f",
    "NAT_AM_F" = "native_american_f",

    # racial categories - pacific islander
    "PI_M" = "pacific_islander_m",
    "HAW_NTV_M(NON_HISP)" = "pacific_islander_m",
    "HAW_NTV_M" = "pacific_islander_m",
    "PI_F" = "pacific_islander_f",
    "HAW_NTV_F(NON_HISP)" = "pacific_islander_f",
    "HAW_NTV_F" = "pacific_islander_f",

    # racial categories - multiracial
    "MU_M" = "multiracial_m",
    "2/MORE_RACES_M(NON_HISP)" = "multiracial_m",
    "2/MORE_RACES_M" = "multiracial_m",
    "MU_F" = "multiracial_f",
    "2/MORE_RACES_F(NON_HISP)" = "multiracial_f",
    "2/MORE_RACES_F" = "multiracial_f",

    # 2020+ aggregated racial/gender columns
    "White" = "white",
    "Black" = "black",
    "Hispanic" = "hispanic",
    "Asian" = "asian",
    "Native American" = "native_american",
    "American Indian" = "native_american",
    "Hawaiian Native" = "pacific_islander",
    "Two or More Races" = "multiracial",
    "Male" = "male",
    "Female" = "female",
    "Non-Binary" = "non_binary",

    # lunch status
    "FREE_LUNCH" = "free_lunch",
    "FREE" = "free_lunch",
    "Free_Lunch" = "free_lunch",
    "Free Lunch" = "free_lunch",

    # reduced lunch
    "REDUCED_PRICE_LUNCH" = "reduced_lunch",
    "REDUCED_LUNCH" = "reduced_lunch",
    "RED_LUNCH" = "reduced_lunch",
    "REDUCE" = "reduced_lunch",
    "REDUCED" = "reduced_lunch",
    "Reduced_Price_Lunch" = "reduced_lunch",
    "Reduced Lunch" = "reduced_lunch",

    # LEP/English Learners
    "LEP" = "lep",
    "English_Learners" = "lep",
    "English Learners" = "lep",

    # migrant
    "MIGRANT" = "migrant",
    "MIG" = "migrant",
    "MIGRNT" = "migrant",
    "Migant" = "migrant",
    "Migrant" = "migrant",

    # row totals
    "ROW_TOTAL" = "row_total",
    "ROWTOT" = "row_total",
    "ROWTOTAL" = "row_total",
    "Row_Total" = "row_total",
    "Total Enrollment" = "row_total",

    # other special populations
    "HOMELESS" = "homeless",
    "Homeless" = "homeless",
    "Military" = "military",
    "SPECED" = "special_ed",
    "CHPT1" = "title_1"
  )

  names(df) <- purrr::map_chr(names(df), ~clean_name(.x, clean))

  return(df)
}


#' Enrollment column type specifications
#'
#' @return Named list of column types
#' @keywords internal
get_enr_types <- function() {
  list(
    "county_id" = "character",
    "county_name" = "character",
    "district_id" = "character",
    "district_name" = "character",
    "school_id" = "character",
    "school_name" = "character",
    "program_code" = "character",
    "program_name" = "character",
    "grade_level" = "character",
    "white_m" = "numeric",
    "white_f" = "numeric",
    "black_m" = "numeric",
    "black_f" = "numeric",
    "hispanic_m" = "numeric",
    "hispanic_f" = "numeric",
    "asian_m" = "numeric",
    "asian_f" = "numeric",
    "native_american_m" = "numeric",
    "native_american_f" = "numeric",
    "pacific_islander_m" = "numeric",
    "pacific_islander_f" = "numeric",
    "multiracial_m" = "numeric",
    "multiracial_f" = "numeric",
    "white" = "numeric",
    "black" = "numeric",
    "hispanic" = "numeric",
    "asian" = "numeric",
    "native_american" = "numeric",
    "pacific_islander" = "numeric",
    "multiracial" = "numeric",
    "male" = "numeric",
    "female" = "numeric",
    "non_binary" = "numeric",
    "free_lunch" = "numeric",
    "reduced_lunch" = "numeric",
    "lep" = "numeric",
    "migrant" = "numeric",
    "row_total" = "numeric",
    "homeless" = "numeric",
    "military" = "numeric",
    "special_ed" = "numeric",
    "title_1" = "numeric",
    "end_year" = "numeric"
  )
}


#' Standard enrollment column order
#'
#' @return Character vector of column names in standard order
#' @keywords internal
get_enr_column_order <- function() {
  c(
    "end_year", "CDS_Code",
    "county_id", "county_name",
    "district_id", "district_name",
    "school_id", "school_name",
    "program_code", "program_name",
    "male", "female",
    "white", "black", "hispanic",
    "asian", "native_american", "pacific_islander", "multiracial",
    "white_m", "white_f",
    "black_m", "black_f",
    "hispanic_m", "hispanic_f",
    "asian_m", "asian_f",
    "native_american_m", "native_american_f",
    "pacific_islander_m", "pacific_islander_f",
    "multiracial_m", "multiracial_f",
    "row_total",
    "free_lunch", "reduced_lunch", "lep", "migrant",
    "homeless", "special_ed", "title_1", "grade_level"
  )
}
