
#' Get Raw Report Card Database
#'
#' @param end_year a school year.  end_year is the end of the academic year - eg 2014-15
#' school year is end_year '2015'.  valid values are 2003 to 2019
#'
#' @return list of data frames
#' @export

get_one_rc_database <- function(end_year) {
  
  if (end_year >= 2017) {
    df_list <- get_merged_rc_database(end_year)
  } else if (end_year >= 2003) {
    df_list <- get_standalone_rc_database(end_year)
  } else {
    stop('Year not covered by NJ report card data.')
  }
  
  df_list
}


#' Get Standalone Raw Report Card Database
#'
#' @param end_year a school year.  end_year is the end of the academic year - eg 2014-15
#' school year is end_year '2015'.  valid values are 2003 to 2016
#'
#' @return list of data frames

get_standalone_rc_database <- function(end_year) {
  
  pr_urls <- list(
    "2016" = "https://rc.doe.state.nj.us/ReportsDatabase/15-16/PerformanceReports.xlsx",
    "2015" = "http://www.nj.gov/education/pr/1415/database/2015PRDATABASE.xlsx",
    "2014" = "http://www.nj.gov/education/pr/1314/database/2014%20performance%20report%20database.xlsx",
    "2013" = "http://www.nj.gov/education/pr/1213/database/nj%20pr13%20database.xlsx",
    "2012" = "http://www.nj.gov/education/pr/2013/database/nj%20pr12%20database.xlsx"
    
    # 2003-2011 report cards deleted
    # "2011" = "http://www.nj.gov/education/reportcard/2011/database/RC11%20database.xls",
    # "2010" = "http://www.nj.gov/education/reportcard/2010/database/RC10%20database.xls",
    # "2009" = "http://www.nj.gov/education/reportcard/2009/database/RC09%20database.xls",
    # "2008" = "http://www.nj.gov/education/reportcard/2008/database/nj_rc08.xls",
    # "2007" = "http://www.nj.gov/education/reportcard/2007/database/nj_rc07.xls",
    # "2006" = "http://www.nj.gov/education/reportcard/2006/database/nj_rc06_data.xls",
    # "2005" = "http://www.nj.gov/education/reportcard/2005/database/NJ_RC05_DATA.XLS",
    # "2004" = "http://www.nj.gov/education/reportcard/2004/database/nj_rc04_data.xls",
    # "2003" = "http://www.nj.gov/education/reportcard/2003/database/nj_rc03_data.xls"
  )
  
  #temp file for downloading
  file_exts <- c(
    rep('xlsx', 5),
    rep('xls', 9)
  )
  tmp_pr = tempfile(fileext = paste0('.', file_exts[1 + (2016-end_year)]))
  
  pr_list <- download_and_clean_pr(tmp_pr,  pr_urls[[as.character(end_year)]], end_year)
  
  pr_list
}


#' Download and clean performance report data
#'
#' @param tmp_pr path to tempfile
#' @param url url to download
#' @param end_year report year
#'
#' @return list of dataframes

