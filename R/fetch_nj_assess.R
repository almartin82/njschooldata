#' @title determine if a end_year/grade pairing can be downloaded from the state website
#' 
#' @description
#' \code{valid_call} returns a boolean value indicating if a given end_year/grade pairing is
#' valid for assessment data
#' @inheritParams fetch_njask
#' @keywords internal
valid_call <- function(end_year, grade) {
  #data for 2015 school year doesn't exist yet
  #common core transition started in 2015 (njask is no more)
  if(end_year > 2014) {
    valid_call <- FALSE
  #assessment coverage 3:8 from 2006 on.
  #NJASK fully implemented in 2008
  } else if(end_year >= 2006) {
    valid_call <- grade %in% c(3:8, 11)
  } else if (end_year >= 2004) {
    valid_call <- grade %in% c(3, 4, 8, 11)
  } else if (end_year < 2004) {
    valid_call <- FALSE
  }
  
  return(valid_call)
}



#' @title call the correct \code{fetch} function for normal assessment years
#' 
#' @description for 2008-2014, this function will grab the NJASK for gr 3-8, and HSPA
#' for grade 11
#' @inheritParams fetch_njask
#' @keywords internal
standard_assess <- function(end_year, grade) {
  if (grade %in% c(3:8)) {
    assess_data <- fetch_njask(end_year, grade)
  } else if (grade == 11) {
    assess_data <- fetch_hspa(end_year) 
  }
  
  return(assess_data)
} 



#' @title a simplified interface into NJ assessment data
#' 
#' @description this is the workhorse function.  given a end_year and a grade (valid years are 2004-present), 
#' \code{fetch_old_nj_assess} will call the appropriate function, process the raw 
#' text file, and return a data frame.  \code{fetch_old_nj_assess} is a wrapper around 
#' all the individual subject functions (NJASK, HSPA, etc.), abstracting away the 
#' complexity of finding the right location/file layout.
#' @param end_year a school year.  end_year is the end of the academic year - eg 2013-14
#' school year is end_year '2014'.  valid values are 2004-2014.
#' @param grade a grade level.  valid values are 3,4,5,6,7,8,11
#' @param tidy if TRUE, takes the unwieldy, inconsistent wide data and normalizes into a 
#' long, tidy data frame with ~20 headers - constants(school/district name and code),
#' subgroup (all the NCLB subgroups) and test_name (LAL, math, etc).  
#' @export

fetch_old_nj_assess <- function(end_year, grade, tidy = FALSE) {
  #only allow valid calls
  if (!valid_call(end_year, grade)) {
    stop("invalid grade/end_year parameter passed")
  }
  
  #everything post 2008 has the same grade coverage
  #some of the layouts are funky, but the fetch_njask function covers that.
  if (end_year >= 2008) {
    assess_data <- standard_assess(end_year, grade)
    
    if (grade == 11) {
      assess_name <- 'HSPA'
    } else {
      assess_name <- 'NJASK'
    }
    
  #2006 and 2007: NJASK 3rd-7th, GEPA 8th, HSPA 11th
  } else if (end_year %in% c(2006, 2007)) {
    if (grade %in% c(3:7)) {
      assess_data <- standard_assess(end_year, grade)
      assess_name <- 'NJASK'
    } else if (grade == 8) {
      assess_data <- fetch_gepa(end_year)
      assess_name <- 'GEPA'
    } else if (grade == 11) {
      assess_data <- fetch_hspa(end_year)
      assess_name <- 'HSPA'
    }
    
  #2004 and 2005:  NJASK 3rd & 4th, GEPA 8th, HSPA 11th
  } else if (end_year %in% c(2004, 2005)) {
    if (grade %in% c(3:4)) {
      assess_data <- standard_assess(end_year, grade)  
      assess_name <- 'NJASK'
    } else if (grade == 8) {
      assess_data <- fetch_gepa(end_year)
      assess_name <- 'GEPA'
    } else if (grade == 11) {
      assess_data <- fetch_hspa(end_year)
      assess_name <- 'HSPA'
    }
    
  } else {
    #if we ever reached this block, there's a problem with our `valid_call()` function
    stop("unable to match your grade/end_year parameters to the appropriate function.")
  }
 
  if (tidy) assess_data <- tidy_nj_assess(assess_name, assess_data)
  
  return(assess_data)
}



