# Find a district's data-driven structural peers

DFG is a 1990s census construct and county is just geography; neither
answers "which districts are actually structurally like mine?" This
standardizes a set of structural features (enrollment, per-pupil cost,
spending composition, revenue mix) and returns the `n` nearest districts
by scaled Euclidean distance. The result is the honest peer set for
every other comparison in this toolkit: pass the returned codes to
`tges_percentile_rank(peer = "custom", custom_ids = ...)`.

## Usage

``` r
tges_find_peers(
  tges,
  district_code,
  n = 10,
  year = NULL,
  features = c("ade", "budgetary_pp", "classroom_share", "administration_share",
    "local_share", "state_share"),
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

- district_code:

  Character. The 4-digit focal district code (Newark = "3570").

- n:

  Integer. Number of peers to return (besides the focal row). Default
  10.

- year:

  Numeric. Composition report year to anchor on. Default: latest
  present.

- features:

  Character vector of feature columns to match on. Default
  `c("ade", "budgetary_pp", "classroom_share", "administration_share", "local_share", "state_share")`.
  Any numeric column in the assembled frame is allowed (e.g. `total_pp`,
  `federal_share`, `support_services_share`, `plant_ops_share`).

- calc_type:

  Character. Composition calc type. Default `"Budgeted"`.

- dfg_revision:

  Numeric. DFG revision for the reported `dfg` column.

## Value

A tibble sorted by `distance` ascending, with the focal district first
(`is_focal = TRUE`, `distance = 0`) followed by the `n` nearest peers:
`district_code`, `district_name`, `county_name`, `group`, `dfg`,
`is_focal`, `distance`, and the raw feature columns.

## Details

Features are assembled per district from the latest available report for
each source (composition for the chosen `year`, the most recent `CSG1AA`
enrollment, the most recent VITSTAT revenue mix), then each feature is
z-scored across all districts with complete data. `ade` (enrollment) is
log-transformed before scaling because it is heavy-tailed. Distance is
the Euclidean norm over the scaled features; the focal district must
have a complete feature vector. Zero-variance features are dropped with
a warning. `dfg` is reported for context but is not part of the
distance.

## Examples

``` r
if (FALSE) { # \dontrun{
library(dplyr)

# Newark's data-driven fiscal twins
peers <- tges_find_peers(fetch_tges(2024), district_code = "3570")
peers %>% select(district_name, dfg, distance, ade, budgetary_pp, local_share)

# Use them as the peer set for an honest rank
twin_ids <- peers$district_code
fetch_tges(2024)$CSG1 %>%
  tges_percentile_rank(peer = "custom", custom_ids = twin_ids) %>%
  filter(district_code == "3570") %>%
  select(`Per Pupil costs`, peer_percentile, peer_n)
} # }
```
