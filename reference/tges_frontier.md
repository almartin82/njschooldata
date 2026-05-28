# Spend-versus-outcome efficiency frontier (free-disposal hull)

Where
[`tges_efficiency()`](https://almartin82.github.io/njschooldata/reference/tges_efficiency.md)
only labels a quadrant, this computes a proper efficiency score against
the free-disposal-hull frontier. For each district it finds the peer
that achieves at least the same outcome for the least spend, and reports
the ratio (0-1, 1 = on the frontier) plus that reference district and
the dollars overspent relative to it. This answers the MarGrady brief's
open cost-effectiveness question with a number, not a quadrant: "Bayonne
hits your graduation rate for \$2,100/pupil less; you are at 0.81
efficiency."

## Usage

``` r
tges_frontier(
  spend_df,
  outcome_df,
  spend_col = "Per Pupil costs",
  outcome_col,
  peer = c("tges_group", "dfg", "county", "statewide"),
  year_col = "end_year",
  dfg_revision = 2000
)
```

## Arguments

- spend_df:

  A tidied TGES table (one report year, one `calc_type`) carrying
  `district_id` and `spend_col`.

- outcome_df:

  A district-level frame with `district_id`, the year column, and
  `outcome_col` (higher = better).

- spend_col:

  Character. Spend column in `spend_df`. Default `"Per Pupil costs"`.

- outcome_col:

  Character. Outcome column in `outcome_df`.

- peer:

  Character. Peer group for the frontier. One of `"tges_group"`
  (default), `"dfg"`, `"county"`, `"statewide"`.

- year_col:

  Character. Year column, present in both frames. Default `"end_year"`.

- dfg_revision:

  Numeric. DFG revision when `peer = "dfg"`. Default 2000.

## Value

A tibble: entity columns, `peer_group`, the year, `spend`, `outcome`,
`efficiency_score`, `on_frontier`, `reference_district_id`,
`reference_district_name`, `reference_spend`, and `excess_spend`.

## Details

The free-disposal hull (FDH) is the dependency-free efficiency frontier:
a district is efficient if no peer in the same group does at least as
well on the outcome for strictly less spend. The input-oriented score is
`min(spend among peers with outcome >= yours) / your spend`. It needs no
linear-programming solver and makes no functional-form assumption
(unlike the regression residual in
[`tges_efficiency()`](https://almartin82.github.io/njschooldata/reference/tges_efficiency.md)).
Spend is treated as the input (lower is better) and the outcome as the
output (higher is better); pass an outcome where higher is better (a
rate or a percentile).

**Cautions.** Use one consistent per-pupil definition for `spend_col`
(CSG1 budgetary vs CSG1AA total), filter `spend_df` to one `calc_type`,
and make sure the outcome and spend peer systems are stated. The
frontier is only as meaningful as the peer group: with few districts per
group, most land on the frontier by default.

## Examples

``` r
if (FALSE) { # \dontrun{
library(dplyr)

grate <- fetch_grad_rate(2023, methodology = "4 year") %>%
  add_dfg() %>%
  filter(dfg == "A", is_district, subgroup == "total") %>%
  grate_percentile_rank(peer_type = "dfg")

spend <- fetch_tges(2024)$CSG1 %>%
  filter(calc_type == "Actuals", end_year == 2023)

fr <- tges_frontier(spend, grate, outcome_col = "grad_rate_percentile",
                    peer = "dfg")
fr %>% filter(district_id == "3570") %>%
  select(district_name, efficiency_score, reference_district_name, excess_spend)
} # }
```
