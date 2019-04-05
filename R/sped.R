#' read Special Ed. excel files from the NJ state website
#'
#' @inheritParams get_raw_enr 
#'
#' @return a dataframe with special ed counts, etc.
#' @export


get_raw_sped <- function(end_year) {
  
  #build url
  if (end_year %in% c(2002:2013)) enr_url <- paste0(
    "http://www.nj.gov/education/specialed/data/ADR/", end_year -1, "/classification/distclassification.xls"
  )
  
  if (end_year %in% c(2014)) enr_url <- paste0(
    "http://www.nj.gov/education/specialed/data/", end_year -1, "/District_Classification_Rate.xlsx"
  )
  
  if (end_year %in% c(2015)) enr_url <- paste0(
    "http://www.nj.gov/education/specialed/data/", end_year -1, "/LEA_Classification.xlsx"
  )
  
  
  if (end_year %in% c(2016)) enr_url <- paste0(
    "http://www.nj.gov/education/specialed/data/", end_year -1, "/LEA_Classificatiom.xlsx"
  )
  
  
  if (end_year >= 2014)  rows.to.skip <- 4
  if (end_year < 2014 & end_year >= 2008)  rows.to.skip <- 5
  if (end_year < 2008 & end_year > 2006)  rows.to.skip <- 8
  if (end_year <= 2006)  rows.to.skip <- 7
  
  url1 <- enr_url
  tf <- tempfile()
  
  download.file ( url1 , tf , mode = 'wb' )
  
  if (grepl('.xlsx', url1)) {
    invisible(file.rename( tf , paste0( tf , ".xlsx" ) ))
    
    # GET(url1, write_disk(tf <- tempfile(fileext = ".xlsx")))
    enr <- readxl::read_excel(paste0( tf , ".xlsx" ),  skip = rows.to.skip)
  } else {
    invisible(file.rename( tf , paste0( tf , ".xls" ) ))
    
    # GET(url1, write_disk(tf <- tempfile(fileext = ".xlsx")))
    enr <- readxl::read_excel(paste0( tf , ".xls" ),  skip = rows.to.skip)
  }
  
  enr$end_year <- end_year
  
  return(enr)
}
