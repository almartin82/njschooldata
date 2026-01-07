# Fetch Disciplinary Removals Data

Downloads discipline data (suspensions/expulsions) from SPR database.

## Usage

``` r
fetch_disciplinary_removals(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2017-2024)

- level:

  One of "school" or "district"

## Value

Data frame with disciplinary actions

## Examples

``` r
if (FALSE) { # \dontrun{
discipline <- fetch_disciplinary_removals(2024)
} # }
```
