# Year-to-year funding volatility, ranked against peers

How bumpy is a district's funding, and is it more fragile than its
peers? For a chosen series this computes per-district volatility across
the available years (coefficient of variation plus the typical and worst
year-over-year swing) and ranks it within the peer group. Pointed at the
federal-revenue share it is the quantitative companion to the
ESSER-cliff screen; pointed at total per-pupil spend it flags districts
whose budgets lurch from year to year.

## Usage

``` r
tges_volatility(
  tges,
  metric = "total_pp",
  peer = c("tges_group", "dfg", "county", "statewide"),
  min_years = 3,
  table = "CSG1",
  calc_type = "Budgeted",
  dfg_revision = 2000
)
```

## Arguments

- tges:

  Output of
  [`fetch_many_tges()`](https://almartin82.github.io/njschooldata/reference/fetch_many_tges.md)
  (multi-year).

- metric:

  Character. Series to measure. Default `"total_pp"`.

- peer:

  Character. Peer group. One of `"tges_group"` (default), `"dfg"`,
  `"county"`, `"statewide"`.

- min_years:

  Integer. Minimum finite observations per district. Default 3.

- table:

  Character. Per-pupil cost table to source `metric` from when it is
  neither a revenue-mix nor a composition column. Default `"CSG1"`.

- calc_type:

  Character. Calc type for composition/table sources. Default
  `"Budgeted"`.

- dfg_revision:

  Numeric. DFG revision when `peer = "dfg"`. Default 2000.

## Value

A per-district tibble: entity columns, `peer_group`, `n_years`,
`mean_value`, `sd_value`, `cv`, `mean_abs_yoy`, `max_abs_yoy`, and the
rank columns `vol_rank`, `vol_n`, `vol_percentile`.

## Details

Needs a multi-year input
([`fetch_many_tges()`](https://almartin82.github.io/njschooldata/reference/fetch_many_tges.md)).
The metric is pulled from
[`tges_revenue_mix()`](https://almartin82.github.io/njschooldata/reference/tges_revenue_mix.md)
(e.g. `total_pp`, `federal_share`, `local_share`), else
[`tges_composition()`](https://almartin82.github.io/njschooldata/reference/tges_composition.md)
(e.g. `classroom_share`), else a per-pupil cost table column. Districts
with fewer than `min_years` finite observations are dropped. `cv` is
`sd / |mean|`; `mean_abs_yoy` and `max_abs_yoy` are the mean and max
absolute year-over-year percent change. The volatility rank is computed
on `cv` within the peer group (higher cv = higher percentile = more
volatile).

## Examples

``` r
if (FALSE) { # \dontrun{
library(dplyr)

# Whose federal-revenue share whipsawed the most through the ESSER years?
tges_volatility(fetch_many_tges(2018:2025), metric = "federal_share",
                peer = "dfg") %>%
  arrange(desc(vol_percentile)) %>%
  select(district_name, mean_value, cv, max_abs_yoy, vol_percentile) %>%
  head(10)
} # }
```
