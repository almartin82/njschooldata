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
#' assessment headers and returns a tidy data frame.
#' @param assess_name NJASK, GEPA, HSPA
#' @param df a processed data frame (eg, output of process_njask)
#' @export

tidy_nj_assess <- function(assess_name, df) {
  
  logistical_columns <- c("CDS_Code", "County_Code/DFG/Aggregation_Code", "District_Code", 
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
  
  return(dplyr::bind_rows(result_list))
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


#' @title common_fwf_req
#'
#' @description common fwf logic across various assessment types.  DRY.
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
  
  #read_fwf
  df <- readr::read_fwf(
    file = raw_fwf %>% paste(collapse = '\n'),
    col_positions = readr::fwf_positions(
      start = layout$field_start_position,
      end = layout$field_end_position,
      col_names = layout$final_name
    ),
    col_types = nj_coltype_parser(layout$data_type),
    na = "*",
    progress = TRUE
  )
  
  if (!nrow(df) == length(raw_fwf)) {
    paste('read_fwf is', nrow(df), 'lines') %>% print()
    paste('raw response', length(raw_fwf), 'lines') %>% print()
    stop("read_fwf and readlines don't agree on size of df.  probably a layout error.")
  }

  df
}
  
