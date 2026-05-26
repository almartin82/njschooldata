# Staffing ratios, median salaries, and the benefits squeeze

Reshapes the personnel tables (CSG16-CSG19) plus the benefits share
(CSG14) into one row per district-year. This is the board's negotiation
and "administrative bloat" dashboard in a single frame: students per
teacher / special-service provider / administrator, faculty per
administrator, the median salary for each role, and benefits as a share
of total salaries.

## Usage

``` r
tges_staffing(tges, years = NULL)
```

## Arguments

- tges:

  Output of
  [`fetch_tges()`](https://almartin82.github.io/njschooldata/reference/fetch_tges.md)
  or
  [`fetch_many_tges()`](https://almartin82.github.io/njschooldata/reference/fetch_many_tges.md).

- years:

  Optional numeric vector. Keep only these `end_year` values.

## Value

A tibble with entity columns, `end_year`, the ratio columns, the
median-salary columns, and `benefits_pct_salary`.

## Details

Sources, by friendly column:

- `student_teacher_ratio`, `teacher_salary` (CSG16)

- `student_special_service_ratio`, `special_service_salary` (CSG17)

- `student_admin_ratio`, `admin_salary` (CSG18)

- `faculty_admin_ratio` (CSG19)

- `benefits_pct_salary` (CSG14, employee benefits as a fraction of total
  salaries)

CSG16-CSG19 report `end_year - 1` and `end_year`; CSG14 also reports
`end_year - 2`, so the earliest year may carry a benefits share with no
ratios. The most recent year's benefits share is the budgeted figure.

## Examples

``` r
if (FALSE) { # \dontrun{
library(dplyr)

# Is Newark administratively heavy, and competitive on teacher pay?
tges_staffing(fetch_tges(2024)) %>%
  filter(district_code == "3570") %>%
  select(end_year, student_admin_ratio, faculty_admin_ratio,
         teacher_salary, admin_salary, benefits_pct_salary)

# Rank student/administrator ratio within enrollment-band peers
tges_staffing(fetch_tges(2024)) %>%
  tges_percentile_rank("student_admin_ratio", peer = "tges_group")
} # }
```
