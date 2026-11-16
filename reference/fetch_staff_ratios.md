# Fetch Student-Staff Ratio Data

Downloads student-to-staff ratio data from SPR database.

## Usage

``` r
fetch_staff_ratios(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2017-2025)

- level:

  One of "school" or "district"

## Value

Data frame with staff ratios

Fields for psychologists, social workers, assistance coordinators and
safety specialists begin in 2022; school-level librarian, nurse,
counselor and child- study ratios begin in 2021. Missing fields are
character NA. The 2017 TeacherRatio, AdministratorsRatio and district
comparison labels on StudentToStaffRatios are renamed to the
corresponding student-to-staff fields; the missing
teacher-to-administrator ratio remains NA. The 2025 school suffix on
specialist fields is harmonized to the legacy names.

## Examples

``` r
if (FALSE) { # \dontrun{
ratios <- fetch_staff_ratios(2024)
} # }
```
