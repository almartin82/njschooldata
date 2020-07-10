
enumerate_possibilities <- function(max=500) {

  all_combos <- expand.grid(rep(list(0:max), 2)) %>%
    as_tibble() %>%
    unique()
  names(all_combos) <- c('num', 'denom')

  all_combos %>%
    filter(denom > 0 & num <= denom) %>%
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
  filter(subgroup=='Total Population') %>%
  print.AsIs()


spr_enr <- extract_rc_enrollment(pr_old)
spr_enr %>%
  filter(district_code == '3570' & school_code == '057' & grade_level == '12')

enr_old <- enr_2013 %>%
  filter(district_id == '3570' & school_id == '057' & grade_level == '12')

univ <- enumerate_possibilities(129)

univ %>%
  filter(round_1 %in% c(68.2)) %>%
  print.AsIs()

}


infer_postsec_n <- function(end_year) {

  # get the progress report
  pr <- get_rc_databases(end_year)

  # extract matriculation
  matric <- extract_rc_college_matric(pr) %>%
    filter(subgroup=='Total Population') %>%
    mutate(
      enroll_any = enroll_any,
      enroll_4yr = enroll_4yr,
      enroll_2yr = enroll_2yr
    )

  # extract spring enrollment and limit to grade 12
  spr_enr <- extract_rc_enrollment(pr) %>%
    filter(grade_level == '12') %>%
    select(-county_name, -district_name, -school_name, -grade_level) %>%
    mutate(n_enrolled = as.numeric(n_enrolled))

  # join spring enrollment to matriculation
  matric <- matric %>%
    left_join(spr_enr, by=c('end_year', 'county_code', 'district_code', 'school_code'))

  # OR fall enrollment?

  # OR grad rate denominator from grate?

  # for every row, enumerate potentnial g / n values.  pick value that is
  # plausible that minimizes n - reported spring n

  # all within .05
  # g / n
  # 4y / g
  # 2y / g

  matric$estimated_g <- NA_integer_
  matric$estimated_n <- NA_integer_

  # if multiple solutions, prefer the solution that minimizes (n - reported n)
  for (i in 1:nrow(matric)) {
    row <- matric[i, ]
    max_search <- round(row$n_enrolled, 0) * 1.5
    candidates <- enumerate_possibilities(max_search)
    print(row$school_name)

    best_guess <- find_best(
      candidates, row$enroll_any, row$enroll_4yr, row$enroll_2yr, row$n_enrolled
    )

    guess_num <- ifelse(nrow(best_guess)==0, NA_integer_, best_guess$num)
    guess_denom <- ifelse(nrow(best_guess)==0, NA_integer_, best_guess$denom)
    matric[i, 'estimated_g'] <- guess_num
    matric[i, 'estimated_n'] <- guess_denom
  }


  matric %>%
    filter(district_code == '3570') %>%
    peek()
}


find_best <- function(candidates, enroll_any, enroll_4yr, enroll_2yr, reported_n) {
  # limit candidates to enroll_any matches
  df <- candidates %>%
    filter(round_1 == enroll_any) %>%
    mutate(
      diff = reported_n - denom
    )

  # are the 4yr and 2yr consistent?
  df <-  df %>%
    mutate(
      num_4yr = round((enroll_4yr / 100) * num, 0),
      num_2yr = round((enroll_2yr / 100) * num, 0),
      num_4yr_pct = round(num_4yr / num * 100, 1),
      num_2yr_pct = round(num_2yr / num * 100, 1),
      num_4yr_test = abs(enroll_4yr - num_4yr_pct) < .1,
      num_2yr_test = abs(enroll_2yr - num_2yr_pct) < .1
    ) %>%
    filter(num_4yr_test & num_2yr_test)

  df %>%
    mutate(
      diff_rank = rank(abs(diff), ties.method='first')
    ) %>%
    filter(diff_rank == 1)
}

find_best(candidates, row$enroll_any, row$enroll_4yr, row$enroll_2yr, row$n_enrolled) %>%
  filter(diff_rank < 10) %>%
  print.AsIs()


# g = number of graduates
# n = total number of 12th students
# g is unknown
# g/n is known to 3 decimals




infer_postsec_counts <- function(many_matric, many_rc_enr) {

  # lag matric df by one year to get prior year 12th grade enr


  # for each row, enumerate percentages and pick closest match


  # apply the postsec matric percentages to the enrollment assumption



}

