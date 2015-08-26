#' @title read a zipped excel HS graduate rate file from the NJ state website
#' 
#' @description
#' \code{get_raw_grate} returns a data frame with NJ HS grad rate
#' @param end_year a school year.  year is the end of the academic year - eg 2006-07
#' school year is year '2007'.  valid values are 1998-2014.
#' @param calc_type c('4 year', '5 year').  5 year only available for 2012 and 2013 
#' as of 8/26/15
#' @export

get_raw_grate <- function(end_year, calc_type = '4 year') {
  
  #xlsx
  if (end_year >= 2013 & calc_type == '4 year') {
    #build url
    grate_url <- paste0(
      "http://www.state.nj.us/education/data/grate/", end_year, "/4Year.xlsx"
    )
    
    #download
    tname <- tempfile(pattern = "grate", tmpdir = tempdir(), fileext = ".xlsx")
    tdir <- tempdir()
    downloader::download(grate_url, dest = tname, mode = "wb") 

    grate <- readxl::read_excel(tname, na = '-')
    names(grate)[names(grate) == 'FOUR_YR_GRAD_RATE'] <- 'grad_rate'
    names(grate)[names(grate) == 'FOUR_YR_ADJ_COHORT_COUNT'] <- 'cohort_count'

    grate$methodology <- 'cohort'
    grate$time_window <- '4 year'
  }
  
  if (end_year >= 2012 & calc_type == '5 year') {
    #build url
    grate_url <- paste0(
      "http://www.state.nj.us/education/data/grate/", end_year + 1, 
      "/4And5YearCohort", substr(end_year, 3, 4), ".xlsx"
    )
    
    #download
    tname <- tempfile(pattern = "grate", tmpdir = tempdir(), fileext = ".xlsx")
    tdir <- tempdir()
    downloader::download(grate_url, dest = tname, mode = "wb") 

    grate <- readxl::read_excel(tname, na = '-')
    grate <- grate[, c(1:6, 8)]
    #nothing is named consistently :(
    mask <- names(grate) %in% c('FIVE_YR_GRAD_RATE', '2012 5 -Year Adj Cohort Grad Rate')
    names(grate)[mask] <- 'grad_rate'    
    grate$methodology <- 'cohort'
    grate$time_window <- '5 year'
  }
  
  
  #2012 and 2011 in the same file?!
  if (end_year %in% c(2012, 2011)) {
    grate_url <- "http://www.state.nj.us/education/data/grate/2012/gradrate.xls"
    tname <- tempfile(pattern = "grate", tmpdir = tempdir(), fileext = ".xls")
    tdir <- tempdir()
    downloader::download(grate_url, dest = tname, mode = "wb") 
    grate <- readxl::read_excel(tname, na = '-')
    
    if (end_year == 2012) {
      grate <- grate[, c(1:7, 8)]
      names(grate)[8] <- 'grad_rate'
    } else if (end_year == 2011) {
      grate <- grate[, c(1:7, 9)]
      names(grate)[8] <- 'grad_rate'
    }
    
    grate$methodology <- 'cohort'
    grate$time_window <- '4 year'
  }
  
  #pre 2010 uses non-cohort methodology
  if (end_year %in% c(1998:2010)) {
    grate_url <- paste0(
      "http://www.state.nj.us/education/data/grd/grd", substr(end_year + 1, 3, 4), "/grd.zip"
    )
    #download and unzip
    tname <- tempfile(pattern = "grate", tmpdir = tempdir(), fileext = ".zip")
    tdir <- tempdir()
    downloader::download(grate_url, dest = tname, mode = "wb") 
    unzip_loc <- paste0(tempfile(pattern = 'subfolder'))
    dir.create(unzip_loc)
    utils::unzip(tname, exdir = unzip_loc)
    
    #read file
    grate_files <- utils::unzip(tname, exdir = ".", list = TRUE)
    
    #extensions changed
    if (end_year >= 2009) {
      grade <- readxl::read_excel(paste0(unzip_loc, '\\', grate_files$Name[1]))
    } else {
      grate <- readr::read_csv(file = paste0(unzip_loc, '\\', grate_files$Name[1]))
    }
    
    #clean up
    closeAllConnections()
    unlink(unzip_loc, recursive = TRUE)
    file.remove(tname)
  }
    
  #tag with year and 
  grate$grad_cohort <- end_year
  grate$year_reported <- end_year
  
  return(grate)
}



#' @title process grate
#' 
#' @description does cleanup of the grad rate ('grate') file
#' @param df the output of get_raw_grate
#' @param end_year a school year.  year is the end of the academic year - eg 2006-07
#' school year is year '2007'.  valid values are 1998-2014.
#' @export

