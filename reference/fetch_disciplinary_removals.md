# Fetch Disciplinary Removals Data

Downloads discipline data (suspensions/expulsions/removals) from the SPR
database, broken down by student group and grade level.

## Usage

``` r
fetch_disciplinary_removals(
  end_year,
  level = "school",
  with_status = FALSE,
  with_denominator = FALSE,
  with_subgroup_std = FALSE
)
```

## Arguments

- end_year:

  A school year (2018-2025). SY2016-17 (end_year 2017) has no
  discipline-removals sheet in the SPR database.

- level:

  One of "school" or "district"

- with_status:

  Logical, default `FALSE`. If `TRUE`, appends `value_status`,
  classified from the raw primary suspension-rate token before numeric
  coercion.

- with_denominator:

  Logical, default `FALSE`. If `TRUE`, appends `n_students` from the
  matching total-enrollment row in
  [`fetch_enr`](https://almartin82.github.io/njschooldata/reference/fetch_enr.md)
  on `end_year` and CDS identifiers. Unmatched rows remain `NA`.

- with_subgroup_std:

  Logical, default `FALSE`. If `TRUE` and the source has a
  student-group/grade label, appends normalized `subgroup`,
  `subgroup_std`, and `grade_level` detail.

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
