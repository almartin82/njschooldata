# Fetch SPR Data

Downloads and extracts data from NJ School Performance Reports database.
The SPR database contains 63+ sheets covering various school performance
metrics.

## Usage

``` r
fetch_spr_data(sheet_name, end_year, level = "school")
```

## Arguments

- sheet_name:

  Exact sheet name from SPR database (case-sensitive). You must know the
  exact sheet name. See vignette("spr-dictionary") for available sheets.

- end_year:

  A school year (2017-2024). Year is the end of the academic year - eg
  2020-21 school year is end_year '2021'.

- level:

  One of "school" or "district". "school" returns school-level data,
  "district" returns district and state-level data.

## Value

Data frame with standardized columns including:

- end_year, county_id, county_name, district_id, district_name

- school_id, school_name (for school-level data)

- \[Additional columns from requested sheet\]

- Aggregation flags (is_state, is_county, is_district, is_school,
  is_charter)

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