#' @title tidies NJ assessment data
#'
#' @description
#' \code{tidy_nj_assess} is a utility/internal function that takes the somewhat messy/inconsistent
#' assessment headers and returns a tidy data frame. The output also carries the
#' same seven entity-selector flag columns emitted by tidy PARCC output -
#' \code{is_state}, \code{is_dfg}, \code{is_district}, \code{is_school},
#' \code{is_charter}, \code{is_charter_sector}, \code{is_allpublic} - so
#' downstream code can filter cross-format (PARCC + NJASK/HSPA/GEPA) results on
#' the same predicates.
#' @param assess_name NJASK, GEPA, HSPA
#' @param df a processed data frame (eg, output of process_njask)
#' @export

tidy_nj_assess <- function(assess_name, df) {
  
  logistical_columns <- c("cds_code", "County_Code/DFG/Aggregation_Code", "District_Code", 
    "School_Code", "County_Name", "District_Name", "School_Name", 
    "DFG", "Special_Needs", "Testing_Year", "Grade", "RECORD_KEY", "County_Code", 
    "DFG_Flag", "Special_Needs_(Abbott)_district_flag", "Grade_Level", "Test_Year"
  )
  
  #by population
  logistical_mask <- names(df) %in% logistical_columns
  total_population_mask <- grepl('TOTAL_POPULATION', names(df))
  general_education_mask <- grepl('GENERAL_EDUCATION', names(df))
  special_education_mask <- grepl('SPECIAL_EDUCATION(?!_WITH_ACCOMMODATIONS)', names(df), perl = TRUE)
  
  lep_current_former_mask <- grepl('LIMITED_ENGLISH_PROFICIENT_current_and_former', names(df)) |
    grepl('LIMITED_ENGLISH_PROFICIENT_Current_and_Former_LEP', names(df)) | 
    grepl('LIMITED_ENGLISH_PROFICIENT_Current_and_', names(df)) |
    grepl('LIMITED_ENGLISH_PROFICIENT_Current_+', names(df), fixed = TRUE) |
    #weirdly, unmarked LEP means 'current and former'
    grepl('(?<!CURRENT_|FORMER_)LIMITED_ENGLISH_PROFICIENT(?!_Current|_current|_Former)', names(df), perl = TRUE)
  
  lep_current_mask <- grepl('CURRENT_LIMITED_ENGLISH_PROFICIENT', names(df)) |
    grepl('LIMITED_ENGLISH_PROFICIENT_Current_LEPC', names(df)) |
    grepl('LIMITED_ENGLISH_PROFICIENT_Current(?!_and|_\\+)', names(df), perl = TRUE)

  lep_former_mask <- grepl('FORMER_LIMITED_ENGLISH_PROFICIENT', names(df)) |
    grepl('LIMITED_ENGLISH_PROFICIENT_Former_LEPF', names(df)) |
    grepl('LIMITED_ENGLISH_PROFICIENT_Former', names(df))
  
  female_mask <- grepl('FEMALE', names(df))
  male_mask <- grepl('(?<!FE)MALE', names(df), perl = TRUE)
  migrant_mask <- grepl('(?<!NON-)MIGRANT', names(df), perl = TRUE)
  nonmigrant_mask <- grepl('NON-MIGRANT', names(df))
  white_mask <- grepl('WHITE', names(df))
  black_mask <- grepl('BLACK', names(df))
  asian_mask <- grepl('ASIAN', names(df))
  pacific_islander_mask <- grepl('PACIFIC_ISLANDER', names(df))
  hispanic_mask <- grepl('HISPANIC', names(df))
  american_indian_mask <- grepl('AMERICAN_INDIAN', names(df))
  other_mask <- grepl('OTHER', names(df))
  ed_mask <- grepl('(?<!NON-)ECONOMICALLY_DISADVANTAGED', names(df), perl = TRUE)
  non_ed_mask <- grepl('NON-ECONOMICALLY_DISADVANTAGED', names(df))
  sped_accomodations_mask <- grepl('SPECIAL_EDUCATION_WITH_ACCOMMODATIONS', names(df))
  #irregular
  not_exempt_from_passing_mask <- grepl('NOT_EXEMPT_FROM_PASSING', names(df))
  iep_exempt_from_passing_mask <- grepl('IEP_EXEMPT_FROM_PASSING', names(df))
  iep_exempt_from_taking_mask <- grepl('IEP_EXEMPT_FROM_TAKING', names(df))
  lep_exempt_lal_only_mask <- grepl('LEP_EXEMPT_(LAL_Only)', names(df), fixed = TRUE) |
    grepl('LEP_EXEMPT_LAL_Only', names(df), fixed = TRUE)

  demog_masks <- rbind(logistical_mask, total_population_mask, general_education_mask, 
    special_education_mask, lep_current_former_mask, lep_current_mask, lep_former_mask, 
    female_mask, male_mask, migrant_mask, nonmigrant_mask, white_mask, black_mask, 
    asian_mask, pacific_islander_mask, hispanic_mask, american_indian_mask, other_mask, 
    ed_mask, non_ed_mask, sped_accomodations_mask, not_exempt_from_passing_mask, 
    iep_exempt_from_passing_mask, iep_exempt_from_taking_mask, lep_exempt_lal_only_mask
  ) %>% 
    as.data.frame()
  
  demog_test <- demog_masks %>%
    dplyr::summarise(dplyr::across(dplyr::everything(), sum)) %>%
    unname() %>% unlist()

  if (!all(demog_test == 1)) {
    message("Columns not matching exactly one demographic mask:")
    message(paste(names(df)[!demog_test == 1], collapse = ", "))
  }
  
  #by subject
  language_arts_mask <- grepl('LANGUAGE_ARTS', names(df), fixed = TRUE) | grepl('_ELA$', names(df)) |
    grepl('_LAL_', names(df)) | grepl('_LAL$', names(df))
  mathematics_mask <- grepl('MATHEMATICS', names(df), fixed = TRUE)
  science_mask <- grepl('SCIENCE', names(df), fixed = TRUE)
  #only number enrolled without subject (some years they did not specify)
  number_enrolled_mask <- grepl('Number_Enrolled', names(df), fixed = TRUE) & 
    !language_arts_mask & !mathematics_mask & !science_mask
  
  subj_masks <- rbind(logistical_mask, language_arts_mask, mathematics_mask, 
    science_mask, number_enrolled_mask) %>% 
    as.data.frame()
  
  subj_test <- subj_masks %>%
    dplyr::summarise(dplyr::across(dplyr::everything(), sum)) %>%
    unname() %>% unlist()

  if (!all(subj_test == 1)) {
    message("Columns not matching exactly one subject mask:")
    message(paste(names(df)[!subj_test == 1], collapse = ", "))
  }

  subgroups <- c('total_population', 'general_education', 'special_education', 
    'lep_current_former', 'lep_current', 'lep_former', 'female', 'male', 'migrant', 
    'nonmigrant', 'white', 'black', 'asian', 'pacific_islander', 'hispanic', 
    'american_indian', 'other', 'ed', 'non_ed', 'sped_accomodations', 'not_exempt_from_passing',
    'iep_exempt_from_passing', 'iep_exempt_from_taking', 'lep_exempt_lal_only')
  
  result_list <- list()
  
  tidy_col <- function(mask, nj_df) {
    if (sum(mask) > 1) stop("tidying assessment data matched more than one column")
    if (all(mask == FALSE)) {
      out <- rep(NA, nrow(nj_df))
    } else {
      out <- nj_df[, mask]
    }
    return(out)
  }
  
  testing_year <- grepl('(Test_Year|Testing_Year)', names(df))
  grade <- grepl('(Grade|Grade_Level)', names(df))
  county_code <- grepl('County_Code', names(df), fixed = TRUE)
  district_code <- grepl('District_Code', names(df), fixed = TRUE)
  school_code <- grepl('School_Code', names(df), fixed = TRUE)
  district_name <- grepl('District_Name', names(df), fixed = TRUE)
  school_name <- grepl('School_Name', names(df), fixed = TRUE)
  dfg <- grepl('^DFG', names(df), perl = TRUE)
  special_needs <- grepl('^Special_Needs', names(df), fixed = TRUE)
  
  constant_df <- data.frame(
    assess_name = assess_name,
    testing_year = tidy_col(testing_year, df) %>% as.integer(),
    grade = tidy_col(grade, df),
    county_code = tidy_col(county_code, df) %>% as.character(),
    district_code = tidy_col(district_code, df),
    school_code = tidy_col(school_code, df),
    district_name = tidy_col(district_name, df),
    school_name = tidy_col(school_name, df),
    dfg = tidy_col(dfg, df),
    special_needs = tidy_col(special_needs, df),
    stringsAsFactors = FALSE
  )
  
  iters <- 1
  
  for (i in subgroups) {
    subgroup_mask <- paste0(i, '_mask') %>% get()
    if (!any(subgroup_mask)) next
    
    for (j in c('language_arts', 'mathematics', 'science')) {
      subj_mask <- paste0(j, '_mask') %>% get()
      
      #skip when no data
      if (!any(subj_mask)) next
      
      this_df <- df[, subgroup_mask & subj_mask]

      this_tidy <- cbind(
        constant_df,
        data.frame(
          subgroup = i,
          test_name = j,

          number_enrolled = tidy_col(grepl('Number_Enrolled', names(this_df)), this_df),
          number_not_present = tidy_col(grepl('Number_Not_Present', names(this_df)), this_df),
          number_of_voids = tidy_col(grepl('Number_of_Voids', names(this_df)), this_df),
          number_of_valid_classifications = tidy_col(grepl('Number_of_Valid_Classifications', names(this_df)), this_df),
          number_apa = tidy_col(grepl('Number_APA', names(this_df)), this_df),
          number_valid_scale_scores = tidy_col(grepl('Number_of_Valid_Scale_Scores', names(this_df)), this_df),
          partially_proficient = tidy_col(grepl('Partially_Proficient_Percentage', names(this_df)), this_df),
          proficient = tidy_col(grepl('(?<!Partially_|Advanced_)Proficient_Percentage', names(this_df), perl = TRUE), this_df),
          advanced_proficient = tidy_col(grepl('Advanced_Proficient_Percentage', names(this_df)), this_df),
          scale_score_mean = tidy_col(grepl('Scale_Score_Mean', names(this_df)), this_df),
          stringsAsFactors = FALSE
        )
      )
      
      result_list[[iters]] <- this_tidy
      iters <- iters + 1
    }
  }

  out <- dplyr::bind_rows(result_list)

  # ----- school_code canonicalization (issue #26) ------------------------
  # NJ DOE files report district-wide rows with EITHER an empty/blank
  # School_Code field OR a literal "000" sentinel, depending on the year
  # and layout revision. Both encode the same logical record (a
  # district-aggregate row), but downstream filters like
  # `filter(school_code == "000")` vs `filter(is.na(school_code))`
  # silently disagree. Collapse both forms to NA so the post-tidy
  # column has exactly one canonical value for "no school".
  out <- canonicalize_legacy_assess_school_code(out)

  # ----- selector flags (PARCC parity, issue #96) ------------------------
  # Mirror the entity-classification flags emitted by process_parcc() so
  # downstream code can `filter(is_district)` / `filter(is_state)` etc.
  # uniformly across PARCC/NJSLA and the legacy NJASK/HSPA/GEPA pipeline.
  #
  # Conventions documented in layout_njask et al.:
  #   County_Code (a.k.a. Aggregation_Code) values:
  #     numeric county codes (01..41) for county/district/school rows;
  #     "80" for charter-sector county/district/school rows;
  #     DFG letters (A, B, CD, DE, FG, GH, I, J, R, V) for DFG aggregates;
  #     "ST" for statewide; "NS"/"SN" for Non-/Special-Needs aggregates.
  out <- assign_legacy_assess_flags(out)

  return(out)
}


