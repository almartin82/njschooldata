#' @title read a fixed width, raw NJASK data file from the NJ state website
#' 
#' @description
#' \code{get_raw_njask} builds a url and uses readr's \code{read_fwf} to get the fixed 
#' width text file into a R data frame
#' @param year a school year.  year is the end of the academic year - eg 2013-14
#' school year is year '2014'.  valid values are 2004-2014.
#' @param grade a grade level.  valid values are 3,4,5,6,7,8
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
    na = "*"
  )
  
  #return df
  return(df)
  
}



#' @title process a raw njask file 
#' 
#' @description
#' \code{process_njask} does cleanup of the raw njask file, primarily ensuring that 
#' columns tagged as 'one implied' are displayed correctly#' 
#' @param df a NJASK data frame (output of \code{get_raw_njask})
#' school year is year '2014'.  valid values are 2004-2014.
#' @param mask a vector indicating which columns are one implied decimal?  
#' uses a layout file.  default is layout_njask
#' @export

process_njask <- function(df, mask=layout_njask$comments) {
  #keep the names to put back in the same order
  all_names <- names(df)
  
  #replace any line breaks in last column
  df$Grade <- gsub('\n', '', df$Grade, fixed = TRUE)
  
  mask_boolean <- mask == 'One implied decimal'
  #put some columns aside
  ignore <- df[, !mask_boolean]
  
  #process the columns that have an implied decimal
  processed <- df[, mask_boolean] %>%
    dplyr::mutate_each(
      dplyr::funs(implied_decimal = . / 10)  
    )
  
  #put back together 
  final <- cbind(ignore, processed)
  
  #reorder and return
  final %>%
    select(
      one_of(names(df))
    )
}
