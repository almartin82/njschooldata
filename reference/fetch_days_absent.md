# Fetch Days Absent Data

Downloads and extracts days absent statistics from the SPR database.
This includes percentage distributions of students by absence ranges.

## Usage

``` r
fetch_days_absent(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2017-2024). Year is the end of the academic year - eg
  2020-21 school year is end_year '2021'.

- level:

  One of "school" or "district". "school" returns school-level data,
  "district" returns district and state-level data.

## Value

Data frame with days absent statistics including:

- end_year, county_id, county_name, district_id, district_name

- school_id, school_name (for school-level data)

- Percentage distribution columns: \`0 \`7 \`20

- Aggregation flags (is_state, is_county, is_district, is_school,
  is_charter)

## Examples

``` r
if (FALSE) { # \dontrun{
# Get school-level days absent distribution
days <- fetch_days_absent(2024)

# View absence distribution for a specific school
days %>%
  filter(school_id == "030") %>%
  select(school_name, `0% Absences`, `20% or higher`)
} # }
```
