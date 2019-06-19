#' @title reads the raw PARCC excel files from the state website
#' 
#' @description
#' \code{get_raw_parcc} builds a url and reads the xlsx file into a dataframe
#' 
#' @param end_year a school year.  end_year is the end of the academic year - eg 2014-15
#' school year is end_year 2015.  valid values are 2015-2017
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
    #in 2018 - honestly I just can't.  
    # fine, state of NJ, ELA003. it's only broken code, not life and death, as they say.
    if (end_year == 2018 & subj == 'ela') {
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
  parcc <- readxl::read_excel(path = tname, skip = 2, na = '*', guess_max = 30000)
  
  #last two rows are notes
  parcc <- parcc[1:(nrow(parcc)-2), ]
  parcc
}


#' PARCC column order
#'
#' @param df tidied PARCC dataframe.  called as final step in fetch_parcc when tidy=TRUE
#'
#' @return PARCC df with columns in coherent order
#' @export

parcc_column_order <- function(df) {
  df %>% 
    select(
      testing_year,
      assess_name, 
      test_name,
      grade,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      dfg,
      subgroup, subgroup_type,
      number_enrolled, number_not_tested, 
      number_of_valid_scale_scores,
      scale_score_mean,
      pct_l1, pct_l2, pct_l3, pct_l4, pct_l5,
      num_l1, num_l2, num_l3, num_l4, num_l5,
      is_state, is_dfg, 
      is_district, is_school, is_charter,
      is_charter_sector,
      is_allpublic
    )
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
  
  #remove random NA row that has the year and grade only
  parcc_file <- parcc_file %>% filter(!is.na(county_code))
  
  #tag subsets
  parcc_file$is_state <- parcc_file$county_code == 'STATE'
  parcc_file$is_dfg <- parcc_file$county_code == 'DFG'
  parcc_file$is_district = is.na(parcc_file$school_code) & !is.na(parcc_file$district_code)
  parcc_file$is_school = !is.na(parcc_file$school_code)
  parcc_file$is_charter = parcc_file$county_code == '80'

  parcc_file$is_charter_sector <- FALSE
  parcc_file$is_allpublic <- FALSE
  
  # use district_id, etc
  parcc_file <- parcc_file %>%
    rename(
      county_id = county_code,
      district_id = district_code,
      school_id = school_code
    )
  
  # level counts
  parcc_file <- parcc_perf_level_counts(parcc_file)
  
  # column order
  parcc_column_order(parcc_file)
}


#' tidy parcc subgroup
#'
#' @param sv subgroup column from parcc data file
#'
#' @return character vector with consistent subgroup names
#' @export

tidy_parcc_subgroup <- function(sv) {
  
  # 2018 is all proper case
  sv <- toupper(sv)
  
  sv <- gsub("ALL STUDENTS", 'total_population', sv, fixed = TRUE)
  
  sv <- gsub('WHITE', 'white', sv, fixed = TRUE)
  sv <- gsub('AFRICAN AMERICAN', 'black', sv, fixed = TRUE)
  sv <- gsub('ASIAN', 'asian', sv, fixed = TRUE)
  sv <- gsub('HISPANIC', 'hispanic', sv, fixed = TRUE)
  sv <- gsub(
    'NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER|NATIVE HAWAIIAN', 'pacific_islander', 
    sv, fixed = FALSE
  )
  sv <- gsub('AMERICAN INDIAN', 'american_indian', sv, fixed = TRUE)
  sv <- gsub('OTHER', 'other', sv, fixed = TRUE)
  
  sv <- gsub('FEMALE', 'female', sv, fixed = TRUE)
  sv <- gsub('MALE', 'male', sv, fixed = TRUE)
  
  sv <- gsub(
    "STUDENTS WITH DISABLITIES|STUDENTS WITH DISABILITIES", 'special_education', 
    sv, fixed = FALSE
  )
  sv <- gsub("SE ACCOMMODATION", 'sped_accomodations', sv, fixed = TRUE)
  
  sv <- gsub('ECONOMICALLY DISADVANTAGED', 'ed', sv, fixed = TRUE)
  sv <- gsub(
    'NON ECON. DISADVANTAGED|NON-ECON. DISADVANTAGED', 'non_ed', sv, fixed = FALSE
  )
  
  sv <- gsub('ENGLISH LANGUAGE LEARNERS', 'lep_current_former', sv, fixed = TRUE)
  sv <- gsub('CURRENT - ELL', 'lep_current', sv, fixed = TRUE)
  sv <- gsub('FORMER - ELL', 'lep_former', sv, fixed = TRUE)
  
  sv <- gsub('GRADE - other', 'grade_other', sv, fixed = TRUE)
  sv <- gsub('GRADE - 06', 'grade_06', sv, fixed = TRUE)
  sv <- gsub('GRADE - 07', 'grade_07', sv, fixed = TRUE)
  sv <- gsub('GRADE - 08', 'grade_08', sv, fixed = TRUE)
  sv <- gsub('GRADE - 09', 'grade_09', sv, fixed = TRUE)
  sv <- gsub('GRADE - 10', 'grade_10', sv, fixed = TRUE)
  sv <- gsub('GRADE - 11', 'grade_11', sv, fixed = TRUE)
  sv <- gsub('GRADE - 12', 'grade_12', sv, fixed = TRUE)
  
  
  sv
}

#' @title gets and cleans up a PARCC data file file
#' 
#' @description
#' \code{fetch_parcc} is a wrapper around \code{get_raw_parcc} and
#' \code{process_parcc} that gets a parcc file and performs any cleanup.
#' @param tidy clean up the data frame to make it more compatible with 
#' NJASK naming conventions and do some additional calculations?  default is FALSE.
#' @inheritParams get_raw_parcc
#' @export

fetch_parcc <- function(end_year, grade_or_subj, subj, tidy = FALSE) {

  p <- get_raw_parcc(end_year, grade_or_subj, subj)
  p <- process_parcc(p, end_year, grade_or_subj, subj)
  
  if (tidy) {
    p$subgroup <- tidy_parcc_subgroup(p$subgroup)
    
    p <- p %>% parcc_perf_level_counts()
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
  
  for (i in c(2015:2018)) {
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
