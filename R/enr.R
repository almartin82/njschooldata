#' @title read a zipped excel fall enrollment file from the NJ state website
#' 
#' @description
#' \code{get_raw_enr} returns a data frame with a year's worth of fall school and 
#' grade level enrollment data.
#' @param end_year a school year.  year is the end of the academic year - eg 2006-07
#' school year is year '2007'.  valid values are 1999-2015.
#' @export

get_raw_enr <- function(end_year) {
  #build url
  enr_url <- paste0(
    "http://www.nj.gov/education/data/enr/enr", substr(end_year, 3, 4), "/enr.zip"
  )
    
  #download and unzip
  tname <- tempfile(pattern = "enr", tmpdir = tempdir(), fileext = ".zip")
  tdir <- tempdir()
  
  downloader::download(enr_url, dest=tname, mode="wb") 

  utils::unzip(tname, exdir = tdir)
  
  #read file
  enr_files <- utils::unzip(tname, exdir = ".", list = TRUE)
  
  if (grepl('.xls', tolower(enr_files$Name[1]))) {
    enr <- readxl::read_excel(paste0(tdir,'\\',enr_files$Name[1]))
  } else if (grepl('.csv', tolower(enr_files$Name[1]))) {
    enr <- readr::read_csv(paste0(tdir,'\\',enr_files$Name[1]))
  }
  
  return(enr)
}


#' @title process a nj enrollment file 
#' 
#' @description
#' \code{process_enr} does cleanup of dataframes returned by \code{get_raw_enr} 
#' @param df a enr data frame (eg output of \code{get_raw_enr})
#' @export

process_enr <- function(df) {

  #data
  clean <- list(
    #county ids
    "COUNTY_ID" = "county_id",
    "COUNTY CODE" = "county_id",
    "Co code" = "county_id",
    "COUNTY_CODE" = "county_id",
    
    #county names
    "COUNTY_NAME" = "county_name",
    "COUNTY NAME" = "county_name",
    "County Name" = "county_name",
    "CO" = "county_name",
    
    #district ids
    "DIST_ID" = "district_id",
    "DISTRICT CODE" = "district_id",
    "District Name" = "district_id",
    "DISTRICT_NAME" = "district_id",
    "DIST" = "district_id",
    
    #district names
    "LEA_NAME" = "district_name",
    "DISTRICT NAME" = "district_name",
    "District Name" = "district_name",
    "DISTRICT_NAME" = "district_name",
    "DIST" = "district_name",
    
    #schoolids
    "SCHOOL_ID" = "school_id",
    "SCHOOL CODE" = "school_id",
    "SCH_CODE" = "school_id",
    
    #school name
    "SCHOOL_NAME" = "school_name",
    "SCHOOL NAME" = "school_name",
    "School Name" = "school_name",
    "SCH" = "school_name",
    
    #programcode
    "PRGCODE" = "program_code",
    "PROGRAM_CODE" = "program_code",
    "PROG" = "program_code",
    "PROG_CODE" = "program_code",
    
    #program
    "PROGRAM_NAME" = "program_name",
    "PROGRAM" = "program_name",
    "PROG_NAME" = "program_name",
    
    #racial categories -----------------------------
    
    #white male
    "WH_M" = "white_m",
    "WHITE_M" = "white_m",
    
    #white female
    "WH_F" = "white_f",
    "WHITE_F" = "white_f",
    
    #black male
    "BL_M" = "black_m",
    "BLACK_M" = "black_m",
    
    #black female
    "BL_F" = "black_f",
    "BLACK_F" = "black_f",
    
    #hispanic male
    "HI_M" = "hispanic_m",
    "HISP_M" = "hispanic_m",
    "HISP_MALE" = "hispanic_m",
    
    #hispanic female
    "HI_F" = "hispanic_f",
    "HISP_F" = "hispanic_f",
    
    #asian male
    "AS_M" = "asian_m",
    "ASIAN_M(NON_HISP)" = "asian_m",
    "ASIAN_M" = "asian_m",
    
    #asian female
    "AS_F" = "asian_f",
    "ASIAN_F(NON_HISP)" = "asian_f",
    "ASIAN_F" = "asian_f",
    
    #native american male
    "AM_M" = "native_american_m",
    "NAT_AM_M(NON_HISP)" = "native_american_m",
    "NAT_AM_M" = "native_american_m",

    #native american female
    "AM_F" = "native_american_f",
    "NAT_AM_F(NON_HISP)" = "native_american_f",
    "NAT_AM_F" = "native_american_f",
    
    #pacific islander male
    "PI_M" = "pacific_islander_m",
    "HAW_NTV_M(NON_HISP)" = "pacific_islander_m",
    "HAW_NTV_M" = "pacific_islander_m",
    
    #pacific islander female
    "PI_F" = "pacific_islander_f",
    "HAW_NTV_F(NON_HISP)" = "pacific_islander_f",
    "HAW_NTV_F" = "pacific_islander_f",
    
    #multiple races male
    "MU_M" = "multiracial_m",
    "2/MORE_RACES_M(NON_HISP)" = "multiracial_m",
    "2/MORE_RACES_M" = "multiracial_m",

    #multiple races female
    "MU_F" = "multiracial_f",
    "2/MORE_RACES_F(NON_HISP)" = "multiracial_f",
    "2/MORE_RACES_F" = "multiracial_f",
    
    #lunch status & english status --------------
    #free
    "FREE_LUNCH" = "free_lunch",
    "FREE" = "free_lunch",
    
    #reduced
    "REDUCED_PRICE_LUNCH" = "reduced_lunch",
    "REDUCED_LUNCH" = "reduced_lunch",
    "RED_LUNCH" = "reduced_lunch",
    "REDUCE" = "reduced_lunch",
    
    #lep
    "LEP" = "lep",
    
    #migrant & homeless ---------------------
    #migrant
    "MIGRANT" = "migrant",
    "MIG" = "migrant",
    "MIGRNT" = "migrant",  
    
    #row totals
    "ROW_TOTAL" = "row_total",
    "ROWTOT" = "row_total",
    "ROWTOTAL" = "row_total",
    
    #very inconsistently reported
    "HOMELESS" = "homeless",
    "SPECED" = "special_ed",
    "CHPT1" = "title_1"
  )

  clean_enr_name <- function(x) {
    z = clean[[x]] 
    
    ifelse(is.na(z), print(x), '')
    
    return(z)
  }
  
  names(df) <- sapply(X = names(df), FUN = clean_enr_name)

  return(df)
}



#' @title gets and processes a NJ enrollment file
#' 
#' @description
#' \code{fetch_enr} is a wrapper around \code{get_raw_enr} and
#' \code{process_enr} that passes the correct file layout data to each function,
#' given an end_year   
#' @inheritParams get_raw_enr
#' @export

fetch_enr <- function(end_year) {
  get_raw_enr(end_year) %>%
    process_enr()
}