foo <- all_assess_tidy %>%
  dplyr::filter(testing_year == 2014)

# peer_percentile_scale_pipe <- . %>%
#   dplyr::ungroup() %>%
#   dplyr::mutate(
#     num_proficient = ((100 - partially_proficient) / 100) * 
#       number_valid_scale_scores,
#     num_proficient = round(num_proficient, 0)
#   ) 

peer_percentile_pipe <- . %>%
  dplyr::ungroup() %>%
#  dplyr::rowwise() %>%
  dplyr::mutate(
    proficient_above = proficient + advanced_proficient,
    count_proficient_dummy = ifelse(is.finite(proficient_above), 1, 0),
    count_scale_dummy = ifelse(is.finite(scale_score_mean), 1, 0)
  ) %>%
  dplyr::group_by(
    assess_name, testing_year, grade, subgroup, test_name
  ) %>%
  dplyr::mutate(
    proficient_numerator_asc = dplyr::dense_rank(proficient_above),
    proficient_denominator = sum(count_proficient_dummy),
    
    scale_numerator_asc = dplyr::dense_rank(scale_score_mean),
    scale_denominator = sum(count_scale_dummy),

    proficiency_percentile = proficient_numerator_asc / proficient_denominator,
    scale_score_percentile = scale_numerator_asc / scale_denominator
  )
  

bizz <- foo %>%
  peer_percentile_pipe()

head(bizz) %>% print.AsIs()


peer_percentile_pipe <- . %>%
  dplyr::mutate(
    count_proficient_dummy = ifelse(is.finite(l3_l4_pct), 1, 0),
    count_scale_dummy = ifelse(is.finite(mean_scale_score), 1, 0)
  ) %>%
  dplyr::group_by(
    test_year,
    test_subject,
    test_grade_string,
    subgroup_code,
    is_school, is_district,
    is_multigrade_aggregate
  ) %>%
  dplyr::mutate(
    proficient_numerator_asc = dplyr::dense_rank(l3_l4_pct),
    proficient_numerator_desc = dplyr::dense_rank(dplyr::desc(l3_l4_pct)),
    proficient_denominator = sum(count_proficient_dummy),
    
    scale_numerator_asc = dplyr::dense_rank(mean_scale_score),
    scale_numerator_desc = dplyr::dense_rank(dplyr::desc(mean_scale_score)),
    scale_denominator = sum(count_scale_dummy),
    
    proficiency_percentile = proficient_numerator_asc / proficient_denominator,
    scale_score_percentile = scale_numerator_asc / scale_denominator
  ) %>%
  dplyr::select(-count_proficient_dummy, -count_scale_dummy)



calc_nj_percentiles(tidy_df, test_year) {
  
  #split out: districts
  
  #split out: schools
  
  #split out: everything else
  
  #calc scale and prof peer percentiles, districts
  
  #calc scale and prof peer percentiles, schools
  
  #put everything back together and return
}
