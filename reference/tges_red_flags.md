# Red-flag scan: where a district sits in the top or bottom decile of peers

The product a board member actually wants before a meeting. Runs
[`tges_percentile_rank()`](https://almartin82.github.io/njschooldata/reference/tges_percentile_rank.md)
across every major spending indicator for one district and surfaces the
ones where it lands in the top or bottom decile of its peer group. The
output is a one-page "you are top-decile in legal services and plant
O&M, bottom-decile in classroom share" brief.

## Usage

``` r
tges_red_flags(
  tges,
  district_code,
  peer = c("tges_group", "dfg", "county", "statewide"),
  year = NULL,
  calc_type = "Budgeted",
  threshold = 10,
  only_flagged = TRUE,
  dfg_revision = 2000
)
```

## Arguments

- tges:

  Output of
  [`fetch_tges()`](https://almartin82.github.io/njschooldata/reference/fetch_tges.md)
  (a single guide) or
  [`fetch_many_tges()`](https://almartin82.github.io/njschooldata/reference/fetch_many_tges.md).

- district_code:

  Character. The 4-digit focal district code (Newark = "3570").

- peer:

  Character. Peer group. See
  [`tges_percentile_rank()`](https://almartin82.github.io/njschooldata/reference/tges_percentile_rank.md).
  Default `"tges_group"`.

- year:

  Numeric. Report year to scan. Default: the latest `end_year` present.

- calc_type:

  Character. For the per-pupil cost tables, which calc type to rank.
  Default `"Budgeted"` (the current-year budgeted figure).

- threshold:

  Numeric. Decile width in percentile points. Default 10: percentile
  `<= 10` is bottom-decile, `>= 90` is top-decile.

- only_flagged:

  Logical. If `TRUE` (default) return only the top/bottom-decile rows;
  if `FALSE` return the full indicator profile with a `flag` column
  (`NA` when not extreme).

- dfg_revision:

  Numeric. DFG revision when `peer = "dfg"`. Default 2000.

## Value

A tibble: `indicator`, `value`, `peer_percentile`, `peer_n`,
`higher_means`, `end_year`, and `flag`.

## Details

The scan covers the per-pupil cost tables (CSG1, CSG2, CSG6, CSG8,
CSG8A, CSG10, CSG12, CSG13, CSG15) ranked on "Per Pupil costs", plus the
classroom and administration shares from
[`tges_composition()`](https://almartin82.github.io/njschooldata/reference/tges_composition.md).
Each row carries `higher_means` so the direction is unambiguous: a
top-decile "Administration \$/pupil" is a cost flag, while a top-decile
"Classroom share" is favourable. Percentile is recomputed within the
chosen peer group (not NJ's published enrollment-band rank, unless
`peer = "tges_group"`), so all indicators use one consistent peer
system.

## Examples

``` r
if (FALSE) { # \dontrun{
library(dplyr)

# Newark's red flags within its enrollment-band peers
tges_red_flags(fetch_tges(2024), district_code = "3570")

# Full profile within DFG A peers, nothing hidden
tges_red_flags(fetch_tges(2024), district_code = "3570",
               peer = "dfg", only_flagged = FALSE)
} # }
```
