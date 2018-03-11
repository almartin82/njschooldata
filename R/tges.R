#' Get Raw Taxpayer's Guide to Educational Spending
#'
#' @param end_year a school year.  end_year is the end of the academic year - eg 2016-17
#' school year is end_year 2017.  valid values are 1999-2017
#'
#' @return list of data frames
#' @export

get_raw_tges <- function(end_year) {
  tges_urls <- list(
    "2017" = "http://www.state.nj.us/education/guide/2017/TGES.zip",
    "2016" = "http://www.state.nj.us/education/guide/2016/TGES.zip",
    "2015" = "http://www.state.nj.us/education/guide/2015/TGES.zip",
    "2014" = "http://www.state.nj.us/education/guide/2014/TGES.zip",
    "2013" = "http://www.state.nj.us/education/guide/2013/TGES.zip",
    "2012" = "http://www.state.nj.us/education/guide/2012/TGES.zip",
    "2011" = "http://www.state.nj.us/education/guide/2011/TGES.zip",
    "2010" = "http://www.state.nj.us/education/guide/2010/csg2010.zip",
    "2009" = "http://www.state.nj.us/education/guide/2009/csg2009.zip",
    "2008" = "http://www.state.nj.us/education/guide/2008/csg2008.zip",
    "2007" = "http://www.state.nj.us/education/guide/2007/csg2007.zip",
    "2006" = "http://www.state.nj.us/education/guide/2006/csg2006.zip",
    "2005" = "http://www.state.nj.us/education/guide/2005/csg2005.zip",
    "2004" = "http://www.state.nj.us/education/guide/2004/csg2004.zip",
    "2003" = "http://www.state.nj.us/education/guide/2003/csg2003.zip",
    "2002" = "http://www.state.nj.us/education/guide/2002/csg2002.zip",
    "2001" = "http://www.state.nj.us/education/guide/2001/csg01.zip",
    "2000" = "http://www.state.nj.us/education/guide/2000/csg2000.zip",
    "1999" = "http://www.state.nj.us/education/guide/1999/csg99.zip"

  )
  tges_url <- tges_urls[[as.character(end_year)]]
  
  #download and unzip
  tname <- tempfile(pattern = "tges", tmpdir = tempdir(), fileext = ".zip")
  tdir <- tempdir()
  downloader::download(tges_url, dest = tname, mode = "wb") 
  unzip_loc <- paste0(tempfile(pattern = 'subfolder'))
  dir.create(unzip_loc)
  utils::unzip(tname, exdir = unzip_loc)  
  
  #tag csv or xlsx
  tges_files <- utils::unzip(tname, exdir = ".", list = TRUE) %>%
    separate(
      col = Name, into = c('file', 'extension'), sep = '\\.', remove = FALSE
    )
  
  tges_csv <- tges_files %>%
    filter(extension %in% c('CSV', 'csv'))
  tges_excel <- tges_files %>%
    filter(extension %in% c('XLS', 'XLSX', 'xls', 'xlsx'))
  tges_dbf <- tges_files %>%
    filter(extension %in% c('dbf', 'DBF'))
  
  #read csv
  csv_list <- map2(
    .x = tges_csv$Name,
    .y = tges_csv$file,
    .f = function(.x, .y) {
      df <- readr::read_csv(file.path(unzip_loc, .x)) %>%
        mutate(
          file_name = .y
        ) %>%
        janitor::clean_names()
      
      df <- clean_cds_fields(df)
      
      if ('county_code' %in% names(df)) {
        df$county_code <- pad_leading(df$county_code, 2)
      }      
      if ('district_code' %in% names(df)) {
        df$district_code <- pad_leading(df$district_code, 4)
      }
      df
    }
  )
  names(csv_list) <- tges_csv$file
  
  #read excel
  excel_list <- map2(
    .x = tges_excel$Name,
    .y = tges_excel$file,
    .f = function(.x, .y) {
      df <- readxl::read_excel(path = file.path(unzip_loc, .x)) %>%
        mutate(
          file_name = .y
        ) %>%
        janitor::clean_names()
      
      df <- clean_cds_fields(df)
      df
    }
  )
  names(excel_list) <- tges_excel$file
  
  #read dbf (1999-2002)
  dbf_list <- map2(
    .x = tges_dbf$Name,
    .y = tges_dbf$file,
    .f = function(.x, .y) {
      df <- foreign::read.dbf(file = file.path(unzip_loc, .x)) %>%
        mutate(
          file_name = .y
        ) %>%
        janitor::clean_names()
      
      df <- clean_cds_fields(df)
      df
    }
  )
  names(dbf_list) <- tges_dbf$file
  
  
  all_df <- c(csv_list, excel_list, dbf_list)
  
  all_df
}


