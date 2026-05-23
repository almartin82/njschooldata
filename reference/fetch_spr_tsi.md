# Fetch Targeted Support and Improvement (TSI) Identification

Downloads the `TSIIdentification` sheet from the redesigned 2024-25
School Performance Reports. Each row reports, for a school / student
group / indicator, whether the school is identified for Targeted Support
and Improvement and the two-year target history (SY2023-24 and
SY2024-25) that drove the determination.

## Usage

``` r
fetch_spr_tsi(end_year)
```

## Arguments

- end_year:

  A school year. Only `2025` (SY2024-25) and later are supported.

## Value

Data frame with entity identifiers, identified_for_tsi,
student_groups_tsi, subgroup, indicator, the SY2023-24 and SY2024-25
value/target/status columns, tsi_criteria_met, identification_note, and
the aggregation flags.

## Details

This sheet exists only in the School database, so this function always
reads school-level data (there is no `level` argument). For readability
a few raw column names are normalized: `IdentifiedforTSI` -\>
`identified_for_tsi`, `TSICriteriaMet` -\> `tsi_criteria_met`, and
`AllTargetsNotMetBelowStatus24-25` -\>
`all_targets_not_met_below_status_2425`. The `actual_value_*` and
`target_*` value columns are returned numeric (percent signs stripped,
suppressed/below-N-size cells set to `NA`); the `*_status_*` and note
columns are kept as labels. `subgroup` is standardized via the SPR
subgroup cleaner.

**Supported years:** only `end_year >= 2025`.

## Examples

``` r
if (FALSE) { # \dontrun{
# School-level TSI identification
tsi <- fetch_spr_tsi(2025)

# Schools identified for TSI and the indicators that triggered it
library(dplyr)
fetch_spr_tsi(2025) %>%
  filter(identified_for_tsi == "Yes", tsi_criteria_met == "Yes") %>%
  select(district_name, school_name, subgroup, indicator)

# Distinct schools identified for TSI
fetch_spr_tsi(2025) %>%
  filter(identified_for_tsi == "Yes") %>%
  distinct(county_id, district_id, school_id, school_name)
} # }
```