#' @title canonicalize school_code in tidy legacy assessment output
#'
#' @description Collapses the multiple "no school here" encodings emitted
#' by the raw NJ DOE NJASK/HSPA/GEPA files into a single canonical value
#' (\code{NA_character_}).
#'
#' Issue #26 documents that the raw fixed-width layouts use two different
#' encodings for district-aggregate rows in the same column:
#' \itemize{
#'   \item \code{""} (whitespace-only, after trimming the padded field)
#'   \item \code{"000"} (a literal three-digit zero sentinel)
#' }
#' Both mean "this row is not a school." Without normalization,
#' downstream filters silently disagree:
#' \code{filter(school_code == "000")} drops the blank-encoded rows,
#' \code{filter(is.na(school_code))} drops the "000"-encoded rows, and
#' neither filter returns the full set of district-aggregate rows.
#'
#' After this function runs, \code{is.na(school_code)} is the single,
#' correct test for "not a school." Real school codes
#' (\code{"001"}..\code{"999"} per layout_njask) are preserved unchanged.
#'
#' The function is idempotent: applying it twice yields the same result.
#'
#' @param df a tidied NJASK/HSPA/GEPA data frame (must have a
#'   \code{school_code} column).
#' @return \code{df} with \code{school_code} normalized.
#' @keywords internal
canonicalize_legacy_assess_school_code <- function(df) {
  if (!"school_code" %in% names(df)) return(df)

  sc <- as.character(df$school_code)
  sc_trim <- trimws(sc)

  # Treat both whitespace-only and "000" as district-aggregate sentinels.
  district_aggregate <- !is.na(sc) & (sc_trim == "" | sc_trim == "000")
  sc[district_aggregate] <- NA_character_

  df$school_code <- sc
  df
}


