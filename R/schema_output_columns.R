# Fixed column order and storage classes for the harmonized SPR fetchers.
.spr_identifier_types <-
c(end_year = "numeric", county_id = "character", county_name = "character",
district_id = "character", district_name = "character", school_id = "character",
school_name = "character")
.spr_aggregation_types <-
c(is_state = "logical", is_county = "logical", is_district = "logical",
is_school = "logical", is_charter = "logical", is_charter_sector = "logical",
is_allpublic = "logical")
.spr_output_schemas <- list(
  essa_status = c(.spr_identifier_types,
    c(status_for_sy = "character", category_of_identification = "character",
    year_eligible_to_exit_status = "character", student_groups = "character",
    status_note = "character", student_group_status_white = "character",
    student_group_status_hispanic = "character", student_group_status_black = "character",
    student_group_status_asian = "character", student_group_status_american_indian = "character",
    student_group_status_twoor_more_races = "character", student_group_status_econ_dis = "character",
    student_group_status_swd = "character", student_group_status_el = "character",
    notes = "character")
    , .spr_aggregation_types),
  days_absent = c(.spr_identifier_types,
    c(absent_0_pctdays = "character", absent_0_1_to_6_9_pctdays = "character",
    absent_7_0_to_9_9_pctdays = "character", absent_10_0_to_12_9_pctdays = "character",
    absent_13_0_to_19_9_pctdays = "character", absent_20_pctplusdays = "character",
    absent_gt0_to_6_9_pctdays = "character", abs_0 = "character",
    abs_1_5 = "character", abs_6_10 = "character", abs_11_15 = "character",
    abs_over_15 = "character", abs_15_plus = "character")
    , .spr_aggregation_types),
  spr_grad_cohort = c(.spr_identifier_types,
    c(cohort_type = "character", subgroup = "character", graduated = "numeric",
    continuing = "numeric", non_continuing = "numeric", persisting = "numeric"
    )
    , .spr_aggregation_types),
  spr_fed_grad = c(.spr_identifier_types,
    c(subgroup = "character", cohort_years = "numeric", cohort_label = "character",
    graduation_rate_federal = "numeric")
    , .spr_aggregation_types),
  dropout_rates = c(.spr_identifier_types,
    c(dropout_school = "character", dropout_district = "character",
    dropout_state = "character")
    , .spr_aggregation_types),
  spr_grad_pathways = c(.spr_identifier_types,
    c(subject = "character", statewide_assessment = "numeric", substitute_competency_test = "numeric",
    portfolio_appeals = "numeric", alternate_requirements_in_iep = "numeric"
    )
    , .spr_aggregation_types),
  teacher_experience = c(.spr_identifier_types,
    c(teacher_count_district = "character", teacher_count_state = "character",
    teacher_avg_years_exp_district = "character", teacher_avg_years_exp_state = "character",
    teacher_avg_years_exp_in_district_district = "character", teacher_avg_years_exp_in_district_state = "character",
    number_teacher_4_years_or_more_years_district = "character",
    number_teacher_4_years_or_more_years_state = "character", percentage_teacher_4_years_or_more_years_district = "character",
    percentage_teacher_4_years_or_more_years_state = "character",
    number_of_out_of_field_teachers = "character", number_of_out_of_field_teachers_state = "character",
    percentage_of_out_of_field_teachers = "character", percentage_of_out_of_field_teachers_state = "character",
    number_teachers_with_provisional_credentials_district = "character",
    number_teachers_with_provisional_credentials_state = "character",
    percentage_teachers_with_provisional_credentials_district = "character",
    percentage_teachers_with_provisional_credentials_state = "character",
    teacher_count_school = "character", teacher_avg_years_exp_school = "character",
    teacher_avg_years_exp_in_district_school = "character", number_teacher_in_district_4_years_or_more_school = "character",
    number_teacher_in_district_4_years_or_more_state = "character",
    percentage_teacher_in_district_4_years_or_more_school = "character",
    percentage_teacher_in_district_4_years_or_more_state = "character",
    number_teachers_with_provisional_credentials_school = "character",
    percentage_teachers_with_provisional_credentials_school = "character",
    number_teacher_in_district_4_years_or_more_district = "character",
    percentage_teacher_in_district_4_years_or_more_district = "character",
    teacher_in_district_4_years_or_more_district = "character", teacher_in_district_4_years_or_more_state = "character",
    number_teacher_4_years_or_more_years_school = "character", percentage_teacher_4_years_or_more_years_school = "character",
    teacher_in_district_4_years_or_more_school = "character")
    , .spr_aggregation_types),
  staff_ratios = c(.spr_identifier_types,
    c(student_teacher_district = "character", student_admin_district = "character",
    teacher_admin_district = "character", student_librarian_district = "character",
    student_nurse_district = "character", student_counselor_district = "character",
    student_child_study_district = "character", school_psychologists_district = "character",
    school_social_workers_district = "character", student_assistance_coordinators_district = "character",
    school_safety_specialists_district = "character", student_teacher_school = "character",
    student_admin_school = "character", teacher_admin_school = "character",
    student_librarian_school = "character", student_nurse_school = "character",
    student_counselor_school = "character", student_child_study_school = "character",
    school_psychologists = "character", school_social_workers = "character",
    student_assistance_coordinators = "character", school_safety_specialists = "character"
    )
    , .spr_aggregation_types),
  disciplinary_removals = c(.spr_identifier_types,
    c(student_group_grade = "character", in_school_count = "character",
    in_school_pct = "character", outof_school_count = "character",
    outof_school_pct = "character", any_susp_count = "character",
    any_susp_pct = "character", removal_count = "character", removal_pct = "character",
    expulsion_count = "character", expulsion_pct = "character", value_status = "character",
    subgroup = "character", subgroup_std = "character", grade_level = "character",
    n_students = "numeric", arrest_count = "character", arrest_pct = "character",
    school_days_missed_oss = "character")
    , .spr_aggregation_types),
  violence_vandalism_hib = c(.spr_identifier_types,
    c(violence = "character", weapons = "character", vandalism = "character",
    substances = "character", harassment_intimidation_bullying_hib = "character",
    total_unique_incidents = "character", incidents_per_100_students_enrolled = "character",
    value_status = "character", n_students = "numeric")
    , .spr_aggregation_types),
  police_notifications = c(.spr_identifier_types,
    c(violence = "numeric", weapons = "numeric", vandalism = "numeric",
    substances = "numeric", hib = "numeric", other_incidents = "numeric",
    value_status = "character", n_students = "numeric")
    , .spr_aggregation_types),
  hib_investigations = c(.spr_identifier_types,
    c(hib_nature = "character", hib_alleged = "numeric", hib_confirmed = "numeric",
    total_hib_investigations = "numeric")
    , .spr_aggregation_types),
  sat_performance = c(.spr_identifier_types,
    c(test_type = "character", subject = "character", district_avg = "character",
    school_avg = "character", state_avg = "character", benchmark = "character",
    pct_benchmark = "character", state_pct_benchmark = "character",
    bt_pct = "character")
    , .spr_aggregation_types),
  ap_participation = c(.spr_identifier_types,
    c(apib_coursework_school = "character", apib_coursework_state = "character",
    apib_exam_school = "character", apib_exam_state = "character",
    ap3_ib4_school = "character", ap3_ib4_state = "character", dual_enrollment_school = "character",
    dual_enrollment_state = "character")
    , .spr_aggregation_types),
  industry_credentials = c(.spr_identifier_types,
    c(career_cluster = "character", students_enrolled = "character",
    earned_one_credential = "character", credentials_earned = "character"
    )
    , .spr_aggregation_types),
  math_course_enrollment = c(.spr_identifier_types,
    c(grade = "character", algebra_i = "numeric", geometry = "numeric",
    algebra_ii = "numeric", pre_calculus = "numeric", calculus = "numeric",
    statistics = "numeric", other_math = "numeric")
    , .spr_aggregation_types),
  sgp_trends = c(.spr_identifier_types,
    c(subgroup = "character", ela_median_sgp = "numeric", ela_median_sgp_category = "character",
    ela_median_sgp_state = "numeric", ela_median_sgp_state_category = "character",
    math_median_sgp = "numeric", math_median_sgp_category = "character",
    math_median_sgp_state = "numeric", math_median_sgp_state_category = "character",
    ela_met_target = "character", math_met_target = "character")
    , .spr_aggregation_types),
  sgp_by_grade = c(.spr_identifier_types,
    c(subject = "character", grade = "character", median_sgp = "numeric",
    median_sgp_category = "character")
    , .spr_aggregation_types),
  sgp_by_performance_level = c(.spr_identifier_types,
    c(subject = "character", njsla_performance_level = "character",
    median_sgp = "numeric", median_sgp_category = "character")
    , .spr_aggregation_types)
)
