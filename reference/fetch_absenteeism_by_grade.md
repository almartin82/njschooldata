# Fetch Absenteeism by Grade

Downloads and extracts chronic absenteeism data broken down by grade
level from the SPR database.

## Usage

``` r
fetch_absenteeism_by_grade(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2017-2024). Year is the end of the academic year - eg
  2020-21 school year is end_year '2021'.

- level:

  One of "school" or "district". "school" returns school-level data,
  "district" returns district and state-level data.

## Value

Data frame with chronic absenteeism by grade including:

- end_year, county_id, county_name, district_id, district_name

- school_id, school_name (for school-level data)

- subgroup - Student group (total population, racial/ethnic groups,
  etc.)

- grade_level - Grade level (PK, KG, 01-12)

- chronically_absent_rate - Percentage chronically absent (0-100)

- Aggregation flags (is_state, is_county, is_district, is_school,
  is_charter)

## Examples

``` r
if (FALSE) { # \dontrun{
# Get school-level chronic absenteeism by grade
ca_grade <- fetch_absenteeism_by_grade(2024)

# Analyze kindergarten absenteeism
k_absent <- ca_grade %>%
  filter(grade_level == "KF", subgroup == "total population")
} # }
```
