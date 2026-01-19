# Fetch Chronic Absenteeism Data

Downloads and extracts chronic absenteeism data from the SPR database.
Chronic absenteeism is defined as missing 10

## Usage

``` r
fetch_chronic_absenteeism(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2017-2024). Year is the end of the academic year - eg
  2020-21 school year is end_year '2021'.

- level:

  One of "school" or "district". "school" returns school-level data,
  "district" returns district and state-level data.

## Value

Data frame with chronic absenteeism rates including:

- end_year, county_id, county_name, district_id, district_name

- school_id, school_name (for school-level data)

- subgroup - Student group (total population, racial/ethnic groups,
  etc.)

- chronically_absent_rate - Percentage chronically absent (0-100)

- Aggregation flags (is_state, is_county, is_district, is_school,
  is_charter)

## Examples

``` r
if (FALSE) { # \dontrun{
# Get school-level chronic absenteeism
ca <- fetch_chronic_absenteeism(2024)

# Get district-level data
ca_dist <- fetch_chronic_absenteeism(2024, level = "district")

# Filter for specific schools
newark_ca <- ca %>%
  filter(district_id == "3570") %>%
  filter(subgroup == "total population")
} # }
```
