# Live-source test inventory

All R and Python live-source tests use one opt-in switch:

```sh
NJSCHOOLDATA_LIVE_TESTS=true
```

Without that exact value, R package checks exclude `test-live-*` files and every
mixed R test calls `skip_if_no_live_tests()` before network work. Pytest skips
every `network`-marked test. Pull-request CI leaves the flag unset.

## R: whole-file live suites

These legacy/pinned-value suites perform network work during file setup or are
entirely live contracts, so they are file-gated:

- `test-live-charter.R`
- `test-live-absence-correctness.R`
- `test-live-absence-edge-cases.R`
- `test-live-absence.R`
- `test-live-college-career-district-grain.R`
- `test-live-directory-contract.R`
- `test-live-directory.R`
- `test-live-enr.R`
- `test-live-fetch-college-career.R`
- `test-live-geo.R`
- `test-live-gepa.R`
- `test-live-grate.R`
- `test-live-hspa.R`
- `test-live-lookups.R`
- `test-live-msgp.R`
- `test-live-njask.R`
- `test-live-parcc.R`
- `test-live-parcc_years.R`
- `test-live-peer_percentile.R`
- `test-live-postsecondary-enrollment.R`
- `test-live-process_assess.R`
- `test-live-report_card.R`
- `test-live-special_pop.R`

## R: mixed offline/live suites

The following retain offline contract tests and guard only their live sections:

- `test-assessment-year-coverage.R`
- `test-ell.R`
- `test-enrollment-year-coverage.R`
- `test-facilities.R`
- `test-fetch-advanced-courses.R`
- `test-fetch-biliteracy.R`
- `test-fetch-course-enrollment.R`
- `test-fetch-police-arrests-detail.R`
- `test-fetch-police-hib.R`
- `test-fetch-restraint-seclusion.R`
- `test-fetch-school-environment.R`
- `test-fetch-sgp.R`
- `test-fetch-spr-bucket-a.R`
- `test-fetch-spr-essa.R`
- `test-fetch-spr-grad-homelang-naep.R`
- `test-fetch-spr-staff.R`
- `test-fetch-spr.R`
- `test-fetch-staff-doedata.R`
- `test-fetch-tges.R`
- `test-finance.R`
- `test-graduation-year-coverage.R`
- `test-njgpa-science-subgroups.R`
- `test-slugify.R`
- `test-sped-placement.R`
- `test-spr-workbook-cache.R`
- `test-state-aid.R`
- `test-tges-analysis.R`
- `test-tges-ground-truth.R`
- `test-tges-structure.R`
- `test-typology-guards.R`
- `test_fetch_nj_assess.R`
- `test_issue_reproductions.R`
- `test_parcc_agg_provenance.R`
- `test_percentile_rank.R`
- `test_sped.R`

The authoritative list is mechanically enforced by
`tests/testthat/test-test-inventory.R`: a test file containing an explicit
network primitive or a live fetch call must be file-gated, use the shared skip,
or be listed as an offline mock/fixture contract.

## Python live suites

Every network case is marked `@pytest.mark.network` in:

- `test_assessment.py`
- `test_directory.py`
- `test_enrollment.py`
- `test_facilities.py`
- `test_graduation.py`
- `test_passthrough.py`

Unmarked Python tests exercise imports, curated signatures, dynamic bridge
behavior, version compatibility, and result conversion without calling NJ DOE.

## Failure interpretation

The scheduled/manual canary writes `live-canary-report.json`. A
`source_unavailable` result is reported as `SOURCE_OUTAGE`; an artifact that was
retrieved but rejected or failed a parser/contract assertion is reported as
`PARSER_OR_CONTRACT_REGRESSION`. Operators should retry outages after checking
the recorded URL/status. Parser regressions require inspecting the downloaded
artifact and updating the domain parser or registry only after verifying an
upstream schema change.
