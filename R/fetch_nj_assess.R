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
    
  #2006 and 2007: NJASK 3rd-7th, GEPA 8th, HSPA 11th
  } else if (end_year %in% c(2006, 2007)) {
    if (grade %in% c(3:7)) {
      assess_data <- standard_assess(end_year, grade)  
    } else if (grade == 8) {
      assess_data <- fetch_gepa(end_year)
    } else if (grade == 11) {
      assess_data <- fetch_hspa(end_year)
    }
    
  #2004 and 2005:  NJASK 3rd & 4th, GEPA 8th, HSPA 11th
  } else if (end_year %in% c(2004, 2005)) {
    if (grade %in% c(3:4)) {
      assess_data <- standard_assess(end_year, grade)  
    } else if (grade == 8) {
      assess_data <- fetch_gepa(end_year)
    } else if (grade == 11) {
      assess_data <- fetch_hspa(end_year)
    }
  
  } else {
    #if we ever reached this block, there's a problem with our `valid_call()` function
    stop("unable to match your grade/end_year parameters to the appropriate function.")
  }
 
  return(assess_data)
}
