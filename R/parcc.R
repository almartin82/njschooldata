#' @title reads the raw PARCC excel files from the state website
#' 
#' @description
#' \code{get_raw_parcc} builds a url and reads the xlsx file into a dataframe
#' 
#' @param end_year a school year.  end_year is the end of the academic year - eg 2014-15
#' school year is end_year '2015'.  valid values are 2015
#' @param grade_or_subj grade level (eg 8) OR math subject code (eg ALG1, GEO, ALG2)
#' @param subj PARCC subject. c('ela' or 'math')
#' @param layout what layout dataframe to use.  default is layout_njask.
#' @export

get_raw_parcc <- function(end_year, grade_or_subj, subj) {  
  
  if (is.numeric(grade_or_subj)) {
    parcc_grade <- pad_grade(grade_or_subj)
    
    #in 2017 they forgot how grade levels work
    if (end_year == 2017 & grade_or_subj >= 10) {
      parcc_grade <- paste0('0', parcc_grade)
    }
  } else {
    parcc_grade <- grade_or_subj
  }
  
  stem <- 'http://www.nj.gov/education/schools/achievement/'
  
  #after 2016 they
  #added a spring / fall element
  #eg http://www.nj.gov/education/schools/achievement/16/parcc/spring/ELA03.xlsx
  #we're pulling spring only (for now)
  season_variant <- if (end_year >= 2016) {
    'spring/'
  } else {
    ''
  }
  
  
  target_url <- paste0(
    stem, substr(end_year, 3, 4), '/parcc/', season_variant,
      parse_parcc_subj(subj), parcc_grade, '.xlsx' 
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
  
  #clean columns
  parcc_file$county_code <- clean_id(parcc_file$county_code)
  parcc_file$district_code <- clean_id(parcc_file$district_code)
  parcc_file$school_code <- clean_id(parcc_file$school_code)
  
  #make some numeric
  parcc_file$number_enrolled <- as.numeric(parcc_file$number_enrolled)
  parcc_file$number_not_tested <- as.numeric(parcc_file$number_not_tested)
  parcc_file$number_of_valid_scale_scores <- as.numeric(parcc_file$number_of_valid_scale_scores)
  parcc_file$pct_l1 <- as.numeric(parcc_file$pct_l1)
  parcc_file$pct_l2 <- as.numeric(parcc_file$pct_l2)
  parcc_file$pct_l3 <- as.numeric(parcc_file$pct_l3)
  parcc_file$pct_l4 <- as.numeric(parcc_file$pct_l4)
  parcc_file$pct_l5 <- as.numeric(parcc_file$pct_l5)
  
  #new columns
  parcc_file$testing_year <- end_year
  parcc_file$assess_name <- 'PARCC'
  parcc_file$grade <- as.character(grade)
  parcc_file$test_name <- subj
  
  #tag district or school
  parcc_file$district_school <- NA
  parcc_file$district_school <- ifelse(
    is.na(parcc_file$school_code) & !is.na(parcc_file$district_code),
    'district', parcc_file$district_school
  )
  parcc_file$district_school <- ifelse(
    !is.na(parcc_file$school_code) & !is.na(parcc_file$district_code),
    'school', parcc_file$district_school
  )
  
  parcc_file
}


#' tidy parcc subgroup
#'
#' @param subgroup_vector subgroup column from parcc data file
#'
#' @return character vector with consistent subgroup names
#' @export

tidy_parcc_subgroup <- function(subgroup_vector) {
  
  subgroup_vector <- gsub("ALL STUDENTS", 'total_population', subgroup_vector, fixed = TRUE)
  
  subgroup_vector <- gsub('WHITE', 'white', subgroup_vector, fixed = TRUE)
  subgroup_vector <- gsub('AFRICAN AMERICAN', 'black', subgroup_vector, fixed = TRUE)
  subgroup_vector <- gsub('ASIAN', 'asian', subgroup_vector, fixed = TRUE)
  subgroup_vector <- gsub('HISPANIC', 'hispanic', subgroup_vector, fixed = TRUE)
  subgroup_vector <- gsub(
    'NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER|NATIVE HAWAIIAN', 'pacific_islander', 
    subgroup_vector, fixed = FALSE
  )
  subgroup_vector <- gsub('AMERICAN INDIAN', 'american_indian', subgroup_vector, fixed = TRUE)
  subgroup_vector <- gsub('OTHER', 'other', subgroup_vector, fixed = TRUE)
  
  subgroup_vector <- gsub('FEMALE', 'female', subgroup_vector, fixed = TRUE)
  subgroup_vector <- gsub('MALE', 'male', subgroup_vector, fixed = TRUE)
  
  subgroup_vector <- gsub(
    "STUDENTS WITH DISABLITIES|STUDENTS WITH DISABILITIES", 'special_education', 
    subgroup_vector, fixed = FALSE
  )
  subgroup_vector <- gsub("SE ACCOMMODATION", 'sped_accomodations', subgroup_vector, fixed = TRUE)
  
  subgroup_vector <- gsub('ECONOMICALLY DISADVANTAGED', 'ed', subgroup_vector, fixed = TRUE)
  subgroup_vector <- gsub(
    'NON ECON. DISADVANTAGED|NON-ECON. DISADVANTAGED', 'non_ed', subgroup_vector, fixed = FALSE
  )
  
  subgroup_vector <- gsub('ENGLISH LANGUAGE LEARNERS', 'lep_current_former', subgroup_vector, fixed = TRUE)
  subgroup_vector <- gsub('CURRENT - ELL', 'lep_current', subgroup_vector, fixed = TRUE)
  subgroup_vector <- gsub('FORMER - ELL', 'lep_former', subgroup_vector, fixed = TRUE)
  
  subgroup_vector <- gsub('GRADE - other', 'grade_other', subgroup_vector, fixed = TRUE)
  subgroup_vector <- gsub('GRADE - 06', 'grade_06', subgroup_vector, fixed = TRUE)
  subgroup_vector <- gsub('GRADE - 07', 'grade_07', subgroup_vector, fixed = TRUE)
  subgroup_vector <- gsub('GRADE - 08', 'grade_08', subgroup_vector, fixed = TRUE)
  subgroup_vector <- gsub('GRADE - 09', 'grade_09', subgroup_vector, fixed = TRUE)
  subgroup_vector <- gsub('GRADE - 10', 'grade_10', subgroup_vector, fixed = TRUE)
  subgroup_vector <- gsub('GRADE - 11', 'grade_11', subgroup_vector, fixed = TRUE)
  subgroup_vector <- gsub('GRADE - 12', 'grade_12', subgroup_vector, fixed = TRUE)
  
  
  subgroup_vector
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

fetch_parcc <- function(end_year, grade_or_subj, subj, tidy = FALSE) {

  p <- get_raw_parcc(end_year, grade_or_subj, subj)
  p <- process_parcc(p, end_year, grade_or_subj, subj)
  
  if (tidy) {
    p$subgroup <- tidy_parcc_subgroup(p$subgroup)
  }
  
  p
}


#' Fetch all PARCC results
#'
#' @description convenience function to download and combine all PARCC results
#' into single data frame
#' 
#' @return a data frame with all PARCC results
#' @export

fetch_all_parcc <- function() {
  
  parcc_results <- list()
  
  for (i in c(2015:2017)) {
    #normal grade level tests
    for (j in c(3:8)) {
      for (k in c('ela', 'math')) {
      
        p <- fetch_parcc(end_year = i, grade_or_subj = j, subj = k, tidy = TRUE)
        
        parcc_results[[paste(i, j, k, sep = '_')]] <- p
        
      }
    }
    #hs ela
    for (j in c(9:11)) {
      p <- fetch_parcc(end_year = i, grade_or_subj = j, subj = 'ela', tidy = TRUE)
      
      parcc_results[[paste(i, j, 'ela', sep = '_')]] <- p
    }
    
    #specific math tests
    for (j in c('ALG1', 'GEO', 'ALG2')) {
      p <- fetch_parcc(end_year = i, grade_or_subj = j, subj = 'math', tidy = TRUE)
      
      parcc_results[[paste(i, j, 'math', sep = '_')]] <- p
    }
  }
  
  dplyr::bind_rows(parcc_results)
}
