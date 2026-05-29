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
  2025.

- age_group:

  one of `"5-21"` (school-age, default) or `"3-5"` (preschool).

- level:

  one of `"district"` (district + charter rows, default) or `"state"`
  (statewide breakdowns by age, disability, race/ ethnicity, gender, and
  multilingual-learner status).

- tidy:

  if `TRUE` (default), pivots to the long tidy schema described above.
  If `FALSE`, returns the raw workbook tibble with minimal cleaning
  (column names preserved as published; all values as character;
  suppression flags retained).

## Value

tibble. See "Tidy output schema" for the layout when `tidy = TRUE`.

## Coverage

Currently only the SY2024-25 consolidated workbook (end_year 2025) is
supported. Earlier years are published on nj.gov but under a different,
fragmented file structure (one workbook per subgroup, with some
subgroups PDF-only). Wiring them up is tracked as a follow-up to issue
\#46. Pre-2020 placement data is not downloadable at all and requires an
OPRA request.

## Tidy output schema

One row per (entity x subgroup x environment), with:

- `end_year`, `county_id`, `county_name`, `district_id`, `district_name`
  (state rows have NA ids and `district_name = "New Jersey"`)

- `subgroup` – standardized snake_case (`"total"`, `"black"`,
  `"hispanic"`, `"lep"`, `"male"`, ..., plus disability categories like
  `"autism"` and (state output only) age rows like `"age_6"`)

- `environment` – short code for the educational setting (see Details
  for valid values)

- `count`, `percent` – counts and percents (0-100 scale) reported for
  the cell; suppressed cells (`"*"`) become `NA`

- `subgroup_total` – the subgroup's row total (Districtwide Total /
  Statewide Total) carried for convenience

- `is_state`, `is_district`, `is_charter` – entity flags consistent with
  other njschooldata fetchers (county_id == "80" marks charter
  schools/districts)

- `dimension` (state output only) – which marginal table the row came
  from (`"age"`, `"disability"`, `"racial_ethnic"`, `"gender"`,
  `"multilingual_learner"`)

## Environment categories (school-age, 5-21)

`gen_ed_80_plus`, `gen_ed_40_79`, `gen_ed_less_40`, `separate_school`,
`residential_facility`, `homebound_hospital`, `correction_facility`,
`parentally_placed_nonpublic`.

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
# 1. Basic call: school-age district-level placement
placement <- fetch_sped_placement(2025)

# 2. Common dplyr filter -- where are Newark's classified students placed?
library(dplyr)
fetch_sped_placement(2025) %>%
  filter(district_name == "Newark Public School District",
         subgroup == "total") %>%
  select(environment, count, percent) %>%
  arrange(desc(percent))

# 3. State-level breakdown by disability
fetch_sped_placement(2025, level = "state") %>%
  filter(dimension == "disability",
         environment == "gen_ed_80_plus") %>%
  select(subgroup, count, percent) %>%
  arrange(desc(percent))

# 4. Preschool placement (statewide, by environment)
fetch_sped_placement(2025, age_group = "3-5", level = "state")
} # }
```
