devtools::load_all(".", quiet = TRUE)

standard_mapping <- data.frame(
  raw_value = c(
    "total population",
    "total_population",
    "economically disadvantaged",
    "ed",
    "non_ed",
    "students with disabilities",
    "special_education",
    "sped_accomodations",
    "limited english proficiency",
    "lep_current_former",
    "lep_current",
    "lep_former",
    "american indian",
    "american_indian",
    "asian",
    "black",
    "hispanic",
    "pacific islander",
    "pacific_islander",
    "white",
    "multiracial",
    "other",
    "male",
    "female",
    "grade_other",
    "grade_06",
    "grade_07",
    "grade_08",
    "grade_09",
    "grade_10",
    "grade_11",
    "grade_12"
  ),
  subgroup_std = c(
    "total_enrollment",
    "total_enrollment",
    "econ_disadv",
    "econ_disadv",
    "non_econ_disadv",
    "special_ed",
    "special_ed",
    NA_character_,
    "lep",
    "lep",
    "lep_current",
    "lep_former",
    "native_american",
    "native_american",
    "asian",
    "black",
    "hispanic",
    "pacific_islander",
    "pacific_islander",
    "white",
    "multiracial",
    "other",
    "male",
    "female",
    NA_character_,
    NA_character_,
    NA_character_,
    NA_character_,
    NA_character_,
    NA_character_,
    NA_character_,
    NA_character_
  ),
  dimension = c(
    "total",
    "total",
    "econ",
    "econ",
    "econ",
    "disability",
    "disability",
    "disability",
    "el",
    "el",
    "el",
    "el",
    "race",
    "race",
    "race",
    "race",
    "race",
    "race",
    "race",
    "race",
    "race",
    "race",
    "gender",
    "gender",
    NA_character_,
    NA_character_,
    NA_character_,
    NA_character_,
    NA_character_,
    NA_character_,
    NA_character_,
    NA_character_
  ),
  stringsAsFactors = FALSE
)

standard_mapping <- rbind(
  standard_mapping,
  data.frame(
    raw_value = c(
      "hispanic/latino",
      "asian, native hawaiian, or pacific islander",
      "migrant students",
      "military-connected students",
      "students experiencing homelessness",
      "students in foster care",
      "non-binary/undesignated gender"
    ),
    subgroup_std = c(
      "hispanic",
      "asian_pacific_islander",
      "migrant",
      "military_connected",
      "homeless",
      "foster_care",
      "non_binary"
    ),
    dimension = c(
      "race",
      "race",
      "migrant",
      "military",
      "homeless",
      "foster_care",
      "gender"
    ),
    stringsAsFactors = FALSE
  )
)

build_family <- function(vocab_family, raw_values) {
  raw_values <- unique(raw_values)
  mapping_idx <- match(raw_values, standard_mapping$raw_value)
  if (any(is.na(mapping_idx))) {
    stop(
      "No subgroup standard mapping for: ",
      paste(raw_values[is.na(mapping_idx)], collapse = ", "),
      call. = FALSE
    )
  }

  data.frame(
    raw_value = raw_values,
    vocab_family = vocab_family,
    subgroup_std = standard_mapping$subgroup_std[mapping_idx],
    dimension = standard_mapping$dimension[mapping_idx],
    stringsAsFactors = FALSE
  )
}

spr_inputs <- c(
  "Schoolwide",
  "Districtwide",
  "Statewide",
  "All Students",
  "American Indian or Alaska Native",
  "Black or African American",
  "Economically Disadvantaged Students",
  "English Learners",
  "Multilingual Learners",
  "Two or More Races",
  "Native Hawaiian or Other Pacific Islander",
  "Students with Disabilities",
  "Students with Disability",
  "Asian",
  "White",
  "Hispanic",
  "Hispanic/Latino",
  "Asian, Native Hawaiian, or Pacific Islander",
  "Migrant Students",
  "Military-Connected Students",
  "Students Experiencing Homelessness",
  "Students in Foster Care",
  "Non-binary/Undesignated Gender",
  "Other",
  "Male",
  "Female"
)

parcc_inputs <- c(
  "ALL STUDENTS",
  "WHITE",
  "AFRICAN AMERICAN",
  "ASIAN",
  "HISPANIC",
  "NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER",
  "NATIVE HAWAIIAN",
  "AMERICAN INDIAN",
  "OTHER",
  "FEMALE",
  "MALE",
  "STUDENTS WITH DISABLITIES",
  "STUDENTS WITH DISABILITIES",
  "SE ACCOMMODATION",
  "ECONOMICALLY DISADVANTAGED",
  "NON ECON. DISADVANTAGED",
  "NON-ECON. DISADVANTAGED",
  "ENGLISH LANGUAGE LEARNERS",
  "CURRENT - ELL",
  "FORMER - ELL",
  "GRADE - OTHER",
  "GRADE - 06",
  "GRADE - 07",
  "GRADE - 08",
  "GRADE - 09",
  "GRADE - 10",
  "GRADE - 11",
  "GRADE - 12"
)

grad6yr_inputs <- c(
  "Schoolwide",
  "Districtwide",
  "All Students",
  "American Indian or Alaska Native",
  "Black or African American",
  "Economically Disadvantaged Students",
  "English Learners",
  "Multilingual Learners",
  "Two or More Races",
  "Hispanic",
  "Hispanic/Latino",
  "Native Hawaiian or Pacific Islander",
  "Asian, Native Hawaiian, or Pacific Islander",
  "Students with Disabilities",
  "Asian",
  "White",
  "Other",
  "Male",
  "Female"
)

subgroup_crosswalk <- rbind(
  build_family("spr", clean_spr_subgroups(spr_inputs)),
  build_family("parcc", tidy_parcc_subgroup(parcc_inputs)),
  build_family("grad6yr", clean_6yr_grad_subgroups(grad6yr_inputs))
)

dir.create("data", showWarnings = FALSE)
save(subgroup_crosswalk, file = "data/subgroup_crosswalk.rda", compress = "xz")
