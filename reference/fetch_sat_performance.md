# Fetch SAT/ACT/PSAT Performance Data

Downloads and extracts college entrance exam performance scores from the
SPR database. Includes average scores and benchmark achievement rates.

## Usage

``` r
fetch_sat_performance(end_year, level = "school", test_type = "all")
```

## Arguments

- end_year:

  A school year (2017-2024). Year is the end of the academic year - eg
  2020-21 school year is end_year '2021'.

- level:

  One of "school" or "district". "school" returns school-level data,
  "district" returns district and state-level data.

- test_type:

  Filter by test type. Options are "SAT", "ACT", "PSAT", or "all"
  (default: "all")

## Value

Data frame with SAT/ACT/PSAT performance scores including:

- end_year, county_id, county_name, district_id, district_name

- school_id, school_name (for school-level data)

- test_type - Type of test (SAT, ACT, or PSAT)

- subject - Test subject (e.g., "Math", "Evidence-Based Reading and
  Writing")

- school_avg - Average score for this school

- state_avg - State average score (comparison)

- benchmark - Whether school meets benchmark (if applicable)

- pct_benchmark - Percentage meeting benchmark (if applicable)

- state_pct_benchmark - State benchmark percentage (comparison)

- Aggregation flags (is_state, is_county, is_district, is_school,
  is_charter)

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 2024 SAT performance
sat_perf <- fetch_sat_performance(2024)

# Filter for SAT Math scores only
sat_math <- sat_perf %>%
  filter(test_type == "SAT", subject == "Math") %>%
  select(school_name, school_avg, state_avg)

# Get only SAT data
sat_only <- fetch_sat_performance(2024, test_type = "SAT")
} # }
```