#' @title assign PARCC-parity selector flags to legacy NJ assessment data
#'
#' @description tags each row of tidy NJASK/HSPA/GEPA output with the same
#' entity-classification flags emitted by `process_parcc()`
#' (\code{is_state}, \code{is_dfg}, \code{is_district}, \code{is_school},
#' \code{is_charter}, \code{is_charter_sector}, \code{is_allpublic}) so
#' downstream code can filter cross-format data on the same predicates.
#'
#' The legacy NJ DOE files encode entity type in the
#' \code{County_Code/DFG/Aggregation_Code} column:
#' \itemize{
#'   \item \code{"ST"} = statewide
#'   \item DFG letter (A, B, CD, DE, FG, GH, I, J, R, V) = DFG aggregate
#'   \item numeric county code (01..41 or 80) = district/school row;
#'         \code{"80"} specifically tags the charter sector
#'   \item \code{"NS"} / \code{"SN"} = Non-/Special-Needs aggregates
#'         (none of \code{is_state} / \code{is_dfg} / \code{is_district} /
#'         \code{is_school} apply to these rows)
#' }
#'
#' `is_charter_sector` and `is_allpublic` are FALSE on every row -
#' matching the placeholder behavior of `process_parcc()`, where these
#' flags only become TRUE in downstream aggregation. Emitted for schema
#' parity with PARCC tidy output.
#'
#' @param df a tidied NJASK/HSPA/GEPA data frame
#' @return df with seven additional logical columns
#' @keywords internal
assign_legacy_assess_flags <- function(df) {
  # NJ DFG codes (per layout_njask$valid_values for the
  # County_Code/DFG/Aggregation_Code field):
  dfg_codes <- c("A", "B", "CD", "DE", "FG", "GH", "I", "J", "R", "V")

  cc <- toupper(as.character(df$county_code))

  df$is_state <- !is.na(cc) & cc == "ST"
  df$is_dfg <- !is.na(cc) & cc %in% dfg_codes
  df$is_district <- !is.na(df$district_code) & is.na(df$school_code) &
    !df$is_state & !df$is_dfg
  df$is_school <- !is.na(df$school_code)
  df$is_charter <- !is.na(cc) & cc == "80"
  df$is_charter_sector <- FALSE
  df$is_allpublic <- FALSE

  df
}


