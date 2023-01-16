#' @title read a zipped excel fall enrollment file from the NJ state website
#' 
#' @description
#' \code{get_raw_enr} returns a data frame with a year's worth of fall school and 
#' grade level enrollment data.
#' @param end_year a school year.  year is the end of the academic year - eg 2006-07
#' school year is year '2007'.  valid values are 2000-2022.
#' @export

get_raw_enr <- function(end_year) {
  
  # sometime in 2022 they ripped, replaced, and rationalized the
  # url pattern for historic data
  # website claims to have 98-99 data but link is broken
  
  # build url
  yy <- substr(end_year, 3, 4)
  enr_folder <- paste0("enr", yy)
  
  enr_filename <- paste0(
    "enrollment_",
    substr(end_year - 1, 3, 4),
    yy,
    ".zip"
  )
  
  enr_url <- paste0(
    "https://www.nj.gov/education/doedata/enr/", enr_folder, "/", enr_filename    
  )
  
  #download and unzip
  tname <- tempfile(pattern = "enr", tmpdir = tempdir(), fileext = ".zip")
  tdir <- tempdir()
  downloader::download(enr_url, dest = tname, mode = "wb") 
  
  utils::unzip(tname, exdir = tdir)
  
  #read file
  enr_files <- utils::unzip(tname, exdir = ".", list = TRUE)
  
  if (grepl('.xls', tolower(enr_files$Name[1]))) {
    this_file <- file.path(tdir, enr_files$Name[1])
    
    to_skip = case_when(
      end_year == 2018 ~ 1,
      end_year >= 2019 ~ 2,
      TRUE ~ 0
    )
    if (end_year < 2020) {
      enr <- readxl::read_excel(this_file, skip = to_skip)

    # starting in the 2020 school year the format changes significantly
    # three distinct worksheets to combine
    } else if (end_year >= 2020) {
      
      # in 2020 they leave a stray space in this sheet name
      enr_state <- readxl::read_excel(
        this_file, sheet = ifelse(end_year==2020, 'State ', 'State'), skip = 2
      )
      enr_dist <- readxl::read_excel(this_file, sheet = 'District', skip = 2)
      enr_sch <- readxl::read_excel(this_file, sheet = 'School', skip = 2)
      
      # fix some bad program columns
      if (end_year == 2020) {
        enr_dist <- enr_dist %>%
          rename("Pre-K Halfday" = "Pre -K Halfday",
                 "Pre-K Fullday" = "Pre-K FullDay")
        enr_sch <- enr_sch %>%
          rename(# sometime after 2020 they #fixed the above errors, 
                 # but only in the enr_sch file and in so doing 
                 # introduced this magnificent error 🤡
                 "Pre-K Fullday" = "Pre-K\r\n Full day",
                 "Pre-K Halfday" = "Pre-K Half Day")
      }

      # set some constants
      enr_dist <- enr_dist %>%
        mutate(`School Code` = '999',
               `School Name` = "District Total")

      # combine state, dist, sch df by binding dist and sch and then 
      # pivoting grade level columns long
      enr_dist_sch <- bind_rows(enr_dist, enr_sch)

      # in 2020 they decided not to report above 95%?!
      # set to 97.5 to split the difference
      if (end_year == 2020) {
          enr_dist_sch <- enr_dist_sch %>%
            mutate(
              # >95 to 95 ... maybe not a good decision?
              `%Free Lunch` = if_else(`%Free Lunch` == ">95", '97.5', `%Free Lunch`),
              `%Reduced Lunch` = if_else(`%Reduced Lunch` == ">95", '97.5', `%Reduced Lunch`),
              `%English Learners` = if_else(`%English Learners` == ">95", '97.5', `%English Learners`),
              `%Migrant` = if_else(`%Migrant` == ">95", '97.5', `%Migrant`),
              `%Military` = if_else(`%Military` == ">95", '97.5', `%Military`),
              `%Homeless` = if_else(`%Homeless` == ">95", '97.5', `%Homeless`)
            )
      }

      enr_dist_sch <- enr_dist_sch %>%
        mutate(
          # populations in this mutate block are only reported as pcts,
          # so convert percents into counts
          `Free Lunch` = as.numeric(`%Free Lunch`) / 100 * `Total Enrollment`,
          `Reduced Lunch` = as.numeric(`%Reduced Lunch`) / 100 * `Total Enrollment`,
          `English Learners` = as.numeric(`%English Learners`) / 100 * `Total Enrollment`,
          `Migrant` = as.numeric(`%Migrant`) / 100 * `Total Enrollment`,
          `Military` = as.numeric(`%Military`) / 100 * `Total Enrollment`,
          `Homeless` = as.numeric(`%Homeless`) / 100 * `Total Enrollment`
        )
      
      enr <- enr_dist_sch %>%
        select(`County Code`:`District Name`, `School Code`, `School Name`,
               `Pre-K Halfday`:`Ungraded`) %>%
        pivot_longer(cols = `Pre-K Halfday`:`Ungraded`,
                     names_to = 'Grade', values_to = 'Total Enrollment') %>%
        bind_rows(enr_dist_sch %>%
                    select(-c(`Pre-K Halfday`:`Ungraded`)) %>%
                    mutate(Grade = 'All Grades')) %>%
        bind_rows(enr_state %>%
                    rename("Total Enrollment" = 'Total',
                           "Native American" = "American Indian"))
      
    }
  } else if (grepl('.csv', tolower(enr_files$Name[1]))) {
    enr <- readr::read_csv(
      file = file.path(tdir, enr_files$Name[1]),
      na = "     . "
    )
  }
  
  enr$end_year <- end_year

  # specific fixes
  # 2010 pre-k disabled issue
  if (end_year==2010) {
    mask <- enr$PROGRAM_CODE == '32' & enr$PROGRAM_NAME == 'Half Day Preschool Dis'
    enr[mask, 'PROGRAM_CODE'] <- '33'
  }
  
  # 2013 marin issue, pfffffffff
  if (end_year==2013) {
    mask <- enr$`SCHOOL NAME` == 'LUIS MUNOZ MARIN ELEM SCH' & enr$`DISTRICT NAME` == 'NEWARK'
    enr[mask, 'DISTRICT NAME'] <- 'THE NEWARK PUBLIC SCHOOLS'
  }
  
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


clean_name <- function(df_names, clean_list) {
  z = clean_list[[df_names]] 
  
  ifelse(is.null(z), print(df_names), '')
  
  return(z)
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
    "program_name" = "program_name",
    "program_code" = "program_code",
    "grade_level" = "grade_level",
    
    #county ids
    "COUNTY_ID" = "county_id",
    "COUNTY CODE" = "county_id",
    "Co code" = "county_id",
    "COUNTY_CODE" = "county_id",
    "County_ID" = "county_id",
    "County Code" = "county_id",
    
    #county names
    "COUNTY_NAME" = "county_name",
    "COUNTY NAME" = "county_name",
    "County Name" = "county_name",
    "CO" = "county_name",
    "COUNTY" = "county_name",
    "County_Name" = "county_name",
    
    #district ids
    "DIST_ID" = "district_id",
    "DISTRICT CODE" = "district_id",
    "District Id" = "district_id",
    "District ID" = "district_id",
    "DISTRICT_ID" = "district_id",
    "Dist_ID" = "district_id",
    "District Code" = "district_id",
    
    #district names
    "LEA_NAME" = "district_name",
    "DISTRICT NAME" = "district_name",
    "District Name" = "district_name",
    "DISTRICT_NAME" = "district_name",
    "DIST" = "district_name",
    "DISTRICT" = "district_name",
    "District_Name" = "district_name",

    #schoolids
    "SCHOOL_ID" = "school_id",
    "SCHOOL CODE" = "school_id",
    "SCH_CODE" = "school_id",
    "School_ID" = "school_id",
    "School Code" = "school_id",
    
    #school name
    "SCHOOL_NAME" = "school_name",
    "SCHOOL NAME" = "school_name",
    "School Name" = "school_name",
    "SCH" = "school_name",
    "SCHOOL" = "school_name",
    "School_Name" = "school_name",
    
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
    "Grade_Level" = "grade_level",
    "Grade" = "grade_level",

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
    
    # 2020 -- a great year, wasn't it?!?!?!??!
    "White" = "white",
    "Black" = "black",
    "Hispanic" = "hispanic",
    "Asian" = "asian",
    "Native American" = "native_american",
    "American Indian" = "native_american",
    "Hawaiian Native" = "pacific_islander",
    "Two or More Races" = "multiracial",
    "Male" = "male",
    "Female" = "female",
    "Non-Binary" = "non_binary",
    
    #lunch status & english status --------------
    #free
    "FREE_LUNCH" = "free_lunch",
    "FREE" = "free_lunch",
    "Free_Lunch" = "free_lunch",
    "Free Lunch" = "free_lunch",
    
    #reduced
    "REDUCED_PRICE_LUNCH" = "reduced_lunch",
    "REDUCED_LUNCH" = "reduced_lunch",
    "RED_LUNCH" = "reduced_lunch",
    "REDUCE" = "reduced_lunch",
    "REDUCED" = "reduced_lunch",
    "Reduced_Price_Lunch" = "reduced_lunch",
    "Reduced Lunch" = "reduced_lunch",
    
    #lep
    "LEP" = "lep",
    # 2019 baby
    "English_Learners" = "lep", 
    "English Learners" = "lep",
    
    #migrant & homeless ---------------------
    #migrant
    "MIGRANT" = "migrant",
    "MIG" = "migrant",
    "MIGRNT" = "migrant", 
    "Migant" = "migrant",
    # maybe they'll fix the typo in the 2018 data?  if so:
    # 2019 - they did! :clap:
    "Migrant" = "migrant",
    
    #row totals
    "ROW_TOTAL" = "row_total",
    "ROWTOT" = "row_total",
    "ROWTOTAL" = "row_total",
    "Row_Total" = "row_total",
    "Total Enrollment" = "row_total",
    
    
    #very inconsistently reported
    "HOMELESS" = "homeless",
    "Homeless" = "homeless",
    "Military" = "military",
    "SPECED" = "special_ed",
    "CHPT1" = "title_1"
  )

  names(df) <- map_chr(names(df), ~clean_name(.x, clean))

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
    "white" = 'numeric',
    "black" = 'numeric',
    "hispanic" = 'numeric',
    "asian" = 'numeric',
    "native_american" = 'numeric',
    "pacific_islander" = 'numeric',
    "multiracial" = 'numeric',
    "male" = 'numeric',
    "female" = 'numeric',
    "non_binary" = 'numeric',
    'free_lunch' = 'numeric',
    'reduced_lunch' = 'numeric',
    'lep' = 'numeric',
    'migrant' = 'numeric',
    'row_total' = 'numeric',
    'homeless' = 'numeric',
    'military' = 'numeric',
    'non_binary' = 'numeric',
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

      # NJ uses periods for missing / suppressed
      # make these empty string to reduce
      # number of "NAs introduced by coercion" warnings
      df[, i] <- gsub(".", "", df[, i], fixed = TRUE)
      df[, i] <- gsub(" ,", "", df[, i], fixed = TRUE)
      df[, i] <- gsub(" ,,", "", df[, i], fixed = TRUE)
      df[, i] <- gsub(",", "", df[, i], fixed = TRUE)

      # find non-numerics (useful when debugging)
      # bad_indices <- which(!grepl('^[0-9]+$|^$', df[, i]))
      # bad_chars <- df[, i][bad_indices] %>% unique()
      # if (length(bad_chars) > 0) {
      #   print(bad_chars %>% unique())
      # }

      df[, i] <- as.numeric(df[, i])

    } else if (z=='character') {
      df[, i] <- trim_whitespace(as.character(df[, i]))
    }
  }
  
  # make sure that various ids are consistent (issue #83)
  df$county_id <- stringr::str_pad(df$county_id, width=2, side='left', pad='0')
  df$district_id <- stringr::str_pad(df$district_id, width=4, side='left', pad='0')
  df$school_id <- stringr::str_pad(df$school_id, width=3, side='left', pad='0')
  
  #make CDS_code
  df$CDS_Code <- paste0(
    df$county_id, df$district_id, df$school_id
  )
  
  return(df)  
}



