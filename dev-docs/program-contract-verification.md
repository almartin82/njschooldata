# District program contract verification

Verified 2026-10-30 using the installed `njschooldata` build.

## Source meaning

`fetch_sped()` returns **public IEP classification counts**, identified as
`measure = "classification_count"`, `age_group = "3_21"`. It does not relabel
these as `child_count`. The 2023 and 2024 district workbooks explicitly label
ages 3–21 and date the counts to October 15, 2022 and October 15, 2023.
The 2025 district worksheet explains the public IEP population, including
students sent out for services, excluding parentally placed private-school
students with ISPs, and assigning shared-time students to their sending district.
NJDOE's release page dates the 2025 classification population to October 15,
2024; the workbook's 2023-24 title is stale. The release page also describes
a separate special-education student-count product. The latest listed SpEd
release is 2025; no 2026 SpEd release is advertised there.

Sources:

- [2023 classification archive](https://www.nj.gov/education/specialed/monitor/ideapublicdata/public618data2022.shtml)
- [2024 classification archive](https://www.nj.gov/education/specialed/monitor/ideapublicdata/public618data2024.shtml)
- [2025 classification definition and downloads](https://www.nj.gov/education/specialed/monitor/ideapublicdata/)
- [Fall enrollment, including 2025-26](https://www.nj.gov/education/doedata/enr/)

Every shipped count comes from the complete NJDOE workbook/ZIP named in the
v1 source manifest. The 2023/2024 statewide rows use the **public** total in the
separate statewide classification files, never the public-plus-nonpublic total
or a sum of districts. The 2025 statewide row is published in District Rates.
The district count and rate for Holland Township (19/2220) are blank in the
2025 source, so its count remains NA with `suppressed = FALSE`. The suppressed
2023 Essex County JDC (13/8509) remains present with NA count and
`suppressed = TRUE`. Missing enrollment no longer removes a district.

EL totals are read from the District worksheet's all-grade count column and
the State worksheet's All Grades row. School observations remain available.
No grade or race sum supplies a missing total. A suppressed total remains NA;
an absent statewide total is omitted. The 2026 enrollment URL uses capitalized
`Enrollment_2526.zip`; the lowercase URL returns 404. Fractional published
counts (including the 2024 statewide EL total) are preserved.

NCES LEA IDs use the bundled **identifiers-only** CCD 2024
`state_leaid`/`leaid` table. Match `NJ-` + published two-digit county code +
four-digit district code exactly; unmatched keys remain NA. The original
state ID columns are preserved. No directory or name fallback is used.

## Installed-build acceptance output

Columns after year: district rows, NCES matches, finite counts, suppressed cells.

```text
SpEd child_count
2023 0 0 0 0
2024 0 0 0 0
2025 0 0 0 0

SpEd classification_count
2023 649 646 648 1
2024 653 653 653 0
2025 655 655 654 0

EL current / total / TOTAL
2023 669 666 669 0
2024 667 667 667 0
2025 666 666 666 0
2026 663 662 663 0
```

Each output has one statewide row. Published SpEd state totals are 228,242,
238,721, and 242,001 in 2023-2025. Published EL state totals are 116,699,
130,823.5, 155,304, and 152,211 in 2023-2026.

The strict requested SpEd child-count selector intentionally returns zero;
these classification counts require an explicit downstream decision to use
the alternate measure. This is not a claim that NJDOE publishes no SpEd counts.

## Independent source-file spot checks

Each cell below was compared with the downloaded state file and the installed
fetcher's result. All pairs matched exactly. Entries are SpEd classification
count / EL count.

| District (county/district) | 2023 | 2024 | 2025 |
|---|---:|---:|---:|
| Absecon (01/0010) | 149 / 73 | 157 / 74 | 165 / 98 |
| Newark (13/3570) | 6,315 / 9,165 | 6,550 / 10,250 | 6,795 / 12,623 |
| Jersey City (17/2390) | 2,359 / 3,667 | 3,518 / 3,713 | 3,662 / 3,932 |

## Verification commands

- `devtools::install(upgrade = "never", build = FALSE, build_vignettes = FALSE)`
- Requested `fetch_sped()` child-count selector and `fetch_ell()` current/TOTAL selector, plus the classification selector and statewide totals shown above.
- `testthat::test_dir("tests/testthat", package = "njschooldata", reporter = "summary")`
- `python3 -m pytest tests/test_source_snapshot_ownership.py -q` — 3 passed.
- Shared `validate_contract.validate_bundle()` for both source-tree and installed-layout v1 manifests — valid, nine complete shipped sources each.
- `git diff --check` — clean.

The added offline tests deny transport, compare all recent SpEd and EL
observations with the shipped raw files, verify exact CCD bindings, and check
that a suppressed/missing statewide EL total cannot become a partial sum.

Installed-build results (`as.data.frame(testthat_results)` column sums):

```text
         failed error warning skipped passed
BEFORE        0     0      14     693   3309
AFTER         0     0      14     693   3404
```

The summary reporter lists 17 warnings in both runs: the 14 in test blocks
plus three existing `context()` deprecations outside `test_that()`. No new
warnings or failures. The new offline test file is registered in the existing
test inventory, with transport explicitly denied. The crosswalk maintainer
script's documentation changes also pass `parse()`.
