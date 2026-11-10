# Legacy assessment reader repair validation

Validated 2026-11-10 with this checkout loaded using devtools::load_all(); no package installation or library writes. All 71 valid calls used fetch_old_nj_assess(end_year, grade, tidy = TRUE). Source downloads were retained in session scratch and replayed through a mocked transport, so old and corrected parsers saw the same NJDOE bytes.

## Causes and raw-cell checks

A. The old reader transcoded single-byte source text to UTF-8 before applying byte offsets. The Windows-1252 en dash (0x96) in Rahway 7 – 8 Academy expanded, shifting every following field. The reader now keeps byte strings through padding, writes them unchanged to a temporary parse file, and applies a Windows-1252 readr locale. Tests cover each affected year/grade.

For 2013 grade 6, source line 547 starts `394290060`. School-name bytes 110–159 contain `RAHWAY 7 [0x96] 8 ACADEMY`. The raw total-population language arts fields are:

| Field | Byte positions | Raw token | Corrected tidy value |
|---|---:|---|---:|
| Valid scale scores | 187–192 | `*     ` | NA |
| Partially proficient | 193–196 | `*   ` | NA |
| Proficient | 197–200 | `*   ` | NA |
| Advanced proficient | 201–204 | `*   ` | NA |

Testing year is 2013, county 39, district 4290, school 060. The suppressed fields remain NA. The following other affected school rows have published numbers (percent fields have one implied decimal):

| Year / grade | Raw valid / partial / proficient / advanced | Fetcher valid / partial / proficient / advanced |
|---|---|---|
| 2013 / 7 | `278 / 439 / 518 / 43` | 278 / 43.9 / 51.8 / 4.3 |
| 2013 / 8 | `294 / 276 / 690 / 34` | 294 / 27.6 / 69.0 / 3.4 |
| 2014 / 7 | `251 / 502 / 422 / 76` | 251 / 50.2 / 42.2 / 7.6 |
| 2014 / 8 | `279 / 262 / 663 / 75` | 279 / 26.2 / 66.3 / 7.5 |

B. There is no unexpected non-numeric token in the numeric fields of the 2012, 2013 or 2014 HSPA source files. The final layout field (bytes 2903–2906, SCIENCE_SPECIAL_EDUCATION_WITH_ACCOMMODATIONS_Advanced_Proficient_Percentage) is blank on every source row: 719 rows in 2012, 732 in 2013, 742 in 2014. read_fwf correctly produces numeric NA. process_nj_assess formerly ran gsub on that column, coercing it to character and breaking bind_rows on block 60. Removing that coercion preserves numeric NA and every row. Strict whole-cell parsing also replaces the implied-decimal processor’s digit stripping, so a non-numeric token can never yield a number by stripping its letters or range sign.

All implied-decimal source tokens across the 71 files were checked: nonblank/non-star cells consist only of digits. This tightening does not alter valid numeric cells.

| HSPA year | Raw statewide total-population LA valid / partial / proficient / advanced | Fetcher values |
|---|---|---|
| 2012 | `96413 / 85 / 697 / 218` | 96413 / 8.5 / 69.7 / 21.8 |
| 2013 | `95571 / 84 / 650 / 266` | 95571 / 8.4 / 65.0 / 26.6 |
| 2014 | `97091 / 67 / 604 / 328` | 97091 / 6.7 / 60.4 / 32.8 |

The HSPA raw byte positions are 181–186 (valid), 187–190 (partial), 191–194 (proficient), 195–198 (advanced).

## Fixed requests: row counts and sources

Counts are tidy rows under the existing selector flags. Other rows are published DFG/special-needs aggregates; they are retained.

