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
    "2005" = "http://www.state.nj.us/education/guide/2005/csg05.zip",
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
      df <- readr::read_csv(
        file.path(unzip_loc, .x),
        col_types = cols()
      ) %>%
      mutate(
        file_name = .y
      ) %>%
      janitor::clean_names()
      
      df <- clean_cds_fields(df, tges = TRUE)
      
      if ('county_code' %in% names(df)) {
        df$county_code <- pad_leading(df$county_code, 2)
      }      
      if ('district_code' %in% names(df)) {
        df$district_code <- pad_leading(df$district_code, 4)
      }
      df
    }
  )
  names(csv_list) <- tges_csv$file %>% toupper()
  
  #read excel
  excel_list <- map2(
    .x = tges_excel$Name,
    .y = tges_excel$file,
    .f = function(.x, .y) {
      df <- readxl::read_excel(
        path = file.path(unzip_loc, .x)
      ) %>%
      mutate(
        file_name = .y
      ) %>%
      janitor::clean_names()
      
      df <- clean_cds_fields(df, tges = TRUE)
      df
    }
  )
  names(excel_list) <- tges_excel$file %>% toupper()
  
  #read dbf (1999-2002)
  dbf_list <- map2(
    .x = tges_dbf$Name,
    .y = tges_dbf$file,
    .f = function(.x, .y) {
      df <- foreign::read.dbf(
        file = file.path(unzip_loc, .x),
        as.is = TRUE
        ) %>%
        mutate(
          file_name = .y
        ) %>%
        janitor::clean_names()
      
      df <- clean_cds_fields(df, tges = TRUE)
      df
    }
  )
  names(dbf_list) <- tges_dbf$file %>% toupper()

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
  if (end_year <= 2003) {
   df <-  year_variable_converter(df, end_year)
   colnames(df) <- str_replace_all(colnames(df), "rank", "rk")
  }
  
  if(end_year > 2003){
    #colnames(df) <- str_replace_all(colnames(df), "\\d{2}$", "")
    colnames(df) <- str_replace_all(colnames(df), "rank", "rk")
  }
  
  both_years <- !grepl('11a|21a', names(df))
  year_1 <- grepl('11a', names(df), fixed = TRUE) | both_years
  year_2 <- grepl('21a', names(df), fixed = TRUE) | both_years
  # 
  # #reshape wide to long
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
  
  force_indicator_types <- function(df) {
    if ('pp' %in% names(df)) df$pp <- as.numeric(df$pp)
    if ('rk' %in% names(df)) df$rk <- str_split(df$rk, "\\|", simplify = TRUE)[,1]
    if ('rk' %in% names(df)) df$rk <- as.numeric(df$rk)
    if ('pct' %in% names(df)) df$pct <- as.numeric(df$pct)
    if ('sb' %in% names(df)) df$sb <- as.numeric(df$sb)
    
    df
  }
  
  #clean up names
  
  names(y1_df) <- gsub('11a', '', names(y1_df), fixed = TRUE)
  #y1_df$rk <- as.numeric(str_extract_all(y1_df$rk, "\\d+(?=\\|?)"))
  y1_df <- force_indicator_types(y1_df)
  names(y1_df) <- tges_name_cleaner(y1_df, indicator_fields)
  y1_df$end_year <- end_year - 2
  y1_df$calc_type <- 'Actuals'
  y1_df$report_year <- end_year

 
  
  names(y2_df) <- gsub('21a', '', names(y2_df), fixed = TRUE)
  # y2_df$rk <- as.numeric(str_extract_all(y2_df$rk, "\\d+(?=\\|?)"))
  # y2_df$rk <- as.numeric(str_split(y2_df$rk, "\\|", simplify = TRUE)[,1]
  y2_df <- force_indicator_types(y2_df)
  names(y2_df) <- tges_name_cleaner(y2_df, indicator_fields)
  y2_df$end_year <- end_year - 1
  y2_df$calc_type <- 'Actuals'
  y2_df$report_year <- end_year
 
  
  
  bind_rows(y1_df, y2_df)
}


#' tidy common/generic budget indicator data frame
#'
#' @param df indicator data frame, eg output of get_raw_tges() 
#' indicators 1-15
#' @param end_year end year that the report was published
#' @param indicator character, indicator name
#'
#' @return long, tidy data frame
#' @export

