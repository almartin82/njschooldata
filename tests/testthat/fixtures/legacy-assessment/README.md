# Legacy assessment raw-line fixtures

Unmodified lines cut from NJDOE fixed-width downloads; LF record terminators.
Windows-1252 bytes (including the Rahway school name byte 0x96) are retained.
Numeric fields use the package’s corresponding published layouts.

| Fixture | Source line numbers (1-based) | NJDOE source |
|---|---|---|
| hspa-2012.txt | 1, 5, 6 | https://www.nj.gov/education/assessment/results/njask/njask12/hspa/state_summary.txt |
| hspa-2013.txt | 1, 5, 6 | https://www.nj.gov/education/assessment/results/njask/njask13/hspa/state_summary.txt |
| hspa-2014.txt | 1, 5, 6 | https://www.nj.gov/education/assessment/results/njask/njask14/hspa/state_summary.txt |
| njask-2013-6.txt | 1, 543, 547 | https://www.nj.gov/education/assessment/results/njask/njask13/njask6/state_summary.txt |
| njask-2013-7.txt | 1, 470, 471 | https://www.nj.gov/education/assessment/results/njask/njask13/njask7/state_summary.txt |
| njask-2013-8.txt | 1, 462, 463 | https://www.nj.gov/education/assessment/results/njask/njask13/njask8/state_summary.txt |
| njask-2014-7.txt | 1, 494, 495 | https://www.nj.gov/education/assessment/results/njask/njask14/njask7/state_summary.txt |
| njask-2014-8.txt | 1, 477, 478 | https://www.nj.gov/education/assessment/results/njask/njask14/njask8/state_summary.txt |

NJASK fixtures contain state, Rahway district and Rahway 7 – 8 Academy school rows.
For 2013 grade 6 the school’s language arts valid scores and proficiency cells are
all `*`; the other four fixtures contain published numeric values for that school.

HSPA fixtures contain state, first district and first school rows. In all 2012–2014
source rows, the final numeric field (bytes 2903–2906, science / special education
with accommodations / advanced proficient percentage) is blank. There is no
unexpected non-numeric token in any numeric field in those three source files.
The former processor coerced this entire blank numeric column to character with
`gsub()`, causing `bind_rows()` to fail. The tests exercise the real blank fields
and compare statewide total-population language arts cells with the raw bytes.
