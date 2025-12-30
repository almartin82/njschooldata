# Calculate percentile rank change over time

Given a dataframe with percentile ranks by year, calculates
year-over-year and cumulative change. This enables the "39th to 78th
percentile" style analysis from MarGrady Research.

## Usage

``` r
percentile_rank_trend(
  df,
  percentile_col,
  year_col = "end_year",
  entity_cols = c("district_id")
)
```

## Arguments

- df:

  Dataframe with a percentile column and year column

- percentile_col:

  Character. Name of the percentile column to track.

- year_col:

  Character. Name of year column. Default "end_year".

- entity_cols:

  Character vector. Columns identifying entities to track over time
  (e.g., c("district_id", "subgroup")).

## Value

df with added columns:

- `{percentile_col}_yoy_change`: Year-over-year change

- `{percentile_col}_cumulative_change`: Change from first year

- `{percentile_col}_baseline`: Value in the first year

## Examples

``` r
if (FALSE) { # \dontrun{
# Track Newark's percentile rank over time
grate_ranked %>%
  filter(district_id == "3570") %>%
  percentile_rank_trend(
    percentile_col = "grad_rate_percentile",
    entity_cols = c("district_id", "subgroup")
  )
} # }
```
