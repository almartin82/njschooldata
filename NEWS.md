# njschooldata 0.9.26

## NJGPA and Science subgroup fix (district grain unlocked)

* `process_parcc()` now maps the NJGPA and Science file columns so `subgroup`
  carries the actual student group ("All Students", "White", ...) and
  `subgroup_type` carries the category ("Total", "Race/Ethnicity", ...),
  matching the ELA/Math files. Previously the two were reversed for these
  assessments, so every district and school row surfaced with category labels
  in `subgroup` and subgroup-keyed consumers (e.g. filtering to
  `"total_population"`) silently found nothing. NJGPA district-level results
  (2022+) are now fully usable.
* `tidy_parcc_subgroup()` learned the 2024-25 label set: "Black or African
  American" (mapped before the shorter "African American" so it can't be
  mangled), "Multilingual Learners" / "Current - Ml" / "Former - Ml" (same
  tokens as the ELL-era labels), and "Non-Binary/Undesignated".

## Fetch fixes

* `fetch_njgpa(2022, ...)` works again: the first (2021-22) administration is
  posted under the spring results directory, not the njgpa directory used by
  2023+.
* `fetch_parcc(2019, "GEO", "math")` works again: the lone 2018-19 NJSLA
  geometry file is named plain "GEO" upstream (ALG01/ALG02 keep their zeros
  that year).
* `fetch_math_course_enrollment()` now normalizes the 2024-25 "Grade 08" style
  labels to the bare "8" used by earlier years, filters the 2024-25 sheet to
  the requested school year, and returns course enrollment counts as numerics
  with suppression markers ("N", "n/a") as `NA` -- a masked count is missing,
  never zero.

# njschooldata 0.9.17

## Federal NCES id linkage

* `fetch_enr()` now attaches federal NCES identifiers to enrollment in BOTH
  wide and tidy output: `nces_dist` (7-digit `LEAID`) on district and school
  rows, and `nces_sch` (12-digit `NCESSCH`) on school rows. These let NJ
  districts and schools join cleanly to the national NCES universe. Identifiers
  only — all data values still come from NJ DOE.
* New exported helper `attach_nces_ids()` performs the exact CDS → NCES join
  against a bundled, identifiers-only crosswalk
  (`inst/extdata/crosswalk/nj_nces_crosswalk.csv`); unmatched/ambiguous entities
  stay `NA`, never a guessed id. Coverage is ~95% of districts and ~97% of
  schools (CCD 2024 + NJ DOE directory vintage).
* New re-runnable build script `data-raw/build_nces_crosswalk.R` regenerates the
  crosswalk and cross-validates every LEAID against the CCD 2024 NJ universe.

## Documentation

* `?fetch_msgp` / `?get_and_process_msgp` now document that district-level
  rows (`is_district == TRUE`) are only produced for `end_year >= 2016`,
  and that NJ DOE never published district mSGP in the public Performance
  Report database for 2012-2015. The pre-2016 `sgp` sheet contains only
  school-level rows (confirmed by inspecting the 2011-12 through 2014-15
  workbooks and the 2014-15 layout doc); district mSGP summaries from
  that era were distributed confidentially through NJ SMART / NJDOE
  Homeroom under TEACHNJ / AchieveNJ and require per-district credentials.
  The roxygen also corrects the stale "valid values are currently 2012-2018"
  upper bound to 2012-2019. Closes #114.

# njschooldata 0.9.15

## Bug fixes

* `get_one_rc_database()` / `fetch_msgp()` / `get_and_process_msgp()` now
  resolve again for end_years 2012-2019. NJ DOE retired the
  `rc.doe.state.nj.us` host (now 301-redirects to `nj.gov/education/spr/`)
  and removed the `/education/schoolperformance/archive/` tree, so every
  Performance Report database URL hardcoded in `R/report_card.R` had been
  returning 404 with no replacement on the public site. The bulk PR
  databases now live in two places:

  - 2011-12 through 2014-15 (legacy single-workbook era):
    `nj.gov/education/spr/download/archive/<YYYYYY>/<file>` -- same
    filenames as the old tree, just a different host path.
  - 2015-16 through 2018-19 (split school/district workbooks):
    `nj.gov/education/sprreports/download/DataFiles/<YYYY-YYYY>/`, with
    `PerformanceReports.xlsx` renamed to `Database_SchoolDetail.xlsx`
    and `DistrictPerformanceReports.xlsx` renamed to
    `Database_DistrictStateDetail.xlsx`. 2015-16 has no separate
    district workbook; the school workbook carries
    `SchoolMedian`/`DistrictMedian`/`StatewideMedian` columns, which is
    what `get_and_process_msgp(2016)` already expects.

  `njdoe_base_urls$performance` in `R/config_urls.R` is updated for the
  same reason. The dead URL pattern in `R/report_card.R:71-75,171-176`
  was confirmed 404 across all 11 entries; the new pattern was
  discovered by reading `nj.gov/education/spr/download/script/download.js`
  (the SPR Download page builds its file list dynamically) and verified
  with end-to-end fetches for 2012, 2014, 2016, and 2017.

* `tests/testthat/test_msgp.R` now includes `is_charter` in the expected
  column list for sgp 2016/2017/2018/2019. The `is_charter` flag was
  added to `get_and_process_msgp()` output in commit `8eb714c8` but the
  column-name assertions in the test were never updated, so all four
  `sgp works with <year> data` tests had been failing on master with a
  spurious "expected[8:10]" mismatch unrelated to the URL fix.

# njschooldata 0.9.14

## Bug fixes