#' @title nj_coltype_parser
#' 
#' @description turns layout datatypes into compact string required by read_fwf
#' @param datatypes vector of datatypes (from a layout df)
#' @return a character string of the types, for read_fwf
#' @keywords internal
nj_coltype_parser <- function(datatypes) {
  datatypes <- ifelse(datatypes == "Text", 'c', datatypes)
  datatypes <- ifelse(datatypes == "Integer", 'i', datatypes)
  datatypes <- ifelse(datatypes == "Decimal", 'd', datatypes)
  datatypes <- datatypes %>% unlist() %>% unname()
 
  paste(datatypes, collapse = '')
}


#' Detect redundant composite fields in a fixed-width layout
#'
#' A field is "redundant" if its `[field_start_position, field_end_position]`
#' interval is the exact, disjoint union of two or more OTHER fields with
#' strictly narrower intervals. The canonical case in the NJASK/HSPA/GEPA
#' layouts is the composite county-district-school identifier (positions
#' 1-9), which decomposes into `County_Code` (1-2), `District_Code` (3-6),
#' and `School_Code` (7-9). Several layouts also carry a `RECORD_KEY`
#' (positions 1-9) that overlaps the same range.
#'
#' `readr::fwf_positions()` rejects layouts with any overlap, so these
#' composite rows must be dropped before parsing and then reconstructed
#' from their components afterward.
#'
#' @param layout A data frame with `field_start_position`,
#'   `field_end_position`, and `final_name` columns.
#' @return A logical vector of length `nrow(layout)`; `TRUE` marks rows to
#'   drop before calling `readr::fwf_positions()`. Rows with the same
#'   interval as another redundant composite (e.g. both `RECORD_KEY` and
#'   the composite identifier both covering 1-9) are all flagged.
#' @keywords internal
#' @noRd
find_redundant_overlaps <- function(layout) {
  n <- nrow(layout)
  redundant <- logical(n)
  if (n < 2) return(redundant)

  starts <- layout$field_start_position
  ends   <- layout$field_end_position
  widths <- ends - starts + 1L

  for (i in seq_len(n)) {
    width_i <- widths[i]
    # Candidate component rows: strictly inside row i's interval AND
    # strictly narrower (so a composite cannot "decompose" itself, and
    # two identical-interval composites do not absorb each other).
    candidate <- which(
      starts >= starts[i] & ends <= ends[i] & widths < width_i
    )
    if (length(candidate) < 2L) next

    # Sort candidates by start, then check that they (a) are pairwise
    # disjoint and (b) their union exactly covers row i.
    ord <- order(starts[candidate])
    cs <- starts[candidate][ord]
    ce <- ends[candidate][ord]

    # First candidate must start where row i starts; last must end where it
    # ends; consecutive candidates must abut without gap or overlap.
    if (cs[1] != starts[i]) next
    if (ce[length(ce)] != ends[i]) next
    if (length(cs) > 1L && !all(ce[-length(ce)] + 1L == cs[-1])) next

    redundant[i] <- TRUE
  }

  redundant
}


