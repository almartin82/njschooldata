# Fetch Work-Based Learning Data

Downloads and extracts work-based learning participation from the SPR
database. Organized by career cluster.

## Usage

``` r
fetch_work_based_learning(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2017-2024). Year is the end of the academic year - eg
  2020-21 school year is end_year '2021'.

- level:

  One of "school" or "district". "school" returns school-level data,
  "district" returns district and state-level data.

## Value

Data frame with work-based learning participation including:

- end_year, county_id, county_name, district_id, district_name

- school_id, school_name (for school-level data)

- career_cluster - Career cluster area

- students_participating - Number of students in work-based learning

- pct_participating - Percentage participating in this career cluster

- Aggregation flags (is_state, is_county, is_district, is_school,
  is_charter)

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 2024 work-based learning data
wbl <- fetch_work_based_learning(2024)

# Schools with highest work-based learning participation
wbl %>%
  group_by(school_name) %>%
  summarize(avg_participation = mean(pct_participating, na.rm = TRUE)) %>%
  dplyr::arrange(desc(avg_participation))
} # }
```
