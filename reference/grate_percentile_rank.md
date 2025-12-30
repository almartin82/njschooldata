# Graduation rate percentile rank

Convenience wrapper for calculating percentile rank of graduation rates
within a peer group.

## Usage

``` r
grate_percentile_rank(
  df,
  peer_type = "statewide",
  custom_ids = NULL,
  by_subgroup = TRUE,
  by_methodology = TRUE
)
```

## Arguments

- df:

  Output of
  [`fetch_grad_rate()`](https://almartin82.github.io/njschooldata/reference/fetch_grad_rate.md)
  or similar graduation data

- peer_type:

  Character. Peer group type. See
  [`define_peer_group()`](https://almartin82.github.io/njschooldata/reference/define_peer_group.md).

- custom_ids:

  Character vector. Custom peer group district IDs.

- by_subgroup:

  Logical. Calculate separate percentiles by subgroup? Default TRUE.

- by_methodology:

  Logical. Calculate separate percentiles by methodology (4-year,
  5-year)? Default TRUE.

## Value

df with grad_rate_rank, grad_rate_n, grad_rate_percentile columns
