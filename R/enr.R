#' @title read a zipped excel fall enrollment file from the NJ state website
#' 
#' @description
#' \code{get_raw_enr} returns a data frame with a year's worth of fall school and 
#' grade level enrollment data.
#' @param end_year a school year.  year is the end of the academic year - eg 2006-07
#' school year is year '2007'.  valid values are 1999-2015.
#' @export

get_raw_enr <- function(end_year) {
  #build url
  enr_url <- paste0(
    "http://www.nj.gov/education/data/enr/enr", substr(end_year, 3, 4), "/enr.zip"
  )
    
  #download and unzip
  tname <- tempfile(pattern = "enr", tmpdir = tempdir(), fileext = ".zip")
  tdir <- tempdir()
  
  downloader::download(enr_url, dest=tname, mode="wb") 

  utils::unzip(tname, exdir = tdir)
  
  #read file
  enr_files <- utils::unzip(tname, exdir = ".", list = TRUE)
  
  if (grepl('.xls', tolower(enr_files$Name[1]))) {
    enr <- readxl::read_excel(paste0(tdir,'\\',enr_files$Name[1]))
  } else if (grepl('.csv', tolower(enr_files$Name[1]))) {
    enr <- readr::read_csv(paste0(tdir,'\\',enr_files$Name[1]))
  }
  
  return(enr)
}
