# Fetch Social Studies Enrollment Data

Downloads social studies and history course participation data from SPR
database.

## Usage

``` r
fetch_social_studies_enrollment(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2017-2024)

- level:

  One of "school" or "district"

## Value

Data frame with social studies course enrollment by subject area (US
History, World History, Government, Economics, etc.)

## Examples

``` r
if (FALSE) { # \dontrun{
social_studies <- fetch_social_studies_enrollment(2024)

# View AP US History enrollment
social_studies %>%
  dplyr::filter(grepl("AP.*History", course_type)) %>%
  dplyr::select(school_name, number_of_students)
} # }
```
