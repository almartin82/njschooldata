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
  
  tname <- tempfile(pattern = 'parcc', tmpdir = tempdir(), fileext = '.xlsx')
  tdir <- tempdir()
  downloader::download(target_url, destfile = tname, mode = 'wb') 
  parcc <- readxl::read_excel(path = tname, skip = 2, na = '*')
  
  #last two rows are notes
  parcc <- parcc[1:(nrow(parcc)-2), ]
  parcc
}


#' Process a raw PARCC data file
#' 
#' @description all the logic needed to clean up the raw PARCC files
#'
#' @param parcc_file output of get_raw_parcc
#' @inheritParams get_raw_parcc
#'
#' @return a tbl_df / data rame
#' @export

process_parcc <- function(parcc_file, end_year, grade, subj) {
  
  names(parcc_file) <- c(
    'county_code', 'county_name', 'district_code', 'district_name', 
    'school_code', 'school_name', 'dfg', 'subgroup', 'subgroup_type', 
    'number_enrolled', 'number_not_tested', 'number_of_valid_scale_scores', 
    'scale_score_mean', 'pct_l1', 'pct_l2', 'pct_l3', 
    'pct_l4', 'pct_l5'
  )
  #subgroup and subgroup type appear to be flipped
  orig_subgroup_type <- parcc_file$subgroup_type
  orig_subgroup <- parcc_file$subgroup
  parcc_file$subgroup <- orig_subgroup_type
  parcc_file$subgroup_type <- orig_subgroup_type
  
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
#' \code{process_parcc} that gets a parcc file and performs any cleanup.
#' @param tidy clean up the data frame to make it more compatible with 
#' NJASK naming conventions?  default is FALSE.
#' @inheritParams get_raw_parcc
#' @export

fetch_parcc <- function(end_year, grade, subj, tidy = FALSE) {
  p <- get_raw_parcc(end_year, grade, subj)
  p <- process_parcc(p, end_year, grade, subj)
  
  if (tidy) {
    p$subgroup <- gsub("ALL STUDENTS", 'total_population', p$subgroup, fixed = TRUE)

    p$subgroup <- gsub('WHITE', 'white', p$subgroup, fixed = TRUE)
    p$subgroup <- gsub('AFRICAN AMERICAN', 'black', p$subgroup, fixed = TRUE)
    p$subgroup <- gsub('ASIAN', 'asian', p$subgroup, fixed = TRUE)
    p$subgroup <- gsub('HISPANIC', 'hispanic', p$subgroup, fixed = TRUE)
    p$subgroup <- gsub(
      'NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER', 'pacific_islander', 
      p$subgroup, fixed = TRUE
    )
    p$subgroup <- gsub('AMERICAN INDIAN', 'american_indian', p$subgroup, fixed = TRUE)
    p$subgroup <- gsub('OTHER', 'other', p$subgroup, fixed = TRUE)

    p$subgroup <- gsub('FEMALE', 'female', p$subgroup, fixed = TRUE)
    p$subgroup <- gsub('MALE', 'male', p$subgroup, fixed = TRUE)
    
    p$subgroup <- gsub("STUDENTS WITH DISABLITIES", 'special_education', p$subgroup, fixed = TRUE)

    p$subgroup <- gsub('ECONOMICALLY DISADVANTAGED', 'ed', p$subgroup, fixed = TRUE)
    p$subgroup <- gsub('NON ECON. DISADVANTAGED', 'non_ed', p$subgroup, fixed = TRUE)
    p$subgroup <- gsub('ENGLISH LANGUAGE LEARNERS', 'lep_current_former', p$subgroup, fixed = TRUE)
    p$subgroup <- gsub('CURRENT - ELL', 'lep_current', p$subgroup, fixed = TRUE)
    p$subgroup <- gsub('FORMER - ELL', 'lep_former', p$subgroup, fixed = TRUE)
  }
  
  p
}


fetch_all_parcc <- function() {
  parcc_results <- list()
  
  for (i in c(2015)) {
    for (j in c(3:8)) {
      for (k in c('ela', 'math')) {
      
        p <- fetch_parcc(end_year = i, grade = j, subj = k, tidy = TRUE)
        
        parcc_results[[paste(i, j, k, sep = '_')]] <- p
        
      }
    }
  }
  
  dplyr::bind_rows(parcc_results)
}
