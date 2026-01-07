# Fetch Math Course Enrollment Data

Downloads math course participation data from SPR database.

## Usage

``` r
fetch_math_course_enrollment(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2017-2024)

- level:

  One of "school" or "district"

## Value

Data frame with math course enrollment

## Examples

``` r
if (FALSE) { # \dontrun{
math <- fetch_math_course_enrollment(2024)
} # }
```
