# Ranked composition-share drift versus peers

Where did a district's budget move, and how does that move rank against
its peers? This takes the spending-share composition at two years and
returns the drift (end minus start, in share points) for each tracked
category, then ranks one chosen drift (classroom share by default)
within the peer group. The output is the "Newark moved 4 points from
classroom to plant O&M, the 2nd-largest classroom-share decline in DFG
A" finding.

## Usage

``` r
tges_composition_drift(
  tges,
  start_year = NULL,
  end_year = NULL,
  shares = c("classroom_share", "administration_share", "support_services_share",
    "plant_ops_share"),
  rank_on = "classroom_share",
  peer = c("tges_group", "dfg", "county", "statewide"),
  calc_type = "Budgeted",
  dfg_revision = 2000
)
```

## Arguments

- tges:

  Output of
  [`fetch_many_tges()`](https://almartin82.github.io/njschooldata/reference/fetch_many_tges.md)
  (multi-year).

- start_year, end_year:

  Numeric. Endpoints. Default: min and max present.

- shares:

  Character vector of share columns from
  [`tges_composition()`](https://almartin82.github.io/njschooldata/reference/tges_composition.md)
  to compute drift for. Default classroom / administration /
  support_services / plant_ops shares.

- rank_on:

  Character. Which share's drift to percentile-rank within the peer
  group. Default `"classroom_share"`.

- peer:

  Character. Peer group. One of `"tges_group"` (default), `"dfg"`,
  `"county"`, `"statewide"`.

- calc_type:

  Character. Composition calc type. Default `"Budgeted"`.

- dfg_revision:

  Numeric. DFG revision when `peer = "dfg"`. Default 2000.

## Value

A per-district tibble: entity columns, `peer_group`, `start_year`,
`end_year`, a `{share}_start`, `{share}_end`, and `{share}_drift` triple
per tracked share, and the rank columns `drift_rank`, `drift_n`,
`drift_percentile` for `rank_on` (computed on the signed drift, so a
larger positive drift ranks higher).

## Examples

``` r
if (FALSE) { # \dontrun{
library(dplyr)

drift <- tges_composition_drift(fetch_many_tges(2019:2024), peer = "dfg")

# biggest classroom-share declines among DFG A
drift %>%
  arrange(classroom_share_drift) %>%
  select(district_name, classroom_share_start, classroom_share_end,
         classroom_share_drift, drift_percentile) %>%
  head(10)
} # }
```
