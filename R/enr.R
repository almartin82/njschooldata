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
    enr <- readr::read_csv(
      file = paste0(tdir,'\\',enr_files$Name[1]),
      na = "     . "
    )
  }
  
  enr$end_year <- end_year
    
  return(enr)
}



#' @title split enr columns
#' 
#' @description splits enrollment columns that combine IDs and names (pre '09-10)
#' @param df a enr data frame (eg output of \code{get_raw_enr})
#' @export

split_enr_cols <- function(df) {
  if (unique(df$end_year)[1] <= 2009) {
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
  
  return(df)
}



#' @title clean enrollment names
#' 
#' @description give consistent names to the enrollment files
#' @param df a enr data frame (eg output of \code{get_raw_enr})
#' @export

clean_enr_names <- function(df) {
  
  #data
  clean <- list(
    #preserve these
    "end_year" = "end_year",
    
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
    "COUNTY" = "county_name",
    
    #district ids
    "DIST_ID" = "district_id",
    "DISTRICT CODE" = "district_id",
    "District Id" = "district_id",
    "District ID" = "district_id",
    "DISTRICT_ID" = "district_id",
    
    #district names
    "LEA_NAME" = "district_name",
    "DISTRICT NAME" = "district_name",
    "District Name" = "district_name",
    "DISTRICT_NAME" = "district_name",
    "DIST" = "district_name",
    "DISTRICT" = "district_name",
    
    #schoolids
    "SCHOOL_ID" = "school_id",
    "SCHOOL CODE" = "school_id",
    "SCH_CODE" = "school_id",
    
    #school name
    "SCHOOL_NAME" = "school_name",
    "SCHOOL NAME" = "school_name",
    "School Name" = "school_name",
    "SCH" = "school_name",
    "SCHOOL" = "school_name",
    
    #programcode
    "PRGCODE" = "program_code",
    "PROGRAM_CODE" = "program_code",
    "PROG" = "program_code",
    "PROG_CODE" = "program_code",
    
    #program
    "PROGRAM_NAME" = "program_name",
    "PROGRAM" = "program_name",
    "PROG_NAME" = "program_name",
    
    #grade level
    "GRADE_LEVEL" = "grade_level",
    
    
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
    "REDUCED" = "reduced_lunch",
    
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

  clean_name <- function(x) {
    z = clean[[x]] 
    
    ifelse(is.null(z), print(x), '')
    
    return(z)
  }
  
  names(df) <- sapply(X = names(df), FUN = clean_name)
  
  return(df)
}



#' @title clean enrollment data types 
#' 
#' @description all columns come back char; coerce some back to numeric
#' @inheritParams clean_enr_names
#' @export

clean_enr_data <- function(df) {
  
  enr_types <- list(
    'county_id' = 'character',
    'county_name' = 'character',
    'district_id' = 'character',
    'district_name' = 'character',
    'school_id' = 'character',
    'school_name' = 'character',
    'program_code' = 'character',
    'program_name' = 'character',
    'grade_level' = 'character',
    'white_m' = 'numeric',
    'white_f' = 'numeric',
    'black_m' = 'numeric',
    'black_f' = 'numeric',
    'hispanic_m' = 'numeric',
    'hispanic_f' = 'numeric',
    'asian_m' = 'numeric',
    'asian_f' = 'numeric',
    'native_american_m' = 'numeric',
    'native_american_f' = 'numeric',
    'pacific_islander_m' = 'numeric',
    'pacific_islander_f' = 'numeric',
    'multiracial_m' = 'numeric',
    'multiracial_f' = 'numeric',
    'free_lunch' = 'numeric',
    'reduced_lunch' = 'numeric',
    'lep' = 'numeric',
    'migrant' = 'numeric',
    'row_total' = 'numeric',
    'homeless' = 'numeric',
    'special_ed' = 'numeric',
    'title_1' = 'numeric',
    'end_year' = 'numeric'
  )
  
  df <- as.data.frame(df)
  
  #some old files (eg 02-03) have random, unlabeled rows.  kill those.
  df <- df[nchar(df$county_name) >0, ]
  
  for (i in 1:ncol(df)) {
    z = enr_types[[names(df)[i]]]
    if (z=='numeric') {
      df[, i] <- as.numeric(df[, i])
    } else if (z=='character') {
      df[, i] <- trim_whitespace(as.character(df[, i]))
      
    }
  }
  
  #make CDS_code
  #make cds code
  df$CDS_Code <- paste0(
    stringr::str_pad(df$county_id, width=2, side='left', pad='0'),
    stringr::str_pad(df$district_id, width=4, side='left', pad='0'),
    stringr::str_pad(df$school_id, width=3, side='left', pad='0')
  )
  
  return(df)  
}



#' @title arrange enrollment file
#' 
#' @description put an enrollment file in the correct order
#' @param df cleaned enrollment file
#' @export

arrange_enr <- function(df) {

  clean_names <- c('end_year', 'CDS_Code', 'county_id', 'county_name', 'district_id', 'district_name', 'school_id',
    'school_name', 'program_code', 'program_name', 'white_m', 'white_f', 'black_m',
    'black_f', 'hispanic_m', 'hispanic_f', 'asian_m', 'asian_f', 'native_american_m',
    'native_american_f', 'pacific_islander_m', 'pacific_islander_f', 'multiracial_m',
    'multiracial_f', 'row_total', 'free_lunch', 'reduced_lunch', 'lep', 'migrant',
    'homeless', 'special_ed', 'title_1', 'grade_level'
  )
  
  mask <- clean_names %in% names(df) 
    
  df <- df %>% 
    dplyr::ungroup() %>%
    dplyr::select_(
      ~one_of(clean_names[mask])
    )
  
  return(df)
}



#' @title join program code to program name
#' 
#' @description decode the program name
#' @inheritParams arrange_enr
#' @export

process_enr_program <- function(df) {
  #program name is messy; drop.
  if ('program_name' %in% names(df)) {
    df <- df %>%
      dplyr::select(
        -program_name  
      )
  }
  
  #join
  df <- df %>%
    dplyr::left_join(prog_codes, by = c("end_year", "program_code")) 

  return(df)
}
  

#' @title process a nj enrollment file 
#' 
#' @description
#' \code{process_enr} does cleanup of dataframes returned by \code{get_raw_enr} 
#' @inheritParams clean_enr_names
#' @export

process_enr <- function(df) {

  cleaned <- clean_enr_names(df) %>%
    split_enr_cols() %>%
    clean_enr_data()  
  
  #join to program code
  final <- cleaned %>%
    process_enr_program() %>%
    arrange_enr()
    
  return(final)
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