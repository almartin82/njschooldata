# Beta-convergence of spending across a peer group

Are spending gaps within a peer group closing or widening? This is the
classic public-finance convergence test, pointed at school dollars: it
regresses each district's growth in per-pupil spend on its starting
level, within each peer group. A negative slope (beta) means
low-spenders grew faster and the group is converging; a positive slope
means the high-spenders pulled further ahead (divergence).

## Usage

``` r
tges_convergence(
  tges,
  metric_col = "Per Pupil costs",
  table = "CSG1",
  peer = c("tges_group", "dfg", "county", "statewide"),
  start_year = NULL,
  end_year = NULL,
  calc_type = "Budgeted",
  dfg_revision = 2000
)
```

## Arguments

- tges:

  Output of
  [`fetch_many_tges()`](https://almartin82.github.io/njschooldata/reference/fetch_many_tges.md)
  (multi-year).

- metric_col:

  Character. Numeric column to track. Default `"Per Pupil costs"`.

- table:

  Character. TGES table code carrying `metric_col`. Default `"CSG1"`
  (budgetary per-pupil cost).

- peer:

  Character. Peer group. One of `"tges_group"` (default), `"dfg"`,
  `"county"`, `"statewide"`.

- start_year, end_year:

  Numeric. Endpoints. Default: the min and max `end_year` present.

- calc_type:

  Character. Calc type to keep. Default `"Budgeted"`.

- dfg_revision:

  Numeric. DFG revision when `peer = "dfg"`. Default 2000.

## Value

A per-district tibble: entity columns, `peer_group`, `start_year`,
`end_year`, `start_value`, `end_value`, `log_start_value`, `growth`, and
the broadcast group statistics `beta`, `beta_pvalue`, `r_squared`,
`n_districts`, and `converging` (`beta < 0` and `beta_pvalue < 0.05`).

## Details

Needs a multi-year input
([`fetch_many_tges()`](https://almartin82.github.io/njschooldata/reference/fetch_many_tges.md)).
For each district the function takes the metric at `start_year` and
`end_year`, drops to one value per district-year, and computes
annualized log growth \\(\ln v\_{end} - \ln v\_{start}) / (end -
start)\\. Within each peer group it fits `growth ~ log(start_value)` by
OLS (requires \>= 4 districts with both endpoints and starting-level
variation). The slope and its stats are broadcast onto every district
row in the group, so the same frame both plots the convergence scatter
(`log_start_value` vs `growth`) and reports the group beta. For one peer
group's headline, take
`distinct(peer_group, beta, beta_pvalue, r_squared, n_districts, converging)`.

## Examples

``` r
if (FALSE) { # \dontrun{
library(dplyr)

conv <- tges_convergence(fetch_many_tges(2015:2024), peer = "dfg")

# one row per peer group: is each DFG converging on spend?
conv %>% distinct(peer_group, beta, beta_pvalue, converging, n_districts)
} # }
```
