# Compare percentile ranks across sectors

Calculates and compares percentile ranks for charter sector, district
sector, and all-public aggregates. Useful for MarGrady-style sector
comparisons.

## Usage

``` r
sector_percentile_comparison(
  df,
  metric_col,
  host_district_id = NULL,
  year_col = "end_year"
)
```

## Arguments

- df:

  Dataframe containing both charter and district data with
  is_charter_sector, is_district, is_allpublic flags

- metric_col:

  Character. The metric to calculate percentile ranks for.

- host_district_id:

  Character. Optional. Filter to specific host district.

- year_col:

  Character. Year column name. Default "end_year".

## Value

Dataframe with sector comparison including percentile ranks
