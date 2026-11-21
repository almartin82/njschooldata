# Graduation and retention rate units

Checked offline on 2026-11-21. The census command
`python3 ../scripts/check-percent-scale-heuristic.py --package nj` found five
magnitude-based conversions: process_grate, both process_grad_rate branches,
and retention/turnover in analyze_retention_patterns. All five are removed.

## Graduation sources and rules

The exact 23 publisher URLs, filenames, byte lengths and SHA-256 digests are
registered in `inst/extdata/source-contract/contracts/new_jersey_release_sources/artifact-manifest.json`.
Every workbook was read locally and its bytes checked against that manifest.
The four-year parents were retained in the existing NJ source-artifacts cache;
the eight dual-cohort parents were in the shared historical-assets-v1 store.
No DOE acquisition was performed and no user cache was cleared.

* 2011: ACGR2012_gradrate.xls, Sheet1, column I, header
  `2011 Adjusted Cohort Grad Rate`. The numeric cells have Excel format
  `0.00%`: I691 (STATE TOTAL) = 0.8317 and I683 (TEAM Academy) = 0.9483.
  These are fractions, passed through unconditionally. Invalid fractions
  outside 0-1 become NA.
* 2012-2017: ACGR2012_grd.xls and ACGR2013_4Year.xlsx through
  ACGR2017_4Year.xlsx, first sheet, header FOUR_YR_GRAD_RATE.
* 2018-2019: ACGR2018_4YearGraduation.xlsx and
  ACGR2019_Cohort2019_4-YearAdjustedCohortGraduationRatesByStudentGroup.xlsx,
  first sheet after three heading rows, header Four Year Graduation Rate.
* 2020-2024: Cohort2020/2021/2022_4YearAdjustedCohortGraduationRatesandCountsbyStudentGroup.xlsx
  and Cohort2023/2024_4YearAdjustedCohortGraduationRatesbyStudentGroup.xlsx,
  first sheet after five heading rows, header Graduation Rate.
* 2025: Cohort2025_4YearAdjustedCohortGraduationRatesbyStudentGroup.xlsx,
  same layout, header Adjusted Cohort Graduation Rate.

All 2012-2025 four-year columns contain percentage points and are divided by
100 unconditionally. Counts corroborate the units independently of magnitude:
2012 first data row 97 graduates / 120 cohort = 80.83%; 2013 104/130 = 80%;
2014 93/113 = 82.30%; 2015 110/128 = 85.94%; 2016 104/119 = 87.39%;
2017 72/80 = 90%; 2018 76/85 = 89.41%; 2019 402/498 = 80.7%;
2020 45/76 = 59.2%; 2021 113/117 = 96.6%; 2022 85/91 = 93.4%;
2024 77/83 = 92.8%; 2025 407/499 = 81.6%. The 2023 table has the same
published Graduation Rate/Cohort Count/Graduated layout (the first numeric
rate row suppresses its counts, so that row is not used as ratio evidence).

The eight registered 2012-2019 dual-cohort workbooks (ACGR2013_4And5YearCohort12.xlsx
through Cohort2019_4-YearAnd5-YearAdjustedCohortGraduationRates.xlsx) likewise
publish both cohort rates in percentage points. They label adjacent columns
4-Year and 5-Year Graduation Rate (2013-2014 use FOUR_YR_GRAD_RATE and
FIVE_YR_GRAD_RATE). Their four-year values overlap the same-school four-year
parents above: Atlantic City High School, 01/0110/010, 2012 = 69.67
(471/676), for example. The five-year column uses that same table's units.
Both downstream conversion branches divide by 100; rates outside 0-100
become NA. Unregistered rate vintages stop with an unknown-scale error.
Pre-2011 legacy graduation-count files do not publish the ACGR rate columns.

Existing layout limitation: only 2013-2014 dual-cohort headers currently map
onto the downstream five_yr_grad_rate selector. The other six parents were
inspected but their missing rate mappings are outside this scale repair.
The four-year bonus-column branch now retains a column already named
five_yr_grad_rate rather than deleting its normalized result.

## Retention analysis

analyze_retention_patterns accepts arbitrary caller-supplied frames, with no
publisher identity or file vintage. No package acquisition pipeline calls it.
The function's documented percentage output and SPR fetch_spr_staff_retention's
retention_pct columns establish a percentage default contract, not the units
of arbitrary unlabelled inputs. rate_scale = "percent" preserves even 0.7;
callers with known fractions explicitly pass rate_scale = "fraction".
Unknown scale declarations stop. Out-of-range declared rates become missing.
There is no published turnover source feeding this generic analysis, so no
real-source retention/turnover activation count or shipped corruption is claimed.

## Measurement and regression evidence

On all 23 retained graduation parents, the old whole-column condition fires
only for 2011: 676 nonmissing cells (690 rows). Neither five-year branch fires
on its retained reachable columns. Across 71,063 nonmissing processed rate
cells (including the preserved four-year column in 2013-2014 dual files),
there are zero changes in missingness or published values at 1e-14 tolerance.
Avoiding the old multiply/divide round trip changes 114 binary doubles by at
most 1.110223e-16, preserving the original fractional source digits. These are
roundoff differences only. No demonstrated shipped percent-scale corruption
is claimed for NJ.

Three minimal source-row CSV donors in tests/testthat/fixtures/percent-scale
come directly from these verified workbooks: 2011 Sheet1 row 691; 2013
dual-cohort first data row; 2025 first data row after its header. end_year and
2011's missing GRADUATED_COUNT are parser annotations, not source observations.
Tests mutate those donor rates to 0.7 percentage points, 0.004 fraction, and
out-of-range values. Retention inputs are explicitly synthetic API probes.
No altered test rate is bundled as a published data observation.

The regression file is tests/testthat/test-percent-scale.R. Restoring both
original R files produced 13 failed expectations and two errors; restoring
the patch was checked with git diff --numstat. R CMD INSTALL succeeded.
Installed relevant families passed 422 assertions, with zero failures/errors,
128 skipped live blocks and eight warning blocks. The new file passed all
24 assertions without skips or warnings. The full offline suite passed 5,811
assertions, with two failures, zero errors, 754 skipped blocks and 16 warning
blocks. The test-inventory failure matches the October 9 baseline; the other
failure is an unchanged stale assertion at test-available-years-contract.R:35
expecting assessment coverage to be undeclared. The baseline does not list it.
The former transformation test's 2024 input was also corrected from fractional
0.85 to percentage 85, consistent with its own 85/100 counts.
