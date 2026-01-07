# ==============================================================================
# Graduation Data Tidying Functions
# ==============================================================================
#
# This file contains functions for transforming graduation data from wide
# format to long (tidy) format.
#
# ==============================================================================

#' Clean graduation rate names
#'
#' Standardizes subgroup names in graduation data.
#'
#' @param name_vector Vector of subgroup names
#' @return Vector of cleaned subgroup names
#' @keywords internal
clean_grate_names <- function(name_vector) {
  name_vector <- ifelse(name_vector == "American Indian", "american_indian", name_vector)
  name_vector <- ifelse(name_vector == "Native Hawaiian", "pacific_islander", name_vector)
  name_vector <- ifelse(name_vector == "Two or More Races", "multiracial", name_vector)
  name_vector <- ifelse(name_vector == "Limited English Proficiency", "lep", name_vector)
  name_vector <- ifelse(
    name_vector == "Economically Disadvantaged", "economically_disadvantaged", name_vector
  )
  name_vector <- ifelse(name_vector == "Students with Disability", "iep", name_vector)
  name_vector <- ifelse(name_vector == "Schoolwide", "total population", name_vector)
  name_vector <- ifelse(name_vector == "Districtwide", "total population", name_vector)
  name_vector <- ifelse(name_vector == "Statewide Total", "total population", name_vector)

  name_vector
}


