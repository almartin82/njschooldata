#' @title read a zipped excel fall enrollment file from the NJ state website
#' 
#' @description
#' \code{get_raw_enr} returns a data frame with a year's worth of fall school and 
#' grade level enrollment data.
#' @param start_year a school year.  year is the start of the academic year - eg 2006-07
#' school year is year '2006'.  valid values are 1998-2015.
#' @export

get_raw_enr <- function(start_year) {
  #build url
  url <- paste0(
    "http://www.nj.gov/education/data/enr/enr", substr(start_year, 3, 4), "/enr.zip"
  )
    
  #download and unzip
  tname <- tempfile(pattern = "enr", tmpdir = tempdir(), fileext = ".zip")
  tdir <- tempdir()
  
  downloader::download(url, dest=tname, mode="wb") 

  utils::unzip(tname, exdir = tdir)
  
  #read excel
  enr_files <- utils::unzip(tname, exdir = ".", list = TRUE)
  enr <- readxl::read_excel(paste0(tdir,'\\',enr_files$Name[1]))
  
  return(enr)
}
