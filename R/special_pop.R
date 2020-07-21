#' Get Special Population Enrollment from Report Card Files
#'
#' @param end_year ending academic year.  valid values are 2017, 2018, 2019
#'
#' @return data.frame with special population enrollment percentages
#' @export

get_reportcard_special_pop <- function(end_year) {
  
  df_list <- get_one_rc_database(end_year)
  
  if (end_year == 2016) { # 2016 contains a few sheets, only school level
    
    out <- df_list %>%
      use_series('enrollment_by_spec_pop') %>%
      left_join(use_series(df_list, 'enrollment_by_gender'),
                by = c('end_year', 'county_code', 'district_code', 'school_code'))
    
    pop_names <- c(
      'female', 'male', 'economically_disadvantaged', 'disability', 'lep'
    )
    
    out <- out %>%
      mutate(
        female = as.numeric(female),
        male = as.numeric(male)
      ) %>%
      pivot_longer(
        cols = pop_names,
        names_to = 'student_group',
        values_to = 'percent'
      ) %>%
      mutate(
        school_name = NA_character_,
        is_district = if_else(school_code == '999', 1, 0),
        is_school = if_else(school_code != '999', 1, 0)
      )
    
  } else { 
    out <- df_list %>% 
      use_series('enrollment_trends_by_student_group')
  
      # 2018, 2019 it's wide
      if (end_year >= 2018) {
        
        pop_names <- c(
          "female", "male", "economically_disadvantaged_students", "students_with_disabilities", 
          "english_learners", "homeless_students", "students_in_foster_care", 
          "military_connected_students", "migrant_students"
        )
          
        out <- pivot_longer(
          data = out,
          cols = one_of(pop_names), 
          names_to = 'student_group',
          values_to = 'percent' 
        )
      }
    
  }
  out
}


#' Process Report Card Special Population Data
#'
#' @param df raw special pop dataframe - output of get_reportcard_special_pop
#'
#' @return tidy dataframe with conforming id columns
#' @export

process_reportcard_special_pop <- function(df) {
  df %>%
    rename(subgroup = student_group) %>%
    rename(
      county_id = county_code,
      district_id = district_code,
      school_id = school_code
    ) %>%
    mutate(
      subgroup = case_when(
        subgroup %in% c(
          "Disability", "Students with Disabilities", "students_with_disabilities",
          "disability"
        ) ~ 'IEP',
        subgroup %in% c(
          "Econdis", "Economically Disadvantaged Students", 
          "economically_disadvantaged_students",
          "economically_disadvantaged"
        ) ~ 'Economically Disadvantaged',
        subgroup %in% c(
          "English Learners", "english_learners", "LEP", "lep"
        ) ~ 'English Learners',
        subgroup %in% c("Homeless Students", "homeless_students") ~ 'Homeless',
        subgroup %in% c("Migrant Students", "migrant_students") ~ 'Migrant',
        subgroup %in% c(
          "military_connected_students", "Military-Connected Students"
        ) ~ 'Military-Connected',
        subgroup %in% c(
          "Students in Foster Care", "students_in_foster_care"
        ) ~ 'Foster Care',
        subgroup %in% c("male", "Male") ~ 'Male', 
        subgroup %in% c("female", "Female") ~ 'Female',
        TRUE ~ subgroup
      ),
      
      percent = as.numeric(percent)
    )
}


#' Fetch Special Population data
#'
#' @inheritParams get_reportcard_special_pop
#'
#' @return data.frame with special population enrollment data
#' @export

fetch_reportcard_special_pop <- function(end_year) {
  get_reportcard_special_pop(end_year) %>%
    process_reportcard_special_pop() %>%
    select(
      one_of(
        'county_id',
        'district_id',
        'school_id', 'school_name', 
        'end_year', 
        'subgroup', 'percent',
        'is_district', 'is_school'
      )
    )
}