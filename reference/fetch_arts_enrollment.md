# Fetch Visual and Performing Arts Enrollment Data

Downloads visual and performing arts course participation data from SPR
database.

## Usage

``` r
fetch_arts_enrollment(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2017-2024)

- level:

  One of "school" or "district"

## Value

Data frame with arts course enrollment by discipline (Music, Visual Art,
Theater, Dance, etc.)

## Examples

``` r
if (FALSE) { # \dontrun{
arts <- fetch_arts_enrollment(2024)

# View music enrollment
arts %>%
  dplyr::filter(grepl("Music|Band|Choir", course_type)) %>%
  dplyr::select(school_name, number_of_students)
} # }
```
