#' Get and Process mSGP data
#'
#' @param end_year ending school year.  valid values are currently 2012-2018.
#'
#' @return df of msgp data, schoolwide (and district-wide and by grade level, if reported)
#' @export

get_and_process_msgp <- function(end_year) {
  
  df_list <- get_one_rc_database(end_year)
  
  if (end_year %in% c(2012, 2013, 2014)) {
    
    df <- df_list %>% use_series('sgp')
    
    names(df) <- gsub('co_', 'county_', names(df))
    names(df) <- gsub('dist_', 'district_', names(df))
    names(df) <- gsub('sch_', 'school_', names(df))
    
    df_school_ela <- df %>%
      select(
        county_code, district_code, school_code, la_sgp, end_year) %>%
      rename(
        median_sgp = la_sgp
      ) %>%
      mutate(
        subject = 'ELA',
        grade = 'TOTAL',
        subgroup = 'total population',
        is_school = TRUE,
        is_district = FALSE
      )
    
    df_school_math <- df %>%
      select(
        county_code, district_code, school_code, m_sgp, end_year) %>%
      rename(
        median_sgp = m_sgp
      ) %>%
      mutate(
        subject = 'Math',
        grade = 'TOTAL',
        subgroup = 'total population',
        is_school = TRUE,
        is_district = FALSE
      )
    

    out <- bind_rows(df_school_ela, df_school_math) %>%
      select(
        county_code, 
        district_code, 
        school_code,
        end_year,
        subject, 
        grade,
        subgroup, 
        median_sgp,
        is_district, is_school
      ) 
  }
  
  if (end_year == 2015) {
    df_school_ela <- df_list %>%
      use_series('sgp') %>%
      select(
        county_code, district_code, school_code, ela_sgp, end_year) %>%
      rename(
        median_sgp = ela_sgp
      ) %>%
      mutate(
        subject = 'ELA',
        grade = 'TOTAL',
        subgroup = 'total population',
        is_school = TRUE,
        is_district = FALSE
      )
    
    df_school_math <- df_list %>%
      use_series('sgp') %>%
      select(
        county_code, district_code, school_code, math_sgp, end_year) %>%
      rename(
        median_sgp = math_sgp
      ) %>%
      mutate(
        subject = 'Math',
        grade = 'TOTAL',
        subgroup = 'total population',
        is_school = TRUE,
        is_district = FALSE
      )
  
    
    out <- bind_rows(df_school_ela, df_school_math) %>%
      select(
        county_code, 
        district_code, 
        school_code,
        end_year,
        subject, 
        grade,
        subgroup, 
        median_sgp,
        is_district, is_school
      ) 
  }
  
  if (end_year == 2016) {
    df_sgp <- df_list$sgp
    
    df_school <- df_sgp %>%
      select(county_code, district_code, school_code, student_growth, school_median, end_year) %>%
      rename(
        subject = student_growth,
        median_sgp = school_median
      ) %>%
      mutate(
        grade = 'TOTAL',
        subgroup = 'total population',
        is_school = TRUE,
        is_district = FALSE
      )
    
    # identify high schools by their presence in PR grad rate table
    high_school_cds <- df_list$grad_rate_by_subgroup %>%
      mutate(cds = paste0(county_code, district_code, school_code)) %>%
      pull(cds)
    
    df_district <- df_sgp %>%
      select(county_code, district_code, school_code, 
             student_growth, district_median, end_year) %>%
      # use cds in grad rate table to filter out high schools
      filter(!paste0(county_code, district_code, school_code) %in% high_school_cds) %>%
      rename(
        subject = student_growth,
        median_sgp = district_median
      ) %>%
      mutate(
        school_code = '999',
        grade = 'TOTAL',
        subgroup = 'total population',
        is_school = FALSE,
        is_district = TRUE
      ) %>%
      # assume majority of high schools have been filtered out; mode of 
      # median_sgp should return the elem value
      # checked: after filtering using cds, two districts are left with
      # multiple msgp values: 3570 (of course... *eye roll*) and 5850. 
      # 5850 only has one school with 'S' as msgp value and 3570 has eagle
      # and state school id 311 with presumably high school values
      filter(median_sgp == DescTools::Mode(median_sgp)) %>%
      unique()
    
    out <- bind_rows(df_school, df_district) %>%
      select(
        county_code, 
        district_code, 
        school_code,
        end_year,
        subject, 
        grade,
        subgroup, 
        median_sgp,
        is_district, is_school
      )      
  }
  
  if (end_year >= 2017) {
    
    # first file, msgp schoolwide
    df_schoolwide <- df_list %>% 
      use_series('student_growth') %>%
      # diff sgp measures into single column
      mutate(
        median_sgp = case_when(
          source_file == 'school' ~ school_median,
          source_file == 'district' & county_code == 'State' ~ state_median,
          source_file == 'district' ~ district_median,
          TRUE ~ NA_character_
        )
      ) %>%
      # implied grade level 
      mutate(grade = 'TOTAL') %>%
      select(-school_median, -district_median, -state_median, -met_target) %>%
      rename(
        subgroup = student_group
      ) %>%
      # subgroup normalization 
      mutate(
        subgroup = case_when(
          subgroup %in% c('Schoolwide', 'Statewide', 'Districtwide') ~ 'total population',
          subgroup %in% c("American Indian or Alaskan Native", 
                          "American Indian or Alaska Native") ~ 'american indian', 
          subgroup %in% c("Asian, Native Hawaiian, or Pacific Islander") ~ 'asian',
          subgroup %in% c("Black or African American") ~ 'black',        
          subgroup %in% c("Economically Disadvantaged",
                          "Economically Disadvantaged Students") ~ 'economically disadvantaged',                 
          subgroup %in% c("English Learners") ~ 'limited english proficiency',                
          subgroup %in% c("Hispanic") ~ 'hispanic',                      
          subgroup %in% c("Students with Disabilities") ~ 'students with disabilities',      
          subgroup %in% c("Two or More Races") ~ 'multiracial',               
          subgroup %in% c("White") ~ 'white',
          subgroup %in% c("Female") ~ 'female',
          subgroup %in% c("Male") ~ 'male',
          subgroup %in% c("Homeless Students") ~ 'homeless',
          subgroup %in% c("Students in Foster Care") ~ 'foster care',
          subgroup %in% c("Military-Connected Students") ~ 'military-connected',
          subgroup %in% c("Migrant Students") ~ 'migrant', 
          TRUE ~ subgroup
        )
      )
    
       # second file, mspg by grade
       if (end_year == 2019) {
          df_grade <- df_list %>%
             magrittr::use_series('student_growth_by_grade') %>%
             dplyr::mutate(
               median_sgp = case_when(
                  #m_sgp_school is numeric in 2019
                  source_file == 'school' ~ as.character(m_sgp_school),
                  source_file == 'district' ~ as.character(m_sgp_school),
                  TRUE ~ NA_character_
               )
            )
        
       } else if (end_year == 2018) {
         df_grade <- df_list %>%
           use_series('student_growth_by_grade') %>%
           # rename cols
           mutate(
             median_sgp = case_when(
               source_file == 'school' ~ m_sgp_school,
               source_file == 'district' ~ m_sgp_school,
               TRUE ~ NA_character_
             ) 
           )
       } else if (end_year == 2017) {
         df_grade <- df_list %>%
           use_series('student_growth_by_grade') %>%
           # rename cols
           mutate(
             median_sgp = case_when(
               source_file == 'school' ~ m_sgp_school,
               source_file == 'district' ~ m_sgp_district,
               TRUE ~ NA_character_
             ) 
           )
       }
    
    df_grade <- df_grade %>%
      # tidy column names
      rename_all(
        recode, 
        ela_math = "subject"
      ) %>%
      # implied
      mutate(
        subgroup = 'total population'
      )
    
    # combine
    out <- bind_rows(df_schoolwide, df_grade) %>%
      select(
        county_code, 
        district_code, 
        school_code,
        end_year,
        subject, 
        grade,
        subgroup, 
        median_sgp,
        is_district, is_school
      )
  }
  
  # clean up
  out <- out %>%
    rename(
      county_id = county_code,
      district_id = district_code,
      school_id = school_code
    ) %>%
    mutate(
      subject = tolower(subject)
    )
  
  out
}


#' Fetch mSGP
#'
#' @inheritParams get_and_process_msgp
#'
#' @return dataframe with mSGP data for the year
#' @export

fetch_msgp <- function(end_year) {
  get_and_process_msgp(end_year)
}