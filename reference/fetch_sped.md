# Fetch Special Education Classification Data

Fetches NJ DOE special education classification data (IDEA Section 618
public reporting). With `level = "district"` (default) returns the
district-level total classification rate (the count of students with
IEPs and the general-education enrollment denominator per district).
With `level = "state"` returns the statewide count of students with IEPs
by IDEA disability category (2025+ only).

District-level classification is available for every end_year 2015-2025
(the 2015-2024 archives live in the year-labeled folders/zips of the
IDEA 618 public-reporting directory; 2025 is the consolidated workbook).
Data before end_year 2015 requires an OPRA request. The statewide
by-disability-category interface currently reads the consolidated 2025
workbook. For by-disability counts and educational placement (LRE)
across 2020-2025, see
[`fetch_sped_placement`](https://almartin82.github.io/njschooldata/reference/fetch_sped_placement.md).

## Usage

``` r
fetch_sped(end_year, level = "district", with_status = FALSE)
```

## Arguments

- end_year:

  ending school year (e.g., 2025 for the 2024-2025 school year). Valid
  years: 2015-2025 (district); 2025 (state).

- level:

  one of `"district"` (default) or `"state"`. The `"state"`
  by-disability table is only published for 2025+.

- with_status:

  logical, default `FALSE`. When `TRUE`, appends a `value_status` column
  classified from the raw published token (before numeric coercion) so
  suppressed cells are distinguishable from a true zero. Additive;
  default output is unchanged.

## Value

For `level = "district"`: a data frame with columns end_year, county_id,
county_name, district_id, district_name, gened_num, sped_num, sped_rate,
plus the standard entity flags (is_state, is_county, is_district,
is_school, is_charter, is_charter_sector, is_allpublic). For
`level = "state"`: a tibble with columns end_year, is_state,
disability_category, n_students, sped_rate, suppressed, plus the entity
flags. Metric polarity/denominator metadata for `sped_rate`, `sped_num`
and `gened_num` is available via
[`metric_meta`](https://almartin82.github.io/njschooldata/reference/metric_meta.md)
/
[`annotate_metric`](https://almartin82.github.io/njschooldata/reference/annotate_metric.md).

## Details

The default output preserves \`sped_num\`, \`gened_num\`, and
\`sped_rate\` and adds \`measure = "classification_count"\`,
\`disability_category = "all_disabilities"\`, \`subgroup = "total"\`,
\`age_group = "3_21"\` (2023-2025), \`grade_level = NA\`,
\`n_students\`, \`suppressed\`, \`pct_of_enrollment\` (0-100), and
\`nces_dist\`. These are public IEP classification counts, not relabeled
IDEA child counts. Published statewide totals are included in the
default output for 2023-2025. Suppressed districts remain present even
when their enrollment denominator is suppressed. NCES identifiers come
only from an exact CCD 2024 match on the full county-plus-district state
LEA code. Complete NJDOE releases for 2023-2025 are shipped and used
offline by default, with length and SHA-256 verification. The 2025
workbook title says 2023-24, but NJDOE's release page dates its count to
October 15, 2024 (end year 2025).

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
