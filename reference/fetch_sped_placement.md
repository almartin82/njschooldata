# Fetch NJ Special Education Placement / Educational Environment data

Returns the IDEA Section 618 "Student Count and Educational Environment"
(placement / Least Restrictive Environment) data published by the NJ
DOE, the companion to
[`fetch_sped`](https://almartin82.github.io/njschooldata/reference/fetch_sped.md)
(which returns classification rates). The workbook reports counts and
percents of students with disabilities by educational setting (eg "In
General Education for 80 More of the Day", "Separate School",
"Residential Facility").

## Usage

``` r
fetch_sped_placement(
  end_year,
  age_group = "5-21",
  level = "district",
  tidy = TRUE
)
```

## Arguments

- end_year:

  ending school year (eg 2025 for the 2024-25 school year). Valid years:
  2020 through 2025.

- age_group:

  one of `"5-21"` (school-age, default) or `"3-5"` (preschool).

- level:

  one of `"district"` (district + charter rows, default) or `"state"`
  (statewide breakdowns).

- tidy:

  if `TRUE` (default), pivots to the long tidy schema described above.
  If `FALSE`, returns the raw workbook tibble(s) with minimal cleaning
  (column names preserved as published; all values as character;
  suppression flags retained). For pre-2025 years that span multiple
  subgroup files, `tidy = FALSE` returns a named list.

## Value

tibble. See "Tidy output schema" for the layout when `tidy = TRUE`.

## Coverage

Supports end_years 2020-2025. NJ DOE changed publication conventions
multiple times across these years: 2020-2021 are bundled inside an
annual zip archive; 2022-2024 publish ~8 single-subgroup workbooks per
year; 2025 consolidates everything into one workbook. The fetcher hides
these differences and exposes a single tidy schema.

Six state-level slices that NJ DOE published only as PDFs (state 5-21
for end_years 2020-2022, state 3-5 for end_years 2020-2022) are served
from bundled CSVs transcribed from those PDFs; the audit trail (source
URL, SHA-256, transcription date) lives next to the CSVs at
`inst/extdata/sped-placement-pdf-transcribed/`. The 2023 state 5-21
Excel file ships with NJ DOE's typo "PlacemnetData" in its filename
(`StateWide_PlacemnetData_5-21Age_2223_nonpublic.xlsx`); the file map
wires this in transparently. Pre-2020 placement data is not downloadable
at all and requires an OPRA request.

## Tidy output schema

One row per (entity x subgroup x environment), with:

- `end_year`, `county_id`, `county_name`, `district_id`, `district_name`
  (state rows have NA ids and `district_name = "New Jersey"`)

- `subgroup` – standardized snake_case (`"total"`, `"black"`,
  `"hispanic"`, `"lep"`, `"male"`, ..., plus disability categories like
  `"autism"` and (2025 state output only) age rows like `"age_6"`)

- `environment` – short code for the educational setting (see Details
  for valid values)

- `count`, `percent` – counts and percents (0-100 scale) reported for
  the cell; suppressed cells (`"*"`) become `NA`. Note: pre-2025
  district 5-21 workbooks publish counts only, so `percent` is `NA` in
  those rows.

- `subgroup_total` – the subgroup's row total (Districtwide Total /
  Statewide Total) carried for convenience. For pre-2025 district 5-21
  rows this is the visible-count sum across environments.

- `is_state`, `is_district`, `is_charter` – entity flags consistent with
  other njschooldata fetchers (county_id == "80" marks charter
  schools/districts)

- `dimension` (state output only) – which marginal table the row came
  from (`"racial_ethnic"`, `"gender"`, `"disability"`,
  `"multilingual_learner"`; 2025 additionally reports `"age"`)

## Environment categories (school-age, 5-21)

`gen_ed_80_plus`, `gen_ed_40_79`, `gen_ed_less_40`, `separate_school`,
`residential_facility`, `homebound_hospital`, `correction_facility`.
2025 additionally reports `parentally_placed_nonpublic`.

## Environment categories (preschool, 3-5 state)

`ec_program_10plus_hrs`, `services_other_loc_attended_ec_10plus_hrs`,
`ec_program_less_10_hrs`, `services_other_loc_attended_ec_less_10_hrs`,
`separate_class`, `separate_school`, `residential_facility`, `home`,
`service_provider_location`. The 3-5 district sheet has no environment
dimension – the tidy output uses `environment = "districtwide"` with the
districtwide total.

## See also

[`fetch_sped`](https://almartin82.github.io/njschooldata/reference/fetch_sped.md)
for the SPED classification rate data,
[`fetch_sped_placement_multi`](https://almartin82.github.io/njschooldata/reference/fetch_sped_placement_multi.md)
for a multi-year wrapper, and
[`get_raw_sped_placement`](https://almartin82.github.io/njschooldata/reference/get_raw_sped_placement.md)
for the underlying raw reader.

## Examples

``` r
if (FALSE) { # \dontrun{
# 1. Basic call: school-age district-level placement (2025)
placement <- fetch_sped_placement(2025)

# 2. Common dplyr filter -- where are Newark's classified students placed?
library(dplyr)
fetch_sped_placement(2025) %>%
  filter(district_name == "Newark Public School District",
         subgroup == "total") %>%
  select(environment, count, percent) %>%
  arrange(desc(percent))

# 3. State-level breakdown by disability (2024)
fetch_sped_placement(2024, level = "state") %>%
  filter(dimension == "disability",
         environment == "gen_ed_80_plus") %>%
  select(subgroup, count, percent) %>%
  arrange(desc(percent))

# 4. Earlier-year district 5-21 (pre-2025 returns counts only)
fetch_sped_placement(2022, age_group = "5-21", level = "district")
} # }
```
