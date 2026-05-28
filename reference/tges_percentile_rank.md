# Percentile-rank a TGES metric within a peer group

Fiscal counterpart to
[`grate_percentile_rank()`](https://almartin82.github.io/njschooldata/reference/grate_percentile_rank.md)
/
[`parcc_percentile_rank()`](https://almartin82.github.io/njschooldata/reference/parcc_percentile_rank.md).
Ranks any numeric TGES column within a peer group and adds
`{prefix}_rank`, `{prefix}_n`, and `{prefix}_percentile`. Higher metric
value = higher percentile.

Ranking is computed within `year_col` and the peer column, and also
within `indicator` and `calc_type` when those columns are present, so
stacked multi-indicator / multi-calc-type frames rank correctly.

## Usage

``` r
tges_percentile_rank(
  df,
  metric_col = "Per Pupil costs",
  peer = c("tges_group", "dfg", "county", "statewide", "custom"),
  year_col = "end_year",
  prefix = "peer",
  dfg_revision = 2000,
  custom_ids = NULL
)
```

## Arguments

- df:

  A tidied TGES table (e.g. `fetch_tges(2024)$CSG1`) or the output of
  [`tges_composition()`](https://almartin82.github.io/njschooldata/reference/tges_composition.md).

- metric_col:

  Character. Column to rank. Default `"Per Pupil costs"`.

- peer:

  Character. Peer group:

  - `"tges_group"` (default): the TGES enrollment-band `group` (no
    network; matches the set NJ's published rank uses)

  - `"dfg"`: District Factor Group (fetches DFG data over the network)

  - `"county"`: within `county_name` (the "town next door" set)

  - `"statewide"`: all districts

  - `"custom"`: a caller-supplied set of district codes (see
    `custom_ids`); ranks within that set only. This is the hook for
    [`tges_find_peers()`](https://almartin82.github.io/njschooldata/reference/tges_find_peers.md)
    output.

- year_col:

  Character. Year column. Default `"end_year"`.

- prefix:

  Character. Prefix for the output columns. Default `"peer"`.

- dfg_revision:

  Numeric. DFG revision when `peer = "dfg"`. Default 2000.

- custom_ids:

  Character vector of `district_id`s. Required when `peer = "custom"`;
  the frame is restricted to these codes and ranked within them. Ignored
  otherwise.

## Value

`df` (ungrouped) with the three percentile columns added.

## Examples

``` r
if (FALSE) { # \dontrun{
library(dplyr)

# Rank budgetary per-pupil cost within each TGES enrollment band
fetch_tges(2024)$CSG1 %>%
  tges_percentile_rank() %>%
  filter(district_id == "3570") %>%
  select(end_year, `Per Pupil costs`, peer_percentile)

# Rank classroom share within DFG peers
tges_composition(fetch_tges(2024), calc_type = "Budgeted") %>%
  tges_percentile_rank("classroom_share", peer = "dfg")

# Rank per-pupil cost against county neighbors
fetch_tges(2024)$CSG1 %>%
  tges_percentile_rank(peer = "county", prefix = "county")
} # }
```
