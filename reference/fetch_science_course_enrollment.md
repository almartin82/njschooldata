# Fetch Science Course Enrollment Data

Downloads science course participation data from SPR database.

## Usage

``` r
fetch_science_course_enrollment(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2017-2024)

- level:

  One of "school" or "district"

## Value

Data frame with science course enrollment by subject area (Biology,
Chemistry, Physics, Environmental Science, etc.)

## Examples

``` r
if (FALSE) { # \dontrun{
science <- fetch_science_course_enrollment(2024)

# View physics enrollment
science %>%
  dplyr::filter(course_type == "Physics") %>%
  dplyr::select(school_name, subgroup, number_of_students)
} # }
```
