
enumerate_possibilities <- function(max=500) {
  
  all_combos <- gtools::combinations(
    n=max, 
    r=2, 
    repeats.allowed = TRUE
  ) %>%
  as_tibble()
  
  names(all_combos) <- c('num', 'denom')
  
  all_combos %>%
    mutate(
      percent = num / denom,
      round_1 = round(percent * 100, 1),
      round_4 = round(percent * 100, 4),
      trunc_1 = trunc2(percent * 100, prec=1),
      trunc_4 = trunc2(percent * 100, prec=4)
    )
}


foo <- function() {
  
pr_2013 <- get_one_rc_database(2013)

pr_old <- get_rc_databases(2013:2014)
matric_old <- extract_rc_college_matric(pr_old)

univ_old <- matric_old %>%
  filter(district_code == '3570' & school_code == '057')

univ_old %>% 
  filter(subgroup=='Schoolwide') %>%
  print.AsIs()

enr_old <- enr_2013 %>% 
  filter(district_id == '3570' & school_id == '057' & grade_level == '12')

univ <- enumerate_possibilities(140)

univ %>% 
  filter(round_1 %in% c(68.2, 71.6, 67.8)) %>%
  print.AsIs()

}


infer_postsec_counts <- function(many_matric, many_rc_enr) {
  
  # lag matric df by one year to get prior year 12th grade enr
  
  
  # for each row, enumerate percentages and pick closest match
  
  
  # apply the postsec matric percentages to the enrollment assumption
  
  
  
} 

