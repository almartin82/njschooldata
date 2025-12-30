# Calculate DFG peer percentile for any metric

Calculates percentile rank within District Factor Group for any metric
column. This is a convenience wrapper that combines
[`define_peer_group()`](https://almartin82.github.io/njschooldata/reference/define_peer_group.md)
and
[`add_percentile_rank()`](https://almartin82.github.io/njschooldata/reference/add_percentile_rank.md).

## Usage

``` r
dfg_percentile_rank(
  df,
  metric_col,
  year_col = "end_year",
  additional_groups = NULL
)
```

## Arguments

- df:

  Dataframe with district data including 'dfg' column

- metric_col:

  Character. The column to rank on.

- year_col:

  Character. The year column. Default "end_year".

- additional_groups:

  Character vector. Additional grouping columns.

## Value

df with percentile rank columns
