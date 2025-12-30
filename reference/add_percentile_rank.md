# Add percentile rank columns for any metric

The fundamental building block for percentile rank calculations. Given a
grouped dataframe and a metric column, calculates the percentile rank
within each group. Percentile rank is defined as the percent of
comparison entities with lesser or equal performance.

This function respects existing grouping on the dataframe. If you want
to calculate percentile rank within specific peer groups (e.g., DFG,
county), group your data appropriately before calling this function, or
use
[`define_peer_group()`](https://almartin82.github.io/njschooldata/reference/define_peer_group.md)
to set up the grouping.

Note: This differs from the simpler `percentile_rank(x, xo)` in util.R
which calculates percentile rank of a single value within a vector. This
function operates on dataframe columns and adds rank/percentile columns.

## Usage

``` r
add_percentile_rank(df, metric_col, prefix = NULL)
```

## Arguments

- df:

  A dataframe, optionally grouped. Grouping defines the comparison set.

- metric_col:

  Character. The column name to rank on.

- prefix:

  Character. Optional prefix for output column names. If NULL, uses
  metric_col as prefix. Default NULL.

## Value

df with added columns:

- `{prefix}_rank`: The rank within the group (1 = lowest)

- `{prefix}_n`: Number of valid observations in the group

- `{prefix}_percentile`: Percentile rank (0-100)

## Examples

``` r
if (FALSE) { # \dontrun{
# Simple statewide percentile
grate %>%
  group_by(end_year, subgroup) %>%
  add_percentile_rank("grad_rate")

# DFG peer percentile
grate %>%
  group_by(end_year, dfg, subgroup) %>%
  add_percentile_rank("grad_rate", prefix = "dfg")
} # }
```
