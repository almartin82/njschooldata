# Fetch Math Course Enrollment Data

Downloads math course participation data from SPR database.

## Usage

``` r
fetch_math_course_enrollment(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2017-2025)

- level:

  One of "school" or "district"

## Value

Data frame with math course enrollment

## Details

Rows are one per entity x grade band. The `grade` column carries the
grade as a bare string (`"6"`..`"12"`) plus the sheet's summary rows
(`"Total"`, `"Enrolled in AP/IB Course"`,
`"Enrolled in Dual Enrollment Course"`); the 2024-25 redesign's
`"Grade 08"` style labels are normalized to the bare form. Course
columns (e.g. `algebra_i`) are enrollment counts, returned as numerics;
suppression markers (`"N"`, `"n/a"`) become `NA` – a masked count is
missing, never zero.

## Examples

``` r
if (FALSE) { # \dontrun{
math <- fetch_math_course_enrollment(2024)
} # }
```
