# Fetch Apprenticeship Data

Downloads and extracts apprenticeship participation data from the SPR
database. Contains counts by year (2016-2023).

## Usage

``` r
fetch_apprenticeship_data(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2017-2024). Year is the end of the academic year - eg
  2020-21 school year is end_year '2021'.

- level:

  One of "school" or "district". "school" returns school-level data,
  "district" returns district and state-level data.

## Value

Data frame with apprenticeship participation including:

- end_year, county_id, county_name, district_id, district_name

- school_id, school_name (for school-level data)

- year_2016 through year_2023 - Number of apprentices by year

- Aggregation flags (is_state, is_county, is_district, is_school,
  is_charter)

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 2024 apprenticeship data
app <- fetch_apprenticeship_data(2024)

# Reshape to long format for analysis
app_long <- app %>%
  tidyr::pivot_longer(
    cols = starts_with("year_"),
    names_to = "apprenticeship_year",
    values_to = "apprenticeship_count",
    names_prefix = "year_"
  ) %>%
  filter(!is.na(apprenticeship_count))
} # }
```
