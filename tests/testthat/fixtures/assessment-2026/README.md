# Spring 2026 NJSLA and NJGPA fixtures

Real NJDOE workbook slices downloaded November 10, 2026 from the
[2025-26 assessment release](https://www.nj.gov/education/assessment/results/reports/2526/index.shtml).
Each preserves the original preamble/header, first All Students school,
district and state rows, first school row with suppressed valid scores,
final data row, and footer. Cells are copied without alteration with
openpyxl (`data_only=True`). `provenance.json` records source URLs, SHA-256
digests of source/fixture bytes, and original one-based Excel row numbers.

NJSLA header row 3 (`skip = 2`): 17 columns for ELA/math, 16 for science.
NJGPA header row 4 (`skip = 3`): 14 columns. The column labels and level counts
match the corresponding 2025 layout: 5 ELA/math levels, 4 science levels,
2 NJGPA levels. Columns 7 and 8 contain subgroup category and student group,
respectively, despite the source's `Subgroup` / `Subgroup Type` labels.
All retain identifiers, registered/not-tested/valid counts, mean scale score,
and level percentages. NJGPA has only one footer row; its suppression note is
above the header, so the last statewide SE Accommodation row must survive.

The new ELA/math and NJGPA score scales are preserved verbatim and marked
with `assessment_era` (`NJSLA-2026` / `NJGPA-2026`). Examples of published mean
scores in these fixtures: H Ashton Marsh grade 4 math 1417, grade 3 ELA 1438;
Emma C Attales Algebra I 2544; Atlantic City High School NJGPA ELA 451.
The same schools' 2025 workbooks report 739, 742, 769, and 721 respectively.
These are different-year observations on different scales, not a crosswalk.
No score is rescaled or mapped to an earlier standard. Science remains `NJSLA-S`.
`assess_name` and existing output fields remain available; `suppressed` flags
any row with an asterisk-masked valid-score count, mean scale score or level
percent; those cells stay NA. Masked Registered To Test / Not Tested counts,
which NJDOE applies to nearly every school row, do not set it.

All 21 release workbooks returned HTTP 200 and parsed successfully: ELA03-ELA09,
MAT03-MAT08, ALG01, GEO01, ALG02, SC05, SC08, SC11 (NJSLA), and ELAGP/MATGP
(NJGPA). The four requested tidy fetches, run against the complete downloaded
workbooks through the existing transport/parser, returned:

| Fetch | State rows | District rows | School rows |
|---|---:|---:|---:|
| Grade 4 math | 24 | 10480 | 23652 |
| Algebra I math | 29 | 10531 | 18304 |
| Grade 3 ELA | 24 | 10468 | 24269 |
| NJGPA ELA | 24 | 6518 | 8506 |

Counts include all published subgroups, not distinct entities. The 2026 index
lists ELA grades 3-9, so the all-results request grid omits grade 10 for this year.
