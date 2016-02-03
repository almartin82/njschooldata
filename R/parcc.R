#' @title reads the raw PARCC excel files from the state website
#' 
#' @description
#' \code{get_raw_parcc} builds a url and reads the xlsx file into a dataframe
#' 
#' @param end_year a school year.  end_year is the end of the academic year - eg 2014-15
#' school year is end_year '2015'.  valid values are 2015
#' @param grade grade level
#' @param subj PARCC subject. c('ela' or 'math')
#' @param layout what layout dataframe to use.  default is layout_njask.
#' @export

get_raw_parcc <- function(end_year, grade, subj) {  
  
  stem <- 'http://www.nj.gov/education/schools/achievement/' 
  target_url <- paste(
    end_year, '/parcc/', parse_parcc_subj(subj), pad_grade(grade), '.xlsx' 
  )
  
  target_url
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
#' @export

fetch_parcc <- function(end_year, grade, subj) {
  
}