download_and_clean_pr <- function(tmp_pr, url, end_year) {
  #download to temp
  download.file(url, destfile = tmp_pr, mode = "wb")
  
  #get the sheet names
  sheets_pr <- readxl::excel_sheets(tmp_pr) %>%
    clean_name_vector()
  
  #get all the data.frames as list
  pr_list <- map(
    .x = c(1:length(sheets_pr)),
    .f = function(.x) {
      readxl::read_excel(
        tmp_pr, 
        sheet = .x,
        na = c('NA', 'N', '*', '**')
      ) %>%
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
#' @param end_year_vector vector of years.  Current valid values are 2003 to 2018. 
#'
#' @return a list of dataframes
#' @export

get_rc_databases <- function(end_year_vector = c(2003:2018)) {

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


#' Combines school and district Performance Reports for 2017-on, when two files were released.
#'
#' @param end_year end of the academic year.  Valid values are 2017, 2018, 2019
#'
#' @return list of dataframes
#' @export

get_merged_rc_database <- function(end_year) {
  
  pr_urls <- list(
    "sch_2019" = "https://rc.doe.state.nj.us/ReportsDatabase/PerformanceReports.xlsx",
    "dist_2019" = "https://rc.doe.state.nj.us/ReportsDatabase/DistrictPerformanceReports.xlsx",
    "sch_2018" = "https://rc.doe.state.nj.us/ReportsDatabase/17-18/PerformanceReports.xlsx",
    "dist_2018" = "https://rc.doe.state.nj.us/ReportsDatabase/17-18/DistrictPerformanceReports.xlsx",
    "sch_2017" = "https://rc.doe.state.nj.us/ReportsDatabase/16-17/PerformanceReports.xlsx",
    "dist_2017" = "https://rc.doe.state.nj.us/ReportsDatabase/16-17/DistrictPerformanceReports.xlsx"
  )
  
  # get district and school df
  dist <- pr_urls[[paste0('dist_', end_year)]]
  sch <- pr_urls[[paste0('sch_', end_year)]]
  
  tmp_pr1 = tempfile(fileext = 'xlsx')
  tmp_pr2 = tempfile(fileext = 'xlsx')
  dist_pr = download_and_clean_pr(tmp_pr1, dist, end_year)
  sch_pr = download_and_clean_pr(tmp_pr2, sch, end_year)
  
  # exclude bad / duplicate data
  sch_pr <- sch_pr[!names(sch_pr) %in% c('per_pupil_expenditures')]

  # tag source
  dist_pr <- map(dist_pr, ~.x %>% mutate(source_file='district'))
  sch_pr <- map(sch_pr, ~.x %>% mutate(source_file='school'))
  
  # add logical tags
  dist_pr <- map(
    dist_pr, 
    function(.x) {
      # would it be too much to ask that the same code be used for State data 
      # *inside the same file*?  It would.
      state_codes <- c('STATE', 'State')
      
      if ('district_code' %in% names(.x)) {
        .x %>%
          mutate(
            school_code = '999',
            school_name = ifelse(!district_code %in% state_codes, 'District Total', ''),
            is_district = ifelse(!district_code %in% state_codes, TRUE, FALSE),
            is_school = FALSE
          )
      } else {
        .x
      }
    }
  )
  
  sch_pr <- map(
    sch_pr, 
    function(.x) {
      if ('school_code' %in% names(.x)) {
        .x %>%
          mutate(
            is_district = FALSE,
            is_school = TRUE
          )
      } else {
        .x
      }
    }
  )
  
  # combine if match
  joint <- names(sch_pr)[names(sch_pr) %in% names(dist_pr)]
  sch_only <- names(sch_pr)[!names(sch_pr) %in% names(dist_pr)]
  dist_only <- names(dist_pr)[!names(dist_pr) %in% names(sch_pr)]
  
  combined <- map(
    joint,
    function(.x) {
      this_dist_df <- dist_pr[[.x]]
      this_sch_df <- sch_pr[[.x]]
      bindable <- compare_df_cols_same(this_dist_df, this_sch_df, verbose=FALSE)
      if (!bindable) {
        # which don't match?
        bad_cols <- compare_df_cols(
          this_dist_df, 
          this_sch_df, 
          return = 'mismatch', 
          bind_method = 'bind_rows'
        )
        # make character if not matched
        this_dist_df <- this_dist_df %>% mutate_at(bad_cols$column_name, as.character)
        this_sch_df <- this_sch_df %>% mutate_at(bad_cols$column_name, as.character)
      }
      bind_rows(this_dist_df, this_sch_df)
    }
  )
  names(combined) <- joint
  
  # only school and only dist
  sch_dfs <- map(sch_only, ~sch_pr[[.x]])
  names(sch_dfs) <- sch_only
  
  dist_dfs <- map(dist_only, ~dist_pr[[.x]])
  names(dist_dfs) <- dist_only
  
  # combine list of prs and return
  c(combined, sch_dfs, dist_dfs)
}


#' Extract Report Card SAT School Averages
#'
#' @param list_of_prs output of get_rc_databases (ie, a list where each element is)
#' a list of data.frames
#' @param school_only some years have district average results, not just school-level. 
#' if school_only, return only school data.  default is TRUE
#' @param cds_identifiers add the county, district and school name?  default is TRUE
#'
#' @return data frame with all years of SAT School Averages present in the input
#' @export

extract_rc_SAT <- function(
  list_of_prs, school_only = TRUE, cds_identifiers = TRUE
) {
  
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
  
  out <- bind_rows(all_sat)
  
  if (cds_identifiers) {
    all_cds <- extract_rc_cds(list_of_prs)
    out <- out %>%
      left_join(
        all_cds, 
        by = c('county_code', 'district_code', 'school_code', 'end_year')
      )
  }
  
  out
}


#' Extract Report Card Matriculation Rates
#'
#' @inheritParams extract_rc_SAT
#' 
#' @return data frame with all the years of 4 year and 2 year college matriculation data
#' present in in the input
#' @export

extract_rc_college_matric <- function(
  list_of_prs, school_only = TRUE, cds_identifiers = TRUE
) {
  
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
        'grad_percent|post_sec_enrolled_percent|percent_enrolled|postsec_enrolled_percent|enrolled_percent', 
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
          mutate(subgroup = 'Total Population')
      }
      
      #make subgroups consistent
      df$subgroup <- gsub('African American', 'Black', df$subgroup)
      df$subgroup <- gsub('Students with Disability', 'Students With Disabilities', df$subgroup)
      df$subgroup <- gsub('Schoolwide', 'Total Population', df$subgroup)
      df$subgroup <- gsub('Districtwide', 'Total Population', df$subgroup)
      df$subgroup <- gsub('Statewide', 'Total Population', df$subgroup)
      df$subgroup <- gsub('Limited English Proficient Students', 'English Language Learners', df$subgroup)
      
      df <- df %>%
        select(
          one_of('county_code', 'district_code', 'school_code', 
                 'end_year', 'subgroup', 'enroll_any', 'enroll_2yr', 'enroll_4yr')
        )
      
      df
    }
  )
  
  out <- bind_rows(all_matric)
  
  if (cds_identifiers) {
    all_cds <- extract_rc_cds(list_of_prs)
    out <- out %>%
      left_join(
        all_cds, 
        by = c('county_code', 'district_code', 'school_code', 'end_year')
      )
  }
  
  out %>%
    select(
      county_code, county_name,
      district_code, district_name,
      school_code, school_name,
      end_year, subgroup,
      enroll_any, enroll_4yr, enroll_2yr
    )
}


#' Extract Report Card Advanced Placement Data
#'
#' @inheritParams extract_rc_SAT
#'
#' @return data frame with all the years of AP participation and AP achievement
#' present in in the input
#' @export

extract_rc_AP <- function(list_of_prs, school_only = TRUE, cds_identifiers = TRUE) {
  
  all_ap <- map(
    list_of_prs,
    function(.x) {
      ap_sum_tables <- grep(
        'ap_sum\\b|ap_ib_sum|apib_test_performance|apib_coursework_part_perf', 
        names(.x), 
        value = TRUE
      )
      ap_tables <- grep('ap\\b|ap_ib\\b|apib_advanced_course_participation|apib_coursework_part_perf|ap03|apnew', names(.x), value = TRUE)
      
      #get the relevant table
      df <- .x %>% extract2(ap_sum_tables)
      df2 <- .x %>% extract2(ap_tables)
      
      #clean up cds fields
      df <- clean_cds_fields(df)
      
      #pre-2010 they included longitudinal data in the table
      if ('year' %in% names(df)) {
        df <- rc_year_matcher(df)
      }
      #they also reported school and district together
      if ('level' %in% names(df) & school_only) {
        df <- df %>% filter(level == 'S')  
      }
      
      #pct tested
      names(df) <- gsub(
        'pctest|perc_stud_ap_ib_score',
        'pct_tested_ap_ib', names(df)
      )
      #this data looks very different across years
      if (ap_tables == 'apib_advanced_course_participation') {
        df2 <- df2 %>% 
          filter(students_taking == 'One or More Test') %>%
          select(county_code, district_code, school_code, school_participation) %>%
          rename(
            pct_tested_ap_ib = school_participation
          )
        
        df <- df %>%
          left_join(df2, by = c('county_code', 'district_code', 'school_code'))
      }
      if (ap_tables == 'apib_coursework_part_perf') {
        df2 <- df2 %>% 
          filter(report_category == 'StudentsTakingInOneOrMoreAPorIBExam') %>%
          select(county_code, district_code, school_code, school_percent) %>%
          rename(
            pct_tested_ap_ib = school_percent
          )
        
        df <- df %>%
          left_join(df2, by = c('county_code', 'district_code', 'school_code'))
      }    
      
      #pct 3 or higher
      names(df) <- gsub(
        'perc_stud_ap_score_3_above1|ap_ib_test_score_3|perc_stud_ap_score_3_above|ap_3_ib4_4',
        'pct_ap_scoring_3', names(df)
      )
      
      if (ap_tables == 'apib_coursework_part_perf') {
        df <- df %>%
          filter(report_category == 'StudentsWithOneOrMoreExamsWithAScoreOfAtLest3AP4IBExams') %>%
          rename(
            pct_ap_scoring_3 = school_percent
          )
      }  
      
      df <- df %>%
        select(one_of(
          'county_code', 'district_code', 'school_code', 
          'pct_ap_scoring_3', 'pct_tested_ap_ib', 'end_year'
        ))
      
      if ('pct_ap_scoring_3' %in% names(df)) {
        df$pct_ap_scoring_3 <- rc_numeric_cleaner(df$pct_ap_scoring_3)
      }
      
      if ('pct_tested_ap_ib' %in% names(df)) {
        df$pct_tested_ap_ib <- rc_numeric_cleaner(df$pct_tested_ap_ib)
      }
      
      df
    }
  )
  
  out <- bind_rows(all_ap)
  
  if (cds_identifiers) {
    all_cds <- extract_rc_cds(list_of_prs)
    out <- out %>%
      left_join(
        all_cds, 
        by = c('county_code', 'district_code', 'school_code', 'end_year')
      )
  }
  
  out
}


#' Extract Report Card CDS
#'
#' @param list_of_prs output of get_rc_databases (ie, a list where each element is)
#' a list of data.frames
#'
#' @return data frame with county, district and school ids and identifiers for all 
#' years present in the input
#' @export

extract_rc_cds <- function(list_of_prs) {
  
  all_cds <- map(
    list_of_prs,
    function(.x) {
      #find the table      
      cds_table <- grep('s_header|sch_header|school_header|header_and_contact', names(.x), value = TRUE)
      #extract the table
      df <- .x %>% extract2(cds_table)
      #make cds names consistent
      df <- clean_cds_fields(df)
      
      df %>%
        select(county_code, district_code, school_code,
               county_name, district_name, school_name,
               end_year)
    }
  )
  
  bind_rows(all_cds)
}
  

#' Clean Report Card Enrollment
#'
#' @param list_of_dfs output of get_one_rc_database (ie, a list  of data.frames)
#'
#' @return data frame with school enrollment
#' @export
clean_rc_enrollment <- function(list_of_dfs) {
   enr_df_name <- grep('enrollment\\b|enrollment_by_grade|enrollment_trends_by_grade|enrollment_trendsby_grade',
        names(list_of_dfs), value = T) 
   
   df <- list_of_dfs %>%
      extract2(enr_df_name) 
   
   # wide
   if (any(str_detect(colnames(df), "grade0+"))) {
      
      colnames(df) <- colnames(df) %>%
         str_replace("co_code", "county_code") %>%
         str_replace("dist_code", "district_code") %>%
         str_replace("sch_code", "school_code") %>%
         str_replace("^pk$", "gradepk") %>%
         str_replace("grade_pk", "gradepk") %>%
         str_replace("^kg$", "gradekg") %>%
         str_replace("grade_kg", "gradekg") %>%
         str_replace("^ug$", "gradeungraded") %>%
         str_replace("^ungraded$", "gradeungraded") %>%
         str_replace("rowtotal|total|row_total", "graderow_total") 
      
      grade_names <- c(
         "grade01", "grade02", "grade03", "grade04", "grade05", "grade06",
         "grade07", "grade08", "grade09", "grade10", "grade11", "grade12",
         "gradepk", "gradekg", "graderow_total", "gradeungraded"
      )
      
      df <- pivot_longer(
         data = df,
         cols = one_of(grade_names), 
         names_to = 'grade_level',
         names_prefix = 'grade',
         values_to = 'n_enrolled' 
      ) %>%
         mutate(
            grade_level = case_when(
               grade_level == "pk" ~ "PK",
               grade_level == "kg" ~ "KG",
               grade_level == "row_total" ~ "TOTAL",
               grade_level == "ungraded" ~ NA_character_,
               TRUE ~ grade_level
               )
         )
   
   } else { # if long
         colnames(df) <- colnames(df) %>%
            str_replace("grade$", "grade_level") %>%
            str_replace("^count$", "n_enrolled")
         
         df <- df %>%
            mutate(
               grade_level = str_replace_all(grade_level, "Grade ", ""),
               grade_level = case_when(
                  grade_level %in% c("Ungraded", "UG") ~ NA_character_,
                  grade_level == "Total Enrollment" ~ "TOTAL",
                  TRUE ~ grade_level
               )
            )
      }

   return(df)
}

#' Extract Report Card Enrollment
#'
#' @param list_of_prs output of get_rc_databases (ie, a list where each element is
#' a list of data.frames)
#' @param cds_identifiers add the county, district and school name?  default is TRUE
#'
#' @return data frame with school enrollment
#' @export
extract_rc_enrollment <- function(list_of_prs, cds_identifiers = TRUE) {
   
   all_enr <- map(
    list_of_prs,
    function(.x) {
      clean_rc_enrollment(.x) %>%
         clean_cds_fields() %>%
         select(
            one_of(c("county_code", "district_code", "school_code",
                     "end_year", "grade_level", "n_enrolled"))
            ) %>%
          return()
    }
  )
  
  out <- bind_rows(all_enr)
  
  if (cds_identifiers) {
    all_cds <- extract_rc_cds(list_of_prs)
    out <- out %>%
      left_join(
        all_cds, 
        by = c('county_code', 'district_code', 'school_code', 'end_year')
      )
  }
  
  out %>%
    rename(county_id = county_code,
           district_id = district_code, 
           school_id = school_code) %>%
    select(-school_name) %>%
    return()

}


#' Enrich report card subgroup percentages with best guesses at 
#' subgroup numbers
#' 
#' @param df data frame of icluding subgroup percentages
#' 
#' return data_frame
#' @export
enrich_rc_enrollment <- function(df) {
# not totally sure if this should be here - or where to put it!
# writing the tests in test_charter.R for now, I think.
  enr_count <- df %>%
    pull(end_year) %>%
    unique() %>%
    get_rc_databases() %>%
    extract_rc_enrollment() %>%
    filter(grade_level == "TOTAL")
  
  df <- df %>% 
    left_join(
      enr_count,
      # line below will likely cause problems later
      by = c("end_year", "county_id", 
             "district_id", "school_id")
    ) %>%
    # is there a better solution here w/ recover_enrollment() ?
    mutate(n_enrolled = as.numeric(n_enrolled),
           n_students = round(percent / 100 * n_enrolled),
           n_students = if_else(n_students == 0 & percent > 0, 1, n_students)) 
  
  return(df)
}