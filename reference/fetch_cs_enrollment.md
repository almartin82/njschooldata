# Fetch Computer Science Enrollment Data

Downloads computer science course participation data from SPR database.

## Usage

``` r
fetch_cs_enrollment(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2017-2024)

- level:

  One of "school" or "district"

## Value

Data frame with computer science course enrollment by course type (AP CS
A, AP CS Principles, Intro to CS, etc.)

## Examples

``` r
if (FALSE) { # \dontrun{
cs <- fetch_cs_enrollment(2024)

# View AP Computer Science enrollment
cs %>%
  dplyr::filter(grepl("AP", course_type)) %>%
  dplyr::select(school_name, number_of_students)
} # }
```