#' @title arrange enrollment file
#' 
#' @description put an enrollment file in the correct order
#' @param df cleaned enrollment file
#' @export

arrange_enr <- function(df) {

  clean_names <- c(
    'end_year', 'CDS_Code', 
    'county_id', 'county_name', 
    'district_id', 'district_name', 
    'school_id', 'school_name', 
    'program_code', 'program_name', 
    'male', 'female', 
    'white', 'black', 'hispanic', 
    'asian', 'native_american', 'pacific_islander', 'multiracial',
    'white_m', 'white_f', 
    'black_m', 'black_f', 
    'hispanic_m', 'hispanic_f', 
    'asian_m', 'asian_f', 
    'native_american_m', 'native_american_f', 
    'pacific_islander_m', 'pacific_islander_f', 
    'multiracial_m', 'multiracial_f', 
    'row_total', 
    'free_lunch', 'reduced_lunch', 'lep', 'migrant',
    'homeless', 'special_ed', 'title_1', 'grade_level'
  )
  
  mask <- clean_names %in% names(df) 
    
  df <- df %>% 
    dplyr::ungroup() %>%
    dplyr::select(
      any_of(clean_names[mask])
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
      dplyr::select(-program_name)
  }
  
  #join
  df <- df %>%
    dplyr::left_join(prog_codes, by = c("end_year", "program_code")) 

  return(df)
}
  

