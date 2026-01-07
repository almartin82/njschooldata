# Fetch Industry Valued Credentials Data

Downloads and extracts industry-valued credentials earned by students
from the SPR database. Organized by career cluster.

## Usage

``` r
fetch_industry_credentials(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2017-2024). Year is the end of the academic year - eg
  2020-21 school year is end_year '2021'.

- level:

  One of "school" or "district". "school" returns school-level data,
  "district" returns district and state-level data.

## Value

Data frame with industry credentials including:

- end_year, county_id, county_name, district_id, district_name

- school_id, school_name (for school-level data)

- career_cluster - Career cluster area (e.g., "Health Sciences", "STEM")

- students_enrolled - Number of students enrolled in CTE program

- earned_one_credential - Students earning at least one credential

- credentials_earned - Total industry credentials earned

- Aggregation flags (is_state, is_county, is_district, is_school,
  is_charter)

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 2024 industry credentials
creds <- fetch_industry_credentials(2024)

# Top schools by credentials earned
creds %>%
  group_by(school_name) %>%
  summarize(total_credentials = sum(credentials_earned, na.rm = TRUE)) %>%
  dplyr::arrange(desc(total_credentials))
} # }
```
