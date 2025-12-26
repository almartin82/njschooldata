# Global variable declarations to avoid R CMD check NOTEs
# These are column names used in dplyr/tidyr operations via non-standard evaluation

utils::globalVariables(c(
  # Common ID columns
  "county_id", "county_name", "county_code",
  "district_id", "district_name", "district_code",
  "school_id", "school_name", "school_code",
  "CDS_Code",

  # Raw column names (with spaces/special chars)
  "District Code", "School Code", "County Code",
  "COUNTY_CODE", "COUNTY_NAME", "DISTRICT_CODE", "DISTRICT_NAME",
  "SCHOOL_CODE", "SCHOOL_NAME",

  # Enrollment columns
  "end_year", "yy", "n_students", "pct", "pct_total_enr",
  "grade_level", "program_code", "program_name",
  "subgroup", "subgroup_type",

  # Assessment columns
  "testing_year", "assess_name", "test_name", "grade",
  "pct_l1", "pct_l2", "pct_l3", "pct_l4", "pct_l5",
  "num_l1", "num_l2", "num_l3", "num_l4", "num_l5",
  "proficient_above", "scale_score_mean",
  "number_enrolled", "number_not_tested",
  "number_of_valid_scale_scores",

  # Graduation columns
  "methodology", "grad_rate", "grad_count",
  "cohort_count", "graduated_count",

  # Boolean flag columns
  "is_state", "is_county", "is_district", "is_school",
"is_charter", "is_charter_sector", "is_allpublic",
  "is_dfg", "is_citywide", "is_subprogram",

  # Geographic columns
  "lat", "lng", "lat.x", "lat.y", "lng.x", "lng.y",
  "address", "address1", "address_2", "address_3",
  "city", "state", "zip", "ward", "locations",

  # Host district columns (for charter aggregations)
  "host_county_id", "host_county_name",
  "host_district_id", "host_district_name",

  # Matriculation columns
  "enroll_any", "is_16mo",

  # Special populations
  "lep", "migrant", "homeless", "title1",

  # DFG (District Factor Group)
  "dfg",

  # Misc columns used in tidyr/dplyr operations
  ".", "value", "name", "row_number"
))
