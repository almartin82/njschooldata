# Global variable declarations to avoid R CMD check NOTEs
# These are column names used in dplyr/tidyr operations via non-standard evaluation

utils::globalVariables(c(
  # ========== Column Names with Special Characters ==========
  "% of Total Salaries",
  "%English Learners", "%Multilingual Learners", "%Free Lunch", "%Homeless", "%Migrant", "%Military", "%Reduced Lunch",
  "Multilingual Learners", "Hawaiian Native", "%Hawaiian Native", "Column1", "Column2",
  "Cost as a percentage of the Total Budgetary Cost Per Pupil",
  "Pre-K Halfday", "Ungraded",

  # ========== Package Data Objects ==========
  "charter_city", "sped_lookup_map", "nwk_address_addendum", "geocoded_cached",
  "layout_gepa", "layout_gepa05", "layout_gepa06",
  "layout_hspa", "layout_hspa04", "layout_hspa05", "layout_hspa06", "layout_hspa10",
  "layout_njask", "layout_njask04", "layout_njask05", "layout_njask06gr3",
  "layout_njask06gr5", "layout_njask07gr3", "layout_njask07gr5", "layout_njask09", "layout_njask10",

  # ========== ID Columns ==========
  "county_id", "county_name", "county_code",
  "district_id", "district_name", "district_code",
  "district_id_full", "district_id_short",
  "school_id", "school_name", "school_code",
  "CDS_Code",

  # ========== Raw Column Names (with spaces/special chars) ==========
  "District Code", "School Code", "County Code",
  "COUNTY_CODE", "COUNTY_NAME", "DISTRICT_CODE", "DISTRICT_NAME",
  "SCHOOL_CODE", "SCHOOL_NAME",
  "County Name", "District Name", "School Name",
  "Total Enrollment", "Grade", "Grade_Level",

  # ========== Enrollment Columns ==========
  "end_year", "yy", "n_students", "pct", "pct_total_enr",
  "grade_level", "program_code", "program_name",
  "subgroup", "subgroup_type", "rowname",
  "row_total", "rowtotal",
  "n_enrolled", "n_schools", "n_charter",
  "source_file", "level", "enr_2013",

  # Enrollment - gender
  "male", "female", "non_binary",

  # Enrollment - race/ethnicity (aggregated)
  "white", "black", "hispanic", "asian",
  "native_american", "pacific_islander", "multiracial",

  # Enrollment - race/ethnicity by gender
  "white_m", "white_f",
  "black_m", "black_f",
  "hispanic_m", "hispanic_f",
  "asian_m", "asian_f",
  "native_american_m", "native_american_f",
  "pacific_islander_m", "pacific_islander_f",
  "multiracial_m", "multiracial_f",

  # Enrollment - lunch status
  "free_lunch", "reduced_lunch", "free_reduced_lunch",

  # Enrollment - other special programs
  "lep", "migrant", "homeless", "military", "title_1", "special_ed",

  # ========== Assessment Columns ==========
  "testing_year", "assess_name", "test_name", "grade",
  "pct_l1", "pct_l2", "pct_l3", "pct_l4", "pct_l5", "pct_l6",
  "num_l1", "num_l2", "num_l3", "num_l4", "num_l5", "num_l6",
  "proficient_above", "scale_score_mean",
  "number_enrolled", "number_not_tested",
  "number_of_valid_scale_scores",
  "valid_scores", "prof_above",
  "scale_score_numerator",

  # ========== Graduation Columns ==========
  "methodology", "grad_rate", "grad_count",
  "cohort_count", "graduated_count",
  "four_year_grad_rate", "five_year_grad_rate",
  "group", "subgroup",
  "total_population", "postgrad_grad",
  "outcome_count", "num_grad",
  "instate", "outstate",
  "program_name_dirty", "iter_key",
  "hisp_m", "hisp_f",
  "nat_am_m", "nat_am_f",
  "hwn_nat_m", "hwn_nat_f",
  "american_indian",
  # Graduation rate validation/recovery columns
  "total_cohort", "calculated_rate", "grad_rate_original", "grad_rate_recovered",
  "calculated_from_schools", "aggregation_flag", "rate_discrepancy_pp",
  "n_schools_with_data", "school_total_cohort", "school_names",
  "ok", "total_records",

  # ========== Boolean Flags ==========
  "is_state", "is_county", "is_district", "is_school",
  "is_charter", "is_charter_sector", "is_allpublic",
  "is_dfg", "is_citywide", "is_subprogram",
  "is_16mo",

  # ========== Geographic Columns ==========
  "lat", "lng", "lat.x", "lat.y", "lng.x", "lng.y",
  "address", "address1", "address_2", "address_3",
  "city", "state", "zip", "ward", "locations",

  # ========== Host District (Charter Aggregations) ==========
  "host_county_id", "host_county_name",
  "host_district_id", "host_district_name",

  # ========== Matriculation Columns ==========
  "enroll_any", "enroll_2yr", "enroll_4yr",
  "enroll_any_count", "enroll_2yr_count", "enroll_4yr_count",
  "matric_rate",
  "orig_end_year",

  # ========== Postsecondary Enrollment Columns ==========
  "cds_code", "record_type", "cohort_year", "measurement_type",
  "lower_bound", "upper_bound",
  "cds_county_district_school_code", "school_district_state",

  # ========== Special Populations ==========
  "economically_disadvantaged", "students_with_disabilities",
  "economically_disadvantaged_students",
  "english_learners", "homeless_students",
  "students_in_foster_care", "military_connected_students",
  "migrant_students",
  "student_group", "percent",
  "lep_current", "lep_former", "lep_current_former",

  # ========== DFG (District Factor Group) ==========
  "dfg", "dfg_code", "x1990_dfg", "x2000_dfg",

  # ========== SGP/Growth Columns ==========
  "ela_sgp", "la_sgp", "m_sgp", "math_sgp", "median_sgp", "student_growth",
  "district_median", "school_median", "state_median", "school_mean", "met_target",

  # ========== Peer Percentile Columns ==========
  "proficiency_percentile", "proficient_above.x", "proficient_above.y", "proficient_diff",
  "proficient_group_size", "proficient_rank",
  "scale_group_size", "scale_rank", "scale_score_diff",
  "scale_score_mean.x", "scale_score_mean.y", "scale_score_percentile",
  "statewide_proficient_percentile", "statewide_scale_percentile",
  "count_proficient_dummy", "count_scale_dummy",

  # ========== Generic Percentile Rank Columns (percentile_rank.R) ==========
  ".metric_valid", "sector", "threshold", "is_above_threshold",
  "n_students_total", "n_students_above", "n_schools_total", "n_schools_above",
  "pct_students_access", "pct_schools_above",
  # Dynamic column names - base patterns
  "grad_rate_rank", "grad_rate_n", "grad_rate_percentile",
  "proficient_above_rank", "proficient_above_n", "proficient_above_percentile",
  "dfg_grad_rate_rank", "dfg_grad_rate_n", "dfg_grad_rate_percentile",
  # Trend columns
  "grad_rate_percentile_yoy_change", "grad_rate_percentile_cumulative_change",
  "grad_rate_percentile_baseline",
  # Gap analysis columns (Extension #1)
  ".gap_for_rank", "subgroup_pair",
  "grad_rate_a", "grad_rate_b", "grad_rate_gap", "grad_rate_gap_pct",
  "grad_rate_gap_equity_rank", "grad_rate_gap_equity_n", "grad_rate_gap_equity_percentile",
  "grad_rate_gap_yoy_change", "grad_rate_gap_cumulative_change", "grad_rate_gap_baseline",
  "proficient_above_a", "proficient_above_b", "proficient_above_gap", "proficient_above_gap_pct",
  # Sector ecosystem columns (Extension #3)
  "charter_value", "district_value", "sector_gap", "sector_leader",
  "charter_enrollment", "total_enrollment", "charter_share", "district_enrollment",
  "allpublic_value", "allpublic_percentile",

  # ========== TGES (Taxpayers Guide) ==========
  "indicator", "indicator_value",

  # ========== SPED Columns ==========
  "gened_num", "sped_num", "sped_rate",
  "sped_num_no_speech", "sped_rate_no_speech",

  # ========== Chronic Absenteeism Columns ==========
  "configuration", "chronic_absenteeism_total",
  "attendance_asian_pacific", "attendance_black", "attendance_ed",
  "attendance_hispanic", "attendance_ell", "attendance_native_american",
  "attendance_multiracial", "attendance_swd", "attendance_white", "attendance_total",

  # ========== PARCC/Assessment Aggregates ==========
  "districts", "schools", "n_charter_rows",
  "gradespan",

  # ========== Report Card Columns ==========
  "year", "test", "subject",
  "math", "reading",
  "report_category", "school_percent", "students_taking",
  "pct_tested_ap_ib", "pct_ap_scoring_3",
  "school_participation",

  # ========== Utility/Helper Columns ==========
  "hash", "Name", "cds", "denom", "extension", "num", "round_1", "temp_id",
  "nrow_before",

  # ========== SAT/ACT/PSAT Assessment Columns ==========
  "SAT", "ACT", "PSAT",
  "STATE_SAT", "STATE_ACT", "STATE_PSAT",
  "sat_participation", "act_participation", "psat_participation",
  "state_sat", "state_act", "state_psat",
  "School_Avg", "State_avg", "BT_PCT", "STATE_BT_PCT",
  "Benchmark", "Test", "Subject", "StudentGroup",
  "Perc12Graders", "Continuing", "Non-Continuing",
  "Graduates", "Students", "Language",
  "CountyCode", "CountyName", "DistrictCode", "DistrictName",
  "SchoolCode", "SchoolName", "SealsEarned",
  "ap3_ib4_school", "ap3_ib4_state", "ap_3_ib_4_school", "ap_3_ib_4_state",
  "has_ap", "has_ib",

  # ========== College & Career Readiness Columns ==========
  "ap_access_rate", "stem_participation_rate",
  "apib_course_school", "apib_course_state",
  "apib_coursework_school", "apib_coursework_state",
  "apib_exam_school", "apib_exam_state",
  "dual_enrollment_school", "dual_enrollment_state",
  "cte_concentrators", "cte_participants",
  "school_cteconcentrators", "school_cteparticipants",
  "state_cte_concentrators", "state_cte_participants",
  "state_cteconcentrators", "state_cteparticipants",
  "students_enrolled_in_program", "students_participating",
  "students_participating_in_work_based_learning",
  "perc_students_participating_learning_by_cluster",
  "career_cluster", "industry_credentials_earned",
  "atleast_one_credential_earned", "earned_one_credential",
  "credentials_earned", "n_cs", "n_math", "n_science", "n_stem_students",
  "n_total_students", "total_staff", "student_staff_ratio",

  # ========== Graduation Rate Columns (6-year) ==========
  "grad_rate_6yr", "grad_rate_4yr", "grad_rate_5yr",
  "retention_rate", "continuing_rate", "non_continuing_rate",
  "persistence_rate", "HighSchoolPersistance",
  "turnover_rate", "stability_index", "diversity_index",
  "gender_diversity_score", "flag_large_gap",
  "year_over_year_change", "year_over_year_pct_change",
  "multi_year_trend", "trend_slope", "trend", "prev_value",
  "n_unique_years", "n_years", "prop", "metric_name", "metric_value",
  "total_population_rate", "pct_12th_graders", "pct_participating",
  "access_rate", "access_gap_percentage", "lm", "coef",
  "weighted_avg", "weighted.mean",

  # ========== Common Tidyverse ==========
  ".", "value", "name", "n",
  "everything", "where", "one_of", "any_of", "all_of",
  "starts_with", "ends_with", "contains", "matches"
))
