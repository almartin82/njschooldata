# ==============================================================================
# Enrollment Data Processing Functions
# ==============================================================================
#
# This file contains functions for processing raw enrollment data into a
# clean, standardized format.
#
# ==============================================================================

#' Split enrollment columns
#'
#' Splits enrollment columns that combine IDs and names (pre 2009-10 format)
#'
#' @param df An enrollment data frame (eg output of `get_raw_enr`)
#' @return Data frame with split columns
#' @keywords internal
split_enr_cols <- function(df) {
  if (unique(df$end_year)[1] <= 2009) {
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

  return(df)
}


#' Clean enrollment data types
#'
#' All columns come back as character; coerce some back to numeric.
#'
#' @param df An enrollment data frame with standardized column names
#' @return Data frame with correct data types
#' @keywords internal
clean_enr_data <- function(df) {

  enr_types <- get_enr_types()

  df <- as.data.frame(df)

  # Some old files (eg 02-03) have random, unlabeled rows. Remove those.
  df <- df[nchar(df$county_name) > 0, ]

  for (i in seq_len(ncol(df))) {
    z <- enr_types[[names(df)[i]]]
    if (!is.null(z) && z == "numeric") {
      df[, i] <- gsub(" ,", "", df[, i], fixed = TRUE)
      df[, i] <- gsub(" ,,", "", df[, i], fixed = TRUE)
      df[, i] <- gsub(",", "", df[, i], fixed = TRUE)
      df[, i] <- as.numeric(df[, i])
    } else if (!is.null(z) && z == "character") {
      df[, i] <- trim_whitespace(as.character(df[, i]))
    }
  }

  # Make sure that various ids are consistent (issue #83)
  df$county_id <- stringr::str_pad(df$county_id, width = 2, side = "left", pad = "0")
  df$district_id <- stringr::str_pad(df$district_id, width = 4, side = "left", pad = "0")
  df$school_id <- stringr::str_pad(df$school_id, width = 3, side = "left", pad = "0")

  # Make CDS_code

  df$CDS_Code <- paste0(df$county_id, df$district_id, df$school_id)

  return(df)
}


#' Tidy up the grade level field on enrollment data
#'
#' @param df An enrollment data file. clean_enr_grade is part of a set
#' of chained cleaning functions that live inside process_enr.
#' @return Data frame with cleaner grade_level column
#' @keywords internal
clean_enr_grade <- function(df) {
  k_codes <- c("KF", "KH")
  pk_codes <- c("PF", "PH")
  df %>%
    dplyr::mutate(
      grade_level = dplyr::case_when(
        grade_level == "Total" ~ "TOTAL",
        grade_level %in% k_codes ~ "K",
        grade_level == "KG" ~ "K",
        grade_level %in% pk_codes ~ "PK",
        is.na(grade_level) & program_code %in% k_codes ~ "K",
        is.na(grade_level) & program_code %in% pk_codes ~ "PK",
        is.na(grade_level) & program_code %in% c(1, 2) ~ "PK",
        is.na(grade_level) & program_code %in% c(3, 4) ~ "K",
        is.na(grade_level) & program_code %in% c("01", "02") ~ "PK",
        is.na(grade_level) & program_code %in% c("03", "04") ~ "K",
        TRUE ~ grade_level
      )
    )
}


#' Join program code to program name
#'
#' Decode the program name using the prog_codes lookup table.
#'
#' @param df Cleaned enrollment file
#' @return Data frame with program_name added
#' @keywords internal
process_enr_program <- function(df) {
  # program name is messy; drop.
  if ("program_name" %in% names(df)) {
    df <- df %>%
      dplyr::select(-program_name)
  }

  # join
  df <- df %>%
    dplyr::left_join(njschooldata::prog_codes, by = c("end_year", "program_code"))

  return(df)
}


#' Calculate enrollment aggregates
#'
#' Aggregates gender columns into racial subgroups (e.g., white_m + white_f = white)
#'
#' @param df Cleaned enrollment dataframe, eg output of `clean_enr_data`
#' @return Data frame with aggregated columns
#' @keywords internal
enr_aggs <- function(df) {

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

  # Helper function to check if columns exist

  sg <- function(cols) {
    cols_exist <- purrr::map_lgl(cols, ~ .x %in% names(df)) %>% all()
    ifelse(cols_exist, paste(cols, collapse = " + "), "NA")
  }

  df_agg <- df %>%
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
    )

  return(df_agg)
}


