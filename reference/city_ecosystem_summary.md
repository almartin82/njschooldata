# Summarize sector performance within a city

Creates a summary showing charter sector, traditional district, and
all-public performance for a specific host city, including peer
percentile ranks for each.

## Usage

``` r
city_ecosystem_summary(
  df,
  metric_col,
  host_district_id,
  peer_type = "statewide",
  year_col = "end_year"
)
```

## Arguments

- df:

  Combined data including sector aggregates (output of `*_aggs()`
  functions combined with base data)

- metric_col:

  Character. Metric to summarize.

- host_district_id:

  Character. The host district ID (e.g., "3570" for Newark).

- peer_type:

  Character. Peer group for percentile calculation.

- year_col:

  Character. Year column. Default "end_year".

## Value

Summary dataframe with sectors as rows, metrics and percentiles as
columns

## Examples

``` r
if (FALSE) { # \dontrun{
# Newark ecosystem summary
city_ecosystem_summary(
  df = grate_with_aggs,
  metric_col = "grad_rate",
  host_district_id = "3570"
)
} # }
```
