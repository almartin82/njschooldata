# Calculate performance gap between charter and district sectors

Calculates the difference in performance between the charter sector
aggregate and traditional district for host cities. Positive values
indicate charter sector outperforms district.

## Usage

``` r
sector_gap(df, metric_col, year_col = "end_year")
```

## Arguments

- df:

  Dataframe with charter sector and district rows, including
  is_charter_sector, is_district, and is_allpublic flags

- metric_col:

  Character. Performance metric column.

- year_col:

  Character. Year column. Default "end_year".

## Value

Dataframe with one row per city-year containing:

- `charter_value`: Charter sector metric value

- `district_value`: Traditional district metric value

- `sector_gap`: charter_value - district_value

- `sector_leader`: "charter", "district", or "tie"

## Examples

``` r
if (FALSE) { # \dontrun{
# Get sector gaps for all host cities
grate_with_aggs %>%
  sector_gap(metric_col = "grad_rate")
} # }
```
