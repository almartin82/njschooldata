# Fetch Special Education Classification Data

Fetches special education classification rate data from NJ DOE. As of
2024, only current data is available. Historical data (2003-2019) is no
longer accessible via URL and requires an OPRA request.

## Usage

``` r
fetch_sped(end_year)
```

## Arguments

- end_year:

  ending school year (e.g., 2024 for 2023-2024 school year). Valid
  years: 2024+

## Value

cleaned sped dataframe with columns: end_year, county_id, county_name,
district_id, district_name, gened_num, sped_num, sped_rate
