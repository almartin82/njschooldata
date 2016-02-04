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
  target_url <- paste0(
    stem, substr(end_year, 3, 4), '/parcc/', 
      parse_parcc_subj(subj), pad_grade(grade), '.xlsx' 
  )
  
  tname <- tempfile(pattern = "parcc", tmpdir = tempdir(), fileext = ".xlsx")
  tdir <- tempdir()
  downloader::download(target_url, destfile = tname, mode = "wb") 
  parcc <- readxl::read_excel(path = tname, skip = 2)
  
  #last two rows are notes
  parcc <- parcc[1:(nrow(parcc)-2), ]
  parcc
}


process_parcc <- function(parcc_file, end_year, grade, subj) {
  
  names(parcc_file) <- c(
    "county_code", "county_name", "district_code", "district_name", 
    "school_code", "school_name", "dfg", "subgroup", "subgroup_type", 
    "number_enrolled", "number_not_tested", "number_of_valid_scale_scores", 
    "scale_score_mean", "pct_l1", "pct_l2", "pct_l3", 
    "pct_l4", "pct_l5"
  )
  
  parcc_file$testing_year <- end_year
  parcc_file$assess_name <- 'PARCC'
  parcc_file$grade <- grade
  parcc_file$test_name <- subj
  
  parcc_file
}


#' @title gets and cleans up a PARCC data file file
#' 
#' @description
#' \code{fetch_parcc} is a wrapper around \code{get_raw_parcc} and
#' \code{process_parcc} that gets a parcc file and performs any celanup.  
#' @inheritParams get_raw_parcc
#' @export

fetch_parcc <- function(end_year, grade, subj) {
  p <- get_raw_parcc(end_year, grade, subj)
  p <- process_parcc(p, end_year, grade, subj)
  
  p
}
