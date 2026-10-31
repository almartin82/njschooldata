# Finance and chronic absenteeism source checks

Checked 2026-10-31 using the package fetchers directly. All figures below are
published values; no missing values were filled. Finance figures are dollars;
absence figures are percentages. HTTP acquisitions returned 200 and validated
as Excel workbooks (or ZIP archives containing them).

## Finance

The prior reader expected `FYnn K-12 Aid`. These releases instead label the
current-year total as revised aid. Each also carries an earlier Governor's
Budget Message total and a duplicate revised total; the parser selects the
first revised total once. FY2019's `State / 9999 / Total` row is statewide,
not a district.

| Year | Publisher archive and member | Sheet and cell | Printed revised total | Computed district sum | Fetch rows |
| --- | --- | --- | ---: | ---: | ---: |
| 2019 | [1819.zip](https://www.nj.gov/education/stateaid/zippedfiles/1819.zip), district.xlsx | DISTRICT DETAILS, F583 | 8,485,965,463 | 8,485,965,463 | 4,546 |
| 2020 | [1920.zip](https://www.nj.gov/education/stateaid/zippedfiles/1920.zip), District Details FY20 Revised.xlsx | District Details, F583 | 8,676,882,785 | 8,676,882,785 | 4,546 |
| 2021 | [2021.zip](https://www.nj.gov/education/stateaid/zippedfiles/2021.zip), FY21 Revised District Detail.xlsx | District Details, F583 | 8,680,457,745 | 8,680,457,745 | 4,546 |

The header is row 5 in all three workbooks. The revised total labels are
`2018-19 Approp. Act Revised Total K-12 Aid`,
`FY20 Approp. Act Revised Total K to 12 Aid`, and
`2020-21 Revised Total K-12 Aid`, respectively.

## Chronic absenteeism

The common school observation is Emma C Attales, CDS 01-0010-050,
Schoolwide (All Students in 2025). A school rate is reconciled by preserving
the printed percentage, rather than summing percentages or deriving a rate
from rounded counts. Each returned value below equals the printed value in
the same workbook. All returned row counts also match the measure sheet.

| Year | Publisher workbook | Sheet and location | Printed rate | Returned rate | Fetch rows |
| --- | --- | --- | ---: | ---: | ---: |
| 2017 | [2016-2017/Database_SchoolDetail.xlsx](https://www.nj.gov/education/sprreports/download/DataFiles/2016-2017/Database_SchoolDetail.xlsx) | ChronicAbsenteeism, D8 (Schoolwide) | 9.3 | 9.3 | 23,910 |
| 2018 | [2017-2018/Database_SchoolDetail.xlsx](https://www.nj.gov/education/sprreports/download/DataFiles/2017-2018/Database_SchoolDetail.xlsx) | ChronicAbsenteeism, I2 (Schoolwide) | 6.7 | 6.7 | 23,870 |
| 2019 | [2018-2019/Database_SchoolDetail.xlsx](https://www.nj.gov/education/sprreports/download/DataFiles/2018-2019/Database_SchoolDetail.xlsx) | ChronicAbsenteeism, I2 (Schoolwide) | 7.1 | 7.1 | 37,984 |
| 2021 | [2020-2021/Database_SchoolDetail.xlsx](https://www.nj.gov/education/sprreports/download/DataFiles/2020-2021/Database_SchoolDetail.xlsx) | ChronicAbsenteeism, I2 (Schoolwide) | 15.0 | 15.0 | 40,307 |
| 2022 | [2021-2022/Database_SchoolDetail.xlsx](https://www.nj.gov/education/sprreports/download/DataFiles/2021-2022/Database_SchoolDetail.xlsx) | ChronicAbsenteeism, I2 (Schoolwide) | 11.6 | 11.6 | 40,188 |
| 2023 | [2022-2023/Database_SchoolDetail.xlsx](https://www.nj.gov/education/sprreports/download/DataFiles/2022-2023/Database_SchoolDetail.xlsx) | ChronicAbsenteeism, I2 (Schoolwide) | 13.3 | 13.3 | 40,256 |
| 2024 | [2023-2024/Database_SchoolDetail.xlsx](https://www.nj.gov/education/sprreports/download/DataFiles/2023-2024/Database_SchoolDetail.xlsx) | ChronicAbsenteeism, I2 (Schoolwide) | 11.0 | 11.0 | 40,171 |
| 2025 | [2024-2025/Database_SchoolDetail.xlsx](https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx) | ChronicAbsenteeismStudentGroup, J5 (All Students) | 7.3 | 7.3 | 40,103 |

The 2017 measure sheet omits names. The reader joins names from SchoolHeader
in that same workbook using the complete county/district/school code.
2020 remains excluded. On 2026-10-31 the [2019-2020 school workbook](https://www.nj.gov/education/sprreports/download/DataFiles/2019-2020/Database_SchoolDetail.xlsx)
returned HTTP 200 and a valid XLSX file, but its sheet inventory contained no
ChronicAbsenteeism sheet. `fetch_absence(2020)` therefore refused that source
with "Sheet 'ChronicAbsenteeism' not found in 2020 SPR database".

## Cache diagnosis

Warm 2017–2019 files used unversioned year/level filenames and had no
`.source.rds` sidecar. Therefore the metadata object was NULL: this was missing
identity evidence, rather than a differing URL or timestamp. Cold downloads
created valid version-1 sidecars and were accepted on subsequent calls.
Documented 2021–2025 cache entries already passed the identity checks.

New acquisitions use a versioned filename containing the URL digest. Legacy
files without metadata remain intact and are not relabelled or assigned an
invented retrieval date. Existing documented entries still go through the
same URL, clock, file size and SHA-256 checks. The regression test verifies
cold acquisition, warm reuse, preservation of legacy bytes, and refusal of
both missing and changed identity metadata in the new namespace. On an
untouched `git archive HEAD` export it fails because acquisition is refused.

## Test verification

Live tests ran with `NOT_CRAN=true` and `NJSCHOOLDATA_LIVE_TESTS=true`.
The before run used the original checkout; the same test files were also run
on an untouched `git archive HEAD` export. No existing test was changed.

| Test file | HEAD passed | Updated passed | HEAD failures/errors | Updated failures/errors |
| --- | ---: | ---: | ---: | ---: |
| test-available-years-contract.R | 85 | 92 | 0 | 0 |
| test-finance.R | 67 | 67 | 0 | 0 |
| test-finance-source-results.R | 15 | 15 | 0 | 0 |
| test-state-aid.R | 40 | 40 | 0 | 0 |
| test-absence-offline-contract.R | 4 | 4 | 0 | 0 |
| test-live-absence.R | 23 | 23 | 2 | 2 |
| test-live-absence-edge-cases.R | 80 | 81 | 4 | 3 |
| test-live-absence-correctness.R | 165 | 165 | 4 | 4 |
| test-spr-workbook-cache.R | 12 | 12 | 0 | 0 |
| test-source-transport.R | 25 | 25 | 0 | 0 |
| test-spr-cache-identity.R (new) | regression reproduced | 11 | 4 | 0 |
| test-finance-absence-reconciliation.R (new) | not present | 62 | — | 0 |

There were no skips. The coverage test emitted 109 warnings on HEAD and 182
with the additional years. The new reconciliation tests emitted 73 warnings:
72 from the existing TGES text reader and one from numeric coercion of SPR
suppression text. Reconciled values remain exact.

The nine remaining broader-suite failures were reproduced on the HEAD export:
seven errors in multi-year warning/error expectations, plus two assertions
in `chronic data: racial subgroups present across levels`. The multi-year
fetcher defaults to strict refusal, while those tests expect partial results
or an older error message. The racial assertions concern existing subgroup
normalization. The 2017 missing-name error is removed by this change.

The new cache test was separately run against the HEAD export and failed on
its first two acquisitions and request count, followed by an error reading
metadata that the refused acquisition never created. It passes all 11
assertions with the new cache key logic. Identity validation in the shared
transport is unchanged.
