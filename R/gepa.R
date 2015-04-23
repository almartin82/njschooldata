#' @title read a fixed width, raw GEPA data file from the NJ state website
#' 
#' @description
#' \code{get_raw_gepa} builds a url and uses readr's \code{read_fwf} to get the fixed 
#' width text file into a R data frame
#' @param year a school year.  year is the end of the academic year - eg 2006-07
#' school year is year '2007'.  valid values are 2004-2007.
#' @param layout what layout dataframe to use.  default is layout_gepa.
#' @export

get_raw_gepa <- function(year, layout=layout_gepa) {
    
  #url paths changed in 2012
  years <- list(
    "2007"="2008", "2006"="2007", "2005"="2006", "2004"="2005"
  )
  parsed_year <- years[[as.character(year)]]
  
  filename <- list(
    "2007"="state_summary.txt", "2006"="state_summary.txt",
    "2005"="2005njgepa_state_summary.txt", "2004"="gepa04state_summary.txt"   
  )
  parsed_filename <- filename[[as.character(year)]]

  #build url
  target_url <- paste0(
    "http://www.state.nj.us/education/schools/achievement/", parsed_year, 
    "/gepa/", parsed_filename
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


#' @title gets and processes a GEPA file
#' 
#' @description
#' \code{fetch_gepa} is a wrapper around \code{get_raw_gepa} and
#' \code{process_nj_assess} that passes the correct file layout data to each function,
#' given a year and grade.   
#' @param year a school year.  year is the end of the academic year - eg 2006-07
#' school year is year '2007'.  valid values are 2004-2007.
#' @export

fetch_gepa <- function(year) {
  get_raw_gepa(year) %>% 
    process_nj_assess(layout=layout_gepa) 
}