tidy_generic_budget_indicator <- function(df, end_year, indicator) {
  
  df$indicator <- indicator
  colnames(df) <- str_replace_all(colnames(df), "rank", "rk")
  
  #for 1999 through 2003 y1, y2, y3 changed per-year
  if (end_year <= 2003) {
    df <-  year_variable_converter(df, end_year)
  }
  #masks to break out y1, y2, y3 data
   if (end_year >= 2011) {
     all_years <- !grepl('[[:alpha:]][1,2,3]+[[:digit:]]|sb[a,b,c]+[[:digit:]]', names(df))
     year_1 <- grepl('[[:alpha:]]1+[[:digit:]]|sba+[[:digit:]]', names(df)) | all_years
     year_2 <- grepl('[[:alpha:]]2+[[:digit:]]|sbb+[[:digit:]]', names(df)) | all_years
     year_3 <- grepl('[[:alpha:]]3+[[:digit:]]|sbc+[[:digit:]]', names(df)) | all_years
   #headers slightly different for comparative guide years
   } else if (end_year < 2011) {
     all_years <- grepl('group|county_name|district_name|district_code|file_name|indicator', names(df))
     year_1 <- grepl('pp01|rk01|pct01|pct201', names(df)) | all_years
     year_2 <- grepl('pp02|rk02|pct02|pct202', names(df)) | all_years
     year_3 <- grepl('pp03|rk03|pct03|pct203', names(df)) | all_years
   }
  
  #reshape wide to long
  y1_df <- df[, year_1 & !grepl('sbb|sbc', names(df))]
  y2_df <- df[, year_2]
  y3_df <- df[, year_3]
  indicator_fields <- list(
    #tges
    "pp" = "Per Pupil costs",
    "rk" = "District rank",
    "e" = "Enrollment (ADE)",
    "pct" = "Cost as a percentage of the Total Budgetary Cost Per Pupil",
    "sb" = "Cost as a percentage of Total Salaries and Benefits"  
  )
  
  #force types to resolve bind_row conflicts when all NA
  force_indicator_types <- function(df) {
    if ('pp' %in% colnames(df)) df$pp <- as.numeric(df$pp)
    if ('rk' %in% colnames(df)) df$rk <- str_split(df$rk, "\\|", simplify = TRUE)[,1]
    if ('rk' %in% colnames(df)) df$rk <- as.numeric(df$rk)
    if ('pct' %in% colnames(df)) df$pct <- as.numeric(df$pct)
    if ('sb' %in% colnames(df)) df$sb <- as.numeric(df$sb)
    
    df
  }
  
  #clean up names
  names(y1_df) <- gsub("pct201", "sb", names(y1_df))
  names(y1_df) <- gsub('[[:digit:]]', '', names(y1_df))
  names(y1_df) <- gsub('sba', 'sb', names(y1_df))
  names(y1_df) <- gsub('a$', '', names(y1_df))
  names(y1_df) <- gsub('rank', 'rk', names(y1_df), fixed = TRUE)
  y1_df <- force_indicator_types(y1_df)
  names(y1_df) <- tges_name_cleaner(y1_df, indicator_fields)
  y1_df$end_year <- end_year - 2
  y1_df$calc_type <- 'Actuals'
  y1_df$report_year <- end_year
  
  names(y2_df) <- gsub("pct202", "sb", names(y2_df))
  names(y2_df) <- gsub('[[:digit:]]', '', names(y2_df))
  names(y2_df) <- gsub('sbb', 'sb', names(y2_df))
  names(y2_df) <- gsub('a$', '', names(y2_df))
  names(y2_df) <- gsub('rank', 'rk', names(y2_df), fixed = TRUE)
  y2_df <- force_indicator_types(y2_df)
  names(y2_df) <- tges_name_cleaner(y2_df, indicator_fields)
  y2_df$end_year <- end_year - 1
  y2_df$calc_type <- 'Actuals'
  y2_df$report_year <- end_year
  
  names(y3_df) <- gsub("pct203", "sb", names(y3_df))
  names(y3_df) <- gsub('[[:digit:]]', '', names(y3_df))
  names(y3_df) <- gsub('sbc', 'sb', names(y3_df))
  names(y3_df) <- gsub('a$', '', names(y3_df))
  names(y3_df) <- gsub('rank', 'rk', names(y3_df), fixed = TRUE)
  y3_df <- force_indicator_types(y3_df)
  names(y3_df) <- tges_name_cleaner(y3_df, indicator_fields)
  y3_df$end_year <- end_year
  y3_df$calc_type <- 'Budgeted'
  y3_df$report_year <- end_year
  
  bind_rows(y1_df, y2_df, y3_df)
 
}

