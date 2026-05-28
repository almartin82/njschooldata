# Translate a peer gap into per-pupil and total dollars

The board/taxpayer-facing translation: "matching the DFG A median
classroom share would cost \$X per pupil, \$Y district-wide." Given a
focal district and a composition metric, it computes the gap to a peer
benchmark and converts it to dollars, using the district's budgetary
per-pupil cost (for a share metric) and its latest reported enrollment
(for the district-wide total).

## Usage

``` r
tges_gap_cost(
  tges,
  district_id,
  metric = "classroom_share",
  target = "median",
  peer = c("tges_group", "dfg", "county", "statewide"),
  year = NULL,
  calc_type = "Budgeted",
  dfg_revision = 2000
)
```

## Arguments

- tges:

  Output of
  [`fetch_tges()`](https://almartin82.github.io/njschooldata/reference/fetch_tges.md)
  or
  [`fetch_many_tges()`](https://almartin82.github.io/njschooldata/reference/fetch_many_tges.md).

- district_id:

  Character. The 4-digit focal district code.

- metric:

  Character. A column from
  [`tges_composition()`](https://almartin82.github.io/njschooldata/reference/tges_composition.md).
  Default `"classroom_share"`.

- target:

  Benchmark within the peer group: `"median"` (default), `"mean"`,
  `"max"`, or a numeric quantile in `[0, 1]`.

- peer:

  Character. Peer group. One of `"tges_group"` (default), `"dfg"`,
  `"county"`, `"statewide"`.

- year:

  Numeric. Composition report year. Default: latest present.

- calc_type:

  Character. Composition calc type. Default `"Budgeted"`.

- dfg_revision:

  Numeric. DFG revision when `peer = "dfg"`. Default 2000.

## Value

A one-row tibble: entity columns, `peer_group`, `n_peers`, `metric`,
`focal_value`, `target_basis`, `target_value`, `gap`, `budgetary_pp`,
`per_pupil_gap_dollars`, `ade`, `ade_year`, and `total_gap_dollars`.

## Details

For a `*_share` metric, the per-pupil dollar gap is
`(target_share - focal_share) * budgetary_pp`; for a per-pupil dollar
metric (e.g. `classroom`) the gap is already in dollars per pupil. The
district-wide total multiplies the per-pupil gap by the latest `CSG1AA`
average daily enrollment (reported in `ade`/`ade_year`; this is the most
recent actuals year, which may differ from the composition year). A
positive gap means the district spends *less* than the benchmark and
would need to add dollars to reach it; a negative gap means it already
exceeds the benchmark.

## Examples

``` r
if (FALSE) { # \dontrun{
library(dplyr)

# What would it cost Newark to reach the DFG A median classroom share?
tges_gap_cost(fetch_tges(2024), district_id = "3570",
              metric = "classroom_share", target = "median", peer = "dfg")
} # }
```