#' Reconstruct a composite fixed-width field from its component parts
#'
#' Used after `readr::read_fwf()` to rebuild a composite identifier
#' (e.g. the legacy assessment composite county-district-school code or
#' `RECORD_KEY`) that was dropped via `find_redundant_overlaps()`.
#' Components are pasted together in positional order with zero-width
#' concatenation; if any component is `NA` for a given row, the composite
#' is `NA` for that row.
#'
#' The reconstructed column is inserted into `df` at the positional index
#' implied by the row's original placement in the full layout, so that
#' downstream code addressing `df` by column position (e.g.
#' `process_nj_assess()`) continues to align with the layout.
#'
#' @param df Data frame produced by `readr::read_fwf()` against
#'   `parse_layout`.
#' @param composite_row A one-row data frame slice from the original layout
#'   describing the composite (`field_start_position`,
#'   `field_end_position`, `final_name`, and a numeric `..orig_index`
#'   column giving its row number in the full layout).
#' @param parse_layout The deduplicated layout that was passed to
#'   `readr::read_fwf()`.
#' @return `df` with the composite column added back.
#' @keywords internal
#' @noRd
reconstruct_composite_field <- function(df, composite_row, parse_layout) {
  composite_name  <- composite_row$final_name[[1]]
  composite_start <- composite_row$field_start_position[[1]]
  composite_end   <- composite_row$field_end_position[[1]]

  component_idx <- which(
    parse_layout$field_start_position >= composite_start &
      parse_layout$field_end_position <= composite_end
  )
  if (length(component_idx) == 0L) {
    stop(
      "Cannot reconstruct composite field '", composite_name,
      "': no component fields found inside [", composite_start, ", ",
      composite_end, "]."
    )
  }

  # Order component rows positionally so concatenation matches the
  # composite's byte order.
  component_idx <- component_idx[
    order(parse_layout$field_start_position[component_idx])
  ]
  component_names <- parse_layout$final_name[component_idx]

  parts <- lapply(component_names, function(nm) as.character(df[[nm]]))
  composite_value <- do.call(paste0, parts)

  # paste0() turns NA into the literal string "NA"; honour the documented
  # contract that any-NA-component yields NA composite.
  any_na <- Reduce(`|`, lapply(parts, is.na))
  composite_value[any_na] <- NA_character_

  df[[composite_name]] <- composite_value
  df
}


