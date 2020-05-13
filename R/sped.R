#' read Special ed excel files from the NJ state website
#'
#' @inheritParams get_raw_enr 
#'
#' @return a dataframe with special ed counts, etc.
#' @export

get_raw_sped <- function(end_year) {
  
  print(end_year)
  #build url
  if (end_year %in% c(2002:2013)) sped_url <- paste0(
    "http://www.nj.gov/education/specialed/data/ADR/", end_year - 1, "/classification/distclassification.xls"
  )
  if (end_year %in% c(2014)) sped_url <- paste0(
    "http://www.nj.gov/education/specialed/data/ADR/", end_year - 1, "/classification/distclassification.xls"
  )
  if (end_year %in% c(2015)) sped_url <- paste0(
    "http://www.nj.gov/education/specialed/data/", end_year - 1, "/District_Classification_Rate.xlsx"
  )
  if (end_year %in% c(2016)) sped_url <- paste0(
    "http://www.nj.gov/education/specialed/data/", end_year - 1, "/LEA_Classification.xlsx"
  )
  # :nail-care:
  if (end_year %in% c(2017)) sped_url <- paste0(
    "http://www.nj.gov/education/specialed/data/", end_year - 1, "/LEA_Classificatiom.xlsx"
  )
  if (end_year >= 2018) sped_url <- paste0(
    "http://www.nj.gov/education/specialed/data/", end_year - 1, "/Lea_Classification.xlsx"
  )
  if (end_year >= 2019) sped_url <- 'https://www.nj.gov/education/specialed/data/2018/LEA_Classification2.xlsx'
  
  if (end_year == 2018) rows_to_skip <- 0
  if (end_year %in% c(2015, 2016, 2017)) rows_to_skip <- 4
  if (end_year %in% c(2009, 2010, 2011, 2012, 2013, 2014, 2019)) rows_to_skip <- 5
  if (end_year %in% c(2003, 2004, 2005, 2006, 2007)) rows_to_skip <- 7
  if (end_year %in% c(2008)) rows_to_skip <- 8
  
  tf <- tempfile()
  download.file(sped_url, tf, mode = 'wb')
  
  if (grepl('.xlsx', sped_url)) {
    invisible(file.rename(tf, paste0(tf, ".xlsx")))
    sped <- readxl::read_excel(
      paste0(tf, ".xlsx" ),  
      skip = rows_to_skip,
      na = c('-', '*')
    )
  } else {
    invisible(file.rename(tf, paste0(tf, ".xls")))
    sped <- readxl::read_excel(
      paste0(tf, ".xls"),  
      skip = rows_to_skip,
      na = c('-', '*')
    )
  }
  
  sped$end_year <- end_year
  
  # county vs countyid disambig
  if (end_year <= 2008) {
    sped <- sped %>%
      rename(
        'county_name' = 'County'
      )
  }
  return(sped)
}


clean_sped_names <- function(df) {
  
  #data
  clean <- list(
    #preserve these
    "end_year" = "end_year",
    
    #county ids
    "County" = "county_id",
    "COUNTY" = "county_id",
    
    #district ids
    "District" = "district_id",
    "DISTRICT" = "district_id",
    "SUB_DIST" = "district_id",
    
    #county name
    "county_name" = "county_name",
    "County Name" = "county_name",
    "COUNTYNAME" = "county_name",
    
    #district name 
    "District Name" = "district_name",
    "DISTRICTNAME" = "district_name",
    "Districts                                 State Agency                            Charter School" = "district_name",
    
    #special ed count
    "Number Classified" = "sped_num",
    "Special Education Student Count" = "sped_num",
    "3-21 Clsfd" = "sped_num",
    "Special Ed. Enrollment" = "sped_num",
    "SPECED" = "sped_num",
    "3-21 Count" = "sped_num",
    
    #special ed count no speech
    "Number Classified Without Speech" = "sped_num_no_speech",
    
    #gened count
    "Enrollment*" = "gened_num",
    "Gened" = "gened_num",
    "Enrollment" = "gened_num",
    "General Ed. Enrollment" = "gened_num",
    "GENED" = "gened_num",
    "LEA" = "gened_num",
    
    #special ed classification rate
    "Percent Classified" = "sped_rate",
    "Classification Rate" = "sped_rate",
    "Clsfd Rate" = "sped_rate",
    "CLASSIFICATION RATE" = "sped_rate",
    
    #special ed classification rate no speech
    "Percent Classified Without Speech" = "sped_rate_no_speech"
  )
  
  names(df) <- map_chr(names(df), ~clean_name(.x, clean))
  
  return(df)
  
}


#' Clean historic SPED data
#'
#' @description SPED data was published in a way that lacked districtids.  We've built a 
#' best guess data file that string matches on county and district.  
#' @param df raw data frame with cleaned names, output of get_raw_sped with clean_sped_names applied.
#' @param end_year academic year, ending year - eg 2019-2020 is 2020.
#'
#' @return cleaned data frame
#' @export

clean_sped_df <- function(df, end_year) {
  
  # remove trailing footer note
  if (end_year >= 2015) {
    df <- df %>% filter(!is.na(gened_num))
  }
  
  # doing the heavy lifting - solves for missing district ids
  # fix missing district ids in 2003-2008 data
  if (end_year <= 2008) {
    
    # sped_lookup_map is saved in package data
    # left join the input to the lookup map and enrich with district_ids where known
    df_new <- df %>% 
      left_join(sped_lookup_map, by=c('county_name', 'district_name'))
    
    ensure_that(
      df, nrow(.) == nrow(df_new) ~ 'fixing 2003-08 enrollment data changed the size of the sped df.  check for duplicate district_name keys!'
    )
    
    # if the data frame hasn't grown, great - overwrite df with the updated joined df
    df <- df_new
  }
  
  # return df with proper column order
  df %>%
    select(
      one_of(
        'end_year', 'county_name',
        'district_id', 'district_name',
        'gened_num', 'sped_num',
        'sped_rate',
        'sped_num_no_speech',
        'sped_rate_no_speech'
      )
    )

}


#' Gets and cleans older SPED data
#'
#' @param end_year @inheritParams fetch_enr
#'
#' @return cleaned sped dataframe
#' @export

fetch_sped <- function(end_year) {
  get_raw_sped(end_year) %>%
    clean_sped_names() %>%
    clean_sped_df(., end_year)
  
}