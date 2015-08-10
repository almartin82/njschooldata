#' @title read a fixed width, raw NJASK data file from the NJ state website
#' 
#' @description
#' \code{get_raw_njask} builds a url and uses readr's \code{read_fwf} to get the fixed 
#' width text file into a R data frame
#' @inheritParams fetch_njask
#' @param layout what layout dataframe to use.  default is layout_njask.
#' @export

get_raw_njask <- function(end_year, grade, layout=layout_njask) {  
  #url paths changed after the 2012 assessment
  years <- list(
    "2014" = "14", "2013" = "13", "2012" = "2013", "2011" = "2012", "2010" = "2011", 
    "2009" = "2010", "2008" = "2009", "2007" = "2008", "2006" = "2007", 
    "2005" = "2006", "2004" = "2005"
  )
  parsed_year <- years[[as.character(end_year)]]
  
  #2008 follows a totally unique pattern
  grade_str <- if (end_year == 2008 & grade >= 5) {
    paste0('58/g', grade)
  } else if (end_year %in% c(2006, 2007) & grade %in% c(5, 6, 7)) {
    '57'
  } else {
    grade
  }
  
  #filenames are also inconsistent 
  filename <- list(
    "2014" = "state_summary.txt", "2013" = "state_summary.txt", "2012" = "state_summary.txt",
    "2011" = "state_summary.txt", "2010" = "state_summary.txt", "2009" = "state_summary.txt",
    "2008" = "state_summary.txt", "2007" = if (grade >= 5) {
        paste0('G', grade, 'state_summary.txt')
      } else {
        "state_summary.txt"
      }, 
      "2006" = if (grade >= 5) {
        paste0('G', grade, 'state_summary.txt')
      } else {
        "state_summary.txt"
      }, 
      "2005" = if (grade == 3) {
        "njask005_state_summary3.txt"
      } else if (grade == 4) {
        "njask2005_state_summary4.txt"
      }, 
    "2004" = paste0("njask", grade, "04state_summary.txt")   
  )
  parsed_filename <- filename[[as.character(end_year)]]
    
  #build url
  target_url <- paste0(
    "http://www.state.nj.us/education/schools/achievement/", parsed_year, 
    "/njask", grade_str, "/", parsed_filename
  )
      
  #read_fwf
  df <- readr::read_fwf(
    file = target_url,
    col_positions = readr::fwf_positions(
      start = layout$field_start_position,
      end = layout$field_end_position,
      col_names = layout$final_name
    ),
    na = "*",
    progress = TRUE
  )
  
  #return df
  return(df)
}



#' @title gets and processes a NJASK file
#' 
#' @description
#' \code{fetch_njask} is a wrapper around \code{get_raw_njask} and
#' \code{process_nj_assess} that passes the correct file layout data to each function,
#' given an end_year and grade.   
#' @param end_year a school year.  end_year is the end of the academic year - eg 2013-14
#' school year is end_year '2014'.  valid values are 2004-2014.
#' @param grade a grade level.  valid values are 3,4,5,6,7,8
#' @param tidy if TRUE, returns a tidy data frame
#' @export

fetch_njask <- function(end_year, grade, tidy = FALSE) {
  if (end_year == 2004) {
    df <- get_raw_njask(end_year, grade, layout = layout_njask04) %>% 
      process_nj_assess(layout = layout_njask04)
    
  } else if (end_year == 2005) {
    df <- get_raw_njask(end_year, grade, layout = layout_njask05) %>% 
      process_nj_assess(layout = layout_njask05) 

  } else if (end_year == 2006 & grade %in% c(3, 4)) {
    df <- get_raw_njask(end_year, grade, layout = layout_njask06gr3) %>% 
      process_nj_assess(layout = layout_njask06gr3)
    
  } else if (end_year == 2006 & grade >= 5) {
    df <- get_raw_njask(end_year, grade, layout = layout_njask06gr5)  
    #inexplicably, 2006 data has no Grade column
    df$Grade <- grade
    df <- df %>% 
      process_nj_assess(layout = layout_njask06gr5) 
    
  } else if (end_year %in% c(2007, 2008) & grade %in% c(3, 4)) {
    df <- get_raw_njask(end_year, grade, layout = layout_njask07gr3) %>% 
      process_nj_assess(layout = layout_njask07gr3) 
    
  #nb - 2007 is the end of the GEPA; 2007 gr 8 does not exist for NJASK.
  } else if (end_year %in% c(2007, 2008) & grade >= 5) {
    df <- get_raw_njask(end_year, grade, layout = layout_njask09) %>% 
      process_nj_assess(layout = layout_njask09) 
    
  } else if (end_year == 2009) {
    df <- get_raw_njask(end_year, grade, layout = layout_njask09) %>% 
      process_nj_assess(layout = layout_njask09) 
    
  } else {
    df <- get_raw_njask(end_year, grade) %>% 
      process_nj_assess(layout = layout_njask)    
  }

  if (tidy) df <- tidy_njask(end_year, grade, df)
  
  return(df)
}



