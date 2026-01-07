# Fetch Teacher Experience Data

Downloads teacher experience data from SPR database.

## Usage

``` r
fetch_teacher_experience(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2017-2024)

- level:

  One of "school" or "district"

## Value

Data frame with teacher experience breakdown

## Examples

``` r
if (FALSE) { # \dontrun{
teachers <- fetch_teacher_experience(2024)
} # }
```
