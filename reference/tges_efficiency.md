# Spend-versus-outcome efficiency frontier

Joins a TGES per-pupil spend metric to an outcome percentile and labels
each district's spend-vs-outcome position. This is the comparative
fiscal analyst's headline product, and the literal answer to the
MarGrady brief's open "cost-effectiveness" question: outcomes rose, but
at what cost, and was that efficient relative to peers?

Spend is ranked within the chosen peer group via
[`tges_percentile_rank()`](https://almartin82.github.io/njschooldata/reference/tges_percentile_rank.md).
The outcome percentile is supplied by the caller (e.g. from
[`grate_percentile_rank()`](https://almartin82.github.io/njschooldata/reference/grate_percentile_rank.md)
or
[`parcc_percentile_rank()`](https://almartin82.github.io/njschooldata/reference/parcc_percentile_rank.md)),
so the outcome metric and its peer definition stay the caller's choice.
The efficiency residual is the vertical distance from a per-year
regression of outcome percentile on spend percentile: positive means
more outcome than the spending would predict.

## Usage

``` r
tges_efficiency(
  spend_df,
  outcome_df,
  spend_col = "Per Pupil costs",
  outcome_percentile_col,
  spend_peer = c("tges_group", "dfg", "county", "statewide"),
  year_col = "end_year"
)
```

## Arguments

- spend_df:

  A tidied TGES table (one report year, ideally filtered to a single
  `calc_type`) carrying `district_id` and `spend_col`.

- outcome_df:

  A district-level frame with `district_id`, the year column, and
  `outcome_percentile_col` (a 0-100 percentile).

- spend_col:

  Character. Spend column in `spend_df`. Default `"Per Pupil costs"`.

- outcome_percentile_col:

  Character. Percentile column in `outcome_df`.

- spend_peer:

  Character. Peer group for ranking spend. See
  [`tges_percentile_rank()`](https://almartin82.github.io/njschooldata/reference/tges_percentile_rank.md).
  Default `"tges_group"`.

- year_col:

  Character. Year column, present in both frames. Default `"end_year"`.

## Value

A tibble: entity columns, `end_year`, the spend value,
`spend_percentile`, `outcome_percentile`, `efficiency_residual`, and
`quadrant`.

## Examples

``` r
if (FALSE) { # \dontrun{
library(dplyr)

# Graduation outcomes ranked within DFG A, joined to per-pupil spend
grate <- fetch_grad_rate(2023, methodology = "4 year") %>%
  add_dfg() %>%
  filter(dfg == "A", is_district, subgroup == "total") %>%
  grate_percentile_rank(peer_type = "dfg")

spend <- fetch_tges(2024)$CSG1 %>%
  filter(calc_type == "Actuals", end_year == 2023)

tges_efficiency(
  spend, grate,
  outcome_percentile_col = "grad_rate_percentile",
  spend_peer = "dfg"
) %>%
  filter(district_id == "3570")

# The "watch" quadrant: high spend, low outcome
eff <- tges_efficiency(spend, grate,
  outcome_percentile_col = "grad_rate_percentile")
eff %>% filter(grepl("watch", quadrant))
} # }
```
