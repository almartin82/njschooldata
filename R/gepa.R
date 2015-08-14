#' @title read a fixed width, raw GEPA data file from the NJ state website
#' 
#' @description
#' \code{get_raw_gepa} builds a url and uses readr's \code{read_fwf} to get the fixed 
#' width text file into a R data frame
#' @param end_year a school year.  end_year is the end of the academic year - eg 2006-07
#' school year is end_year '2007'.  valid values are 2004-2007.
#' @param layout what layout dataframe to use.  default is layout_gepa.
#' @export

get_raw_gepa <- function(end_year, layout=layout_gepa) {
    
  #url paths changed in 2012
  years <- list(
    "2007" = "2008", "2006" = "2007", "2005" = "2006", "2004" = "2005"
  )
  parsed_year <- years[[as.character(end_year)]]
  
  filename <- list(
    "2007" = "state_summary.txt", "2006" = "state_summary.txt",
    "2005" = "2005njgepa_state_summary.txt", "2004" = "gepa04state_summary.txt"   
  )
  parsed_filename <- filename[[as.character(end_year)]]

  #build url
  target_url <- paste0(
    "http://www.state.nj.us/education/schools/achievement/", parsed_year, 
    "/gepa/", parsed_filename
  )
  
  df <- common_fwf_req(target_url, layout)

  #return df
  return(df)
}


#' @title gets and processes a GEPA file
#' 
#' @description
#' \code{fetch_gepa} is a wrapper around \code{get_raw_gepa} and
#' \code{process_nj_assess} that passes the correct file layout data to each function,
#' given a end_year and grade.   
#' @param end_year a school end_year.  end_year is the end of the academic year - eg 2006-07
#' school year is end_year '2007'.  valid values are 2004-2007.
#' @export

fetch_gepa <- function(end_year) {
  if (end_year == 2007) {
    gepa_df <- get_raw_gepa(end_year, layout = layout_gepa) %>% 
      process_nj_assess(layout = layout_gepa) 
  } else if (end_year == 2006) {
    gepa_df <- get_raw_gepa(end_year, layout = layout_gepa06) %>% 
      process_nj_assess(layout = layout_gepa06)
  } else if (end_year == 2005) {
    gepa_df <- get_raw_gepa(end_year, layout = layout_gepa05) %>% 
      process_nj_assess(layout = layout_gepa05) 
  } else if (end_year == 2004) {
    gepa_df <- get_raw_gepa(end_year, layout = layout_njask04[1:361,]) %>% 
      process_nj_assess(layout = layout_njask04[1:361,]) 
  }  
  
  #some gepa files dont list test year.
  if (!c('Test_Year', 'Testing_Year') %in% names(gepa_df) %>% any()) {
    gepa_df$Testing_Year <- end_year
  }  
  #or grade level...
  if (!c('Grade', 'Grade_Level') %in% names(gepa_df) %>% any()) {
    gepa_df$Grade <- 8
  }  
    
  return(gepa_df)
}
