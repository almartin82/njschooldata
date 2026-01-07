# Fetch CTE Participation Data

Downloads and extracts Career and Technical Education (CTE)
participation from the SPR database. Includes CTE participants and
concentrators by subgroup.

## Usage

``` r
fetch_cte_participation(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2017-2024). Year is the end of the academic year - eg
  2020-21 school year is end_year '2021'.

- level:

  One of "school" or "district". "school" returns school-level data,
  "district" returns district and state-level data.

## Value

Data frame with CTE participation including:

- end_year, county_id, county_name, district_id, district_name

- school_id, school_name (for school-level data)

- subgroup - Student group (total population, racial/ethnic groups,
  etc.)

- cte_participants - Number or percentage of CTE participants

- cte_concentrators - Number or percentage of CTE concentrators

- state_cte_participants - State CTE participants (comparison)

- state_cte_concentrators - State CTE concentrators (comparison)

- Aggregation flags (is_state, is_county, is_district, is_school,
  is_charter)

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 2024 CTE participation
cte <- fetch_cte_participation(2024)

# Compare CTE participation across subgroups
cte %>%
  filter(school_id == "030") %>%
  select(subgroup, cte_participants)
} # }
```