#' Tidy grad rate
#'
#' Tidies a processed grate data frame, producing a data frame with consistent
#' headers and values, suitable for longitudinal analysis.
#'
#' @param df The output of process_grad_rate
#' @param end_year A school year. Year is the end of the academic year - eg 2006-07
#' school year is year '2007'. Valid values are 1998-2024.
#' @param methodology One of '4 year' or '5 year'
#' @return Tidied graduation rate data frame
#' @keywords internal
tidy_grad_rate <- function(df, end_year, methodology = "4 year") {

  grate_col <- function(col_name, nj_df) {
    nj_df <- nj_df %>% as.data.frame(stringsAsFactors = FALSE)

    mask <- grepl(col_name, names(nj_df))
    if (sum(mask) > 1) stop("tidying grate data matched more than one column")

    if (all(mask == FALSE)) {
      out <- rep(NA, nrow(nj_df))
    } else {
      out <- nj_df[, mask, drop = TRUE]
    }
    return(out)
  }


  tidy_old_format <- function(sch_subset) {

    # Constants
    constant_df <- data.frame(
      county_id = grate_col("county_id", sch_subset) %>% unique(),
      county_name = grate_col("county_name", sch_subset) %>% unique(),

      district_id = grate_col("district_id", sch_subset) %>% unique(),
      district_name = grate_col("district_name", sch_subset) %>% unique(),

      school_id = grate_col("school_id", sch_subset) %>% unique(),
      school_name = grate_col("school_name", sch_subset) %>% unique(),

      grad_cohort = grate_col("grad_cohort", sch_subset) %>% unique(),
      year_reported = grate_col("year_reported", sch_subset) %>% unique(),
      methodology = grate_col("methodology", sch_subset) %>% unique(),
      time_window = grate_col("time_window", sch_subset) %>% unique(),

      stringsAsFactors = FALSE
    )

    # Build composites
    sch_subset$white <- sch_subset %$% magrittr::add(white_m, white_f)
    sch_subset$black <- sch_subset %$% magrittr::add(black_m, black_f)
    sch_subset$hispanic <- sch_subset %$% magrittr::add(hisp_m, hisp_f)
    sch_subset$american_indian <- sch_subset %$% magrittr::add(nat_am_m, nat_am_f)
    sch_subset$asian <- sch_subset %$% magrittr::add(asian_m, asian_f)

    # Force NA for some subgroups if not present
    sch_subset$hwn_nat_m <- grate_col("hwn_nat_m", sch_subset)
    sch_subset$hwn_nat_f <- grate_col("hwn_nat_f", sch_subset)
    sch_subset$pacific_islander <- sch_subset %$% magrittr::add(hwn_nat_m, hwn_nat_f)

    sch_subset$multiracial_m <- grate_col("multiracial_m", sch_subset)
    sch_subset$multiracial_f <- grate_col("multiracial_f", sch_subset)
    sch_subset$multiracial <- sch_subset %$% magrittr::add(multiracial_m, multiracial_f)

    sch_subset$female <- rowSums(
      cbind(
        sch_subset$white_f, sch_subset$black_f, sch_subset$hisp_f,
        sch_subset$nat_am_f, sch_subset$asian_f, sch_subset$hwn_nat_f,
        sch_subset$multiracial_f
      ),
      na.rm = TRUE
    )
    sch_subset$male <- rowSums(
      cbind(
        sch_subset$white_m, sch_subset$black_m, sch_subset$hisp_m,
        sch_subset$nat_am_m, sch_subset$asian_m, sch_subset$hwn_nat_m,
        sch_subset$multiracial_m
      ),
      na.rm = TRUE
    )

    # Force code if missing
    sch_subset$program_code <- grate_col("program_code", sch_subset)

    # rowtotal is actually total population
    names(sch_subset)[names(sch_subset) == "rowtotal"] <- "total_population"

    to_tidy <- c(
      "program_name", "program_code",
      "total_population",
      "female", "male",
      "white", "black", "hispanic", "american_indian",
      "asian", "pacific_islander", "multiracial",
      "white_m", "white_f",
      "black_m", "black_f",
      "hisp_m", "hisp_f",
      "nat_am_m", "nat_am_f",
      "asian_m", "asian_f",
      "hwn_nat_m", "hwn_nat_f",
      "multiracial_m", "multiracial_f",
      "instate", "outstate"
    )
    col_mask <- names(sch_subset) %in% to_tidy
    row_mask <- sch_subset$program_name == "Total"

    sch_to_tidy <- sch_subset[, col_mask]
    # Reorder
    sch_to_tidy <- sch_to_tidy[to_tidy]

    sch_programs <- sch_to_tidy[!row_mask, ]
    sch_total <- sch_to_tidy[row_mask, ]
    # Sometimes (thanks MCVS HEALTH OCCUP CENT) there is no TOTAL field
    if (nrow(sch_total) == 0) {
      message("no TOTAL row for: ", constant_df$district_name, " ", constant_df$school_name)
      sch_total <- colSums(sch_programs[, 3:26]) %>%
        t() %>%
        as.data.frame(stringsAsFactors = FALSE)
      sch_total$program_name <- "Total"
      sch_total$program_code <- NA
      sch_total$instate <- NA
      sch_total$outstate <- NA
      # Reorder
      sch_total <- sch_total[to_tidy]
      sch_to_tidy <- rbind(sch_to_tidy, sch_total)
    }

    old_tidy_list <- list()

    # All the subgroups
    for (j in to_tidy[3:26]) {
      to_pivot <- sch_to_tidy[, c(to_tidy[1:2], j)]
      sub_long <- reshape2::melt(to_pivot, id.vars = c("program_name", "program_code"))
      sub_long$variable <- as.character(sub_long$variable)
      names(sub_long)[names(sub_long) == "variable"] <- "group"
      names(sub_long)[names(sub_long) == "value"] <- "outcome_count"

      sub_long$num_grad <- sub_long[sub_long$program_name == "Total", "outcome_count"]
      sub_long$postgrad_grad <- ifelse(sub_long$program_name == "Total", "grad", "postgrad")
      sub_long$level <- ifelse(constant_df$school_id == "999", "D", "S")
      sub_long$grad_rate <- NA
      sub_long$cohort_count <- NA

      old_tidy_list[[j]] <- cbind(constant_df, sub_long)
    }

    out <- dplyr::bind_rows(old_tidy_list)

    return(out)
  }


  tidy_new_format <- function(df) {
    names(df)[names(df) %in% c(
      "2012 5 -year adj cohort grad rate",
      "cohort 2015 5 year graduation rate",
      "cohort 2016 5 year graduation rate",
      "class of 2017 5-year graduation rate",
      "cohort 2018 5-year graduation rate",
      "cohort 2019 5-year graduation rate"
    )] <- "grad_rate"

    if (is.character(df$grad_rate)) {
      df <- df %>%
        dplyr::mutate(
          grad_rate = as.numeric(
            dplyr::if_else(
              # Match suppressed data indicators: *, N, -, <, > (e.g., "<10%", ">90%")
              stringr::str_detect(grad_rate, "\\*|N|-|<|>"),
              NA_character_,
              grad_rate
            )
          ),
          grad_rate = grad_rate / 100
        )
    }

    if (!"cohort_count" %in% names(df)) {
      df$cohort_count <- NA_integer_
    }
    if (!"program_name" %in% names(df)) {
      df$program_name <- "Total"
      df$program_code <- NA
      df$outcome_count <- NA
      df$postgrad_grad <- "grad"
    }

    if (!"graduated_count" %in% names(df)) {
      df$graduated_count <- NA
    }

    if (!"group" %in% names(df)) {
      df$group <- "total population"
    }
    df$group <- tolower(df$group)

    return(df)
  }

  # Old method (pre-cohort)
  if (end_year < 2011) {
    # Iterate over the sch/district totals
    df$iter_key <- paste0(df$county_id, "@", df$district_id, "@", df$school_id)
    sch_list <- list()

    for (i in df$iter_key %>% unique()) {
      this_sch <- df %>% dplyr::filter(iter_key == i)
      sch_list[[i]] <- tidy_old_format(this_sch)
    }

    out <- dplyr::bind_rows(sch_list)
    # Cohort 2011-2012 didn't report subgroups method (different file structure)
    # Cohort 2020 lacks cohort_count and graduated_count columns
  } else if (end_year %in% c(2011, 2012, 2020)) {
    out <- tidy_new_format(df)
    # 2013 shifted to long format
  } else if (end_year > 2012) {
    # 5 year doesn't have group
    if (methodology == "5 year") {
      df <- tidy_new_format(df)
    }
    df$group <- tolower(df$group)
    df$group <- clean_grate_names(df$group)
    out <- df
  }

  # 2018, 2019, 2020 silly row
  out <- out %>% dplyr::filter(!county_id == "end of worksheet")

  out$group <- grad_file_group_cleanup(out$group)
  out <- out %>%
    dplyr::rename(subgroup = group)

  return(out)
}


