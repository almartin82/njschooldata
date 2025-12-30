# Calculate charter market share for host cities

Calculates the percentage of public school students enrolled in charter
schools for each host city over time.

## Usage

``` r
charter_market_share(df_enrollment, year_col = "end_year")
```

## Arguments

- df_enrollment:

  Enrollment data with charter sector and all-public aggregates (combine
  [`fetch_enr()`](https://almartin82.github.io/njschooldata/reference/fetch_enr.md)
  output with
  [`charter_sector_enr_aggs()`](https://almartin82.github.io/njschooldata/reference/charter_sector_enr_aggs.md)
  and
  [`allpublic_enr_aggs()`](https://almartin82.github.io/njschooldata/reference/allpublic_enr_aggs.md))

- year_col:

  Character. Year column. Default "end_year".

## Value

Dataframe with charter market share by city and year