#' @title common_fwf_req
#'
#' @description common fwf logic across various assessment types.  DRY.
#'
#' Detects redundant composite fields (see `find_redundant_overlaps()`),
#' parses the deduplicated layout via `readr::read_fwf()`, then reconstructs
#' the dropped composites from their component parts so that downstream
#' code receives a data frame with the same column count and order as the
#' full layout.
#'
#' @param url file location
#' @param layout data frame containing fixed-width file column specifications
#' @return layout layout to use
#' @keywords internal
common_fwf_req <- function(url, layout) {
  #got burned by bad layouts.  read in the raw file
  #this will take extra time, but it is worth it.

  raw_fwf <- readLines(url)
  raw_fwf <- iconv(raw_fwf, "LATIN2", "UTF-8")
  num_lines <- lapply(raw_fwf, nchar) %>% unlist()

  #if everything is consistent, great.  if the fwf is ragged, trim whitespace.
  if (any(num_lines < max(num_lines))) {
    raw_fwf <- raw_fwf %>% gsub("[[:space:]]*$","", .)
  }

  #check that incoming response (when cleaned) is of consistent length.
  if (!nchar(raw_fwf) %>% unique() %>% length() == 1) {
    warning("the fixed width input file is not fixed - rows are of different length.")
    warning("truncating rows that are too wide, and padding rows that are too short...")
  }

  #sometimes the raw response is too short.  that wrecks havoc with read_fwf
  #additionally, some layouts call for data that there is data that really isnt there.
  #(aka science).
  #right pad them to the full extent of the array OR layout
  max_extent <- max(nchar(raw_fwf), max(layout$field_end_position))
  raw_fwf <- sprintf(paste0('%-', max_extent, 's'), raw_fwf)

  # Detect and drop redundant composite fields (the composite county-
  # district-school identifier, plus any RECORD_KEY) that overlap their
  # decomposed parts. readr::fwf_positions() rejects any overlap; we
  # reconstruct the composites post-parse from their parts.
  redundant <- find_redundant_overlaps(layout)
  parse_layout <- layout[!redundant, , drop = FALSE]

  #read_fwf
  df <- readr::read_fwf(
    file = raw_fwf %>% paste(collapse = '\n'),
    col_positions = readr::fwf_positions(
      start = parse_layout$field_start_position,
      end = parse_layout$field_end_position,
      col_names = parse_layout$final_name
    ),
    col_types = nj_coltype_parser(parse_layout$data_type),
    na = "*",
    progress = TRUE
  )

  # Reconstruct dropped composite fields by concatenating their component
  # parts, then reorder columns to match the full layout so downstream
  # positional indexing (e.g. process_nj_assess() implied-decimal mask)
  # still aligns.
  redundant_idx <- which(redundant)
  for (i in redundant_idx) {
    df <- reconstruct_composite_field(df, layout[i, , drop = FALSE], parse_layout)
  }
  if (length(redundant_idx) > 0L) {
    df <- df[, layout$final_name, drop = FALSE]
  }

  if (!nrow(df) == length(raw_fwf)) {
    paste('read_fwf is', nrow(df), 'lines') %>% print()
    paste('raw response', length(raw_fwf), 'lines') %>% print()
    stop("read_fwf and readlines don't agree on size of df.  probably a layout error.")
  }

  df
}
  
