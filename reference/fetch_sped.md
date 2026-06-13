# Fetch Special Education Classification Data

Fetches NJ DOE special education classification data (IDEA Section 618
public reporting). With `level = "district"` (default) returns the
district-level total classification rate (the count of students with
IEPs and the general-education enrollment denominator per district).
With `level = "state"` returns the statewide count of students with IEPs
by IDEA disability category (2025+ only).

Historical district data (2003-2019) is no longer accessible via URL and
requires an OPRA request. For by-disability counts and educational
placement (LRE) across 2020-2025, see
[`fetch_sped_placement`](https://almartin82.github.io/njschooldata/reference/fetch_sped_placement.md).

## Usage

``` r
fetch_sped(end_year, level = "district")
```

## Arguments

- end_year:

  ending school year (e.g., 2025 for the 2024-2025 school year). Valid
  years: 2024, 2025.

- level:

  one of `"district"` (default) or `"state"`. The `"state"`
  by-disability table is only published for 2025+.

## Value

For `level = "district"`: a data frame with columns end_year, county_id,
county_name, district_id, district_name, gened_num, sped_num, sped_rate.
For `level = "state"`: a tibble with columns end_year, is_state,
disability_category, n_students, sped_rate, suppressed.

## See also

[`fetch_sped_placement`](https://almartin82.github.io/njschooldata/reference/fetch_sped_placement.md)
for IDEA 618 educational environment / placement data and multi-year
by-disability counts.

## Examples

``` r
if (FALSE) { # \dontrun{
# 1. District-level classification rates (default)
fetch_sped(2025)

# 2. Filter to the highest-classification districts
library(dplyr)
fetch_sped(2025) %>%
  filter(gened_num > 1000) %>%
  arrange(desc(sped_rate)) %>%
  select(district_name, gened_num, sped_num, sped_rate)

# 3. Statewide child count by disability category (2025+)
fetch_sped(2025, level = "state") %>%
  arrange(desc(n_students))
} # }
```
