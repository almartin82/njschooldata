# Fetch 6-Year Graduation Rate data

Downloads and processes 6-year graduation rate data from the NJ School
Performance Reports database. This data shows the percentage of students
who graduated within six years of entering high school.

## Usage

``` r
fetch_6yr_grad_rate(end_year, level = "school")
```

## Arguments

- end_year:

  A school year. Year is the end of the academic year - eg 2020-21
  school year is end_year '2021'. Valid values are 2021-2024.

- level:

  One of "school" or "district". "school" returns school-level data,
  "district" returns district and state-level data.

## Value

dataframe with 6-year graduation rates including:

- end_year, county_id, county_name, district_id, district_name

- school_id, school_name (for school-level data)

- subgroup - student group (total population, racial/ethnic groups,
  etc.)

- grad_rate_6yr - 6-year graduation rate (0-100 scale)

- continuing_rate - percentage of students still enrolled after 6 years

- non_continuing_rate - percentage who dropped out or left

- persistence_rate - graduates + continuing students (high school
  persistence)

- Aggregation flags (is_state, is_district, is_school, is_charter)

## Details

The 6-year graduation data is from a different source than the 4-year
and 5-year data (SPR database vs ACGR files), which is why it has its
own fetch function rather than being an option in
[`fetch_grad_rate()`](https://almartin82.github.io/njschooldata/reference/fetch_grad_rate.md).

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 2024 school-level 6-year graduation rates
grad6_2024 <- fetch_6yr_grad_rate(2024)

# Get district-level 6-year graduation rates
grad6_dist <- fetch_6yr_grad_rate(2024, level = "district")
} # }
```
