# Fetch World Language Enrollment Data

Downloads world languages course participation data from SPR database.

## Usage

``` r
fetch_world_language_enrollment(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2017-2024)

- level:

  One of "school" or "district"

## Value

Data frame with world language course enrollment by language (Spanish,
French, German, Italian, Chinese, etc.)

## Examples

``` r
if (FALSE) { # \dontrun{
world_lang <- fetch_world_language_enrollment(2024)

# View Spanish enrollment
world_lang %>%
  dplyr::filter(grepl("Spanish", course_type)) %>%
  dplyr::select(school_name, number_of_students)
} # }
```
