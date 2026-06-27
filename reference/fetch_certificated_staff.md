# Fetch Certificated-Staff FTE Counts (position x race x gender)

Downloads the NJ DOE certificated-staff file for `end_year` and returns
staff full-time-equivalent (FTE) counts by position, race, and gender,
harmonized to one tidy long-by-gender schema across two source eras.
This is the deep historical staffing series, distinct from the
SPR-sourced staff fetchers (which start in 2018).

## Usage

``` r
fetch_certificated_staff(end_year, level = "school")
```

## Arguments

- end_year:

  A school year end in 2000-2008 or 2020-2026. Years 2009-2019 error
  (unsupported intermediate layout).

- level:

  One of `"school"` (default), `"district"`, `"county"`, `"state"`.

## Value

Data frame with `end_year`, the entity identifiers, `position`,
`gender`, the race FTE columns (`white`, `black`, `hispanic`, `asian`,
`american_indian`, `pacific_islander`, `two_or_more`), `total`, and the
entity flags (`is_state`, `is_county`, `is_district`, `is_school`,
`is_charter`).

## Details

**Source + covered years.** Standalone files under
`nj.gov/education/doedata/cs/`. The covered-year set was established
empirically against the live files:

- **Legacy CSV era: 2000-2008** – a 20-column CSV (one row per entity x
  position x sex). Race buckets are `WHITE`, `BLACK`, `HISP`, `ALS_IND`
  (American Indian) and `ASI_PAC` (a single combined
  Asian/Pacific-Islander group). In this era `asian` carries that
  combined count and `pacific_islander` / `two_or_more` are `NA` (NJ did
  not report them separately) – never `0`.

- **Modern xlsx era: 2020-2026** – a four-sheet workbook
  (STATE/COUNTY/DISTRICT/SCHOOL) with race reported separately (`asian`,
  `pacific_islander`, `two_or_more` all populated).

- **2009-2019 ERROR (unsupported).** The intermediate Excel files use a
  drifting, non-uniform layout (varying header-row position, column
  order and race-column names, and an ambiguous `OTHER` bucket). Rather
  than risk emitting misaligned values, these years error.

**Long-by-gender schema.** Output is one row per (entity, position,
gender), `gender` in `"total"`, `"male"`, `"female"`. The race FTE
columns are the race breakdown for that gender: the legacy era reports
race x sex, so race columns are populated on all three gender rows; the
modern era reports race only as a gender total, so race columns are
populated on the `"total"` row and `NA` on the `"male"` / `"female"`
rows (whose `total` carries that gender's headcount). An era-absent race
column is `NA`, never `0`. Non-binary staff are published only as a
percent (no count) in the modern files and are not surfaced as a count.

**FTE values.** Counts are full-time equivalents and are fractional in
the modern era (e.g. `35.8`); they are preserved as doubles, never
rounded.

**Positions.** Normalized to `administrators`, `teachers`,
`special_services`, `supervisors_coordinators`, `total`.

**Levels.** `level` selects the entity grain: `"school"` (default),
`"district"`, `"county"`, `"state"`. The modern era reads the matching
sheet; the legacy era filters the single CSV by its entity conventions
(state = `STATE SUM`, county = `CO SUMMARY`, district = `DIST SUMMARY`).

## Examples

``` r
if (FALSE) { # \dontrun{
# Statewide teacher FTE by gender, 2024-25
library(dplyr)
fetch_certificated_staff(2025, level = "state") %>%
  filter(position == "teachers")

# School-level teacher race breakdown (gender total), latest year
fetch_certificated_staff(2026) %>%
  filter(position == "teachers", gender == "total") %>%
  select(district_name, school_name, white, black, hispanic, asian, total)

# Long-run statewide teacher headcount (legacy + modern)
purrr::map_dfr(c(2000, 2005, 2008, 2020, 2025), function(y) {
  fetch_certificated_staff(y, level = "state") %>%
    filter(position == "teachers", gender == "total") %>%
    transmute(end_year, teachers = total)
})
} # }
```