#' Arrange enrollment file columns
#'
#' Put an enrollment file in the correct column order.
#'
#' @param df Cleaned enrollment file
#' @return Data frame with columns in standard order
#' @keywords internal
arrange_enr <- function(df) {

  clean_names <- get_enr_column_order()

  mask <- clean_names %in% names(df)

  df <- df %>%
    dplyr::ungroup() %>%
    dplyr::select(dplyr::any_of(clean_names[mask]))

  return(df)
}


#' Process a NJ enrollment file
#'
#' Does cleanup of dataframes returned by `get_raw_enr`.
#'
#' @param df An enrollment data frame (eg output of `get_raw_enr`)
#' @return Cleaned and processed enrollment data frame
#' @keywords internal
process_enr <- function(df) {

  # If no grade level
  if (!"grade_level" %in% tolower(names(df)) | df$end_year[1] == "2018") {

    # Something weird w/ 2018 grade levels; proceed as if they aren't there
    if (df$end_year[1] == "2018") df <- dplyr::select(df, -Grade_Level)

    # Clean up program code and name
    prog_map <- list(
      "PRGCODE" = "program_code",
      "PROGRAM_CODE" = "program_code",
      "PROG" = "program_code",
      "PROG_CODE" = "program_code",
      "PROGRAM_NAME" = "program_name_dirty",
      "PROGRAM" = "program_name_dirty",
      "PROG_NAME" = "program_name_dirty"
    )
    names(df) <- purrr::map_chr(
      names(df),
      function(.x) {
        cleaned <- prog_map[[.x]]
        ifelse(is.null(cleaned), .x, cleaned)
      }
    )

    # There isn't a program_code in 2020...
    if (!"program_code" %in% names(df)) {
      convert_from_grade <- data.frame(
        Grade = c(
          "Pre-K Halfday", "Pre-K Fullday",
          "Kindergarten Halfday", "Kindergarten Fullday",
          "First Grade", "Second Grade", "Third Grade", "Fourth Grade",
          "Fifth Grade", "Sixth Grade", "Seventh Grade", "Eighth Grade",
          "Ninth Grade", "Tenth Grade", "Eleventh Grade", "Twelfth Grade",
          "Ungraded", "All Grades"
        ),
        program_code = c(
          "PH", "PF", "KH", "KF", "01", "02", "03", "04", "05",
          "06", "07", "08", "09", "10", "11", "12", "UG", "55"
        ),
        grade_level = c(
          "PK", "PK", "K", "K", "01", "02", "03", "04", "05",
          "06", "07", "08", "09", "10", "11", "12", "UG", "TOTAL"
        ),
        stringsAsFactors = FALSE
      )

      df <- df %>%
        dplyr::left_join(convert_from_grade, by = "Grade") %>%
        dplyr::select(-Grade)
    }

    # Force program character
    df$program_code <- as.character(df$program_code)

    df <- df %>%
      dplyr::left_join(njschooldata::prog_codes, by = c("end_year", "program_code"))

    if ("program_name_dirty" %in% names(df)) df <- df %>% dplyr::select(-program_name_dirty)

    gl_program_df <- tibble::tibble(
      program_name = c(
        "Half-Day Pre-Kindergarten",
        "Half-Day Preschool Disabled",
        "Half-Day Kindergarten",
        "Full-Day Pre-Kindergarten",
        "Full-Day Preschool Disabled",
        "Full-Day Kindergarten",
        "Grade 1", "Grade 2", "Grade 3", "Grade 4",
        "Grade 5", "Grade 6", "Grade 7", "Grade 8",
        "Grade 9", "Grade 10", "Grade 11", "Grade 12",
        "Grade 9 Vocational", "Grade 10 Vocational",
        "Grade 11 Vocational", "Grade 12 Vocational",
        "Total"
      ),
      grade_level = c(
        "PH", "PH", "KH",
        "PF", "PF", "KF",
        "01", "02", "03", "04",
        "05", "06", "07", "08",
        "09", "10", "11", "12",
        "09", "10", "11", "12",
        "TOTAL"
      )
    )

    # Grade level already exists for 2020 onward, no need to enrich
    if (df$end_year[1] < 2020) {
      df <- df %>%
        dplyr::left_join(gl_program_df, by = "program_name")
    }
  }

  # Basic cleaning
  cleaned <- df %>%
    dplyr::select(!dplyr::starts_with("%")) %>%
    clean_enr_names() %>%
    split_enr_cols() %>%
    clean_enr_data() %>%
    clean_enr_grade()

  # Add in gender and racial aggregates
  if (df$end_year[1] < 2020) {
    cleaned_agg <- enr_aggs(cleaned)
  } else {
    cleaned_agg <- cleaned
  }

  # Join to program code
  final <- cleaned_agg %>%
    process_enr_program() %>%
    arrange_enr() %>%
    dplyr::filter(!is.na(county_id))

  return(final)
}
