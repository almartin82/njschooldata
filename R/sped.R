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


clean_sped_df <- function(df, end_year) {
  
  # remove trailing footer note
  if (end_year >= 2015) {
    df <- df %>% filter(!is.na(gened_num))
  }
  
  # fix missing district ids in 2003-2008 data
  if (end_year <= 2008) {
    lookup_df <- fetch_enr(end_year) %>%
      filter(program_code == '55' & school_id == '999') %>%
      select(county_name, district_name, district_id, row_total) %>%
      mutate(
        county_name = tolower(county_name),
        district_name = tolower(district_name)
      ) %>% 
      unique()
    
     lookup_df <- lookup_df %>% 
       mutate(
        district_name = gsub(' twp', ' township', district_name)
      )

    df_before <- df
    
    df2 <- df %>%
      mutate(
        county_name_orig = county_name,
        district_name_orig = district_name,
        county_name = tolower(county_name),
        district_name = tolower(district_name)
      ) %>%
      left_join(lookup_df, by = c('county_name', 'district_name'))
    
    df2_matched <- df2 %>% filter(!is.na(district_id))
    df2_unmatched <- df2 %>% filter(is.na(district_id))
    lookup_unmatched <- lookup_df %>% 
      filter(!district_id %in% df2_matched$district_id) %>%
      mutate(
        district_name = gsub(' township', '', district_name),
        district_name = gsub(' boro', '', district_name)
      )      
    
    nrow(df2_unmatched)
    
    df2_unmatched <- df2_unmatched %>%
      select(-district_id, -row_total) %>%
      left_join(lookup_unmatched, by = c('county_name', 'district_name'))
    
    sum(is.na(df2_unmatched$district_id))
    
    df2 %>%
      filter(is.na(district_id)) %>%
      peek()
      
    # %>%
    #   select(-county_name, -district_name) %>%
    #   rename(
    #     county_name = county_name_orig,
    #     district_name = district_name_orig
    #   )
    # sum(is.na(df2$district_name))
    # 
    ensure_that(
      df, nrow(.) == nrow(df_new) ~ 'fixing 2003-08 enrollment data changed the size of the sped df.  check for duplicate district_name keys!'
    )
    
  }
  # return df
  df
}


fetch_sped <- function(end_year) {
  get_raw_sped(end_year) %>%
    clean_sped_names() %>%
    clean_sped_df(., end_year)
  
}