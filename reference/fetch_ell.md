# Fetch New Jersey English Learner (EL) population data

Downloads and tidies the English Learner / Multilingual Learner
headcount from the NJ DOE Fall Enrollment files, at state, district, and
school level. This is the EL \*\*population\*\* feature (how many EL
students are enrolled and their share of total enrollment) — it is
distinct from EL \*\*proficiency\*\* assessment (WIDA ACCESS), exposed
separately via \[fetch_access()\].

## Usage

``` r
fetch_ell(end_year, tidy = TRUE, use_cache = FALSE)
```

## Arguments

- end_year:

  ending academic year. Valid values: 2006-2026. See
  \[get_available_ell_years()\].

- tidy:

  if \`TRUE\` (default), returns the long cross-state tidy contract (see
  \[tidy_ell()\]). If \`FALSE\`, returns the wider per-entity frame with
  \`el_count\`, \`el_pct\`, and \`total_enrollment\` as columns.

- use_cache:

  if \`TRUE\`, uses the session cache to avoid re-downloading. See
  \[njsd_cache_info()\].

## Value

data.frame of EL population data. An out-of-range \`end_year\` returns
the empty, correctly-typed tidy frame.

## Details

New Jersey publishes a single current-EL headcount per entity, so the
tidy output carries \`el_status == "current"\` and \`subgroup ==
"total"\` for every row. The EL share of enrollment
(\`pct_of_enrollment\`, 0-100) is computed fresh from the published
headcount; for the 2020-2022 district/school files, which publish only a
percent, that published percent is carried through and \`n_students\` is
\`NA\` (the count is never back-derived from the percent).

## Examples

``` r
if (FALSE) { # \dontrun{
# Statewide and district EL counts for 2024-25
ell <- fetch_ell(2025)

# State EL trend, EL share of enrollment
library(dplyr)
fetch_ell(2025) %>%
  filter(is_state) %>%
  select(end_year, n_students, pct_of_enrollment)

# Districts with the highest EL share
fetch_ell(2025) %>%
  filter(is_district, total_enrollment > 1000) %>%
  arrange(desc(pct_of_enrollment)) %>%
  select(district_name, n_students, pct_of_enrollment) %>%
  head(10)
} # }
```