#' year variable converter
#'
#' @description for the 1999-2003 tges files, the 'year' of the data
#' was encoded in the variable names
#' @param df a tges indicator data frame published between 1999 and 2003
#' @param end_year year published
#'
#' @return data frame that conforms to 2004-2009 style
#' @export
year_variable_converter <- function(df, end_year) {
  old_id <- end_year - 1
  old_ids <- c(old_id-2, old_id-1, old_id)
  old_ids <- str_sub(old_ids, 3, 4)
  on <- names(df)
  on[grepl(old_ids[3], on)] <- gsub(
    pattern = old_ids[3],
    replacement = '03',
    x = on[grepl(old_ids[3], on)]
  )
  on[grepl(old_ids[2], on)] <- gsub(
    pattern = old_ids[2],
    replacement = '02',
    x = on[grepl(old_ids[2], on)]
  )
  on[grepl(old_ids[1], on)] <- gsub(
    pattern = old_ids[1],
    replacement = '01',
    x = on[grepl(old_ids[1], on)]
  )
  names(df) <- on

  df
}

#' tidy generic personnel indicator data frame
#'
#' @param df personnel data frame, eg output of get_raw_tges() 
#' indicators 16-19
#' @param end_year end year that the report was published
#' @param indicator character, indicator name
#'
#' @return long, tidy data frame
#' @export

tidy_generic_personnel <- function(df, end_year, indicator) {
  
  df$indicator <- indicator
  
  #for 1999 through 2003 y1, y2, y3 changed per-year
  if (end_year <= 2003) {
    df <-  year_variable_converter(df, end_year)
    colnames(df) <- str_replace_all(colnames(df), "rank", "rk")
  } 
  
  #masks to break out y1, y2, y3 data
  if (end_year >= 2011) {
    all_years <- !grepl('[[:alpha:]][00,01,02]+[[:digit:]]', names(df))
    year_1 <- str_detect(names(df), "[[:alpha:]]00+[[:digit:]]")|all_years
    year_2 <- str_detect(names(df), "[[:alpha:]]01+[[:digit:]]")|all_years
    # all_years <- !grepl('00|01', names(df))
    # year_1 <- grepl('00', names(df)) | all_years
    # year_2 <- grepl('01', names(df)) | all_years
  } else if (end_year < 2011) {
    all_years <- !grepl('[[:alpha:]][01,02,03]+[[:digit:]]', names(df))
    year_1 <- str_detect(names(df), "[[:alpha:]]02+[[:digit:]]")|all_years
    year_2 <- str_detect(names(df), "[[:alpha:]]03+[[:digit:]]")|all_years
  }
  
  #reshape wide to long
  y1_df <- df[, year_1]
  y2_df <- df[, year_2]
  
  indicator_fields <- list(
    'strat' = 'Student/Teacher ratio',
    'rk' = 'Ratio Rank',
    'salt' = 'Teacher Salary',
    'rksal' = 'Salary Rank',
    'ssrat' = 'Student/Special Service ratio',
    'sals' = 'Special Service Salary',
    'sarat' = 'Student/Administrator ratio',
    'salam' = 'Administrator Salary',
    'farat' = 'Faculty/Administrator ratio',
    #cges
    'rrk' = 'Ratio Rank',
    'srk' = 'Salary Rank',
    'sala' = 'Administrator Salary',
    #CSG14 modified
    "pctsalary" = "% of Total Salaries"
  )
  
  #lu's edit
  #force types to resolve bind_row conflicts when all NA
   force_indicator_types <- function(df) {
     if ('rk' %in% colnames(df)) df$rk <- str_split(df$rk, "\\|", simplify = TRUE)[,1]
     if ('rksal' %in% colnames(df)) df$rksal <- str_split(df$rksal, "\\|", simplify = TRUE)[,1]
     if ('rrk' %in% colnames(df)) df$rrk <- str_split(df$rrk, "\\|", simplify = TRUE)[,1]
     if ('ssrat' %in% colnames(df)) df$ssrat <- str_split(df$ssrat, "\\|", simplify = TRUE)[,1]
     if ('salam' %in% colnames(df)) df$salam <- str_split(df$salam, "\\|", simplify = TRUE)[,1]
     if ('srk' %in% colnames(df)) df$srk <- str_split(df$srk, "\\|", simplify = TRUE)[,1]
     if ('farat' %in% colnames(df)) df$farat <- str_split(df$farat, "\\|", simplify = TRUE)[,1]
     # 
      if ('rk' %in% colnames(df)) df$rk <- as.numeric(df$rk)
      if ('rksal' %in% colnames(df)) df$rksal <- as.numeric(df$rksal)
      if ('rrk' %in% colnames(df)) df$rrk <- as.numeric(df$rrk)
      if ('ssrat' %in% colnames(df)) df$ssrat <- as.numeric(df$ssrat)
      if ('salam' %in% colnames(df)) df$salam <- as.numeric(df$salam)
      if ('srk' %in% colnames(df)) df$srk <- as.numeric(df$srk)
      if ('farat' %in% colnames(df)) df$farat <- as.numeric(df$farat)
     df
   }


  # force_indicator_types <- function(df) {
  #   df$rk <- as.numeric(str_split(df$rk, "\\|", simplify = TRUE)[,1]
  #   df$rksal <- as.numeric(str_split(df$rksal, "\\|", simplify = TRUE)[,1]
  #   df$rrk <- as.numeric(str_split(df$rrk, "\\|", simplify = TRUE)[,1]
  #   df$ssrat <- as.numeric(str_split(df$ssrat, "\\|", simplify = TRUE)[,1]
  #   df$salam <- as.numeric(str_split(df$salam, "\\|", simplify = TRUE)[,1]
  #   df$srk <- as.numeric(str_split(df$srk, "\\|", simplify = TRUE)[,1]
  #   df$farat <- as.numeric(str_split(df$farat, "\\|", simplify = TRUE)[,1]
  #   df
  # }
  
  #clean up names
  names(y1_df) <- gsub('[[:digit:]]', '', names(y1_df))
  y1_df$end_year <- end_year - 2
  y1_df$report_year <- end_year
  y1_df$calc_type <- 'Actuals'
  y1_df <- force_indicator_types(y1_df)
  names(y1_df) <- tges_name_cleaner(y1_df, indicator_fields)
  
  #clean up names
  names(y2_df) <- gsub('[[:digit:]]', '', names(y2_df))
  y2_df$end_year <- end_year-1
  y2_df$report_year <- end_year
  y2_df$calc_type <- 'Actuals'
  y2_df <- force_indicator_types(y2_df)
  names(y2_df) <- tges_name_cleaner(y2_df, indicator_fields)
  
  bind_rows(y1_df, y2_df)

}