#' @title Calculate enrollment aggregates
#'
#' @param df cleaned enrollment dataframe, eg output of `clean_enr_data`
#'
#' @return dataframe
#' @export

enr_aggs <- function(df) {

  possible_m <- c(
    'white_m', 'black_m', 'hispanic_m', 
    'asian_m', 'native_american_m', 'pacific_islander_m', 'multiracial_m'
  )
  valid_m <- possible_m[possible_m %in% names(df)]
  valid_m <- paste(valid_m, collapse = '+')
  
  possible_f <- c(
    'white_f', 'black_f', 'hispanic_f', 
    'asian_f', 'native_american_f', 'pacific_islander_f', 'multiracial_f'
  )
  valid_f <- possible_f[possible_f %in% names(df)]
  valid_f <- paste(valid_f, collapse = '+')
  
  # old
  valid_pi <- ifelse(
    'pacific_islander_m' %in% names(df),
    'pacific_islander_m + pacific_islander_f',
    'NA'
  )
  # new
  sg <- function(cols) {
    cols_exist <- map_lgl(cols, ~.x %in% names(df)) %>% all()
    ifelse(cols_exist, paste(cols, collapse = ' + '), 'NA')
  }
  
  df_agg <- df %>%
    mutate(
      male = !!rlang::parse_expr(valid_m),
      female = !!rlang::parse_expr(valid_f),
      
      white =  !!rlang::parse_expr(sg(c('white_m', 'white_f'))),
      black =  !!rlang::parse_expr(sg(c('black_m', 'black_f'))),
      hispanic =  !!rlang::parse_expr(sg(c('hispanic_m', 'hispanic_f'))),
      asian =  !!rlang::parse_expr(sg(c('asian_m', 'asian_f'))),
      native_american = !!rlang::parse_expr(sg(c('native_american_m', 'native_american_f'))),
      pacific_islander = !!rlang::parse_expr(sg(c('pacific_islander_m', 'pacific_islander_f'))),
      multiracial =  !!rlang::parse_expr(sg(c('multiracial_m', 'multiracial_f')))
    )
  
  return(df_agg)
}


