# Fetch AP/IB Participation and Performance Data

Downloads and extracts Advanced Placement (AP) and International
Baccalaureate (IB) coursework participation and exam performance from
the SPR database.

## Usage

``` r
fetch_ap_participation(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2017-2024). Year is the end of the academic year - eg
  2020-21 school year is end_year '2021'.

- level:

  One of "school" or "district". "school" returns school-level data,
  "district" returns district and state-level data.

## Value

Data frame with AP/IB participation and performance including:

- end_year, county_id, county_name, district_id, district_name

- school_id, school_name (for school-level data)

- apib_coursework_school - Percentage students in AP/IB coursework

- apib_coursework_state - State percentage in AP/IB coursework

- apib_exam_school - Percentage taking AP/IB exams

- apib_exam_state - State percentage taking AP/IB exams

- ap3_ib4_school - Percentage scoring AP 3+ or IB 4+

- ap3_ib4_state - State percentage scoring AP 3+ or IB 4+

- dual_enrollment_school - Dual enrollment participation

- dual_enrollment_state - State dual enrollment percentage

- Aggregation flags (is_state, is_county, is_district, is_school,
  is_charter)

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 2024 AP/IB data
apib <- fetch_ap_participation(2024)

# Compare exam participation vs performance
apib %>%
  select(school_name, apib_exam_school, ap3_ib4_school)
} # }
```