#' Tidy Budgeted vs Actual Fund Balance
#'
#' @param df general fund vs actual used data frame, eg CSG20 
#' output from get_raw_tges()
#' @param end_year end year that the report was published
#'
#' @return data frame
#' @export

tidy_budgeted_vs_actual_fund_balance <- function(df, end_year) {

  #goofy column names from 99-2010  
  if (end_year <= 2010) {
    names(df)[5:8] <- c('de120', 'de220', 'de320', 'de420')
  }
  
  df$indicator <- 'Budgeted General Fund Balance vs. Actual'
  
  y1_df <- df[, c('group', 'county_name', 'district_code', 'district_name',
                   'de120', 'de220', 'file_name', 'indicator')]
  y2_df <- df[, c('group', 'county_name', 'district_code', 'district_name',
                   'de320', 'de420', 'file_name', 'indicator')]
  
  indicator_fields <- list(
    'de120' = 'Budgeted General Fund Balance',
    'de220' = 'Actual',
    'de320' = 'Budgeted General Fund Balance',
    'de420' = 'Actual'
  )
  
  y1_df$end_year <- end_year - 2
  y1_df$report_year <- end_year
  names(y1_df) <- tges_name_cleaner(y1_df, indicator_fields)
  
  y2_df$end_year <- end_year - 1
  y2_df$report_year <- end_year
  names(y2_df) <- tges_name_cleaner(y2_df, indicator_fields)
  
  bind_rows(y1_df, y2_df)
}


#' Tidy Excess Unreserved General Fund 
#'
#' @param df excess unreserved general fund data frame, eg CSG21 
#' output from get_raw_tges()
#' @param end_year end year that the report was published
#'
#' @return data frame
#' @export