#' @title process a nj enrollment file 
#' 
#' @description
#' \code{process_enr} does cleanup of dataframes returned by \code{get_raw_enr} 
#' @inheritParams clean_enr_names
#' @export

process_enr <- function(df) {

  # if no grade level
  if (!'grade_level' %in% tolower(names(df)) | df$end_year[1] == "2018") {
    
     # something weird w/ 2018 grade levels; proceed as if they aren't there
     if (df$end_year[1] == "2018") df <- select(df, -Grade_Level)
     
    # clean up program code and name
    prog_map <- list(
      "PRGCODE" = "program_code",
      "PROGRAM_CODE" = "program_code",
      "PROG" = "program_code",
      "PROG_CODE" = "program_code",
      
      "PROGRAM_NAME" = "program_name_dirty",
      "PROGRAM" = "program_name_dirty",
      "PROG_NAME" = "program_name_dirty"
    )
    names(df) <- map_chr(
      names(df),
      function(.x) {
        cleaned <- prog_map[[.x]]
        ifelse(is.null(cleaned), .x, cleaned)
      }
    )
    
    # there isn't in 2020...
    if (!"program_code" %in% names(df)) {
      convert_from_grade = data.frame(
        Grade = c("Pre-K Halfday", "Pre-K Fullday", "Kindergarten Halfday",
                  "Kindergarten Fullday", "First Grade", "Second Grade",
                  "Third Grade", "Fourth Grade", "Fifth Grade", "Sixth Grade",
                  "Seventh Grade", "Eighth Grade", "Ninth Grade", "Tenth Grade",
                  "Eleventh Grade", "Twelfth Grade", "Ungraded", "All Grades"),
        program_code = c("PH", "PF", "KH", "KF", "01", "02", "03", "04", "05",
                         "06", "07", "08", "09", "10", "11", "12", "UG", "55"),
        grade_level = c("PK", "PK", "K", "K", "01", "02", "03", "04", "05",
                        "06", "07", "08", "09", "10", "11", "12", "UG", "TOTAL")
      )
      
      df <- df %>%
        left_join(convert_from_grade,
                  by = "Grade") %>%
        select(-Grade)
    }
    
    # force program character
    df$program_code <- as.character(df$program_code)
    
    df <- df %>%
      dplyr::left_join(prog_codes, by = c("end_year", "program_code"))
    
    if ('program_name_dirty' %in% names(df)) df <- df %>% select(-program_name_dirty)
    
    gl_program_df <- tibble(
      program_name = c(
        'Half-Day Pre-Kindergarten',
        'Half-Day Preschool Disabled',
        'Half-Day Kindergarten',
        
        'Full-Day Pre-Kindergarten',
        'Full-Day Preschool Disabled',
        'Full-Day Kindergarten',
        
        'Grade 1',
        'Grade 2',
        'Grade 3',
        'Grade 4', 
        'Grade 5',
        'Grade 6',
        'Grade 7',
        'Grade 8',
        'Grade 9',
        'Grade 10',
        'Grade 11', 
        'Grade 12',
        
        'Grade 9 Vocational',
        'Grade 10 Vocational',
        'Grade 11 Vocational',
        'Grade 12 Vocational',
        
        'Total'
      ),
      grade_level = c(
        'PH',
        'PH',
        'KH',
        
        'PF',
        'PF',
        'KF',
        
        '01',
        '02',
        '03',
        '04',
        '05',
        '06',
        '07',
        '08',
        '09',
        '10',
        '11',
        '12',
        
        '09',
        '10',
        '11',
        '12',
        
        'TOTAL'
      )
    )
    
    if (df$end_year[1] < 2020) {
      df <- df %>%
        left_join(gl_program_df, by = 'program_name')
    }
  }
  
  # basic cleaning
  cleaned <- df %>%
    select(!starts_with("%")) %>%
    clean_enr_names() %>%
    split_enr_cols() %>%
    clean_enr_data() %>%
    clean_enr_grade()
  
  # add in gender and racial aggregates
  if (df$end_year[1] < 2020) {
    cleaned_agg <- enr_aggs(cleaned)
  } else {
    cleaned_agg <- cleaned
  }

  #join to program code
  final <- cleaned_agg %>%
    process_enr_program() %>%
    arrange_enr() %>%
    filter(!is.na(county_id))
  
  return(final)
}


