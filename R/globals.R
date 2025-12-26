# Global variable declarations to avoid R CMD check NOTEs
# These are column names used in dplyr/tidyr operations via non-standard evaluation

utils::globalVariables(c(
  # ========== ID Columns ==========
  "county_id", "county_name", "county_code",
  "district_id", "district_name", "district_code",
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
  "n_enrolled", "n_schools",
  "source_file", "level",

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
  "pct_l1", "pct_l2", "pct_l3", "pct_l4", "pct_l5",
  "num_l1", "num_l2", "num_l3", "num_l4", "num_l5",
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

  # ========== Special Populations ==========
  "economically_disadvantaged", "students_with_disabilities",
  "economically_disadvantaged_students",
  "english_learners", "homeless_students",
  "students_in_foster_care", "military_connected_students",
  "migrant_students",
  "student_group", "percent",
  "lep_current", "lep_former", "lep_current_former",

  # ========== DFG (District Factor Group) ==========
  "dfg", "dfg_code",

  # ========== TGES (Taxpayers Guide) ==========
  "indicator", "indicator_value",

  # ========== SPED Columns ==========
  "gened_num", "sped_num", "sped_rate",
  "sped_num_no_speech", "sped_rate_no_speech",

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
  "hash",
  "nrow_before",

  # ========== Common Tidyverse ==========
  ".", "value", "name", "n",
  "everything", "where", "one_of", "any_of", "all_of",
  "starts_with", "ends_with", "contains", "matches"
))
