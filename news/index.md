# Changelog

## njschooldata 0.9.2

### Bug fixes

- [`fetch_enr()`](https://almartin82.github.io/njschooldata/reference/fetch_enr.md)
  now works end-to-end for 1999-2009. Pre-2010 NJDOE files arrive with
  combined “01-ATLANTIC” strings in the `COUNTY` / `DISTRICT` / `SCHOOL`
  columns.
  [`clean_enr_names()`](https://almartin82.github.io/njschooldata/reference/clean_enr_names.md)
  renames those to `county_name` / `district_name` / `school_name`, and
  [`split_enr_cols()`](https://almartin82.github.io/njschooldata/reference/split_enr_cols.md)
  is what creates the matching `*_id` columns by splitting on `"-"`.
  [`process_enr()`](https://almartin82.github.io/njschooldata/reference/process_enr.md)
  previously called the `dplyr::mutate(county_id = ...)` cleanup step
  *before*
  [`split_enr_cols()`](https://almartin82.github.io/njschooldata/reference/split_enr_cols.md),
  so every pre-2010 year errored on “object ‘county_id’ not found.”
  Reordered so
  [`split_enr_cols()`](https://almartin82.github.io/njschooldata/reference/split_enr_cols.md)
  runs first.
- `ENR_VALID_YEARS` extended back to 1999. The earlier note that “1999
  was removed from the NJ DOE website” turned out to be stale; the
  1998-99 ZIP is still hosted at
  `/education/doedata/enr/enr99/enrollment_9899.zip` and parses cleanly
  after the fix above.

### Data notes

- The full enrollment panel is now 1999-2026 (28 years). State Hispanic
  enrollment grew every single year from 1999-2025 and posted its first
  decline (-6,318, -1.3%) in 2025-26.

## njschooldata 0.9.1

### New features

- [`fetch_enr()`](https://almartin82.github.io/njschooldata/reference/fetch_enr.md)
  now supports 2026 (2025-26 fall enrollment). `ENR_VALID_YEARS` and the
  enrollment `year_ranges` extend to 2026.
- [`get_raw_enr()`](https://almartin82.github.io/njschooldata/reference/get_raw_enr.md)
  is resilient to NJ DOE’s filename capitalization: the 2025-26 file
  shipped as `Enrollment_2526.zip` (capital E) versus the historical
  lowercase `enrollment_*.zip`. The fetcher now tries both.

### Bug fixes

- Fixed
  [`fetch_grad_rate()`](https://almartin82.github.io/njschooldata/reference/fetch_grad_rate.md)
  for all years. In 2026 NJ DOE retired the `/schoolperformance/grad/`
  tree and moved every cohort file to `/spr/adddata/doc/acgrdocs/`; the
  old URLs began returning a 404 HTML page that failed to open as xlsx.
  All 4-year (2011-2024) and 5-year (2012-2019) URLs now point at the
  current location.
- Fixed a long-standing state-level grade-8 dropout. NJ DOE ships the
  label “Eight Grade” (sic) as a *row value* on the State worksheet; the
  existing typo fix only corrected column names, so state 8th-grade
  enrollment (~100k students) silently landed in an NA-grade row for all
  2020+ years. State grade-8 totals now map to “08” and match the sum of
  district grade-8 totals. State and district/school totals are
  unchanged.

### Data notes

- 2026 K-12 enrollment fell 1.90% (state total 1.72%) from 2025 - the
  first real decline in years. Verified as genuine demographic change:
  cohort retention 2025-\>2026 sits in \[0.975, 1.013\] for every grade,
  PreK rose while K-12 fell, and the state total reproduces NJ DOE’s
  published 1,357,450 exactly. No definition or coverage change.

### Tests

- Extended enrollment year-coverage tests with 2026 pins and added
  structural invariants (state = sum of districts, PK + K12UG = total,
  state grade-8 regression, cohort-retention believability).
- Fixed stale `test_validation.R` assertions that expected 1999
  enrollment to be valid (1999 was removed from the NJ DOE website; the
  range starts at 2000).

### Documentation

- Refreshed the enrollment vignette and README to the 2020-2026 window,
  with all 15 stories recomputed and the committed `figure-html` charts
  regenerated so the published site reflects 2026. Plot chunks now
  default to `cache = FALSE` to prevent stale cached figures.

## njschooldata 0.9.0

### New features

- Extended data support through 2024-2025 school year
- [`fetch_enr()`](https://almartin82.github.io/njschooldata/reference/fetch_enr.md)
  supports 2024 and 2025 data
- [`fetch_parcc()`](https://almartin82.github.io/njschooldata/reference/fetch_parcc.md)
  supports 2024 NJSLA data
- Added GitHub Actions CI/CD workflows

### Breaking changes

- Minimum R version now 4.1.0 (was 3.5.0)

### Internal changes

- Migrated tests to testthat 3e edition
- Replaced deprecated `ensurer::ensure_that()` with base R validation
- Replaced deprecated
  [`dplyr::summarise_each()`](https://dplyr.tidyverse.org/reference/defunct-each.html)
  with [`across()`](https://dplyr.tidyverse.org/reference/across.html)
- Replaced deprecated `dplyr::rbind_all()` with
  [`bind_rows()`](https://dplyr.tidyverse.org/reference/bind_rows.html)
- Fixed deprecated function calls

### njschooldata 0.8.19

### New features

`get_school_directory` and `get_district_directory` updated to reflect
new NJDOE pages / format.

### njschooldata 0.8.18

### New features

`fetch_enr` supports 2023 data.

### njschooldata 0.8.17

### Bugfixes

- More explicit namespace prefixes for functions
- Moved some dependencies to imports

### njschooldata 0.8.16

### New features

[`get_district_directory()`](https://almartin82.github.io/njschooldata/reference/get_district_directory.md)
and
[`get_school_directory()`](https://almartin82.github.io/njschooldata/reference/get_school_directory.md)
read in metadata about schools and districts (eg, NCES ids!)

### njschooldata 0.8.15

### New features

`fetch_enr` supports 2022 data. several bugfixes for older years.

### njschooldata 0.8.14

### New features

`lookup_peer_percentile` function to gauge where an aggregation falls in
the distribution of measured/actual schools/districts.

### njschooldata 0.8.13

### New features

- postsecondary matriculation aggregations - `district_matric_aggs` and
  `allpublic_matric_aggs`

- bug fixes for mSGP and for njsla/parcc assessment file location
  changes

### njschooldata 0.8.12

### New features

- `K12UG` aggregate published - K12 w/ ungraded students.

### njschooldata 0.8.11

### New features

- [`ward_grate_aggs()`](https://almartin82.github.io/njschooldata/reference/ward_grate_aggs.md)
  and
  [`ward_gcount_aggs()`](https://almartin82.github.io/njschooldata/reference/ward_gcount_aggs.md)
  calculate grad rate and grad count for supported ward geographies

### njschooldata 0.8.10

### New features

- [`charter_sector_spec_pop_aggs()`](https://almartin82.github.io/njschooldata/reference/charter_sector_spec_pop_aggs.md)
  and
  [`allpublic_spec_pop_aggs()`](https://almartin82.github.io/njschooldata/reference/allpublic_spec_pop_aggs.md)
  calculate sector wide special population aggregations
- [`charter_sector_sped_aggs()`](https://almartin82.github.io/njschooldata/reference/charter_sector_sped_aggs.md)
  and
  [`allpublic_sped_aggs()`](https://almartin82.github.io/njschooldata/reference/allpublic_sped_aggs.md)
  calculate sector-wide SPED aggregations
- [`extract_rc_enrollment()`](https://almartin82.github.io/njschooldata/reference/extract_rc_enrollment.md)
  extracts and cleans spring enrollment data from report card databases
- `fetch_enr` now also returns the count and percentage of free *or*
  reduced lunch students

### njschooldata 0.8.9

### New features

- [`ward_parcc_aggs()`](https://almartin82.github.io/njschooldata/reference/ward_parcc_aggs.md)
  aggregates PARCC data for city ward / neighborhood geographies
  (currently supported: Newark)

### njschooldata 0.8.8

### New features

- [`fetch_grad_rate()`](https://almartin82.github.io/njschooldata/reference/fetch_grad_rate.md)
  and
  [`fetch_grad_count()`](https://almartin82.github.io/njschooldata/reference/fetch_grad_count.md)
  support 2019 data

### njschooldata 0.8.7

### New features

- [`fetch_msgp()`](https://almartin82.github.io/njschooldata/reference/fetch_msgp.md)
  supports 2019 data

- msgp data supports new subgroups: female, male, homeless, foster care,
  military-connected, migrant

### njschooldata 0.8.6

### New features

- [`get_reportcard_special_pop()`](https://almartin82.github.io/njschooldata/reference/get_reportcard_special_pop.md)
  supports 2019 data

### njschooldata 0.8.3

### New features

- [`fetch_parcc()`](https://almartin82.github.io/njschooldata/reference/fetch_parcc.md)
  supports 2019 NJSLA data

### njschooldata 0.8.2

### New features

- [`enrich_school_latlong()`](https://almartin82.github.io/njschooldata/reference/enrich_school_latlong.md)
  will add the address and latitude / longitude of a school

- [`enrich_school_city_ward()`](https://almartin82.github.io/njschooldata/reference/enrich_school_city_ward.md)
  will return the relevant administrative subdivision of a school for
  supported cities. Currently supported: Newark

- `enrich_school_city_neighborhood()` will return the relevant
  neighborhood subdivision for supported cities. Currently supported:
  Newark

## njschooldata 0.8.1

### New features

- [`fetch_msgp()`](https://almartin82.github.io/njschooldata/reference/fetch_msgp.md)
  reads msgp data from report card files.

- [`fetch_reportcard_special_pop()`](https://almartin82.github.io/njschooldata/reference/fetch_reportcard_special_pop.md)

## njschooldata 0.8.0

### New features

- Method for combining school/district Report Card data.

- PARCC Percentile Rank functions are more thoroughly tested, with some
  errors corrected.

## njschooldata 0.7.9

### New features

- Grad Count data (`fetch_grad_count`) from 1999-present.
- Grad rate and count charter sector and all public aggregations.

## njschooldata 0.7.8

### New features

- `fetch_grate` takes a calc type argument, and will return 5 year
  cohort grad rates for 2012-present.

## njschooldata 0.7.7

### New features

- `statewide_peer_percentile` will calculate PARCC scale and proficiency
  percentile rank across NJ.
- `dfg_peer_percentile` will calculate PARCC scale and proficiency
  percentile rank across NJ.

## njschooldata 0.7.6

### New features

- `charter_sector_parcc_aggs` will calculate PARCC composites for city
  charter sectors.
- `allpublic_parcc_aggs` will calculate PARCC composites across city and
  charter schools.

### Breaking changes

- PARCC functions now return `_id` (ie `district_id`, `school_id`)
  instead of `_code`. This closes
  [\#65](https://github.com/almartin82/njschooldata/issues/65) and makes
  school/district identifiers consistent across enrollment and PARCC
  assessment files.

- `parcc_aggregate_calcs` expects a field called `is_charter`.

## njschooldata 0.7.5

### New features

- `enr_grade_aggs` will calculate some common grade level aggregations.
- Any K (half + full day K)
- K-12 enrollment (exclude pre-k)
- K-8 enrollment
- HS

## njschooldata 0.7.4

### New features

- `friendly_district_names` will make a legibile vector of unique
  district names, one per district_id.
- `district_name_to_id` reverses it, giving ids from names.

## njschooldata 0.7.3

### New features

- can calculate aggregates of all public school options in a given city
  with
  [`allpublic_enr_aggs()`](https://almartin82.github.io/njschooldata/reference/allpublic_enr_aggs.md).

## njschooldata 0.7.2

### New features

- older (largely closed) charter schools added to `charter_city` table
  to allow for accurate calculations of longitudinal charter sector
  statistics.

## njschooldata 0.7.1

### New features

- can calculate charter sector (eg, charters in Jersey City) enrollment
  stats using
  [`charter_sector_enr_aggs()`](https://almartin82.github.io/njschooldata/reference/charter_sector_enr_aggs.md)

## njschooldata 0.7.0

### New features

- can pass `tidy = TRUE` argument to
  [`fetch_enr()`](https://almartin82.github.io/njschooldata/reference/fetch_enr.md)
  to get subgroups tidied
- fetch enr aggregates gender subgroups into racial subgroups (white_m +
  white_f = white)

## njschooldata 0.6.1

### New features

- ability to standardize / clean / label Taxpayers Guide data with
  [`tidy_tges_data()`](https://almartin82.github.io/njschooldata/reference/tidy_tges_data.md)

## njschooldata 0.6

### New features

- ability to read in Taxpayers Guide to Educational Spending data files
  with `get_raw_tges(2016)` and `fetch_tges(2017)`

## njschooldata 0.5.2

### New features

- ability to read in Federal ESSA (Every Student Succeeds Act)
  accountability data files with `get_essa_file(2017)`.

## njschooldata 0.5.1

### New features

- extensions of NJ School Report Card functions with
  [`extract_rc_college_matric()`](https://almartin82.github.io/njschooldata/reference/extract_rc_college_matric.md)
  and
  [`extract_rc_AP()`](https://almartin82.github.io/njschooldata/reference/extract_rc_AP.md).
- ability to put county/district/school names onto longitudinal report
  card data sets.

## njschooldata 0.5

### New features

- support for for PARCC data via the
  [`fetch_parcc()`](https://almartin82.github.io/njschooldata/reference/fetch_parcc.md)
  family of functions.
- support for NJ School Report Card / Performance Report data via the
  [`get_rc_databases()`](https://almartin82.github.io/njschooldata/reference/get_rc_databases.md)
  function
- ability to read longitudinal NJ Report Card SAT data via
  `extract_pr_SAT()`

## njschooldata 0.4

### New features

- support for HS graduation data via the `fetch_grate()` family of
  functions

## njschooldata 0.3

### New features

- a `tidy = TRUE` argument to `fetch_nj_assess` that converts the wide
  data files to long, enabling easier longitudinal analysis

### Bug fixes

- resolved various file layout errors and problems (that were silently
  dropping data when fixed-width files were read in!)

## njschooldata 0.2

### New features

- support for enrollment data

## njschooldata 0.1

### New features

- support for NJASK and other assessment data