#' Tidy up the grade level field on enrollment data
#'
#' @param df an enrollment data file.  clean_enr_grade is part of a set
#' of chained cleaning functions that live inside process_enr.
#'
#' @return df with cleaner grade_level column
#' @export

clean_enr_grade <- function(df) {
  k_codes <- c('KF', 'KH')
  pk_codes <- c('PF', 'PH')
  df %>% 
    mutate(
      grade_level = case_when(
        grade_level == 'Total' ~ 'TOTAL',
        grade_level %in% k_codes ~ 'K',
        grade_level == 'KG' ~ 'K',
        grade_level %in% pk_codes ~ 'PK',
        is.na(grade_level) & program_code %in% k_codes ~ 'K',
        is.na(grade_level) & program_code %in% pk_codes ~ 'PK',
        is.na(grade_level) & program_code %in% c(1, 2) ~ 'PK',
        is.na(grade_level) & program_code %in% c(3, 4) ~ 'K',
        is.na(grade_level) & program_code %in% c('01', '02') ~ 'PK',
        is.na(grade_level) & program_code %in% c('03', '04') ~ 'K',
        TRUE ~ grade_level
      )
    )
}


#' Custom Enrollment Grade Level Aggregates
#'
#' @param df a tidy enrollment df
#'
#' @return df of aggregated enrollment data
#' @export

