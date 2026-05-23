# Fetch Disciplinary Removals Data

Downloads discipline data (suspensions/expulsions/removals) from the SPR
database, broken down by student group and grade level.

## Usage

``` r
fetch_disciplinary_removals(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2017-2025)

- level:

  One of "school" or "district"

## Value

Data frame with disciplinary actions. Includes a `student_group_grade`
column identifying the student group / grade row, plus suspension,
removal, and expulsion counts and percentages.

## Examples

``` r
if (FALSE) { # \dontrun{
discipline <- fetch_disciplinary_removals(2024)
} # }
```
