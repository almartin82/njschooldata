#' @title determine if a end_year/grade pairing can be downloaded from the state website
#' 
#' @description
#' \code{valid_call} returns a boolean value indicating if a given end_year/grade pairing is
#' valid for assessment data
#' @inheritParams fetch_njask
#' @export

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
#' @export

standard_assess <- function(end_year, grade) {
  if(grade %in% c(3:8)) {
    assess_data <- fetch_njask(end_year, grade)
  } else if (grade == 11) {
    assess_data <- fetch_hspa(end_year) 
  }
  
  return(assess_data)
} 



#' @title a simplified interface into NJ assessment data
#' 
#' @description this is the workhorse function.  given a end_year and a grade (valid years are 2004-present), 
#' \code{fetch_nj_assess} will call the appropriate function, process the raw 
#' text file, and return a data frame.  \code{fetch_nj_assess} is a wrapper around 
#' all the individual subject functions (NJASK, HSPA, etc.), abstracting away the 
#' complexity of finding the right location/file layout.
#' @inheritParams fetch_njask
#' @export

fetch_nj_assess <- function(end_year, grade, tidy = FALSE) {
  #only allow valid calls
  valid_call(end_year, grade) %>%
    ensure_that(
      all(.) ~ "invalid grade/end_year parameter passed")
  
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
    dplyr::summarise_each(funs(sum)) %>% 
    unname() %>% unlist()
  
  if (!all(demog_test == 1)) {
    print(names(df)[!demog_test == 1])
    print(demog_test)
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
    dplyr::summarise_each(funs(sum)) %>% 
    unname() %>% unlist()

  if (!all(subj_test == 1)) {
    print(names(df)[!subj_test == 1])  
    names(subj_masks) <- names(df)
    print(subj_masks[, !subj_test == 1])
  }

  subgroups <- c('total_population', 'general_education', 'special_education', 
    'lep_current_former', 'lep_current', 'lep_former', 'female', 'male', 'migrant', 
    'nonmigrant', 'white', 'black', 'asian', 'pacific_islander', 'hispanic', 
    'american_indian', 'other', 'ed', 'non_ed', 'sped_accomodations', 'not_exempt_from_passing',
    'iep_exempt_from_passing', 'iep_exempt_from_taking', 'lep_exempt_lal_only')
  
  tidy_df <- data.frame(
    testing_year = integer(0),
    grade = integer(0),
    district_code = character(0),
    school_code = character(0),
    district_name = character(0),
    school_name = character(0),
    
    number_enrolled = numeric(0),
    number_not_present = numeric(0),
    number_of_voids = numeric(0),
    number_apa = numeric(0),
    number_valid_scale_scores = numeric(0),
    partially_proficient = numeric(0),
    proficient = numeric(0),
    advanced_proficient = numeric(0),
    scale_score_mean = numeric(0)
  )
  
  testing_year <- grepl('(Test_Year|Testing_Year)', names(df))
  grade <- grepl('(Grade|Grade_Level)', names(df))
  district_code <- grepl('District_Code', names(df), fixed = TRUE)
  school_code <- grepl('School_Code', names(df), fixed = TRUE)
  district_name <- grepl('District_Name', names(df), fixed = TRUE)
  school_name <- grepl('School_Name', names(df), fixed = TRUE)
  
  constant_df <- data.frame(
    testing_year = df[, testing_year],
    grade = df[, grade],
    district_code = df[, district_code],
    school_code = df[, school_code],
    district_name = df[, district_name],
    school_name = df[, school_name],
    stringsAsFactors = FALSE
  )
  
  for (i in subgroups) {
    print(i)
    for (j in c('language_arts', 'mathematics', 'science')) {
      print(j)
        subgroup_mask <- paste0(i, '_mask') %>% get()
        subj_mask <- paste0(j, '_mask') %>% get()
        
        names(df)[subgroup_mask & subj_mask]
        this_df <- df[, subgroup_mask & subj_mask]
  
        this_tidy <- cbind(
          constant_df,
          data.frame(
            number_enrolled = this_df[, grepl('Number_Enrolled', names(this_df))],
            number_not_present = this_df[, grepl('Number_Not_Present', names(this_df))],
            number_of_voids = this_df[, grepl('Number_Enrolled', names(this_df))],
            number_apa = this_df[, grepl('Number_APA', names(this_df))],
            number_valid_scale_scores = this_df[, grepl('Number_of_Valid_Scale_Scores', names(this_df))],
            partially_proficient = this_df[, grepl('Partially_Proficient_Percentage', names(this_df))],
            proficient = this_df[, grepl('Proficient_Percentage', names(this_df))],
            advanced_proficient = this_df[, grepl('Advanced_Proficient_Percentage', names(this_df))],
            scale_score_mean = this_df[, grepl('Scale_Score_Mean', names(this_df))],
            stringsAsFactors = FALSE
          )
        )
    }
  }
  
}