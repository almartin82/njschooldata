# Changelog

## njschooldata 0.9.8

### Bug fixes

- The Taxpayers’ Guide to Educational Spending (TGES) fetchers work
  again. NJ DOE retired the old `state.nj.us/education/guide/{year}/`
  URLs (every one now returns a 404) and moved the files under
  `nj.gov/education/guide/docs/`.
  [`fetch_tges()`](https://almartin82.github.io/njschooldata/reference/fetch_tges.md)
  and
  [`get_raw_tges()`](https://almartin82.github.io/njschooldata/reference/get_raw_tges.md)
  build the current URLs and cover 2001-2025, adding 2020-2025
  (including the 2024/2025 per-year bundle layout). 1999 and 2000 are
  dropped because NJ links them but the downloads 404 at the source.

### Other TGES parsing fixes (surfaced while restoring the fetcher)

- District ranks no longer vanish. From 2019 on, ranks ship as
  “rank\|out_of” (e.g. “33\|57”) and were being coerced to all-NA; they
  are now parsed to the integer rank via
  [`parse_rank()`](https://almartin82.github.io/njschooldata/reference/parse_rank.md).
- Personnel tables (CSG16-19) no longer emit duplicate columns. The year
  mask mis-split the modern 4-digit codes (`strat0016`/`strat0116`) and
  CSG19’s `farat01`/`farat02` suffixes.
- Budget tables (CSG3/7/9/11) keep both percentage columns distinct
  (cost as a share of total budget vs. of salaries) instead of
  collapsing them into one.
- CSG14 (employee benefits as a share of salaries) reshapes over its
  full 3-year window instead of being squeezed into a 2-year personnel
  layout.
- [`tidy_vitstat()`](https://almartin82.github.io/njschooldata/reference/tidy_vitstat.md)
  returns spending, revenue mix, and ratios as numbers rather than
  character.
- Missing-data markers (“N.R.” Not Reported, “N.A.” Not Applicable)
  coerce cleanly to NA without warnings.

### Tests

- Added a comprehensive TGES test suite: unit tests for the URL builder
  and rank parser plus live ground-truth and round-trip fidelity tests
  that pin real district values and verify the wide-to-long reshape
  neither invents nor drops rows across the full 2001-2025 range.

## njschooldata 0.9.7

### New features

- New School Performance Report (SPR) fetchers for the redesigned
  2024-25 databases:

  - ESSA accountability:
    [`fetch_spr_essa_targets()`](https://almartin82.github.io/njschooldata/reference/fetch_spr_essa_targets.md)
    (six long-term-goal indicators),
    [`fetch_spr_accountability_summative()`](https://almartin82.github.io/njschooldata/reference/fetch_spr_accountability_summative.md),
    [`fetch_spr_tsi()`](https://almartin82.github.io/njschooldata/reference/fetch_spr_tsi.md),
    [`fetch_spr_essa_status_counts()`](https://almartin82.github.io/njschooldata/reference/fetch_spr_essa_status_counts.md),
    and a fixed district-level
    [`fetch_essa_status()`](https://almartin82.github.io/njschooldata/reference/fetch_essa_status.md).
  - Graduation, language, and assessment:
    [`fetch_spr_grad_pathways()`](https://almartin82.github.io/njschooldata/reference/fetch_spr_grad_pathways.md),
    [`fetch_spr_home_language()`](https://almartin82.github.io/njschooldata/reference/fetch_spr_home_language.md),
    [`fetch_spr_naep()`](https://almartin82.github.io/njschooldata/reference/fetch_spr_naep.md).
  - Staff:
    [`fetch_spr_admin_experience()`](https://almartin82.github.io/njschooldata/reference/fetch_spr_admin_experience.md),
    [`fetch_spr_staff_counts()`](https://almartin82.github.io/njschooldata/reference/fetch_spr_staff_counts.md),
    [`fetch_spr_staff_demo_subject()`](https://almartin82.github.io/njschooldata/reference/fetch_spr_staff_demo_subject.md),
    [`fetch_spr_staff_education()`](https://almartin82.github.io/njschooldata/reference/fetch_spr_staff_education.md),
    [`fetch_spr_staff_retention()`](https://almartin82.github.io/njschooldata/reference/fetch_spr_staff_retention.md),
    [`fetch_spr_teacher_exp_subject()`](https://almartin82.github.io/njschooldata/reference/fetch_spr_teacher_exp_subject.md),
    [`fetch_spr_educator_equity()`](https://almartin82.github.io/njschooldata/reference/fetch_spr_educator_equity.md).

- Historical coverage: the 2024-25 SPR fetchers were extended backward
  to the earliest year each source sheet exists with a structure that
  maps to the redesigned shape without fabrication
  (e.g. [`fetch_spr_home_language()`](https://almartin82.github.io/njschooldata/reference/fetch_spr_home_language.md)
  and
  [`fetch_spr_staff_education()`](https://almartin82.github.io/njschooldata/reference/fetch_spr_staff_education.md)
  to 2018,
  [`fetch_spr_naep()`](https://almartin82.github.io/njschooldata/reference/fetch_spr_naep.md)
  to 2017,
  [`fetch_spr_grad_pathways()`](https://almartin82.github.io/njschooldata/reference/fetch_spr_grad_pathways.md)
  across 2018-2022 and 2024). Years where the underlying sheet is absent
  or reports a different measure error with an explanatory message
  rather than guessing a mapping.

- [`fetch_sgp()`](https://almartin82.github.io/njschooldata/reference/fetch_sgp.md)
  (median Student Growth Percentiles) now supports pre-2025 years:
  `type = "by_grade"` and `type = "trends"` back to 2018, and
  `type = "by_performance_level"` to 2023. SY2019-20 through SY2021-22
  remain unavailable (NJ produced no SGP during the COVID assessment
  pause), and the pre-2020 by-performance-level sheet (a growth-band
  percentage distribution, not a median SGP) stays gated. Pre-2025
  `trends` rows preserve the legacy `MetTarget` flag in new
  `ela_met_target` / `math_met_target` columns.

### Performance

- SPR Excel workbooks are now cached on disk (per year + level), so a
  workbook is downloaded from NJ DOE at most once and reused across
  sheet reads and across sessions – reading a second sheet from the
  2024-25 District file drops from ~12s to ~0.1s. New helpers:
  [`njsd_workbook_cache_dir()`](https://almartin82.github.io/njschooldata/reference/njsd_workbook_cache_dir.md),
  [`njsd_workbook_cache_info()`](https://almartin82.github.io/njschooldata/reference/njsd_workbook_cache_info.md),
  [`njsd_workbook_cache_clear()`](https://almartin82.github.io/njschooldata/reference/njsd_workbook_cache_clear.md).
  Relocate the cache with `options(njschooldata.cache_dir =)` or disable
  it with `options(njschooldata.workbook_cache = FALSE)`. Downloads are
  validated as real `.xlsx` files (ZIP signature) before caching, so an
  HTTP error or bot-protection page is never cached or parsed as data.

## njschooldata 0.9.6

### Infrastructure

- Live geocoding in `enrich_school_latlong(use_cache = FALSE)` now uses
  the CRAN package `tidygeocoder` instead of the GitHub-only,
  CRAN-archived `placement` package. The new path cascades through the
  keyless US Census geocoder and OpenStreetMap (Nominatim), with an
  optional Google pass when an `api_key` is supplied. This removes the
  `Remotes: DerekYves/placement` entry from `DESCRIPTION`, so dependency
  resolution no longer touches a GitHub remote (which had been
  intermittently failing CI with “Bad GitHub credentials”). The default
  cached path (`use_cache = TRUE`, the bundled `geocoded_cached`
  dataset, itself built with tidygeocoder) is unchanged.

## njschooldata 0.9.5

### Bug fixes

- [`fetch_disciplinary_removals()`](https://almartin82.github.io/njschooldata/reference/fetch_disciplinary_removals.md)
  now requests the correct discipline-removals sheet for every supported
  year. The sheet has been renamed several times in the NJ DOE
  Database_SchoolDetail workbooks: `DisciplinaryRemovals` for end_years
  2018-2023, `DisciplinaryRemovalsByStudgroup` for end_year 2024, and
  `RemovalsStudentGroupGrade` for end_year 2025+. Previously the
  function asked for `DisciplinaryRemovalsByStudgroup` for all of
  2017-2024, so it returned no data for 2018-2023 (the sheet does not
  exist in those years). SY2016-17 (end_year 2017) has no
  discipline-removals sheet at all.

### Test fixes

- SPR tests: corrected the stale year-range assertions to expect “SPR
  data available for years 2017-2025” and to treat end_year 2026 (not
  2025. as out of range, since 2025 is now valid.
- SPR tests:
  [`list_spr_sheets()`](https://almartin82.github.io/njschooldata/reference/list_spr_sheets.md)
  returns a plain character vector, so the `list_spr_sheets` tests now
  use `expect_type(x, "character")` instead of the incorrect
  `expect_s3_class(x, "character")` (a character vector has no S3 class,
  so the old assertion always failed when run online).
- SPR tests: replaced the misspelled, nonexistent
  `"GraduatonRateTrendsProgress"` sheet with the confirmed
  `"GraduationRateTrendsProgress"` sheet from the 2023-24 workbook.
- Fixed a self-comparison in
  [`track_essa_progress_over_time()`](https://almartin82.github.io/njschooldata/reference/track_essa_progress_over_time.md):
  the school_id filter used `dplyr::filter(school_id == school_id)`,
  which data-masked both sides to the column and ignored the argument.
  It now uses `.env$school_id`, and a new offline unit test covers both
  the filtered and unfiltered paths.
- Hardened the SPR test suite with `skip_on_cran()` +
  `skip_if_offline()` guards on every networked block so the suite
  degrades gracefully offline.

## njschooldata 0.9.4

### New features

- New
  [`fetch_sgp()`](https://almartin82.github.io/njschooldata/reference/fetch_sgp.md)
  fetches NJ Student Growth Percentile (median SGP / mSGP) data from the
  redesigned 2024-25 SPR databases. Three `type` options map to the
  three source sheets: `"trends"` (`StudentGrowthTrends`, median SGP by
  student group for ELA and Math, with statewide comparison columns),
  `"by_grade"` (`StudentGrowthbyGrade`, by subject and grade), and
  `"by_performance_level"` (`StudentGrowthByPerformLevel`, by subject
  and prior NJSLA performance level). The entity median is normalized to
  a level-agnostic `*_median_sgp` column (school value at
  `level = "school"`, district value at `level = "district"`), and
  suppressed cells (“Fewer than 10 testers”) are mapped to `NA` with the
  reason retained in the companion `*_category` column. Only
  `end_year = 2025` is supported for now; pre-2025 SPR databases store
  SGP in differently-shaped, differently-named sheets, which is a
  documented follow-up.

### Bug fixes

- `fetch_essa_status(end_year, level = "district")` works for SY2024-25
  (`end_year = 2025`). The 2024-25 redesign removed the
  `ESSAAccountabilityStatus` sheet from the District/State workbook and
  replaced it with `ESSAAccountabilityStatusList` (per-entity status,
  the structural analogue of the legacy sheet) and
  `ESSAAccountabilityStatusCounts` (aggregate CSI/ATSI/TSI tallies).
  District-level 2025+ requests now map to
  `ESSAAccountabilityStatusList`. School-level requests continue to use
  `ESSAAccountabilityStatus` for all years, and pre-2025 behavior is
  unchanged.

## njschooldata 0.9.3

### New features

- School Performance Reports (SPR) fetchers now support SY2024-25
  (`end_year` 2025). NJ DOE heavily restructured the 2024-25 SPR
  workbooks: the column header row moved from row 1 to row 4, ~10 source
  sheets were renamed, and many value columns gained `_School`/`_State`
  suffixes.
  [`get_spr_url()`](https://almartin82.github.io/njschooldata/reference/get_spr_url.md)
  accepts 2017-2025, and
  [`fetch_spr_data()`](https://almartin82.github.io/njschooldata/reference/fetch_spr_data.md)
  skips the three preamble rows for 2025+.
- Sheet renames are handled per source for 2025 while keeping 2017-2024
  behavior intact: chronic absenteeism
  (`ChronicAbsenteeismStudentGroup`), chronic absenteeism by grade
  (`ChronicAbsenteeismGrade`), violence/vandalism/HIB
  (`IncidentsbyType`), SAT/ACT/PSAT participation
  (`PSATSATACT_Participation`), SAT/ACT/PSAT performance (joined from
  `PSATSATACT_AverageScore` + `PSATSATACT_Benchmark`), CTE
  (`CTEParticipants_*` columns), industry credentials
  (`IndustryValuedCredClusters`), work-based learning
  (`WorkBasedLearning`), social studies (`SocStudiesCoursePart`), world
  languages (`WorldLanguagesCoursePart`), computer science
  (`CompSciITCoursePart`), visual/performing arts
  (`VisualPerformingArts`), seal of biliteracy
  (`SealofBiliteracy_Language`), and ESSA progress
  (`ESSAAccountabilityTrends`).
- SAT participation and SAT performance 2025 sheets are now multi-year
  trend tables; the fetchers filter to the requested academic year via
  the new internal
  [`filter_spr_to_year()`](https://almartin82.github.io/njschooldata/reference/filter_spr_to_year.md)
  helper so the output keeps its historical single-year,
  one-row-per-school shape.
- [`clean_spr_subgroups()`](https://almartin82.github.io/njschooldata/reference/clean_spr_subgroups.md)
  maps the new 2024-25 “All Students” total label to `total population`,
  and the SPR statewide aggregate row (CDS code `State`/`State`) is now
  correctly flagged with `is_state`.
- Assessment fetchers
  ([`fetch_parcc()`](https://almartin82.github.io/njschooldata/reference/fetch_parcc.md)/NJSLA,
  [`fetch_njgpa()`](https://almartin82.github.io/njschooldata/reference/fetch_njgpa.md),
  [`fetch_access()`](https://almartin82.github.io/njschooldata/reference/fetch_access.md),
  plus
  [`fetch_all_parcc()`](https://almartin82.github.io/njschooldata/reference/fetch_all_parcc.md)/[`fetch_all_njgpa()`](https://almartin82.github.io/njschooldata/reference/fetch_all_njgpa.md)/[`fetch_all_access()`](https://almartin82.github.io/njschooldata/reference/fetch_all_access.md))
  now cover SY2024-25 (`end_year = 2025`). NJ DOE reverted to the
  2019-era space-encoded filenames for 2025
  (e.g. `ELA03%20NJSLA%20DATA%202024-25.xlsx`); the URL builders now use
  spaces for 2019 and 2025+ and underscores for 2022-2024.
  `PARCC_VALID_YEARS` extends to 2025. Schemas are unchanged from 2024.
- Extend the 4-year and 6-year graduation fetchers to SY2024-25
  (end_year 2025). `fetch_grad_rate(2025, "4 year")`,
  `fetch_grad_count(2025)`, and `fetch_6yr_grad_rate(2025)` (school and
  district) now work. NJ DOE restructured the SY2024-25 files: the
  4-year ACGR file (`Cohort2025`) renamed `Graduation Rate` -\>
  `Adjusted Cohort Graduation Rate` and `Cohort Count` -\>
  `Adjusted Cohort Count`; the SPR 6-year cohort data moved from the
  `6YrGraduationCohortProfile` sheet to the combined
  `GraduationCohortProfile` sheet (filtered on `CohortType == "6-Year"`,
  header on row 4, `_School`/`_District`/`_State` column suffixes,
  percent-string rate values). Subgroup labels renamed by NJ DOE
  (`Total` -\> `All Students`, `Hispanic` -\> `Hispanic/Latino`) are
  normalized back to the package’s standard names so cross-year filters
  keep working.

### Bug fixes

- [`fetch_disciplinary_removals()`](https://almartin82.github.io/njschooldata/reference/fetch_disciplinary_removals.md)
  was broken for every year: it requested a sheet
  `"DisciplinaryRemovals"` that has never existed. It now selects the
  real sheet per year (`DisciplinaryRemovalsByStudgroup` for 2017-2024,
  `RemovalsStudentGroupGrade` for 2025) and standardizes the
  student-group/grade column to `student_group_grade`.
- [`fetch_apprenticeship_data()`](https://almartin82.github.io/njschooldata/reference/fetch_apprenticeship_data.md)
  no longer errors on its year-column rename (the
  [`dplyr::rename()`](https://dplyr.tidyverse.org/reference/rename.html)
  mapping was inverted, naming columns that did not exist); the rename
  is now correctly directed and skipped when the columns are absent.
- [`fetch_spr_data()`](https://almartin82.github.io/njschooldata/reference/fetch_spr_data.md)
  drops the trailing `"end of worksheet"` sentinel row that the 2024-25
  sheets append.
- [`get_raw_sla()`](https://almartin82.github.io/njschooldata/reference/get_raw_sla.md)
  now maps the Geometry math test code `GEO` to `GEO01`, which NJ DOE
  has used since 2022. The old `gsub("ALG", "ALG0", ...)` step left
  `GEO` unchanged, so `fetch_parcc(year, "GEO", "math")` silently 404’d
  for 2022-2024. Geometry results now fetch for all of 2022-2025.
- [`fetch_6yr_grad_rate()`](https://almartin82.github.io/njschooldata/reference/fetch_6yr_grad_rate.md)
  no longer fabricates suppressed-district rates. The SPR cohort
  profiles repeat the statewide reference rate in `State:`/`_State`
  columns on every district row, and the 2025 district path filled those
  onto ordinary districts whose own rate was blank (suppressed, fewer
  than 10 students) via an unconditional
  `coalesce(..._District, ..._State)`. For 2024-25 this had assigned the
  statewide subgroup rate to ~2,700 suppressed district-subgroup rows.
  The fallback to the `State:`/`_State` columns is now restricted to the
  statewide aggregate row, so suppressed districts stay `NA`.
- [`fetch_6yr_grad_rate()`](https://almartin82.github.io/njschooldata/reference/fetch_6yr_grad_rate.md)
  now flags the statewide aggregate row with `is_state` for 2017-2024 as
  well, and populates that row’s rate. Every SPR cohort profile stores
  the literal string `"State"` in the statewide row’s
  CountyCode/DistrictCode instead of the numeric `99`/`9999` codes; the
  normalization that was added for 2025 now runs for all years, and the
  legacy district path fills the statewide row’s rate from the `State:`
  columns, so the statewide 6-year rate is no longer silently dropped
  for older years.

### Known follow-ups

- [`fetch_ap_participation()`](https://almartin82.github.io/njschooldata/reference/fetch_ap_participation.md)
  is not yet available for 2025. The 2024-25 `AP_IB_Dual_Participation`
  SPR sheet is malformed at the school level (many rows per school with
  no disambiguating column), so a reliable one-row-per-school mapping
  cannot be derived without fabricating data. The 2025 path raises an
  informative error; 2017-2024 are unaffected.

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