#' @title tidies NJASK
#' 
#' @description
#' \code{tidy_njask} is a utility/internal function that takes the somewhat messy/inconsistent 
#' NJASK headers and returns a tidy data frame.
#' @param end_year a school year.  end_year is the end of the academic year - eg 2013-14
#' school year is end_year '2014'.  valid values are 2004-2014.
#' @param grade a grade level.  valid values are 3,4,5,6,7,8
#' @param tidy if TRUE, returns a tidy data frame
#' @param df a NJASK data frame (output of process_njask)
#' @export

tidy_njask <- function(end_year, grade, df) {
  
  logistical_columns <- c("CDS_Code", "County_Code/DFG/Aggregation_Code", "District_Code", 
    "School_Code", "County_Name", "District_Name", "School_Name", 
    "DFG", "Special_Needs", "Testing_Year", "Grade")
  
  logistical_mask <- names(df) %in% logistical_columns
  total_population_mask <- grepl('^TOTAL_POPULATION', names(df))
  general_education_mask <- grepl('^GENERAL_EDUCATION', names(df))
  special_education_mask <- grepl('^SPECIAL_EDUCATION(?!_WITH_ACCOMMODATIONS)', names(df), perl = TRUE)
  lep_current_former_mask <- grepl('^LIMITED_ENGLISH_PROFICIENT_current_and_former', names(df))
  lep_current_mask <- grepl('^CURRENT_LIMITED_ENGLISH_PROFICIENT', names(df))
  lep_former_mask <- grepl('^FORMER_LIMITED_ENGLISH_PROFICIENT', names(df))
  female_mask <- grepl('^FEMALE', names(df))
  male_mask <- grepl('^MALE', names(df))
  migrant_mask <- grepl('^MIGRANT', names(df))
  nonmigrant_mask <- grepl('^NON-MIGRANT', names(df))
  white_mask <- grepl('^WHITE', names(df))
  black_mask <- grepl('^BLACK', names(df))
  asian_mask <- grepl('^ASIAN', names(df))
  pacific_islander_mask <- grepl('^PACIFIC_ISLANDER', names(df))
  hispanic_mask <- grepl('^HISPANIC', names(df))
  american_indian_mask <- grepl('^AMERICAN_INDIAN', names(df))
  other_mask <- grepl('^OTHER', names(df))
  ed_mask <- grepl('^ECONOMICALLY_DISADVANTAGED', names(df))
  non_ed_mask <- grepl('^NON-ECONOMICALLY_DISADVANTAGED', names(df))
  sped_accomodations_mask <- grepl('^SPECIAL_EDUCATION_WITH_ACCOMMODATIONS', names(df))
 
  demog_masks <- rbind(logistical_mask, total_population_mask, general_education_mask, 
    special_education_mask, lep_current_former_mask, lep_current_mask, lep_former_mask, 
    female_mask, male_mask, migrant_mask, nonmigrant_mask, white_mask, black_mask, 
    asian_mask, pacific_islander_mask, hispanic_mask, american_indian_mask, other_mask, 
    ed_mask, non_ed_mask, sped_accomodations_mask
  ) %>% 
    as.data.frame()
  
  demog_test <- demog_masks %>%
    dplyr::summarise_each(funs(sum)) %>% 
    unname() %>% unlist()
  
  if (!all(demog_test == 1)) {
    print(names(df)[!demog_test == 1])  
  }
  
}