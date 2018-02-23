
#' Get Raw Report Card Database
#'
#' @param end_year a school year.  end_year is the end of the academic year - eg 2014-15
#' school year is end_year '2015'.  valid values are 2003 to 2017
#'
#' @return list of data frames
#' @export

get_one_rc_database <- function(end_year) {
  
  pr_urls <- list(
    "2017" = "https://rc.doe.state.nj.us/ReportsDatabase/PerformanceReports.xlsx",
    "2016" = "https://rc.doe.state.nj.us/ReportsDatabase/15-16/PerformanceReports.xlsx",
    "2015" = "http://www.nj.gov/education/pr/1415/database/2015PRDATABASE.xlsx",
    "2014" = "http://www.nj.gov/education/pr/1314/database/2014%20performance%20report%20database.xlsx",
    "2013" = "http://www.nj.gov/education/pr/1213/database/nj%20pr13%20database.xlsx",
    "2012" = "http://www.nj.gov/education/pr/2013/database/nj%20pr12%20database.xlsx",
    "2011" = "http://www.nj.gov/education/reportcard/2011/database/RC11%20database.xls",
    "2010" = "http://www.nj.gov/education/reportcard/2010/database/RC10%20database.xls",
    "2009" = "http://www.nj.gov/education/reportcard/2009/database/RC09%20database.xls",
    "2008" = "http://www.nj.gov/education/reportcard/2008/database/nj_rc08.xls",
    "2007" = "http://www.nj.gov/education/reportcard/2007/database/nj_rc07.xls",
    "2006" = "http://www.nj.gov/education/reportcard/2006/database/nj_rc06_data.xls",
    "2005" = "http://www.nj.gov/education/reportcard/2005/database/NJ_RC05_DATA.XLS",
    "2004" = "http://www.nj.gov/education/reportcard/2004/database/nj_rc04_data.xls",
    "2003" = "http://www.nj.gov/education/reportcard/2003/database/nj_rc03_data.xls"
  )
  
  #temp file for downloading
  file_exts <- c(
    rep('xlsx', 6),
    rep('xls', 9)
  )
  tmp_pr = tempfile(fileext = paste0('.', file_exts[1 + (2017-end_year)]))
  
  #download to temp
  download.file(url = pr_urls[[as.character(end_year)]], destfile = tmp_pr, mode = "wb")
  
  #get the sheet names
  sheets_pr <- readxl::excel_sheets(tmp_pr) %>%
    clean_name_vector()
  
  #get all the data.frames as list
  pr_list <- map(
    .x = c(1:length(sheets_pr)),
    .f = function(.x) {
      readxl::read_excel(tmp_pr, sheet = .x) %>%
        mutate(end_year = end_year) %>%
        janitor::clean_names()
    }
  )
  
  #rename each pr
  names(pr_list) <- sheets_pr
  
  pr_list
}


#' Get multiple RC databases
#'
#' @param end_year_vector vector of years.  Current valid values are 2003 to 2017. 
#'
#' @return a list of dataframes
#' @export

get_rc_databases <- function(end_year_vector = c(2003:2017)) {

  all_prs <- map(
    .x = end_year_vector,
    .f = function(.x) {
      print(.x)
      get_one_rc_database(.x)
    }
  )
  
  names(all_prs) <- end_year_vector
  
  all_prs
}


#' Extract Report Car SAT School Averages
#'
#' @param list_of_prs output of get_rc_databases (ie, a list where each element is)
#' a list of data.frames
#' @param school_only some years have district average results, not just school-level. 
#' if school_only, return only school data.  default is TRUE
#'
#' @return data frame with all years of SAT School Averages present in the input
#' @export