| Family | Year | Grade | State | District | School | Other | Total | Source |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| HSPA | 2012 | 11 | 69 | 20769 | 28083 | 690 | 49611 | https://www.nj.gov/education/assessment/results/njask/njask12/hspa/state_summary.txt |
| NJASK | 2013 | 6 | 60 | 33060 | 56940 | 600 | 90660 | https://www.nj.gov/education/assessment/results/njask/njask13/njask6/state_summary.txt |
| NJASK | 2013 | 7 | 60 | 30300 | 46920 | 600 | 77880 | https://www.nj.gov/education/assessment/results/njask/njask13/njask7/state_summary.txt |
| NJASK | 2013 | 8 | 60 | 30300 | 45780 | 600 | 76740 | https://www.nj.gov/education/assessment/results/njask/njask13/njask8/state_summary.txt |
| HSPA | 2013 | 11 | 69 | 20907 | 28842 | 690 | 50508 | https://www.nj.gov/education/assessment/results/njask/njask13/hspa/state_summary.txt |
| NJASK | 2014 | 7 | 60 | 30600 | 48480 | 600 | 79740 | https://www.nj.gov/education/assessment/results/njask/njask14/njask7/state_summary.txt |
| NJASK | 2014 | 8 | 60 | 30240 | 46380 | 600 | 77280 | https://www.nj.gov/education/assessment/results/njask/njask14/njask8/state_summary.txt |
| HSPA | 2014 | 11 | 69 | 21252 | 29187 | 690 | 51198 | https://www.nj.gov/education/assessment/results/njask/njask14/hspa/state_summary.txt |

## All-year sweep

NJASK: grades 3–4 in 2004–2005, 3–7 in 2006–2007, 3–8 in 2008–2014. GEPA: grade 8 in 2004–2007. HSPA: grade 11 in 2004–2014. All requests downloaded successfully (including all four 2004 Wayback sources); no year could not be served.

Nonblank county/district/school codes must be digits, except known aggregate codes ST, N, NS, SN, O, S and DFG letters A, B, CD, DE, FG, GH, I, J, R, V. Names were compared with independently sliced source-byte fields decoded as Windows-1252. The HSPA 2011 N-only placeholder is padded by the production reader; its missing name fields compare as blanks, not shifted names.

| Year | Calls | Tidy rows | Old wrong years | Old invalid codes | Old shifted names | Old fetch errors | Fixed wrong years | Fixed invalid codes | Fixed shifted names | Fixed errors |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 2004 | 4 | 281262 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 2005 | 4 | 298587 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 2006 | 7 | 584379 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 2007 | 7 | 597618 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 2008 | 7 | 596274 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 2009 | 7 | 598173 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 2010 | 7 | 608589 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 2011 | 7 | 635442 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 2012 | 7 | 639591 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 |
| 2013 | 7 | 639588 | 180 | 0 | 180 | 1 | 0 | 0 | 0 | 0 |
| 2014 | 7 | 644118 | 120 | 0 | 120 | 1 | 0 | 0 | 0 | 0 |

No additional encoding defects were found. Old HSPA errors have no returned rows to screen; all corrected requests were screened. No advertised years changed, no registry gaps changed, no other family changed, and legacy fetchers have no persistent processed cache/schema version to bump.

## Every request: counts and exact source URL

