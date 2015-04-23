#' @title read a fixed width, raw NJASK data file from the NJ state website
#' 
#' @description
#' \code{get_raw_njask} builds a url and uses readr's \code{read_fwf} to get the fixed 
#' width text file into a R data frame
#' @inheritParams fetch_njask
#' @param layout what layout dataframe to use.  default is layout_njask.
#' @export

get_raw_njask <- function(year, grade, layout=layout_njask) {  
  #url paths changed after the 2012 assessment
  years <- list(
    "2014"="14", "2013"="13", "2012"="2013", "2011"="2012", "2010"="2011", "2009"="2010", 
    "2008"="2009", "2007"="2008", "2006"="2007", "2005"="2006", "2004"="2005"
  )
  parsed_year <- years[[as.character(year)]]
  
  #2008 follows a totally unique pattern
  grade_str <- if (year==2008 & grade >=5) {
    paste0('58/g', grade)
  } else if (year %in% c(2006, 2007) & grade %in% c(5, 6, 7)) {
    '57'
  } else {
    grade
  }
  
  #filenames are also inconsistent 
  filename <- list(
    "2014"="state_summary.txt", "2013"="state_summary.txt", "2012"="state_summary.txt",
    "2011"="state_summary.txt", "2010"="state_summary.txt", "2009"="state_summary.txt",
    "2008"="state_summary.txt", "2007"=if(grade >= 5) {
        paste0('G', grade, 'state_summary.txt')
      } else {
        "state_summary.txt"
      }, 
      "2006"=if(grade >= 5) {
        paste0('G', grade, 'state_summary.txt')
      } else {
        "state_summary.txt"
      }, 
      "2005"= if(grade==3) {
        "njask005_state_summary3.txt"
      } else if (grade==4) {
        "njask2005_state_summary4.txt"
      }, 
    "2004"=paste0("njask", grade, "04state_summary.txt")   
  )
  parsed_filename <- filename[[as.character(year)]]
    
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
#' given a year and grade.   
#' @param year a school year.  year is the end of the academic year - eg 2013-14
#' school year is year '2014'.  valid values are 2004-2014.
#' @param grade a grade level.  valid values are 3,4,5,6,7,8
#' @export

fetch_njask <- function(year, grade) {
  if (year == 2004) {
    df <- get_raw_njask(year, grade, layout = layout_njask04)  %>% 
      process_nj_assess(layout = layout_njask04)
    
  } else if (year == 2005) {
    df <- get_raw_njask(year, grade, layout = layout_njask05)  %>% 
      process_nj_assess(layout = layout_njask05) 
    
  } else if (year %in% c(2007, 2008) & grade %in% c(3, 4)) {
    df <- get_raw_njask(year, grade, layout = layout_njask07gr3)  %>% 
      process_nj_assess(layout = layout_njask07gr3) 
    
  } else if (year == 2006 & grade %in% c(3, 4)) {
    df <- get_raw_njask(year, grade, layout = layout_njask06gr3)  %>% 
      process_nj_assess(layout = layout_njask06gr3)
    
  } else if (year == 2006 & grade >= 5) {
    df <- get_raw_njask(year, grade, layout = layout_njask06gr5)  
    #inexplicably, 2006 data has no Grade column
    df$Grade <- grade
    df <- df %>% 
      process_nj_assess(layout = layout_njask06gr5) 
    
  } else {
    df <- get_raw_njask(year, grade) %>% 
      process_nj_assess(layout = layout_njask)    
  }

  return(df)
}
