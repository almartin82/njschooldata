#' Get Special Population Enrollment from Report Card Files
#'
#' @param end_year ending academic year.  valid values are 2017, 2018, 2019
#'
#' @return data.frame with special population enrollment percentages
#' @keywords internal
get_reportcard_special_pop <- function(end_year) {
  
  df_list <- get_one_rc_database(end_year)
  
  out <- df_list %>% 
    use_series('enrollment_trends_by_student_group')
  
  enr <- df_list %>%
    list() %>%
    extract_rc_enrollment() %>%
    filter(grade_level == "TOTAL") %>%
    select(county_code, district_code, school_code, 
           end_year, n_enrolled)

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
  
  out <- out %>%
    left_join(enr,
              by = c("county_code", "district_code", 
                     "school_code", "end_year")) %>% 
    # is there a better solution for below w/ recover_enrollment() ?
    mutate(n_enrolled = as.numeric(n_enrolled),
           percent = as.numeric(percent),
           n_students = round(percent / 100 * n_enrolled),
           n_students = if_else(n_students == 0 & percent > 0, 1, n_students)) 
    
  
  return(out)
}


#' Process Report Card Special Population Data
#'
#' @param df raw special pop dataframe - output of get_reportcard_special_pop
#'
#' @return tidy dataframe with conforming id columns
#' @keywords internal
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
          "Disability", "Students with Disabilities", "students_with_disabilities"
        ) ~ 'IEP',
        subgroup %in% c(
          "Econdis", "Economically Disadvantaged Students", 
          "economically_disadvantaged_students"
        ) ~ 'Economically Disadvantaged',
        subgroup %in% c(
          "English Learners", "english_learners", "LEP"
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
      county_id,
      district_id,
      school_id, school_name, 
      end_year, 
      subgroup, n_enrolled, percent, n_students,
      is_district, is_school
    )
}