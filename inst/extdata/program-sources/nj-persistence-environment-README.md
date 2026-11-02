# NJDOE persistence, educational environments and school enrollment shares

Retrieved November 1, 2026. Statewide SPR text extracts and other source files
are bundled. The large original SPR workbooks are retained outside the repository.
The manifest in `source-contract/contracts/new_jersey_shipped_sources/`
records exact byte lengths, SHA-256 digests, URLs and retrieval dates.
The readers verify these bytes on every call and never download a replacement.

The parent `spr-school-2024.xlsx` is NJDOE's 2023-24 school database:
https://www.nj.gov/education/sprreports/download/DataFiles/2023-2024/Database_SchoolDetail.xlsx
Its `6YrGraduationCohortProfile` sheet publishes `HighSchoolPersistance`.
For Camden City School District (0680), Camden High School (030), the
Students with Disabilities cell N1441 is 58.7; the Schoolwide cell N1430
is 66.3. These are Cohort 2022 six-year results.

The parent `spr-school-2025.xlsx` is NJDOE's 2024-25 school database, released
May 21, 2026:
https://www.nj.gov/education/sprreports/download/DataFiles/2024-2025/Database_SchoolDetail.xlsx
`HSPersistenceTargets` uses the previous year's Cohort 2022 results for
2024-25 accountability. J852 is 58.7% for the same school and disability
group. `GraduationCohortProfile` instead publishes the current Cohort 2023
six-year `Persisting_School` value: S4337 is 75.4%. These periods are kept
separate. The number of students is not published, so counts stay missing.
Markers such as `Data was available for less than 10 students` remain text
with a missing numeric value. Accountability calculations require 20 students.

High school persistence means the percentage in a graduation cohort who
graduated with a state-endorsed diploma or remained enrolled six years after
entering high school. It does not establish annual same-school retention.
The verified `spr-reference-guide.pdf` defines the construct on pages 36-37
and the lag in the accountability section:
https://www.nj.gov/education/spr/resources/doc/SPR_ReferenceGuide.pdf
The 2022-23 workbook was also opened: its six-year profile has no persistence
column. The reader does not construct one from graduates and continuing students.

The 2025 database's `EnrollmentTrendsByStudentGroup` includes historical rows
for 2022-23 and 2023-24. Students with Disabilities is a percent of enrollment,
not an exact IEP count. For Camden High School, L2487:L2489 is 20.0%, 16.9%,
14.9%. The reader preserves source text, rounding precision and any published
interval. It reads enrollment and grade spans from `EnrollmentTrendsbyGrade`;
it never multiplies a rounded rate by enrollment to create a count. Per the
guide (pages 8-10), these are end-of-year enrollment submissions, including
full-time-equivalent enrollment. Reporting follows the school enrollment
submission. Specialized receiving schools have their accountability outcomes
attributed to sending schools, which is a separate construct.

The six `spr-school-*.csv.gz` projections retain every data row and only
the columns used by these readers, as text, including leading-zero codes,
suppression markers, cached formula values and published precision. The 2024
enrollment-group projection is also retained for that release. Nothing is
recalculated or filtered by entity. The 2025 sheets have three introductory
rows before their column headers; the 2024 headers are on the first row.
Extracts preserve whitespace; readers apply the original readxl trimming.
Each extract's manifest entry records its own length and SHA-256, plus the
parent workbook URL, retrieval date, length, SHA-256, sheet, columns and row
count. Missing or changed extracts stop the reader.

Rebuild from the retained parent paths with
`Rscript data-raw/build_nj_spr.R /path/to/workbook-2024.xlsx /path/to/workbook-2025.xlsx`.
The script verifies the parent hashes before extraction and updates the shipped
manifest and contract. No network request is made.

`environment-profiles.twbx` is the complete downloadable NJDOE Tableau
workbook linked from its Data and Resources page:
https://www.nj.gov/education/specialed/monitor/dataandresources/
https://public.tableau.com/workbooks/SPPAPRLocalProfiles.twb?showVizHome=no
Its embedded `SPPAPR_LOCALPROFILES_RPTYEAR_2025_8EA3ED3DE717473C95C7007563F38881`
Hyper table includes report years 2023-2026 and school years 2021-22 through
2024-25. `environment-5c.csv` projects all IND_5C rows and the fields named
in `data-raw/build_nj_environment.py`. The original archive and projection
are both checked at read time. No hidden `*_UNSUP` field is served.

Use SCHOOL_YEAR to set end_year. REPORT_YEAR 2026 is school year 2024-25,
not 2025-26. The published LOCAL percent and NUMERATOR / DENOMINATOR cells are:

| end_year | State district id | LOCAL | NUMERATOR | DENOMINATOR |
|---|---|---|---|---|
| 2023 | 0680 | 8.11 | 90 | 1110 |
| 2024 | 0680 | 10.35 | 104 | 1005 |
| 2025 | 0680 | 8.98 | 103 | 1147 |
| 2023 | 3570 | 3.48 | 201 | 5771 |
| 2024 | 3570 | 3.29 | 192 | 5836 |
| 2025 | 3570 | 2.74 | 164 | 5995 |

These are published profile values, not sums of placement components. The
profile includes a state row only for school year 2024-25 (9999). Earlier
state rows are not manufactured. Nonnumeric LOCAL markers (including N)
remain missing with their source text; underlying unsuppressed values never
replace them. The denominator is the profile's own denominator, without a
substitution from the public-IEP classification workbook.
The bundled undated `environment-indicator5-definition.pdf` defines 5C, its
age group, the denominator and marker N. It notes that parentally placed
students are included in the total count:
https://www.nj.gov/education/specialed/monitor/dataandresources/docs/LocalProfile_One-Pagers_Indicator5.pdf

No 2025-26 source was published in these releases. The SPR selector ends at
2024-25 and its 2025-26 workbook URL returns HTTP 404 with a browser User-Agent.
The profile's latest school year is 2024-25. See `inst/registry/gaps.csv`.