tidy_excess_unreserved_general_fund <- function(df, end_year) {
  
  #goofy column names from 99-2010  
  if (end_year <= 2010) {
    names(df)[5:7] <- c('ex121', 'ex221', 'ex331')
  }
  
  df$indicator <- 'Excess Unreserved General Fund Balances'
  
  #reshape
  y1_df <- df[, c('group', 'county_name', 'district_code', 'district_name',
                  'ex121', 'file_name', 'indicator')]
  y2_df <- df[, c('group', 'county_name', 'district_code', 'district_name',
                  'ex221', 'file_name', 'indicator')]
  
  indicator_fields <- list(
    'ex121' = 'Actual Excess',
    'ex221' = 'Actual Excess'
  )
  
  y1_df$end_year <- end_year - 2
  y1_df$report_year <- end_year
  names(y1_df) <- tges_name_cleaner(y1_df, indicator_fields)
  
  y2_df$end_year <- end_year - 1
  y2_df$report_year <- end_year
  names(y2_df) <- tges_name_cleaner(y2_df, indicator_fields)
  
  bind_rows(y1_df, y2_df)
}


#' Tidy Vital Statistics
#'
#' @param df vital statistics data frame, eg VITSTAT_TOTAL 
#' output from get_raw_tges()
#' @param end_year end year that the report was published
#'
#' @return data frame
#' @export