#' Tidy Grad Count
#'
#' Transforms graduation count data to long format.
#'
#' @param df Output of process_grad_count
#' @param end_year End of the academic year - eg 2006-07 is 2007.
#' Valid values are 1998-present.
#' @return data.frame with number of graduates
#' @keywords internal
tidy_grad_count <- function(df, end_year) {

  if (end_year <= 2010) {
    # invariant cols
    invariants <- c(
      "end_year",
      "county_id", "county_name",
      "district_id", "district_name",
      "school_id", "school_name"
    )

    # cols to tidy
    to_tidy <- c(
      "male", "female",
      "white", "black", "hispanic",
      "asian", "native_american", "pacific_islander", "multiracial",
      "white_m", "white_f",
      "black_m", "black_f",
      "hispanic_m", "hispanic_f",
      "asian_m", "asian_f",
      "native_american_m", "native_american_f",
      "pacific_islander_m", "pacific_islander_f",
      "multiracial_m", "multiracial_f"
    )

    # limit to cols in df
    to_tidy <- to_tidy[to_tidy %in% names(df)]

    # iterate over cols to tidy, do calculations
    tidy_subgroups <- purrr::map_df(
      to_tidy,
      function(.x) {
        df %>%
          dplyr::rename(n_students = .x) %>%
          dplyr::select(dplyr::one_of(invariants, "n_students", "row_total")) %>%
          dplyr::mutate(
            subgroup = .x,
            pct = n_students / row_total
          ) %>%
          dplyr::select(dplyr::one_of(invariants, "subgroup", "n_students", "pct"))
      }
    )

    # also extract row total as a "subgroup"
    tidy_total_enr <- df %>%
      dplyr::select(dplyr::one_of(invariants, "row_total")) %>%
      dplyr::mutate(
        n_students = row_total,
        subgroup = dplyr::case_when(
          school_id == "999" ~ "statewide_total",
          school_id == "997" ~ "districtwide",
          TRUE ~ "schoolwide"
        ),
        pct = n_students / row_total
      ) %>%
      dplyr::select(dplyr::one_of(invariants, "subgroup", "n_students", "pct"))

    # put it all together in a long data frame
    out <- dplyr::bind_rows(tidy_subgroups, tidy_total_enr) %>%
      dplyr::rename(graduated_count = n_students)
  } else if (end_year == 2011) {
    out <- df %>% dplyr::mutate(subgroup = "total population")
  } else if (end_year >= 2012) {
    df$group <- grad_file_group_cleanup(tolower(df$group))

    out <- df %>%
      dplyr::mutate(group = gsub(" ", "_", tolower(group))) %>%
      dplyr::rename(subgroup = group)
  }

  # 2018 silly row
  out <- out %>% dplyr::filter(!county_id == "end of worksheet")

  out$subgroup <- grad_file_group_cleanup(out$subgroup)

  return(out)
}