enr_grade_aggs <- function(df) {
  
  gr_aggs_group_logic <- . %>%
    group_by(
      end_year, 
      CDS_Code, 
      county_id, county_name, 
      district_id, district_name,
      school_id, school_name, 
      subgroup,
      # see summarize/mutate
      is_state, is_county, is_district,
      is_charter_sector, is_allpublic, is_school, is_subprogram
    ) %>%
    summarize(
      n_students = sum(n_students, na.rm = TRUE)
    ) %>%
    ungroup()
  
  gr_aggs_col_order <- . %>%
    select(
      end_year, CDS_Code,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      program_code, program_name, grade_level,
      subgroup,
      n_students,
      pct,
      pct_total_enr, 
      is_state, is_county, 
      is_district, is_charter_sector, is_allpublic,
      is_school, 
      is_subprogram
    )
  
  # Any PK
  pk_agg <- df %>%
    filter(grade_level == 'PK') %>%
    gr_aggs_group_logic() %>%
    mutate(
      program_code = 'PK',
      program_name = 'Pre-Kindergarten (Full + Half)',
      grade_level = 'PK (Any)',
      pct = NA_real_,
      pct_total_enr = NA_real_
    ) %>%
    gr_aggs_col_order()
  
  # Any K (half + full day K)
  k_agg <- df %>%
    filter(grade_level == 'K') %>%
    gr_aggs_group_logic() %>%
    mutate(
      program_code = '0K',
      program_name = 'Kindergarten (Full + Half)',
      grade_level = 'K (Any)',
      pct = NA_real_,
      pct_total_enr = NA_real_
    ) %>%
    gr_aggs_col_order()
  
  # K-12 enrollment (exclude pre-k)
  k12_agg <- df %>%
    filter(
      grade_level %in% c('K', 
                         '01', '02', '03', '04',
                         '05', '06', '07', '08',
                         '09', '10', '11', '12')
    ) %>%
    gr_aggs_group_logic() %>%
    mutate(
      program_code = 'K12',
      program_name = 'K to 12 Total',
      grade_level = 'K12',
      pct = NA_real_,
      pct_total_enr = NA_real_
    ) %>%
    gr_aggs_col_order()
  
  # All but PK enrollment
  nopk_agg <- df %>%
    filter(
      grade_level %in% c('K', 
                         '01', '02', '03', '04',
                         '05', '06', '07', '08',
                         '09', '10', '11', '12') |
        program_code == 'UG'
    ) %>%
    gr_aggs_group_logic() %>%
    mutate(
      program_code = 'K12UG',
      program_name = 'K to 12 Total, UG inclusive',
      grade_level = 'K12UG',
      pct = NA_real_,
      pct_total_enr = NA_real_
    ) %>%
    gr_aggs_col_order()
  
  # K-8 enrollment
  k8_agg <- df %>%
    filter(
      grade_level %in% c('K', 
                         '01', '02', '03', '04',
                         '05', '06', '07', '08')
    ) %>%
    gr_aggs_group_logic() %>%
    mutate(
      program_code = 'K8',
      program_name = 'K to 8 Total',
      grade_level = 'K8',
      pct = NA_real_,
      pct_total_enr = NA_real_
    ) %>%
    gr_aggs_col_order()
  
  # HS
  hs_agg <- df %>%
    filter(
      grade_level %in% c('09', '10', '11', '12')
    ) %>%
    gr_aggs_group_logic() %>%
    mutate(
      program_code = 'HS',
      program_name = 'HS (9-12) Total',
      grade_level = 'HS',
      pct = NA_real_,
      pct_total_enr = NA_real_
    ) %>%
    gr_aggs_col_order()
  
  bind_rows(pk_agg, k_agg, k12_agg, nopk_agg, k8_agg, hs_agg)
}

#' @title gets and processes a NJ enrollment file
#' 
#' @description
#' \code{fetch_enr} is a wrapper around \code{get_raw_enr} and
#' \code{process_enr} that passes the correct file layout data to each function,
#' given an end_year   
#' @param end_year a school year.  year is the end of the academic year - eg 2006-07
#' school year is year '2007'.  valid values are 1999-2019.
#' @param tidy if TRUE, takes the unwieldy wide data and normalizes into a 
#' long, tidy data frame with limited headers - constants (school/district name and code),
#' subgroup (all the enrollment file subgroups), program/grade and measure (row_total, free lunch, etc).  
#' @export