| Family | Year | Grade | State | District | School | Other | Total | Source |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| NJASK | 2004 | 3 | 48 | 25968 | 67440 | 432 | 93888 | https://web.archive.org/web/20160708id_/http://www.state.nj.us/education/schools/achievement/2005/njask3/njask304state_summary.txt |
| NJASK | 2004 | 4 | 48 | 25920 | 66144 | 432 | 92544 | https://web.archive.org/web/20160708id_/http://www.state.nj.us/education/schools/achievement/2005/njask4/njask404state_summary.txt |
| GEPA | 2004 | 8 | 48 | 23520 | 34272 | 432 | 58272 | https://web.archive.org/web/20160708id_/http://www.state.nj.us/education/schools/achievement/2005/gepa/gepa04state_summary.txt |
| HSPA | 2004 | 11 | 54 | 15768 | 20196 | 540 | 36558 | https://web.archive.org/web/20160708id_/http://www.state.nj.us/education/schools/achievement/2005/hspa/hspa04state_summary.txt |
| NJASK | 2005 | 3 | 51 | 27642 | 71604 | 459 | 99756 | https://www.nj.gov/education/assessment/results/njask/njask05/njask3/njask005_state_summary3.txt |
| NJASK | 2005 | 4 | 51 | 27540 | 69768 | 459 | 97818 | https://www.nj.gov/education/assessment/results/njask/njask05/njask4/njask2005_state_summary4.txt |
| GEPA | 2005 | 8 | 51 | 25194 | 36720 | 459 | 62424 | https://www.nj.gov/education/assessment/results/njask/njask05/gepa/2005njgepa_state_summary.txt |
| HSPA | 2005 | 11 | 57 | 16758 | 21204 | 570 | 38589 | https://www.nj.gov/education/assessment/results/njask/njask05/hspa/2005hspa_state_summary.txt |
| NJASK | 2006 | 3 | 54 | 29052 | 75600 | 486 | 105192 | https://www.nj.gov/education/assessment/results/njask/njask06/njask3/state_summary.txt |
| NJASK | 2006 | 4 | 54 | 29052 | 73764 | 486 | 103356 | https://www.nj.gov/education/assessment/results/njask/njask06/njask4/state_summary.txt |
| NJASK | 2006 | 5 | 57 | 30894 | 74271 | 570 | 105792 | https://www.nj.gov/education/assessment/results/njask/njask06/njask5/G5state_summary.txt |
| NJASK | 2006 | 6 | 57 | 30951 | 54378 | 570 | 85956 | https://www.nj.gov/education/assessment/results/njask/njask06/njask6/G6state_summary.txt |
| NJASK | 2006 | 7 | 57 | 28386 | 45828 | 570 | 74841 | https://www.nj.gov/education/assessment/results/njask/njask06/njask7/G7state_summary.txt |
| GEPA | 2006 | 8 | 54 | 26784 | 39204 | 486 | 66528 | https://www.nj.gov/education/assessment/results/njask/njask06/gepa/state_summary.txt |
| HSPA | 2006 | 11 | 63 | 18522 | 23499 | 630 | 42714 | https://www.nj.gov/education/assessment/results/njask/njask06/hspa/state_summary.txt |
| NJASK | 2007 | 3 | 57 | 30837 | 79401 | 513 | 110808 | https://www.nj.gov/education/assessment/results/njask/njask07/njask3/state_summary.txt |
| NJASK | 2007 | 4 | 57 | 30723 | 77862 | 513 | 109155 | https://www.nj.gov/education/assessment/results/njask/njask07/njask4/state_summary.txt |
| NJASK | 2007 | 5 | 57 | 31008 | 73131 | 513 | 104709 | https://www.nj.gov/education/assessment/results/njask/njask07/njask5/G5state_summary.txt |
| NJASK | 2007 | 6 | 57 | 30951 | 54378 | 570 | 85956 | https://www.nj.gov/education/assessment/results/njask/njask07/njask6/G6state_summary.txt |
| NJASK | 2007 | 7 | 57 | 28443 | 43206 | 570 | 72276 | https://www.nj.gov/education/assessment/results/njask/njask07/njask7/G7state_summary.txt |
| GEPA | 2007 | 8 | 57 | 28329 | 40812 | 570 | 69768 | https://www.nj.gov/education/assessment/results/njask/njask07/gepa/state_summary.txt |
| HSPA | 2007 | 11 | 66 | 19536 | 24684 | 660 | 44946 | https://www.nj.gov/education/assessment/results/njask/njask07/hspa/state_summary.txt |
| NJASK | 2008 | 3 | 57 | 30894 | 79914 | 513 | 111378 | https://www.nj.gov/education/assessment/results/njask/njask08/njask3/state_summary.txt |
| NJASK | 2008 | 4 | 57 | 30894 | 78489 | 513 | 109953 | https://www.nj.gov/education/assessment/results/njask/njask08/njask4/state_summary.txt |
| NJASK | 2008 | 5 | 57 | 31122 | 72219 | 513 | 103911 | https://www.nj.gov/education/assessment/results/njask/njask08/njask5/state_summary.txt |
| NJASK | 2008 | 6 | 57 | 31008 | 51642 | 570 | 83277 | https://www.nj.gov/education/assessment/results/njask/njask08/njask6/state_summary.txt |
| NJASK | 2008 | 7 | 57 | 28500 | 42693 | 570 | 71820 | https://www.nj.gov/education/assessment/results/njask/njask08/njask7/state_summary.txt |
| NJASK | 2008 | 8 | 57 | 28386 | 41382 | 570 | 70395 | https://www.nj.gov/education/assessment/results/njask/njask08/njask8/state_summary.txt |
| HSPA | 2008 | 11 | 66 | 19668 | 25146 | 660 | 45540 | https://www.nj.gov/education/assessment/results/njask/njask08/hspa/state_summary.txt |
| NJASK | 2009 | 3 | 57 | 31065 | 79743 | 513 | 111378 | https://www.nj.gov/education/assessment/results/njask/njask09/njask3/state_summary.txt |
| NJASK | 2009 | 4 | 57 | 31065 | 78375 | 513 | 110010 | https://www.nj.gov/education/assessment/results/njask/njask09/njask4/state_summary.txt |
| NJASK | 2009 | 5 | 57 | 31236 | 72675 | 513 | 104481 | https://www.nj.gov/education/assessment/results/njask/njask09/njask5/state_summary.txt |
| NJASK | 2009 | 6 | 57 | 31236 | 51243 | 570 | 83106 | https://www.nj.gov/education/assessment/results/njask/njask09/njask6/state_summary.txt |
| NJASK | 2009 | 7 | 57 | 28614 | 42864 | 570 | 72105 | https://www.nj.gov/education/assessment/results/njask/njask09/njask7/state_summary.txt |
| NJASK | 2009 | 8 | 57 | 28500 | 42294 | 570 | 71421 | https://www.nj.gov/education/assessment/results/njask/njask09/njask8/state_summary.txt |
| HSPA | 2009 | 11 | 66 | 19668 | 25278 | 660 | 45672 | https://www.nj.gov/education/assessment/results/njask/njask09/hspa/state_summary.txt |
| NJASK | 2010 | 3 | 57 | 31065 | 80313 | 513 | 111948 | https://www.nj.gov/education/assessment/results/njask/njask10/njask3/state_summary.txt |
| NJASK | 2010 | 4 | 57 | 31122 | 78945 | 513 | 110637 | https://www.nj.gov/education/assessment/results/njask/njask10/njask4/state_summary.txt |
| NJASK | 2010 | 5 | 57 | 31122 | 74727 | 513 | 106419 | https://www.nj.gov/education/assessment/results/njask/njask10/njask5/state_summary.txt |
| NJASK | 2010 | 6 | 57 | 31179 | 55290 | 570 | 87096 | https://www.nj.gov/education/assessment/results/njask/njask10/njask6/state_summary.txt |
| NJASK | 2010 | 7 | 57 | 28728 | 44631 | 570 | 73986 | https://www.nj.gov/education/assessment/results/njask/njask10/njask7/state_summary.txt |
| NJASK | 2010 | 8 | 57 | 28614 | 42864 | 570 | 72105 | https://www.nj.gov/education/assessment/results/njask/njask10/njask8/state_summary.txt |
| HSPA | 2010 | 11 | 66 | 19866 | 25806 | 660 | 46398 | https://www.nj.gov/education/assessment/results/njask/njask10/hspa/state_summary.txt |
| NJASK | 2011 | 3 | 60 | 33060 | 83880 | 540 | 117540 | https://www.nj.gov/education/assessment/results/njask/njask11/njask3/state_summary.txt |
| NJASK | 2011 | 4 | 60 | 32700 | 81900 | 540 | 115200 | https://www.nj.gov/education/assessment/results/njask/njask11/njask4/state_summary.txt |
| NJASK | 2011 | 5 | 60 | 32880 | 77220 | 540 | 110700 | https://www.nj.gov/education/assessment/results/njask/njask11/njask5/state_summary.txt |
| NJASK | 2011 | 6 | 60 | 32760 | 56880 | 600 | 90300 | https://www.nj.gov/education/assessment/results/njask/njask11/njask6/state_summary.txt |
| NJASK | 2011 | 7 | 60 | 30240 | 48180 | 600 | 79080 | https://www.nj.gov/education/assessment/results/njask/njask11/njask7/state_summary.txt |
| NJASK | 2011 | 8 | 60 | 30300 | 45000 | 600 | 75960 | https://www.nj.gov/education/assessment/results/njask/njask11/njask8/state_summary.txt |
| HSPA | 2011 | 11 | 66 | 19800 | 26136 | 660 | 46662 | https://www.nj.gov/education/assessment/results/njask/njask11/hspa/state_summary.txt |
| NJASK | 2012 | 3 | 60 | 33360 | 83880 | 540 | 117840 | https://www.nj.gov/education/assessment/results/njask/njask12/njask3/state_summary.txt |
| NJASK | 2012 | 4 | 60 | 33060 | 81660 | 540 | 115320 | https://www.nj.gov/education/assessment/results/njask/njask12/njask4/state_summary.txt |
| NJASK | 2012 | 5 | 60 | 33060 | 77760 | 540 | 111420 | https://www.nj.gov/education/assessment/results/njask/njask12/njask5/state_summary.txt |
| NJASK | 2012 | 6 | 60 | 33120 | 56700 | 600 | 90480 | https://www.nj.gov/education/assessment/results/njask/njask12/njask6/state_summary.txt |
| NJASK | 2012 | 7 | 60 | 30480 | 47760 | 600 | 78900 | https://www.nj.gov/education/assessment/results/njask/njask12/njask7/state_summary.txt |
| NJASK | 2012 | 8 | 60 | 30300 | 45060 | 600 | 76020 | https://www.nj.gov/education/assessment/results/njask/njask12/njask8/state_summary.txt |
| HSPA | 2012 | 11 | 69 | 20769 | 28083 | 690 | 49611 | https://www.nj.gov/education/assessment/results/njask/njask12/hspa/state_summary.txt |
| NJASK | 2013 | 3 | 60 | 33540 | 83280 | 540 | 117420 | https://www.nj.gov/education/assessment/results/njask/njask13/njask3/state_summary.txt |
| NJASK | 2013 | 4 | 60 | 33360 | 81480 | 540 | 115440 | https://www.nj.gov/education/assessment/results/njask/njask13/njask4/state_summary.txt |
| NJASK | 2013 | 5 | 60 | 33180 | 77160 | 540 | 110940 | https://www.nj.gov/education/assessment/results/njask/njask13/njask5/state_summary.txt |
| NJASK | 2013 | 6 | 60 | 33060 | 56940 | 600 | 90660 | https://www.nj.gov/education/assessment/results/njask/njask13/njask6/state_summary.txt |
| NJASK | 2013 | 7 | 60 | 30300 | 46920 | 600 | 77880 | https://www.nj.gov/education/assessment/results/njask/njask13/njask7/state_summary.txt |
| NJASK | 2013 | 8 | 60 | 30300 | 45780 | 600 | 76740 | https://www.nj.gov/education/assessment/results/njask/njask13/njask8/state_summary.txt |
| HSPA | 2013 | 11 | 69 | 20907 | 28842 | 690 | 50508 | https://www.nj.gov/education/assessment/results/njask/njask13/hspa/state_summary.txt |
| NJASK | 2014 | 3 | 60 | 33660 | 83460 | 540 | 117720 | https://www.nj.gov/education/assessment/results/njask/njask14/njask3/state_summary.txt |
| NJASK | 2014 | 4 | 60 | 33540 | 82140 | 540 | 116280 | https://www.nj.gov/education/assessment/results/njask/njask14/njask4/state_summary.txt |
| NJASK | 2014 | 5 | 60 | 33300 | 77700 | 540 | 111600 | https://www.nj.gov/education/assessment/results/njask/njask14/njask5/state_summary.txt |
| NJASK | 2014 | 6 | 60 | 33120 | 56520 | 600 | 90300 | https://www.nj.gov/education/assessment/results/njask/njask14/njask6/state_summary.txt |
| NJASK | 2014 | 7 | 60 | 30600 | 48480 | 600 | 79740 | https://www.nj.gov/education/assessment/results/njask/njask14/njask7/state_summary.txt |
| NJASK | 2014 | 8 | 60 | 30240 | 46380 | 600 | 77280 | https://www.nj.gov/education/assessment/results/njask/njask14/njask8/state_summary.txt |
| HSPA | 2014 | 11 | 69 | 21252 | 29187 | 690 | 51198 | https://www.nj.gov/education/assessment/results/njask/njask14/hspa/state_summary.txt |

## Offline verification

The initial fixture tests failed on the old reader (wrong year and school name) and processor (numeric column became character; bind_rows errored). Eight regression cases now use three unmodified real source lines each, with fixture provenance in tests/testthat/fixtures/legacy-assessment/README.md. The five NJASK cases each return 180 fixture rows; the three HSPA cases each return 207.

Full devtools::test(): 5,192 passing expectations, 1 failure, 0 errors, 719 skipped test cases; 16 warning expectations (plus 3 top-level context deprecation warnings). The sole failure is the existing network-test inventory classification of test-historical-store-recovery.R. Replaying the classifier against HEAD versions of the test files identifies the same offender. That unrelated family/test was left unchanged.

Legacy test file: 74 passes, 0 failures/errors/warnings, 2 live-test skips. Of these, the eight new regression cases contribute 69 passing assertions.

Broader targeted legacy/selector/overlap tests: 363 passing assertions, 0 failures/errors/warnings, 11 live-test skips. Review was confined to these fixes; the byte-preservation path, strict numeric parsing and source-fixture comparisons were reviewed sequentially in the main thread. No additional code changes were needed.
