# Rank entities by achievement gap within peer group

Calculates percentile rank of achievement gaps. By default, smaller gaps
receive higher percentile ranks (better equity = higher rank). This
enables questions like "Which DFG A districts have the smallest
Black-White achievement gaps?"

## Usage

``` r
gap_percentile_rank(
  df,
  gap_col,
  peer_type = "statewide",
  year_col = "end_year",
  smaller_is_better = TRUE
)
```

## Arguments

- df:

  Output of
  [`calculate_subgroup_gap()`](https://almartin82.github.io/njschooldata/reference/calculate_subgroup_gap.md)
  or any dataframe with a gap column

- gap_col:

  Character. The column containing gap values. Default "metric_gap".

- peer_type:

  Character. Peer group type. See
  [`define_peer_group()`](https://almartin82.github.io/njschooldata/reference/define_peer_group.md).

- year_col:

  Character. Year column name. Default "end_year".

- smaller_is_better:

  Logical. If TRUE (default), smaller gaps get higher percentile ranks.
  Set to FALSE if larger gaps are preferred.

## Value

df with added gap percentile columns

## Examples

``` r
if (FALSE) { # \dontrun{
grate %>%
  calculate_subgroup_gap("grad_rate", "white", "black") %>%
  gap_percentile_rank(gap_col = "grad_rate_gap", peer_type = "dfg")
} # }
```
