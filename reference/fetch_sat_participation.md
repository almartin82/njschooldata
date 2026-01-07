# Fetch SAT/ACT/PSAT Participation Data

Downloads and extracts college entrance exam participation rates from
the SPR database. Includes SAT, ACT, and PSAT participation percentages.

## Usage

``` r
fetch_sat_participation(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2017-2024). Year is the end of the academic year - eg
  2020-21 school year is end_year '2021'.

- level:

  One of "school" or "district". "school" returns school-level data,
  "district" returns district and state-level data.

## Value

Data frame with SAT/ACT/PSAT participation rates including:

- end_year, county_id, county_name, district_id, district_name

- school_id, school_name (for school-level data)

- sat_participation - Percentage of students taking SAT

- act_participation - Percentage of students taking ACT

- psat_participation - Percentage of students taking PSAT

- state_sat - State SAT participation rate (comparison)

- state_act - State ACT participation rate (comparison)

- state_psat - State PSAT participation rate (comparison)

- Aggregation flags (is_state, is_county, is_district, is_school,
  is_charter)

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 2024 SAT/ACT participation
sat <- fetch_sat_participation(2024)

# Analyze SAT participation gaps
sat %>%
  filter(sat_participation < 50) %>%
  select(school_name, sat_participation, state_sat)
} # }
```