#' TGES name cleaner
#' 
#' @description internal function for converting cryptic variable codes to full name
#' @param x vector of names
#' @param indicator_fields list of key/value variables to convert
#'
#' @return character vector of names

tges_name_cleaner <- function(x, indicator_fields) {
  out <- map_chr(
    names(x),
    function(.x) {
      ifelse(.x %in% names(indicator_fields), indicator_fields[[.x]],.x)
    }
  )
  out
}


#' tidy total spending per pupil
#'
#' @param df total spending data frame, eg CSG1AA_AVGS output from get_raw_tges()
#' @param end_year end year that the report was published
#'
#' @return data frame
#' @export

tidy_total_spending_per_pupil <- function(df, end_year) {
  
  #masks to break out y1, y2 data
  both_years <- !grepl('11a|21a', names(df))
  year_1 <- grepl('11a', names(df), fixed = TRUE) | both_years
  year_2 <- grepl('21a', names(df), fixed = TRUE) | both_years
  
  #reshape wide to long
  y1_df <- df[, year_1]
  y2_df <- df[, year_2]
  
  #codes from http://www.state.nj.us/education/guide/2017/install.pdf
  indicator_fields <- list(
    "exp" = "Total Expenditures, actual costs",
    "ade" = "Average Daily Enrollment plus Sent Pupils",
    "pp" = "Per Pupil Total Expenditures",
    "rk" = "Per Pupil Rank",
    "boty" = "Budget / Operating type"
  )
  
  #clean up names
  names(y1_df) <- gsub('11a', '', names(y1_df), fixed = TRUE)
  names(y1_df) <- tges_name_cleaner(y1_df, indicator_fields)
  y1_df$end_year <- end_year - 2
  y1_df$calc_type <- 'Actuals'
  y1_df$report_year <- end_year
  
  names(y2_df) <- gsub('21a', '', names(y2_df), fixed = TRUE)
  names(y2_df) <- tges_name_cleaner(y2_df, indicator_fields)
  y2_df$end_year <- end_year - 1
  y2_df$calc_type <- 'Actuals'
  y2_df$report_year <- end_year
  
  bind_rows(y1_df, y2_df)
}


#' tidy common/generic budget indicator data frame
#'
#' @param df indicator data frame, eg output of get_raw_tges()
#' @param end_year end year that the report was published
#' @param indicator character, indicator name
#'
#' @return long, tidy data frame
#' @export

tidy_generic_budget_indicator <- function(df, end_year, indicator) {
  
  df$indicator <- indicator
  
  #masks to break out y1, y2, y3 data
  all_years <- !grepl('+[[:digit:]]?a\\>', names(df))
  year_1 <- grepl('1+[[:digit:]]?a\\>|a+[[:digit:]]\\>', names(df)) | all_years
  year_2 <- grepl('2+[[:digit:]]?a\\>|b+[[:digit:]]\\>', names(df)) | all_years
  year_3 <- grepl('3+[[:digit:]]?a\\>|c+[[:digit:]]\\>', names(df)) | all_years
  
  #reshape wide to long
  y1_df <- df[, year_1]
  y2_df <- df[, year_2]
  y3_df <- df[, year_3]
  
  indicator_fields <- list(
    "pp" = "Per Pupil costs",
    "rk" = "District rank",
    "e" = "Enrollment (ADE)",
    "pct" = "Cost as a percentage of the Total Budgetary Cost Per Pupil",
    "sb" = "Cost as a percentage of Total Salaries and Benefits"
  )
  
  #clean up names
  names(y1_df) <- gsub('1+[[:digit:]]?a\\>|a+[[:digit:]]\\>', '', names(y1_df))
  names(y1_df) <- tges_name_cleaner(y1_df, indicator_fields)
  y1_df$end_year <- end_year - 2
  y1_df$calc_type <- 'Actuals'
  y1_df$report_year <- end_year
  
  names(y2_df) <- gsub('2+[[:digit:]]?a\\>|b+[[:digit:]]\\>', '', names(y2_df))
  names(y2_df) <- tges_name_cleaner(y2_df, indicator_fields)
  y2_df$end_year <- end_year - 1
  y2_df$calc_type <- 'Actuals'
  y2_df$report_year <- end_year
  
  names(y3_df) <- gsub('3+[[:digit:]]?a\\>|c+[[:digit:]]\\>', '', names(y3_df))
  names(y3_df) <- tges_name_cleaner(y3_df, indicator_fields)
  y3_df$end_year <- end_year
  y3_df$calc_type <- 'Budgeted'
  y3_df$report_year <- end_year
  
  bind_rows(y1_df, y2_df, y3_df)
}


