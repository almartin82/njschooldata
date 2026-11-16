# Fetch SPR Data (raw sheet reader)

Downloads and extracts one sheet from the NJ School Performance Reports
database, in NJDOE's own layout for that year. This is a raw reader:
NJDOE has changed many sheets' layouts between years (one row per group
in one year, one column per group in another, renamed columns, text
versus numeric cells), and this function passes those changes through.
It is outside the package's same-shape-every-year guarantee. For
analysis across years use a tidy fetcher, for example
[`fetch_spr_enrollment_by_group`](https://almartin82.github.io/njschooldata/reference/fetch_spr_enrollment_by_group.md)
for "EnrollmentTrendsByStudentGroup",
[`fetch_absence`](https://almartin82.github.io/njschooldata/reference/fetch_absence.md),
[`fetch_essa_status`](https://almartin82.github.io/njschooldata/reference/fetch_essa_status.md)
or the other `fetch_spr_*` functions.

## Usage

``` r
fetch_spr_data(sheet_name, end_year, level = "school", clean_subgroups = TRUE)
```

## Arguments

- sheet_name:

  Exact sheet name from SPR database (case-sensitive). You must know the
  exact sheet name. See vignette("spr-dictionary") for available sheets.

- end_year:

  A school year (2017-2025). Year is the end of the academic year - eg
  2020-21 school year is end_year '2021'.

- level:

  One of "school" or "district". "school" returns school-level data,
  "district" returns district and state-level data.

- clean_subgroups:

  Standardize `StudentGroup` labels via the package subgroup cleaner
  (default `TRUE`). Pass `FALSE` to keep the sheet's raw labels, e.g.
  when a sheet uses "Statewide" as a student group that must stay
  distinguishable from "Districtwide".

## Value

Data frame with standardized columns including:

- end_year, county_id, county_name, district_id, district_name

- school_id, school_name (for school-level data)

- \[Additional columns from requested sheet\]

- Aggregation flags (is_state, is_county, is_district, is_school,
  is_charter)

## Details

The SPR database contains 63+ sheets covering various school performance
metrics.

## Examples

``` r
if (FALSE) { # \dontrun{
# Get chronic absenteeism data
ca <- fetch_spr_data("ChronicAbsenteeism", 2024)

# Get district-level graduation data
grad <- fetch_spr_data("6YrGraduationCohortProfile", 2024, level = "district")

# Get teacher experience data
teachers <- fetch_spr_data("TeachersExperience", 2023)
} # }
```