tidy_vitstat <- function(df, end_year) {
  
  if (end_year <= 2003) {
    df <-  year_variable_converter(df, end_year)
  } 
  
  df$end_year <- end_year - 1
  
  indicator_fields <- list(
    'pp3vv' = 'Total Spending Per Pupil',
    'stpct01vv' = 'Revenue: State %',
    'ltpct01vv' = 'Revenue: Local %',
    'fdpct01vv' = 'Revenue: Federal %',
    'tupct01vv' = 'Revenue: Tuition %',
    'fbpct01vv' = 'Revenue: Free balance %',
    'otpct01vv' = 'Revenue: Other %',
    'strat01vv' = 'Student / Teacher ratio',
    'ssrat01vv' = 'Student / Special Service ratio',
    'sarat01vv' = 'Student / Administrator ratio',
    'pctsevv' = 'Percent Special Education Students',
    'pp03' = 'Total Spending Per Pupil',
    'stpct03' = 'Revenue: State %',
    'ltpct03' = 'Revenue: Local %',
    'fdpct03' = 'Revenue: Federal %',
    'tupct03' = 'Revenue: Tuition %',
    'fbpct03' = 'Revenue: Free balance %',
    'otpct03' = 'Revenue: Other %',
    'strat03' = 'Student / Teacher ratio',
    'ssrat03' = 'Student / Special Service ratio',
    'sarat03' = 'Student / Administrator ratio',
    'pctspeced' = 'Percent Special Education Students'
  )
  names(df) <- tges_name_cleaner(df, indicator_fields)
  
  df  
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
 
tidy_legal_services <- function(df, end_year) {
  tidy_generic_budget_indicator(df, end_year, 'Legal Services per Pupil')
}


#' Tidy Administrative Salaries and Benefits
#'
#' @inheritParams tidy_budgetary_per_pupil_cost
#'
#' @return data.frame
#' @export

tidy_admin_salaries <- function(df, end_year) {
  tidy_generic_budget_indicator(df, end_year, 'Salaries + Benefits for Administration')
}


#' Tidy Plant Operations and Maintenance
#'
#' @inheritParams tidy_budgetary_per_pupil_cost
#'
#' @return data.frame
#' @export

tidy_plant_operations_maintenance <- function(df, end_year) {
  tidy_generic_budget_indicator(df, end_year, 'Operations and Maintenance of Plant')
}


#' Tidy Plant Operations and Maintenance - Salaries and Benefits
#'
#' @inheritParams tidy_budgetary_per_pupil_cost
#'
#' @return data.frame
#' @export

tidy_plant_operations_maintenance_salaries <- function(df, end_year) {
  tidy_generic_budget_indicator(df, end_year, 'Salaries + Benefits - Operations/Maintenance of Plant')
}


#' Tidy Food Service Costs
#'
#' @inheritParams tidy_budgetary_per_pupil_cost
#'
#' @return data.frame
#' @export

tidy_food_service <- function(df, end_year) {
  tidy_generic_budget_indicator(df, end_year, 'Food Service Cost per Pupil + Benefits')
}


#' Tidy Extracurricular Costs
#'
#' @inheritParams tidy_budgetary_per_pupil_cost
#'
#' @return data.frame
#' @export

tidy_extracurricular <- function(df, end_year) {
  tidy_generic_budget_indicator(df, end_year, 'Extracurricular Costs per Pupil + Benefits')
}


#' Tidy Personal Services and Benefits Costs
#'
#' @inheritParams tidy_budgetary_per_pupil_cost
#'
#' @return data.frame
#' @export

tidy_personal_services_benefits <- function(df, end_year) {
  #CSG 14 IS DIFFERENT
  names(df) <- gsub('pp|pct', 'pctsalary', names(df))
  tidy_generic_personnel(df, end_year, 'Personal Services - Employee Benefits')
}


#' Tidy Equipment Costs
#'
#' @inheritParams tidy_budgetary_per_pupil_cost
#'
#' @return data.frame
#' @export

tidy_equipment <- function(df, end_year) {
  tidy_generic_budget_indicator(df, end_year, 'Total Equipment Cost per Pupil')
}


#' Tidy Ratio of Students to Teachers
#'
#' @inheritParams tidy_budgetary_per_pupil_cost
#'
#' @return data.frame
#' @export

tidy_ratio_students_to_teachers <- function(df, end_year) {
  tidy_generic_personnel(df, end_year, 'Ratio of Students to Teachers, Median Salary')
}


#' Tidy Ratio of Students to Special Service
#'
#' @inheritParams tidy_budgetary_per_pupil_cost
#'
#' @return data.frame
#' @export

tidy_ratio_students_to_special_service <- function(df, end_year) {
  tidy_generic_personnel(df, end_year, 'Ratio of Students to Special Service, Median Salary')  
}


#' Tidy Ratio of Students to Administrators
#'
#' @inheritParams tidy_budgetary_per_pupil_cost
#'
#' @return data.frame
#' @export

tidy_ratio_students_to_administrators <- function(df, end_year) {
  tidy_generic_personnel(df, end_year, 'Ratio of Students to Administrators, Median Salary')
}


#' Tidy Ratio of Faculty to Administrators
#'
#' @inheritParams tidy_budgetary_per_pupil_cost
#'
#' @return data.frame
#' @export

tidy_ratio_faculty_to_administrators <- function(df, end_year) {
  tidy_generic_personnel(df, end_year, 'Ratio of Faculty to Administrators')
}


#' Tidy list of TGES data frames
#'
#' @param list_of_dfs list of TGES data frames, eg output of 
#' get_raw_tges(). Current valid values are 2011 to 2017. 
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
    "CSG8A" = "tidy_legal_services",
    "CSG9" = "tidy_admin_salaries",
    "CSG10" = "tidy_plant_operations_maintenance",
    "CSG11" = "tidy_plant_operations_maintenance_salaries",
    "CSG12" = "tidy_food_service",
    "CSG13" = "tidy_extracurricular",
    "CSG14" = "tidy_personal_services_benefits",
    "CSG15" = "tidy_equipment",
    "CSG16" = "tidy_ratio_students_to_teachers",
    "CSG17" = "tidy_ratio_students_to_special_service",
    "CSG18" = "tidy_ratio_students_to_administrators",
    "CSG19" = "tidy_ratio_faculty_to_administrators",
    "CSG20" = "tidy_budgeted_vs_actual_fund_balance",
    "CSG21" = "tidy_excess_unreserved_general_fund",
    "VITSTAT_TOTAL" = "tidy_vitstat",
    "VITSTAT" = "tidy_vitstat"
  )
  
  #apply a cleaning function if known
  out <- map2(
    .x = list_of_dfs, 
    .y = names(list_of_dfs), 
    .f = function(.x, .y) {
      #look up the table name and see if we know how to clean it
      cleaning_function <- tges_cleaners %>% extract2(.y)
      print(cleaning_function)
      if (!is.null(cleaning_function)) {
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


#' Fetch Multiple Cleaned Taxpayer's Guides to Educational Spending
#'
#' @param end_year_vector vector of years.  Current valid values 
#' are 2011 to 2017. 
#'
#' @return list of lists of data frames
#' @export

fetch_many_tges <- function(end_year_vector) {
  all_tges <- map(
    .x = end_year_vector,
    .f = function(.x) {
      print(.x)
      fetch_tges(.x)
    }
  )
  
  names(all_tges) <- end_year_vector
  
  all_tges
}