#' Tidy Budgetary Per Pupil data frame
#'
#' @param df indicator data frame, eg output of get_raw_tges()
#' @param end_year end year that the report was published
#'
#' @return data.frame

tidy_budgetary_per_pupil_cost <- function(df, end_year) {
  tidy_generic_budget_indicator(df, end_year, 'Budgetary Per Pupil Cost')
}


#' Tidy Total Classroom Instruction data frame
#'
#' @inheritParams tidy_budgetary_per_pupil_cost
#'
#' @return data.frame
#' @export

tidy_total_classroom_instruction <- function(df, end_year) {
  tidy_generic_budget_indicator(df, end_year, 'Total Classroom Instruction')
}


#' Tidy Classroom Salaries and Benefits
#'
#' @inheritParams tidy_budgetary_per_pupil_cost
#'
#' @return data.frame
#' @export

tidy_classroom_salaries_benefits <- function(df, end_year) {
  tidy_generic_budget_indicator(df, end_year, 'Classroom Salaries & Benefits')
}


#' Tidy Classroom General Supplies and Textbooks
#'
#' @inheritParams tidy_budgetary_per_pupil_cost
#'
#' @return data.frame
#' @export

tidy_classroom_general_supplies <- function(df, end_year) {
  tidy_generic_budget_indicator(df, end_year, 'Classroom General Supplies and Textbooks')
}


#' Tidy Classroom Purchased Services and Other
#'
#' @inheritParams tidy_budgetary_per_pupil_cost
#'
#' @return data.frame
#' @export

tidy_classroom_purchased_services <- function(df, end_year) {
  tidy_generic_budget_indicator(df, end_year, 'Classroom Purchased Services and Other')
}


#' Tidy Total Support Services
#'
#' @inheritParams tidy_budgetary_per_pupil_cost
#'
#' @return data.frame
#' @export

tidy_total_support_services <- function(df, end_year) {
  tidy_generic_budget_indicator(df, end_year, 'Total Support Services')
}


#' Tidy Support Services Salaries
#'
#' @inheritParams tidy_budgetary_per_pupil_cost
#'
#' @return data.frame
#' @export

tidy_support_services_salaries <- function(df, end_year) {
  tidy_generic_budget_indicator(df, end_year, 'Support Services Salaries + Benefits')
}


#' Tidy Administrative Costs
#'
#' @inheritParams tidy_budgetary_per_pupil_cost
#'
#' @return data.frame
#' @export

tidy_administrative_costs <- function(df, end_year) {
  tidy_generic_budget_indicator(df, end_year, 'Total Administrative Costs per Pupil')
}


#' Tidy Legal Services
#'
#' @inheritParams tidy_budgetary_per_pupil_cost
#'
#' @return data.frame
#' @export
#' 
tidy_legal_services <- function(df, end_year) {
  tidy_generic_budget_indicator(df, end_year, 'Legal Services per Pupil')
}


#' Tidy list of TGES data frames
#'
#' @param list_of_dfs list of TGES data frames, eg output of get_raw_tges()
#' @param end_year year that the report was published
#'
#' @return list of cleaned (wide to long, tidy) dataframes
#' @export

tidy_tges_data <- function(list_of_dfs, end_year) {
  
  #which function cleans which indicator?
  tges_cleaners = list(
    "CSG1AA_AVGS" = 'tidy_total_spending_per_pupil',
    "CSG1" = "tidy_budgetary_per_pupil_cost",
    "CSG2" = "tidy_total_classroom_instruction",
    "CSG3" = "tidy_classroom_salaries_benefits",
    "CSG4" = "tidy_classroom_general_supplies",
    "CSG5" = "tidy_classroom_purchased_services",
    "CSG6" = "tidy_total_support_services",
    "CSG7" = "tidy_support_services_salaries",
    "CSG8" = "tidy_administrative_costs",
    "CSG8A" = "tidy_legal_services"
  )
  
  #apply a cleaning function if known
  out <- map2(
    .x = list_of_dfs, 
    .y = names(list_of_dfs), 
    .f = function(.x, .y) {
      #look up the table name and see if we know how to clean it
      cleaning_function <- tges_cleaners %>% extract2(.y)
      if (!is_null(cleaning_function)) {
        do.call(cleaning_function, list(.x, end_year))
        #if not, just return it
      } else {
        return(.x)
      }
    })
  
  out
}


#' Fetch Cleaned Taxpayer's Guide to Educational Spending
#'
#' @inheritParams get_raw_tges
#'
#' @return list of data frames
#' @export

fetch_tges <- function(end_year) {
  get_raw_tges(end_year) %>%
    tidy_tges_data(end_year)
}