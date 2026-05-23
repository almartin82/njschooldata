# Fetch ESSA Accountability Status Counts (district/state)

Downloads the `ESSAAccountabilityStatusCounts` sheet from the redesigned
2024-25 School Performance Reports. Each row tallies, for a district
(and the statewide total), how many of its schools are identified as
Comprehensive Support and Improvement (CSI), Additional Targeted Support
and Improvement (ATSI), and Targeted Support and Improvement (TSI).

## Usage

``` r
fetch_spr_essa_status_counts(end_year)
```

## Arguments

- end_year:

  A school year. Only `2025` (SY2024-25) and later are supported.

## Value

Data frame with county_id, county_name, district_id, district_name,
school_id, school_name, comprehensive_csi, additional_targeted_atsi,
targeted_tsi, end_year, and the aggregation flags.

## Details

This sheet exists only in the District/State database, so this function
always reads district-level data (there is no `level` argument). The
three count columns are returned numeric. The per-school identification
detail behind these tallies is available from
[`fetch_essa_status`](https://almartin82.github.io/njschooldata/reference/fetch_essa_status.md)
(the `ESSAAccountabilityStatusList` sheet).

**Supported years:** only `end_year >= 2025`. The pre-2025
District/State database stored accountability status in a single sheet
that
[`fetch_essa_status`](https://almartin82.github.io/njschooldata/reference/fetch_essa_status.md)
reads; the separate counts sheet is new in the redesign.

## Examples

``` r
if (FALSE) { # \dontrun{
# District/state CSI/ATSI/TSI tallies
counts <- fetch_spr_essa_status_counts(2025)

# Statewide totals
library(dplyr)
fetch_spr_essa_status_counts(2025) %>%
  filter(is_state) %>%
  select(comprehensive_csi, additional_targeted_atsi, targeted_tsi)

# Districts with the most CSI schools
fetch_spr_essa_status_counts(2025) %>%
  filter(is_district) %>%
  slice_max(comprehensive_csi, n = 10) %>%
  select(county_name, district_name, comprehensive_csi)
} # }
```