fetch_enr <- function(end_year, tidy=FALSE) {
  enr_data <- get_raw_enr(end_year) %>%
    process_enr()
  
  if (tidy) {
    enr_data <- tidy_enr(enr_data) %>% 
      id_enr_aggs()
  }
  
  enr_data
}


#' @title tidy enrollment data
#'
#' @param df a wide data.frame of processed enrollment data - eg output of \code{fetch_enr}
#'
#' @return a long data.frame of tidied enrollment data
#' @export

tidy_enr <- function(df) {
  
  # invariant cols
  invariants <- c(
    'end_year', 'CDS_Code', 
    'county_id', 'county_name', 
    'district_id', 'district_name',
    'school_id', 'school_name',
    'program_code', 'program_name', 'grade_level'
  )
  
  # cols to tidy
  to_tidy <- c(
    'male',
    'female',
    'white',
    'black',
    'hispanic',
    'asian',
    'native_american',
    'pacific_islander',
    'multiracial',
    'white_m',
    'white_f',
    'black_m',
    'black_f',
    'hispanic_m',
    'hispanic_f',
    'asian_m',
    'asian_f',
    'native_american_m',
    'native_american_f',
    'pacific_islander_m',
    'pacific_islander_f',
    'multiracial_m',
    'multiracial_f'
  )
  
  # limit to cols in df
  to_tidy <- to_tidy[to_tidy %in% names(df)]
  
  # iterate over cols to tidy, do calculations
  tidy_subgroups <- map_df(to_tidy, 
    function(.x) {
      df %>%
        rename(n_students = .x) %>%
        select(one_of(invariants, 'n_students', 'row_total')) %>%
        mutate(
          'subgroup' = .x,
          'pct' = n_students / row_total
        ) %>%
        select(one_of(invariants, 'subgroup', 'n_students', 'pct'))
    }
  )

  # also extract row total as a "subgroup"
  tidy_total_enr <- df %>%
    select(one_of(invariants, 'row_total')) %>%
    mutate(
      'n_students' = row_total,
      'subgroup' = 'total_enrollment',
      'pct' = n_students / row_total
    ) %>%
    select(one_of(invariants, 'subgroup', 'n_students', 'pct')) 

  # some subgroups are only reported for school totals
  # just total counts, for extracting total enr, free, reduced, migrant etc
  total_counts <- df %>% 
     filter(program_code == '55') %>%
  # create free and reduced group 
     rowwise() %>% 
     mutate(free_reduced_lunch = sum(free_lunch, reduced_lunch, na.rm = T))
  
  total_subgroups <- c('free_lunch', 'reduced_lunch', 'lep', 'migrant',
                       'free_reduced_lunch')
  total_subgroups <- total_subgroups[total_subgroups %in% names(total_counts)]
  
  # iterate over cols to tidy, do calculations
  tidy_total_subgroups <- map_df(total_subgroups, 
    function(.x) {
      total_counts %>%
       rename(n_students = .x) %>%
       select(one_of(invariants, 'n_students', 'row_total')) %>%
       mutate(
         'subgroup' = .x,
         'pct' = n_students / row_total
       ) %>%
       select(one_of(invariants, 'subgroup', 'n_students', 'pct'))
    }
  )
  
  # put it all together in a long data frame
  bind_rows(tidy_total_enr, tidy_total_subgroups, tidy_subgroups) %>% 
    filter(!is.na(n_students) | !is.na(pct))
}


#' Identify enrollment aggregation levels
#'
#' @param df enrollment dataframe, output of tidy_enr
#'
#' @return data.frame with boolean aggregation flags
#' @export

id_enr_aggs <- function(df) {
  df %>%
    mutate(
      is_state = district_id == '9999' & county_id == '99',
      is_county = district_id == '9999' & !county_id =='99',
      is_district = school_id == '999' & !is_state,
      is_charter_sector = FALSE,
      is_allpublic = FALSE,
      is_school = !school_id == '999' & !is_state,
      
      is_subprogram = !program_code == '55'
    )
}