extract_rc_SAT <- function(list_of_prs, school_only = TRUE) {
  
  all_sat <- map(
    .x = list_of_prs,
    .f = function(.x) {
      #finds tables that have SAT data
      sat_tables <- grep('sat', names(.x), value = TRUE) 
      #excludes some tables in years where multiple tables match 'sat'
      sat_tables <- sat_tables[!grepl("participation|1550", sat_tables)]
      df <- .x %>% extract2(sat_tables)
      
      #reshapes the data for some years where it was reported in 'long' format
      if ('test' %in% names(df)) {
        
        names(df) <- gsub('school_avg', 'school_mean', names(df))
        names(df) <- gsub('bt_pct|schoolwide_benchmark', 'school_benchmark', names(df))
        
        df <- df %>%
          filter(test == 'SAT')
        
        df$subject <- gsub('Math', 'math', df$subject)
        df$subject <- gsub('Reading and Writing', 'reading', df$subject)
        
        df <- df %>%
          select(county_code, district_code, school_code, 
                 end_year, test, subject, school_mean)
        
        df <- reshape2::dcast(
          df, 
          county_code + district_code + school_code + end_year + test ~ subject,
          value.var = 'school_mean'
        )
      }
      
      df <- clean_cds_fields(df)
      
      #2 digit years to 4 digit YYYY years
      if ('year' %in% names(df)) {
        df <- rc_year_matcher(df)
      }
      
      #filters out district results and only returns schools
      if ('level' %in% names(df) & school_only) {
        df <- df %>% filter(level == 'S')  
      }
      
      #cleans variable names
      names(df) <- gsub('mmean|mathematics', 'math', names(df))
      names(df) <- gsub('vmean|critical_reading', 'reading', names(df))
      
      df <- df %>%
        select(county_code, district_code, school_code, end_year, math,
               reading)
      
      #cleans up suppression and NA codes
      df$math <- gsub('N', NA_character_, df$math, fixed = TRUE) 
      df$math <- gsub('N/A', NA_character_, df$math, fixed = TRUE) 
      df$math <- gsub('*', NA_character_, df$math, fixed = TRUE) 
      df$math <- df$math %>% as.numeric()
      
      df$reading <- gsub('N', NA_character_, df$reading, fixed = TRUE)
      df$reading <- gsub('N/A', NA_character_, df$reading, fixed = TRUE)
      df$reading <- gsub('*', NA_character_, df$reading, fixed = TRUE)
      df$reading <- df$reading %>% as.numeric()
      
      df
    }
  ) 
  
  bind_rows(all_sat)
}


#' Extract Report Card Matriculation Rates
#'
#' @inheritParams extract_pr_SAT
#' 
#' @return data frame with all the years of 4 year and 2 year college matriculation data
#' present in in the input
#' @export

extract_rc_college_matric <- function(list_of_prs, school_only = TRUE) {
  
  all_matric <- map(
    list_of_prs,
    function(.x) {
      matric_tables <- grep('postgrad|post_sec|postsecondary', names(.x), value = TRUE)
      matric_tables <- matric_tables[!grepl("16mos", matric_tables)] 
      
      #2011 didn't include postsec because :shrug:
      if (!is_empty(matric_tables)) {
        df <- .x %>% extract2(matric_tables)
      } else {
        return(NULL)
      }
      
      #pre-2010 they included longitudinal data in the table
      #filter to just the matching year
      if ('year' %in% names(df)) {
        df <- rc_year_matcher(df)
      }
      #they also reported school and district together
      if ('level' %in% names(df) & school_only) {
        df <- df %>% filter(level == 'S')  
      }
      
      df <- clean_cds_fields(df)
      
      #specific field cleaning for college matric
      names(df) <- gsub(
        'colleg4|enroll_4yr_percent|postsec_enrolled_4yr|percent_in4years|post_sec_pct|enrolled4yr|postsec_enrolled_4year|enrolled4year', 
        'enroll_4yr', names(df)
      )
      names(df) <- gsub(
        'colleg2|enroll_2yr_percent|postsec_enrolled_2yr|percent_in2years|enrolled2yr|postsec_enrolled_2year|enrolled2year',
        'enroll_2yr', names(df)
      )
      names(df) <- gsub(
        'post_sec_enrolled_percent|percent_enrolled|postsec_enrolled_percent|enrolled_percent', 
        'enroll_any', names(df)
      )
      names(df) <- gsub('sub_group|student_group', 'subgroup', names(df))
      
      #clean up messy data vectors, suppression codes, etc
      if ('enroll_any' %in% names(df)) {
        df$enroll_any <- rc_numeric_cleaner(df$enroll_any)
      }
      if ('enroll_2yr' %in% names(df)) {
        df$enroll_2yr <- rc_numeric_cleaner(df$enroll_2yr)
      }
      if ('enroll_4yr' %in% names(df)){
        df$enroll_4yr <- rc_numeric_cleaner(df$enroll_4yr)
      }
      
      #from 2015 onward enroll_4yr, enroll_2yr pct of college-going, not pct of grade
      this_year <- df$end_year %>% unique()
      if (this_year >= 2015) {
        df <- df %>%
          mutate(enroll_4yr = enroll_4yr * (enroll_any/100))
      }
      
      #if there's no subgroup field, implicitly assume that means Schoolwide
      if (!'subgroup' %in% names(df)) {
        df <- df %>%
          mutate(subgroup = 'Schoolwide')
      }
      
      #make subgroups consistent
      df$subgroup <- gsub('African American', 'Black', df$subgroup)
      
      df <- df %>%
        select(
          one_of('county_code', 'district_code', 'school_code', 
                 'end_year', 'subgroup', 'enroll_any', 'enroll_2yr', 'enroll_4yr')
        )
      
      df
    }
  )
  
  bind_rows(all_matric)
}

