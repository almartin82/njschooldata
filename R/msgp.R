#' Get and Process mSGP data
#'
#' @param end_year ending school year.  valid values are currently 2012-2018.
#'
#' @return df of msgp data, schoolwide (and district-wide and by grade level, if reported)
#' @export

get_and_process_msgp <- function(end_year) {
  
  
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
    
    df_district_ela <- df %>%
      select(
        county_code, district_code, la_sgp, end_year) %>%
      rename(
        median_sgp = la_sgp
      ) %>%
      unique() %>%
      mutate(
        school_code = '999',
        subject = 'ELA',
        grade = 'TOTAL',
        subgroup = 'total population',
        is_school = FALSE,
        is_district = TRUE
      )
    
    df_district_math <- df %>%
      select(
        county_code, district_code, m_sgp, end_year) %>%
      rename(
        median_sgp = m_sgp
      ) %>%
      unique() %>%
      mutate(
        school_code = '999',
        subject = 'Math',
        grade = 'TOTAL',
        subgroup = 'total population',
        is_school = FALSE,
        is_district = TRUE
      )
    
    out <- bind_rows(df_school_ela, df_school_math, df_district_ela, df_district_math) %>%
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
    
    
    df_district_ela <- df %>%
      select(
        county_code, district_code, ela_sgp, end_year) %>%
      rename(
        median_sgp = ela_sgp
      ) %>%
      unique() %>%
      mutate(
        school_code = '999',
        subject = 'ELA',
        grade = 'TOTAL',
        subgroup = 'total population',
        is_school = FALSE,
        is_district = TRUE
      )
    
    df_district_math <- df %>%
      select(
        county_code, district_code, math_sgp, end_year) %>%
      rename(
        median_sgp = math_sgp
      ) %>%
      unique() %>%
      mutate(
        school_code = '999',
        subject = 'Math',
        grade = 'TOTAL',
        subgroup = 'total population',
        is_school = FALSE,
        is_district = TRUE
      )
    
    out <- bind_rows(df_school_ela, df_school_math, df_district_ela, df_district_math) %>%
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
    
    df_district <- df_sgp %>%
      select(county_code, district_code, student_growth, district_median, end_year) %>%
      rename(
        subject = student_growth,
        median_sgp = district_median
      ) %>%
      unique() %>%
      mutate(
        school_code = '999',
        grade = 'TOTAL',
        subgroup = 'total population',
        is_school = FALSE,
        is_district = TRUE
      )
    
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
          subgroup %in% c("American Indian or Alaskan Native") ~ 'american indian', 
          subgroup %in% c("Asian, Native Hawaiian, or Pacific Islander") ~ 'asian',
          subgroup %in% c("Black or African American") ~ 'black',        
          subgroup %in% c("Economically Disadvantaged") ~ 'economically disadvantaged',                 
          subgroup %in% c("English Learners") ~ 'limited english proficiency',                
          subgroup %in% c("Hispanic") ~ 'hispanic',                      
          subgroup %in% c("Students with Disabilities") ~ 'students with disabilities',      
          subgroup %in% c("Two or More Races") ~ 'multiracial',               
          subgroup %in% c("White") ~ 'white',
          TRUE ~ subgroup
        )
      )
    
    # second file, mspg by grade
    if (end_year == 2018) {
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
  
  # clean upt
  out <- out %>%
    rename(
      county_id = county_code,
      district_id = district_code,
      school_id = school_code
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