* `tidy_nj_assess()` now emits a single canonical value for the
  `school_code` column on district-aggregate rows in NJASK / HSPA / GEPA
  output (issue #26). The raw NJ DOE fixed-width files encode
  district-aggregate rows with either a whitespace-only `School_Code`
  field or the literal sentinel `"000"`, depending on year and layout
  revision. Before this fix, both encodings could appear in the same
  tidy output, so `filter(school_code == "000")` and
  `filter(is.na(school_code))` silently disagreed about which rows were
  district aggregates. After this fix, both encodings collapse to
  `NA_character_`, matching the convention `process_parcc()` already
  uses for PARCC tidy output. `is.na(school_code)` is now the single
  correct test for "not a school" across the cross-format pipeline.

# njschooldata 0.9.13

## New features

* `fetch_sped_placement()` now covers end_years 2020-2024 in addition to
  the 2025 path that shipped in v0.9.12 (PR #278). NJ DOE changed
  publication conventions multiple times across this range -- 2020/2021
  ship as annual `.zip` archives bundling 8+ subgroup-specific workbooks
  each, 2022-2024 publish those workbooks loose under three distinct
  `docs/{year}*/` directory conventions, and 2025 consolidates everything
  into one workbook. The fetcher transparently downloads, extracts (for
  zip years), and parses every variant into the same tidy schema that
  shipped in v1.
* The public API and the tidy output schema are unchanged: a 2024 call
  returns the same columns as a 2025 call, so any downstream code written
  against the v1 schema keeps working as soon as it bumps the year range.
  Pre-2025 district 5-21 workbooks publish counts only (no percent
  column), so `percent` is `NA` in those rows and `subgroup_total` is
  derived from the visible-count sum.
* Every `(end_year, age_group, level)` combination across 2020-2025 now
  returns data. The pre-2025 state-level slices that NJ DOE published
  only as PDFs (state 5-21 for end_years 2020-2022 and state 3-5 for
  end_years 2020-2022 -- six slices total) ship as bundled CSVs
  transcribed from those PDFs, alongside per-slice `_source.json` audit
  trails that record the source URL, PDF SHA-256, transcription
  timestamp, and notes on any data anomalies in the published PDFs
  (misaligned percent tables, copy-paste errors, etc.). Bundled CSVs
  live under
  `inst/extdata/sped-placement-pdf-transcribed/`.
* The 2023 state 5-21 placement file
  (`StateWide_PlacemnetData_5-21Age_2223_nonpublic.xlsx`, with NJ DOE's
  "Placemnet" typo preserved) is now wired into the file map; the
  pre-2025 state parser was extended to handle the slightly different
  section-header layout that file uses (`Measure` in column 1 instead
  of a separate `Race` label row).
* `fetch_sped_placement_multi(2020:2025)` returns one bound tibble
  covering the whole range. Per-year network failures still surface as
  warnings and skip the affected year, but no slice is short-circuited
  any more.
* On-disk cache extended with a `file_label` so per-subgroup workbooks
  cache to distinct paths under
  `tools::R_user_dir("njschooldata", "cache")/sped-placement/`. Pre-2025
  years are static snapshots, so subsequent calls are free.

# njschooldata 0.9.12

## New features

* `fetch_sped_placement()` exposes the NJ DOE IDEA Section 618 "Student
  Count and Educational Environment" workbook -- the placement / Least
  Restrictive Environment dataset that complements the existing
  `fetch_sped()` classification-rate fetcher. Returns counts and percents
  of students with disabilities by educational setting (eg "In General
  Education for 80% or More of the Day", "Separate School", "Residential
  Facility"), at the district (school-age and preschool) and state
  levels. The state output ships five marginal breakdowns (by age, by
  disability category, by race/ethnicity, by gender, and by multilingual-
  learner status). Tidy output uses the standard `county_id` /
  `district_id` naming, snake_case subgroup labels (`total`, `black`,
  `hispanic`, `lep`, ...), and the cross-state entity flags
  (`is_state`, `is_district`, `is_charter`). The large workbook (~3 MB,
  10 sheets) is cached on disk via the same mechanism as the SPR
  workbooks (`spr_cached_workbook()`), so the second call in any session
  is effectively free. Currently supports SY2024-25 only -- earlier
  years are published on nj.gov but spread across a dozen subgroup-
  specific files (and some are PDF-only); pre-2020 requires an OPRA
  request. (Closes #46.)
* `fetch_sped_placement_multi()` is a multi-year convenience wrapper
  that calls `fetch_sped_placement()` per year and binds the results,
  warning on (but not failing for) unsupported years -- so downstream
  multi-year code keeps working as more years come online.

# njschooldata 0.9.11

## New features

* `fetch_police_notifications_detail()` and `fetch_arrests()` expose the SPR
  StudentGroup x Grade detail sheets that report police-notification and
  arrest counts by student subgroup (race, gender, ED, SwD) and by grade
  level. Both first appear in SY2023-24 (end_year 2024) under legacy aliases
  (`PoliceNotificationByStuGroup`, `StuArrestbyStudentGroupGradelev`) and
  carry through to SY2024-25 (end_year 2025) under the redesigned names
  (`PoliceNotificationsGroupGrade`, `ArrestsStudentGroupGrade`). Each row
  preserves the raw `student_group_grade` label and adds normalized
  `subgroup` + `grade_level` columns ("PK", "K", "01"-"12", or "TOTAL" for
  subgroup marginals) so downstream code can filter on the two dimensions
  independently. The 2024-25 `ArrestsStudentGroupGrade` sheet ships with
  column headers mistakenly copy-pasted from the Police Notifications detail
  sheet (`Police_Count` etc.); `fetch_arrests()` renames those to the
  canonical `arrested_*` prefix used by the 2024 sheet, so the public API is
  consistent across years. Fully closes #191.
* `calc_discipline_rates_by_subgroup()` gains a `by_grade = FALSE` argument.
  When `TRUE` and the input carries a `grade_level` column,
  `grade_level` is added to the per-entity grouping keys so discipline rates
  and risk ratios are computed within each (entity x grade) cell. Default
  `FALSE` preserves the existing per-subgroup behavior. Pairs naturally with
  the new Group/Grade detail fetchers for disproportionality analysis.

## Bug fixes

* `common_fwf_req()` (the workhorse fixed-width parser behind `fetch_njask()`,
  `fetch_hspa()`, `fetch_gepa()`, and `fetch_old_nj_assess()`) no longer
  fails with `"Overlapping specification not supported"` on the legacy
  NJASK/HSPA/GEPA layouts. Every layout encodes the composite county-
  district-school identifier (positions 1-9) alongside its decomposed parts
  (`County_Code` 1-2, `District_Code` 3-6, `School_Code` 7-9), and several
  also carry a `RECORD_KEY` (1-9). The parser now detects these redundant
  composites, drops them before calling `readr::fwf_positions()`, and
  reconstructs them post-parse by concatenating the component parts. The
  on-disk layout metadata is untouched, so it remains a faithful description
  of the upstream NJ DOE file format. (#47, #53)

## Improvements

* `tidy_nj_assess()` (used by `fetch_old_nj_assess(tidy = TRUE)` for
  NJASK/HSPA/GEPA) now emits the same seven entity-selector flag columns
  as tidy PARCC/NJSLA output: `is_state`, `is_dfg`, `is_district`,
  `is_school`, `is_charter`, `is_charter_sector`, `is_allpublic`. Cross-format
  code that already does `filter(is_district)` / `filter(is_state)` on PARCC
  results now works identically on legacy assessment data. Closes #96.

## Documentation

* New vignette, "The Head First Analyst's Guide to NJ TGES" (also in
  `dev-docs/tges-analyst-guide.md`). Ten common analytical traps in the
  Taxpayers' Guide to Education Spending and how to avoid them: the three
  different "per pupil" numbers, the resident-vs-sent-pupil denominator that
  breaks cross-district subtraction, county special-services outliers, nominal
  vs real dollars, actuals vs budgeted years, within-peer-group ranks, the ESSER
  cliff inside Total Spending, why state aid does not predict spending, the
  guide-year vs `end_year` mismatch, and average-row / district-code hygiene.
  Each points at the relevant analysis helper.

# njschooldata 0.9.10

## New features

* `fetch_state_aid()` and `fetch_many_state_aid()` pull the NJ DOE Office of
  School Finance K-12 State Aid "District Details" workbook: per-district aid by
  category (equalization, educational adequacy, school choice, transportation,
  special education, security, adjustment, vocational expansion stabilization,
  military impact) plus the year totals. Output is long/tidy, one row per district
  per category, with `is_aid_category` distinguishing the categories from the
  totals/difference columns. This is the state-aid (revenue subsidy) counterpart
  to the spending data in `fetch_tges()`.
  - Category names are normalized across years, so the label drift in the source
    ("Choice Aid" vs "School Choice Aid"; "Special Education Categorical Aid" vs
    "Special Education Aid") collapses to one cross-year name.
  - The fetcher tries the current-year direct workbook URL first, then falls back
    to the archived per-year zip bundle and locates the district-details member
    by name (which also drifts across years). Valid years are 2019 and later.
  - Note: `transportation_aid` is a formula subsidy, not transportation cost, and
    runs well below a district's actual spending; see the TGES dev-doc.

# njschooldata 0.9.9

## New features

* Total Spending Detail is now parsed. The `Detail_FY##.xlsx` workbooks that ship
  inside the 2024+ TGES bundles were passing through un-tidied (their real header
  sits on row 3 under a description banner). `get_raw_tges()` now skips the banner
  and `tidy_total_spending_detail()` cleans them into six per-pupil component
  columns (general current expense, capital outlay, grants & entitlements, food
  service, locally-issued debt service, SDA debt service) that sum to the
  published total. Tables surface as `DETAIL_FY24` / `DETAIL_FY23` in
  `fetch_tges()` output.
* `tges_excluded_costs()` joins Total Spending Detail to CSG1 to expose, per
  district-year, everything the budgetary per-pupil figure leaves out, including
  the state-paid on-behalf TPAF pension. It returns the six components plus two
  differences: `excluded_total_pp` (total spending minus budgetary, the full
  wedge) and `gce_excess_pp` (general current expense minus budgetary, roughly
  transportation + on-behalf TPAF + tuition + judgments). Because budgetary cost
  divides by resident enrollment while the Detail figures divide by enrollment
  plus sent pupils, the helper carries `sent_pupil_share` and a `residual_reliable`
  flag so sending districts (where the per-pupil subtraction breaks down) are
  marked. Neither difference isolates pension on its own; no public TGES file
  breaks out the on-behalf TPAF line.

# njschooldata 0.9.8

## Bug fixes

* The Taxpayers' Guide to Educational Spending (TGES) fetchers work again. NJ DOE
  retired the old `state.nj.us/education/guide/{year}/` URLs (every one now
  returns a 404) and moved the files under `nj.gov/education/guide/docs/`.
  `fetch_tges()` and `get_raw_tges()` build the current URLs and cover 2001-2025,
  adding 2020-2025 (including the 2024/2025 per-year bundle layout). 1999 and 2000
  are dropped because NJ links them but the downloads 404 at the source.

## Other TGES parsing fixes (surfaced while restoring the fetcher)

* District ranks no longer vanish. From 2019 on, ranks ship as "rank|out_of"
  (e.g. "33|57") and were being coerced to all-NA; they are now parsed to the
  integer rank via `parse_rank()`.
* Personnel tables (CSG16-19) no longer emit duplicate columns. The year mask
  mis-split the modern 4-digit codes (`strat0016`/`strat0116`) and CSG19's
  `farat01`/`farat02` suffixes.
* Budget tables (CSG3/7/9/11) keep both percentage columns distinct (cost as a
  share of total budget vs. of salaries) instead of collapsing them into one.
* CSG14 (employee benefits as a share of salaries) reshapes over its full 3-year
  window instead of being squeezed into a 2-year personnel layout.
* `tidy_vitstat()` returns spending, revenue mix, and ratios as numbers rather
  than character.
* Missing-data markers ("N.R." Not Reported, "N.A." Not Applicable) coerce
  cleanly to NA without warnings.

## New features

* A comparative fiscal-analysis toolkit in `R/tges_analysis.R` points the
  peer-benchmarking engine (built for outcomes) at dollars. Three core functions:
  - `tges_composition()` reshapes the per-category indicators into one row per
    district-year with each category as a per-pupil dollar plus its share of
    budgetary per-pupil cost.
  - `tges_percentile_rank()` ranks any TGES metric within a peer group
    (TGES enrollment band, DFG, county, or statewide).
  - `tges_efficiency()` joins per-pupil spend to a caller-supplied outcome
    percentile and labels the spend-vs-outcome quadrant.
* Six comparative helpers on top of those:
  - `tges_revenue_mix()` decomposes VITSTAT into revenue shares and per-pupil
    dollar attribution (local property tax vs. state aid vs. federal).
  - `tges_fund_balance_health()` joins CSG20/CSG21 and flags structural deficit
    (declining actual balance) and excess surplus over the statutory cap.
  - `tges_federal_exposure()` screens the ESSER cliff off the federal revenue
    share: pre-pandemic baseline vs. ESSER-window peak, flagged when per-pupil
    spending grew during the surge.
  - `tges_staffing()` reshapes CSG16-19 and CSG14 into a negotiation dashboard
    (student/teacher, student/administrator, faculty/administrator ratios, median
    salaries, and benefits as a share of salaries).
  - `tges_red_flags()` loops the rank wrapper across every major indicator and
    surfaces a district's top/bottom-decile placements within its peers.
  - `tges_real_growth()` decomposes per-pupil spending growth into a real-cost
    component and an enrollment (denominator) component that sum to the total,
    with optional caller-supplied price deflator for real-terms growth.
* A cross-district comparative layer that reasons across districts (and over
  time) rather than one rank at a time:
  - `tges_find_peers()` builds a data-driven peer set by scaled Euclidean
    distance over enrollment, per-pupil cost, composition, and revenue mix, and
    feeds the new `peer = "custom"` mode of `tges_percentile_rank()`.
  - `tges_frontier()` scores each district against the free-disposal-hull
    spend-versus-outcome efficiency frontier (0-1) and names the district that
    reaches at least its outcome for less money (no solver dependency).
  - `tges_convergence()` regresses spending growth on starting level within a
    peer group to test beta-convergence (are the gaps closing or widening?).
  - `tges_composition_drift()` measures how each spending share moved between
    two years and ranks the move against peers.
  - `tges_gap_cost()` translates a peer gap (e.g. classroom share vs. the DFG A
    median) into per-pupil and district-wide dollars.
  - `tges_volatility()` measures year-to-year funding volatility (coefficient of
    variation plus typical/worst swing) and ranks it within the peer group.
  - `tges_compare()` assembles a side-by-side fiscal scorecard for a named set
    of districts (the counterfactual-cities table).

## Articles

* New "Following the Money" spending deep-dives built entirely on `fetch_tges()`:
  South Orange-Maplewood (a property-tax suburb) and Newark (an *Abbott* district
  where state aid funds ~80% of the budget). Each traces 25 years of per-pupil
  spending, revenue mix, benefits, facilities, and the classroom dollar; the
  Newark article also compares the district to its largest charter networks.
* "What Did Newark's Gains Cost? A DFG A Fiscal Brief" applies the comparative
  toolkit to benchmark Newark against its 37 highest-need DFG A peers on revenue
  mix, classroom share, real vs. enrollment-driven cost growth, ESSER exposure,
  staffing, and a one-page red-flag scan.
* "Newark on the Efficiency Frontier: Do the Dollars Pay Off?" works the new
  cross-district layer end to end: data-driven peers, the spend-versus-graduation
  efficiency frontier, the dollar cost of closing the classroom-share gap, DFG A
  spending convergence, composition drift, federal-funding volatility, and a
  five-city scorecard.

## Tests

* Added a comprehensive TGES test suite: unit tests for the URL builder and rank
  parser plus live ground-truth and round-trip fidelity tests that pin real
  district values and verify the wide-to-long reshape neither invents nor drops
  rows across the full 2001-2025 range.
* The comparative toolkit is covered by `test-tges-analysis.R` (synthetic-fixture
  unit tests for the reshape/rank/join/decomposition math plus live integration).
  The cross-district layer adds 34 more cases that pin the free-disposal-hull
  scores and references, convergence/divergence signs, signed composition drift,
  the share-to-dollars gap math, volatility ranking, and the scorecard assembly,
  with live checks against the 2024 guide and DFG A graduation outcomes.

# njschooldata 0.9.7

## New features

* New School Performance Report (SPR) fetchers for the redesigned 2024-25
  databases:
  - ESSA accountability: `fetch_spr_essa_targets()` (six long-term-goal
    indicators), `fetch_spr_accountability_summative()`, `fetch_spr_tsi()`,
    `fetch_spr_essa_status_counts()`, and a fixed district-level
    `fetch_essa_status()`.
  - Graduation, language, and assessment: `fetch_spr_grad_pathways()`,
    `fetch_spr_home_language()`, `fetch_spr_naep()`.
  - Staff: `fetch_spr_admin_experience()`, `fetch_spr_staff_counts()`,
    `fetch_spr_staff_demo_subject()`, `fetch_spr_staff_education()`,
    `fetch_spr_staff_retention()`, `fetch_spr_teacher_exp_subject()`,
    `fetch_spr_educator_equity()`.

* Historical coverage: the 2024-25 SPR fetchers were extended backward to the
  earliest year each source sheet exists with a structure that maps to the
  redesigned shape without fabrication (e.g. `fetch_spr_home_language()` and
  `fetch_spr_staff_education()` to 2018, `fetch_spr_naep()` to 2017,
  `fetch_spr_grad_pathways()` across 2018-2022 and 2024). Years where the
  underlying sheet is absent or reports a different measure error with an
  explanatory message rather than guessing a mapping.

* `fetch_sgp()` (median Student Growth Percentiles) now supports pre-2025 years:
  `type = "by_grade"` and `type = "trends"` back to 2018, and
  `type = "by_performance_level"` to 2023. SY2019-20 through SY2021-22 remain
  unavailable (NJ produced no SGP during the COVID assessment pause), and the
  pre-2020 by-performance-level sheet (a growth-band percentage distribution,
  not a median SGP) stays gated. Pre-2025 `trends` rows preserve the legacy
  `MetTarget` flag in new `ela_met_target` / `math_met_target` columns.

## Performance

* SPR Excel workbooks are now cached on disk (per year + level), so a workbook
  is downloaded from NJ DOE at most once and reused across sheet reads and
  across sessions -- reading a second sheet from the 2024-25 District file drops
  from ~12s to ~0.1s. New helpers: `njsd_workbook_cache_dir()`,
  `njsd_workbook_cache_info()`, `njsd_workbook_cache_clear()`. Relocate the
  cache with `options(njschooldata.cache_dir =)` or disable it with
  `options(njschooldata.workbook_cache = FALSE)`. Downloads are validated as
  real `.xlsx` files (ZIP signature) before caching, so an HTTP error or
  bot-protection page is never cached or parsed as data.

# njschooldata 0.9.6

## Infrastructure

* Live geocoding in `enrich_school_latlong(use_cache = FALSE)` now uses the
  CRAN package `tidygeocoder` instead of the GitHub-only, CRAN-archived
  `placement` package. The new path cascades through the keyless US Census
  geocoder and OpenStreetMap (Nominatim), with an optional Google pass when an
  `api_key` is supplied. This removes the `Remotes: DerekYves/placement` entry
  from `DESCRIPTION`, so dependency resolution no longer touches a GitHub remote
  (which had been intermittently failing CI with "Bad GitHub credentials").
  The default cached path (`use_cache = TRUE`, the bundled `geocoded_cached`
  dataset, itself built with tidygeocoder) is unchanged.

# njschooldata 0.9.5

## Bug fixes

* `fetch_disciplinary_removals()` now requests the correct discipline-removals
  sheet for every supported year. The sheet has been renamed several times in
  the NJ DOE Database_SchoolDetail workbooks: `DisciplinaryRemovals` for
  end_years 2018-2023, `DisciplinaryRemovalsByStudgroup` for end_year 2024, and
  `RemovalsStudentGroupGrade` for end_year 2025+. Previously the function asked
  for `DisciplinaryRemovalsByStudgroup` for all of 2017-2024, so it returned no
  data for 2018-2023 (the sheet does not exist in those years). SY2016-17
  (end_year 2017) has no discipline-removals sheet at all.

## Test fixes

* SPR tests: corrected the stale year-range assertions to expect
  "SPR data available for years 2017-2025" and to treat end_year 2026 (not
  2025) as out of range, since 2025 is now valid.
* SPR tests: `list_spr_sheets()` returns a plain character vector, so the
  `list_spr_sheets` tests now use `expect_type(x, "character")` instead of the
  incorrect `expect_s3_class(x, "character")` (a character vector has no S3
  class, so the old assertion always failed when run online).
* SPR tests: replaced the misspelled, nonexistent `"GraduatonRateTrendsProgress"`
  sheet with the confirmed `"GraduationRateTrendsProgress"` sheet from the
  2023-24 workbook.
* Fixed a self-comparison in `track_essa_progress_over_time()`: the school_id
  filter used `dplyr::filter(school_id == school_id)`, which data-masked both
  sides to the column and ignored the argument. It now uses `.env$school_id`,
  and a new offline unit test covers both the filtered and unfiltered paths.
* Hardened the SPR test suite with `skip_on_cran()` + `skip_if_offline()` guards
  on every networked block so the suite degrades gracefully offline.


# njschooldata 0.9.4

## New features

* New `fetch_sgp()` fetches NJ Student Growth Percentile (median SGP / mSGP)
  data from the redesigned 2024-25 SPR databases. Three `type` options map to
  the three source sheets: `"trends"` (`StudentGrowthTrends`, median SGP by
  student group for ELA and Math, with statewide comparison columns),
  `"by_grade"` (`StudentGrowthbyGrade`, by subject and grade), and
  `"by_performance_level"` (`StudentGrowthByPerformLevel`, by subject and prior
  NJSLA performance level). The entity median is normalized to a level-agnostic
  `*_median_sgp` column (school value at `level = "school"`, district value at
  `level = "district"`), and suppressed cells ("Fewer than 10 testers") are
  mapped to `NA` with the reason retained in the companion `*_category` column.
  Only `end_year = 2025` is supported for now; pre-2025 SPR databases store SGP
  in differently-shaped, differently-named sheets, which is a documented
  follow-up.

## Bug fixes

* `fetch_essa_status(end_year, level = "district")` works for SY2024-25
  (`end_year = 2025`). The 2024-25 redesign removed the
  `ESSAAccountabilityStatus` sheet from the District/State workbook and replaced
  it with `ESSAAccountabilityStatusList` (per-entity status, the structural
  analogue of the legacy sheet) and `ESSAAccountabilityStatusCounts` (aggregate
  CSI/ATSI/TSI tallies). District-level 2025+ requests now map to
  `ESSAAccountabilityStatusList`. School-level requests continue to use
  `ESSAAccountabilityStatus` for all years, and pre-2025 behavior is unchanged.


# njschooldata 0.9.3

## New features

* School Performance Reports (SPR) fetchers now support SY2024-25 (`end_year`
  2025). NJ DOE heavily restructured the 2024-25 SPR workbooks: the column
  header row moved from row 1 to row 4, ~10 source sheets were renamed, and many
  value columns gained `_School`/`_State` suffixes. `get_spr_url()` accepts
  2017-2025, and `fetch_spr_data()` skips the three preamble rows for 2025+.
* Sheet renames are handled per source for 2025 while keeping 2017-2024
  behavior intact: chronic absenteeism (`ChronicAbsenteeismStudentGroup`),
  chronic absenteeism by grade (`ChronicAbsenteeismGrade`),
  violence/vandalism/HIB (`IncidentsbyType`), SAT/ACT/PSAT participation
  (`PSATSATACT_Participation`), SAT/ACT/PSAT performance (joined from
  `PSATSATACT_AverageScore` + `PSATSATACT_Benchmark`), CTE
  (`CTEParticipants_*` columns), industry credentials
  (`IndustryValuedCredClusters`), work-based learning (`WorkBasedLearning`),
  social studies (`SocStudiesCoursePart`), world languages
  (`WorldLanguagesCoursePart`), computer science (`CompSciITCoursePart`),
  visual/performing arts (`VisualPerformingArts`), seal of biliteracy
  (`SealofBiliteracy_Language`), and ESSA progress (`ESSAAccountabilityTrends`).
* SAT participation and SAT performance 2025 sheets are now multi-year trend
  tables; the fetchers filter to the requested academic year via the new
  internal `filter_spr_to_year()` helper so the output keeps its historical
  single-year, one-row-per-school shape.
* `clean_spr_subgroups()` maps the new 2024-25 "All Students" total label to
  `total population`, and the SPR statewide aggregate row (CDS code
  `State`/`State`) is now correctly flagged with `is_state`.
* Assessment fetchers (`fetch_parcc()`/NJSLA, `fetch_njgpa()`, `fetch_access()`,
  plus `fetch_all_parcc()`/`fetch_all_njgpa()`/`fetch_all_access()`) now cover
  SY2024-25 (`end_year = 2025`). NJ DOE reverted to the 2019-era space-encoded
  filenames for 2025 (e.g. `ELA03%20NJSLA%20DATA%202024-25.xlsx`); the URL
  builders now use spaces for 2019 and 2025+ and underscores for 2022-2024.
  `PARCC_VALID_YEARS` extends to 2025. Schemas are unchanged from 2024.
* Extend the 4-year and 6-year graduation fetchers to SY2024-25 (end_year
  2025). `fetch_grad_rate(2025, "4 year")`, `fetch_grad_count(2025)`, and
  `fetch_6yr_grad_rate(2025)` (school and district) now work. NJ DOE
  restructured the SY2024-25 files: the 4-year ACGR file (`Cohort2025`)
  renamed `Graduation Rate` -> `Adjusted Cohort Graduation Rate` and
  `Cohort Count` -> `Adjusted Cohort Count`; the SPR 6-year cohort data moved
  from the `6YrGraduationCohortProfile` sheet to the combined
  `GraduationCohortProfile` sheet (filtered on `CohortType == "6-Year"`, header
  on row 4, `_School`/`_District`/`_State` column suffixes, percent-string rate
  values). Subgroup labels renamed by NJ DOE (`Total` -> `All Students`,
  `Hispanic` -> `Hispanic/Latino`) are normalized back to the package's
  standard names so cross-year filters keep working.

## Bug fixes

* `fetch_disciplinary_removals()` was broken for every year: it requested a
  sheet `"DisciplinaryRemovals"` that has never existed. It now selects the real
  sheet per year (`DisciplinaryRemovalsByStudgroup` for 2017-2024,
  `RemovalsStudentGroupGrade` for 2025) and standardizes the student-group/grade
  column to `student_group_grade`.
* `fetch_apprenticeship_data()` no longer errors on its year-column rename
  (the `dplyr::rename()` mapping was inverted, naming columns that did not
  exist); the rename is now correctly directed and skipped when the columns are
  absent.
* `fetch_spr_data()` drops the trailing `"end of worksheet"` sentinel row that
  the 2024-25 sheets append.
* `get_raw_sla()` now maps the Geometry math test code `GEO` to `GEO01`, which
  NJ DOE has used since 2022. The old `gsub("ALG", "ALG0", ...)` step left `GEO`
  unchanged, so `fetch_parcc(year, "GEO", "math")` silently 404'd for 2022-2024.
  Geometry results now fetch for all of 2022-2025.
* `fetch_6yr_grad_rate()` no longer fabricates suppressed-district rates. The
  SPR cohort profiles repeat the statewide reference rate in `State:`/`_State`
  columns on every district row, and the 2025 district path filled those onto
  ordinary districts whose own rate was blank (suppressed, fewer than 10
  students) via an unconditional `coalesce(..._District, ..._State)`. For 2024-25
  this had assigned the statewide subgroup rate to ~2,700 suppressed
  district-subgroup rows. The fallback to the `State:`/`_State` columns is now
  restricted to the statewide aggregate row, so suppressed districts stay `NA`.
* `fetch_6yr_grad_rate()` now flags the statewide aggregate row with `is_state`
  for 2017-2024 as well, and populates that row's rate. Every SPR cohort profile
  stores the literal string `"State"` in the statewide row's
  CountyCode/DistrictCode instead of the numeric `99`/`9999` codes; the
  normalization that was added for 2025 now runs for all years, and the legacy
  district path fills the statewide row's rate from the `State:` columns, so the
  statewide 6-year rate is no longer silently dropped for older years.

## Known follow-ups

* `fetch_ap_participation()` is not yet available for 2025. The 2024-25
  `AP_IB_Dual_Participation` SPR sheet is malformed at the school level (many
  rows per school with no disambiguating column), so a reliable
  one-row-per-school mapping cannot be derived without fabricating data. The
  2025 path raises an informative error; 2017-2024 are unaffected.

# njschooldata 0.9.2

## Bug fixes

* `fetch_enr()` now works end-to-end for 1999-2009. Pre-2010 NJDOE files arrive
  with combined "01-ATLANTIC" strings in the `COUNTY` / `DISTRICT` / `SCHOOL`
  columns. `clean_enr_names()` renames those to `county_name` / `district_name`
  / `school_name`, and `split_enr_cols()` is what creates the matching `*_id`
  columns by splitting on `"-"`. `process_enr()` previously called the
  `dplyr::mutate(county_id = ...)` cleanup step *before* `split_enr_cols()`,
  so every pre-2010 year errored on "object 'county_id' not found." Reordered
  so `split_enr_cols()` runs first.
* `ENR_VALID_YEARS` extended back to 1999. The earlier note that "1999 was
  removed from the NJ DOE website" turned out to be stale; the 1998-99 ZIP
  is still hosted at `/education/doedata/enr/enr99/enrollment_9899.zip` and
  parses cleanly after the fix above.

## Data notes

* The full enrollment panel is now 1999-2026 (28 years). State Hispanic
  enrollment grew every single year from 1999-2025 and posted its first
  decline (-6,318, -1.3%) in 2025-26.

# njschooldata 0.9.1

## New features

* `fetch_enr()` now supports 2026 (2025-26 fall enrollment). `ENR_VALID_YEARS`
  and the enrollment `year_ranges` extend to 2026.
* `get_raw_enr()` is resilient to NJ DOE's filename capitalization: the 2025-26
  file shipped as `Enrollment_2526.zip` (capital E) versus the historical
  lowercase `enrollment_*.zip`. The fetcher now tries both.

## Bug fixes

* Fixed `fetch_grad_rate()` for all years. In 2026 NJ DOE retired the
  `/schoolperformance/grad/` tree and moved every cohort file to
  `/spr/adddata/doc/acgrdocs/`; the old URLs began returning a 404 HTML page
  that failed to open as xlsx. All 4-year (2011-2024) and 5-year (2012-2019)
  URLs now point at the current location.
* Fixed a long-standing state-level grade-8 dropout. NJ DOE ships the label
  "Eight Grade" (sic) as a *row value* on the State worksheet; the existing
  typo fix only corrected column names, so state 8th-grade enrollment (~100k
  students) silently landed in an NA-grade row for all 2020+ years. State
  grade-8 totals now map to "08" and match the sum of district grade-8 totals.
  State and district/school totals are unchanged.

## Data notes

* 2026 K-12 enrollment fell 1.90% (state total 1.72%) from 2025 - the first
  real decline in years. Verified as genuine demographic change: cohort
  retention 2025->2026 sits in [0.975, 1.013] for every grade, PreK rose while
  K-12 fell, and the state total reproduces NJ DOE's published 1,357,450
  exactly. No definition or coverage change.

## Tests

* Extended enrollment year-coverage tests with 2026 pins and added structural
  invariants (state = sum of districts, PK + K12UG = total, state grade-8
  regression, cohort-retention believability).
* Fixed stale `test_validation.R` assertions that expected 1999 enrollment to
  be valid (1999 was removed from the NJ DOE website; the range starts at 2000).

## Documentation

* Refreshed the enrollment vignette and README to the 2020-2026 window, with all
  15 stories recomputed and the committed `figure-html` charts regenerated so the
  published site reflects 2026. Plot chunks now default to `cache = FALSE` to
  prevent stale cached figures.

# njschooldata 0.9.0

## New features

* Extended data support through 2024-2025 school year
* `fetch_enr()` supports 2024 and 2025 data
* `fetch_parcc()` supports 2024 NJSLA data
* Added GitHub Actions CI/CD workflows

## Breaking changes

* Minimum R version now 4.1.0 (was 3.5.0)

## Internal changes

* Migrated tests to testthat 3e edition
* Replaced deprecated `ensurer::ensure_that()` with base R validation
* Replaced deprecated `dplyr::summarise_each()` with `across()`
* Replaced deprecated `dplyr::rbind_all()` with `bind_rows()`
* Fixed deprecated function calls

## njschooldata 0.8.19

## New features

`get_school_directory` and `get_district_directory` updated to reflect new NJDOE pages / format.


## njschooldata 0.8.18

## New features

`fetch_enr` supports 2023 data.


## njschooldata 0.8.17

## Bugfixes
- More explicit namespace prefixes for functions
- Moved some dependencies to imports


## njschooldata 0.8.16

## New features

`get_district_directory()` and `get_school_directory()` read in metadata about schools and districts (eg, NCES ids!)


## njschooldata 0.8.15

## New features

`fetch_enr` supports 2022 data.  several bugfixes for older years.


## njschooldata 0.8.14

## New features

`lookup_peer_percentile` function to gauge where an aggregation falls in the distribution of measured/actual schools/districts. 


## njschooldata 0.8.13

## New features

* postsecondary matriculation aggregations - `district_matric_aggs` and `allpublic_matric_aggs`

* bug fixes for mSGP and for njsla/parcc assessment file location changes


## njschooldata 0.8.12

## New features

* `K12UG` aggregate published - K12 w/ ungraded students.


## njschooldata 0.8.11

## New features

* `ward_grate_aggs()` and `ward_gcount_aggs()` calculate grad rate and grad count for supported ward geographies


## njschooldata 0.8.10

## New features

* `charter_sector_spec_pop_aggs()` and `allpublic_spec_pop_aggs()` calculate sector wide special population aggregations
* `charter_sector_sped_aggs()` and `allpublic_sped_aggs()` calculate sector-wide SPED aggregations
* `extract_rc_enrollment()` extracts and cleans spring enrollment data from report card databases
* `fetch_enr` now also returns the count and percentage of free *or* reduced lunch students

## njschooldata 0.8.9

## New features

* `ward_parcc_aggs()` aggregates PARCC data for city ward / neighborhood geographies (currently supported: Newark)


## njschooldata 0.8.8

## New features

* `fetch_grad_rate()` and `fetch_grad_count()` support 2019 data


## njschooldata 0.8.7

## New features

* `fetch_msgp()` supports 2019 data

* msgp data supports new subgroups: female, male, homeless, foster care, military-connected, migrant


## njschooldata 0.8.6

## New features

* `get_reportcard_special_pop()` supports 2019 data


## njschooldata 0.8.3

## New features

* `fetch_parcc()` supports 2019 NJSLA data


## njschooldata 0.8.2

## New features

* `enrich_school_latlong()` will add the address and latitude / longitude of a school

* `enrich_school_city_ward()` will return the relevant administrative subdivision of a school for supported cities.  Currently supported: Newark

* `enrich_school_city_neighborhood()` will return the relevant neighborhood subdivision for supported cities.  Currently supported: Newark


# njschooldata 0.8.1

## New features

* `fetch_msgp()` reads msgp data from report card files.

* `fetch_reportcard_special_pop()`


# njschooldata 0.8.0

## New features

* Method for combining school/district Report Card data.

* PARCC Percentile Rank functions are more thoroughly tested, with some errors corrected.


# njschooldata 0.7.9

## New features

* Grad Count data (`fetch_grad_count`) from 1999-present.
* Grad rate and count charter sector and all public aggregations.


# njschooldata 0.7.8

## New features

* `fetch_grate` takes a calc type argument, and will return 5 year cohort grad rates for 2012-present.



# njschooldata 0.7.7

## New features

* `statewide_peer_percentile` will calculate PARCC scale and proficiency percentile rank across NJ.
* `dfg_peer_percentile` will calculate PARCC scale and proficiency percentile rank across NJ.



# njschooldata 0.7.6

## New features

* `charter_sector_parcc_aggs` will calculate PARCC composites for city charter sectors.
* `allpublic_parcc_aggs` will calculate PARCC composites across city and charter schools.

## Breaking changes

* PARCC functions now return `_id` (ie `district_id`, `school_id`) instead of `_code`.  This closes [#65](https://github.com/almartin82/njschooldata/issues/65) and makes school/district identifiers consistent across enrollment and PARCC assessment files.

* `parcc_aggregate_calcs` expects a field called `is_charter`. 



# njschooldata 0.7.5

## New features

* `enr_grade_aggs` will calculate some common grade level aggregations.
- Any K (half + full day K)
- K-12 enrollment (exclude pre-k)
- K-8 enrollment
- HS



# njschooldata 0.7.4

## New features

* `friendly_district_names` will make a legibile vector of unique district names, one per district_id.
* `district_name_to_id` reverses it, giving ids from names.



# njschooldata 0.7.3

## New features

* can calculate aggregates of all public school options in a given city with `allpublic_enr_aggs()`.


# njschooldata 0.7.2

## New features

* older (largely closed) charter schools added to `charter_city` table to allow for accurate calculations of longitudinal charter sector statistics.



# njschooldata 0.7.1

## New features

* can calculate charter sector (eg, charters in Jersey City) enrollment stats using `charter_sector_enr_aggs()`



# njschooldata 0.7.0

## New features

* can pass `tidy = TRUE` argument to `fetch_enr()` to get subgroups tidied
* fetch enr aggregates gender subgroups into racial subgroups (white_m + white_f = white)



# njschooldata 0.6.1

## New features

* ability to standardize / clean / label Taxpayers Guide data with `tidy_tges_data()` 



# njschooldata 0.6

## New features

* ability to read in Taxpayers Guide to Educational Spending data files with `get_raw_tges(2016)` and `fetch_tges(2017)` 



# njschooldata 0.5.2

## New features

* ability to read in Federal ESSA (Every Student Succeeds Act) accountability data files with `get_essa_file(2017)`.



# njschooldata 0.5.1

## New features

* extensions of NJ School Report Card functions with `extract_rc_college_matric()` and  `extract_rc_AP()`.
* ability to put county/district/school names onto longitudinal report card data sets.



# njschooldata 0.5

## New features

* support for for PARCC data via the `fetch_parcc()` family of functions.
* support for NJ School Report Card / Performance Report data via the `get_rc_databases()` function
* ability to read longitudinal NJ Report Card SAT data via `extract_pr_SAT()`



# njschooldata 0.4

## New features

* support for HS graduation data via the `fetch_grate()` family of functions



# njschooldata 0.3

## New features

* a `tidy = TRUE` argument to `fetch_nj_assess` that converts the wide data files to long, enabling easier longitudinal analysis

## Bug fixes

* resolved various file layout errors and problems (that were silently dropping data when fixed-width files were read in!)



# njschooldata 0.2

## New features

* support for enrollment data



# njschooldata 0.1

## New features

* support for NJASK and other assessment data