process_grate <- function(df, end_year) {
  #clean up names
  names(df)[names(df) %in% c('COUNTY', 'CO', 'CO_NAME')] <- 'county_name'
  names(df)[names(df) %in% c('DISTRICT', 'DIST', 'DIS_NAME')] <- 'district_name'
  names(df)[names(df) %in% c('SCHOOL', 'SCH', 'SCH_NAME')] <- 'school_name'
  names(df)[names(df) %in% c('PROG_CODE')] <- 'program_code'
  names(df)[names(df) %in% c('PROGNAME', 'PROG')] <- 'program_name'
  
  names(df)[names(df) %in% c('COUNTY_CODE', 'County')] <- 'county_id'
  names(df)[names(df) %in% c('DISTRICT_CODE', 'District')] <- 'district_id'
  names(df)[names(df) %in% c('SCHOOL_CODE', 'School')] <- 'school_id'
  
  #errata
  names(df)[names(df) %in% c('HISP_MALE')] <- 'hisp_m'  
  names(df)[names(df) %in% c("NAT_AM-F", 'NAT_F', 'NAT_AM_F(NON_HISP)')] <- 'nat_am_f'
  names(df)[names(df) %in% c('NAT_M', 'NAT_AM_M(NON_HISP)')] <- 'nat_am_m'
  
  #oh, 2007...
  names(df)[names(df) %in% c('ROWTOT')] <- 'rowtotal'
  names(df)[names(df) %in% c('WH_M')] <- 'white_m'
  names(df)[names(df) %in% c('WH_F')] <- 'white_f'
  names(df)[names(df) %in% c('BL_M')] <- 'black_m'
  names(df)[names(df) %in% c('BL_F')] <- 'black_f'
  names(df)[names(df) %in% c('ASIAN_M(NON_HISP)')] <- 'asian_m'
  names(df)[names(df) %in% c('ASIAN_F(NON_HISP)')] <- 'asian_f'
  names(df)[names(df) %in% c('HAW_NTV_M(NON_HISP)')] <- 'hwn_nat_m'
  names(df)[names(df) %in% c('HAW_NTV_F(NON_HISP)')] <- 'hwn_nat_f'
  names(df)[names(df) %in% c('2/MORE_RACES_M(NON_HISP)')] <- '2_more_m'
  names(df)[names(df) %in% c('2/MORE_RACES_F(NON_HISP)')] <- '2_more_f'
  
  names(df) <- names(df) %>% tolower()

  #county distr sch codes
  if (end_year <= 2010) {
    
    #county_id and county_name
    int_matrix <- stringr::str_split_fixed(df$county_name, "-", 2)    
    df$county_id <- int_matrix[, 1]
    df$county_name <- int_matrix[, 2]
    
    #district_id and ditrict_name
    int_matrix <- stringr::str_split_fixed(df$district_name, "-", 2)    
    df$district_id <- int_matrix[, 1]
    df$district_name <- int_matrix[, 2]

    #school_id and school_name
    int_matrix <- stringr::str_split_fixed(df$school_name, "-", 2)    
    df$school_id <- int_matrix[, 1]
    df$school_name <- int_matrix[, 2]
 
  }
  
  #missing program names
  
  if (end_year >= 2013 ) {
  }
  
  clean_names <- c(
    "county_id", "county_name", 
    "district_id", "district_name", 
    "school_id", "school_name", 
    "level", 
    "grad_cohort", "year_reported", "methodology", "time_window",
    "program_name", "program_code", 
    "white_m", "white_f", 
    "black_m", "black_f", 
    "hisp_m", "hisp_f", 
    "nat_am_m", "nat_am_f", 
    "asian_m", "asian_f", 
    "hwn_nat_m", "hwn_nat_f",
    "2_more_m", "2_more_f", 
    "rowtotal", 
    "instate", "outstate", 
    "subgroup",
    "grad_rate", "cohort_count", "graduated_count"
  )

  return(df)
}













tidy_grate <- function(df) {
  
  hs_list <- list()
  for (i in c(1998:2014)) {
    hs_list[[i]] <- get_raw_grate(i)
  }


    
  for (i in c(1998:2014)) {
    print(i)
    foo <- process_grate(hs_list[[i]], i) 
    
    all_names <- names(foo)
    
    #print(names(hs_list[[i]]))
    clean_names <- c(
      "county_id", "county_name", 
      "district_id", "district_name", 
      "school_id", "school_name", 
      "level", 
      "grad_cohort", "year_reported", "methodology", "time_window",
      "program_name", "program_code", 
      "white_m", "white_f", 
      "black_m", "black_f", 
      "hisp_m", "hisp_f", 
      "nat_am_m", "nat_am_f", 
      "asian_m", "asian_f", 
      "hwn_nat_m", "hwn_nat_f",
      "2_more_m", "2_more_f", 
      "rowtotal", 
      "instate", "outstate", 
      "subgroup",
      "grad_rate", "cohort_count", "graduated_count"
    )

    all_names[!all_names %in% clean_names] %>% print()
  }


  
    
}







