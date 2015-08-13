#' @title read a fixed width, raw HSPA data file from the NJ state website
#' 
#' @description
#' \code{get_raw_hspa} builds a url and uses readr's \code{read_fwf} to get the fixed 
#' width text file into a R data frame
#' @param end_year a school end_year.  end_year is the end of the academic year - eg 2013-14
#' school year is end_year '2014'.  valid values are 2004-2014.
#' @param layout what layout dataframe to use.  default is layout_hspa.
#' @export

get_raw_hspa <- function(end_year, layout=layout_hspa[c(1:558), ]) {    
  #url paths changed in 2012
  years <- list(
    "2014"="14", "2013"="13", "2012"="2013", "2011"="2012", "2010"="2011", "2009"="2010", 
    "2008"="2009", "2007"="2008", "2006"="2007", "2005"="2006", "2004"="2005"
  )
  parsed_year <- years[[as.character(end_year)]]
  
  #filenames are screwy
  parsed_filename <- if(end_year > 2005) {
    "state_summary.txt"
  } else if (end_year == 2005) {
    "2005hspa_state_summary.txt" 
  } else if (end_year == 2004) {
    "hspa04state_summary.txt"
  }
      
  #build url
  target_url <- paste0(
    "http://www.state.nj.us/education/schools/achievement/", parsed_year, 
    "/hspa/", parsed_filename
  )
  
  #read_fwf
  df <- readr::read_fwf(
    file = target_url,
    col_positions = readr::fwf_positions(
      start = layout$field_start_position,
      end = layout$field_end_position,
      col_names = layout$final_name
    ),
    col_types = nj_coltype_parser(layout$data_type),
    na = "*"
  )
  
  #return df
  return(df)
}



#' @title gets and processes a HSPA file
#' 
#' @description
#' \code{fetch_njask} is a wrapper around \code{get_raw_hspa} and
#' \code{process_nj_assess} that passes the correct file layout data to each function,
#' given a end_year and grade.   
#' @param end_year a school end_year.  end_year is the end of the academic year - eg 2013-14
#' school year is end_year '2014'.  valid values are 2004-2014.
#' @export

fetch_hspa <- function(end_year) {
  if (end_year > 2011) {
    hspa_df <- get_raw_hspa(end_year) %>% 
      #posted hspa layout has an error
      process_nj_assess(layout = layout_hspa[c(1:558), ])
  } else if (end_year > 2006) {
    hspa_df <- get_raw_hspa(end_year, layout = layout_hspa10) %>% 
      process_nj_assess(layout = layout_hspa10)
  } else if (end_year == 2006) {
    hspa_df <- get_raw_hspa(end_year, layout = layout_hspa06) %>% 
      process_nj_assess(layout = layout_hspa06)     
  } else if (end_year == 2005) {
    hspa_df <- get_raw_hspa(end_year, layout = layout_hspa05) %>% 
      process_nj_assess(layout = layout_hspa05)     
  } else if (end_year == 2004) {
    hspa_df <- get_raw_hspa(end_year, layout = layout_hspa04) %>% 
      process_nj_assess(layout = layout_hspa04)     
  }
  
  hspa_df$Grade <- 11
  
  #some hspa files dont have test year.
  if (!c('Test_Year', 'Testing_Year') %in% names(hspa_df) %>% any()) {
    hspa_df$Testing_Year <- end_year
  }
  
  return(hspa_df)
}
