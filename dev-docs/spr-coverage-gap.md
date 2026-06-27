> Load this when: triaging which redesigned 2024-25 SPR sheets to expose as new fetchers, or scoping SPR coverage work.

# SPR 2024-25 Coverage Gap

## Background

NJ DOE publishes two School Performance Reports Excel databases each year:

- **Database_SchoolDetail.xlsx** — 82 sheets, school-level data
- **Database_DistrictStateDetail.xlsx** — 81 sheets, district- and state-level data

The package routes access to most SPR sheets through a shared internal helper:

```r
fetch_spr_data("<SheetName>", end_year, level)
```

Higher-level category fetchers (e.g., `fetch_chronic_absenteeism()`, `fetch_disciplinary_removals()`) call this helper with the appropriate sheet name(s). The 2024-25 databases introduced several new sheets and restructured others, creating gaps between what the package exposes and what is available in the source files.

This doc catalogues every uncovered sheet by domain, flags priority, and proposes a fetcher name for each. Sheets that are pure metadata (tab `2024-25 Database Notes`, `Data Quality Notes`, `HeaderContact`, `Narrative`) are excluded — they contain no data rows.

---

## Already Implemented

The Tier 1 and Tier 2 shortlist below was implemented in 2026-05 (PRs #247, #250, #251, #252). The **Years** column reflects the backfill work (below): six fetchers were extended to the earliest year their source sheet exists with a structure that maps to the redesigned shape without fabrication; the rest stay gated at `end_year >= 2025` and error rather than guess a mapping for earlier years.

| Sheet(s) | Fetcher | Years | PR |
|---|---|---|---|
| StudentGrowthTrends / StudentGrowthbyGrade / StudentGrowthByPerformLevel | `fetch_sgp(type=)` | **trends/by_grade: 2018-2019, 2023-2025; by_performance_level: 2023-2025** | #247, backfill |
| ProficiencyTargets / GrowthTargets / GraduationTargets / ProgresstowardELPTargets / ChronicAbsenteeismTargets / HSPersistenceTargets | `fetch_spr_essa_targets(indicator=)` | 2025+ | #250 |
| AccountabilitySummative | `fetch_spr_accountability_summative()` | 2025+ | #250 |
| TSIIdentification | `fetch_spr_tsi()` | 2025+ | #250 |
| ESSAAccountabilityStatusList (district) | `fetch_essa_status(level="district")` | 2025+ | #248 |
| ESSAAccountabilityStatusCounts | `fetch_spr_essa_status_counts()` | 2025+ | #250 |
| GraduationPathways | `fetch_spr_grad_pathways()` | **2018-2022, 2024-2025** | #251, backfill |
| EnrollmentByHomeLanguage | `fetch_spr_home_language()` | **2018-2025** | #251, backfill |
| NAEP (district/state) | `fetch_spr_naep()` | **2017-2025** | #251, backfill |
| AdministratorsExperience | `fetch_spr_admin_experience()` | 2025+ | #252 |
| StaffCounts | `fetch_spr_staff_counts()` | **2021-2025** | #252, backfill |
| TeachersAdminsDemoSubjectArea | `fetch_spr_staff_demo_subject()` | 2025+ | #252 |
| TeachersAdminsEducation (legacy: TeachersAdminsLevelOfEducation) | `fetch_spr_staff_education()` | **2018-2025** | #252, backfill |
| TeachersAdminsOneYearRetention | `fetch_spr_staff_retention()` | **2018-2025 (district); 2025+ (school)** | #252, backfill |
| TeacherExperienceSubjArea | `fetch_spr_teacher_exp_subject()` | 2025+ | #252 |
| StatewideEducatorEquity (district/state) | `fetch_spr_educator_equity()` | 2025+ | #252 |
| PoliceNotifications | `fetch_police_notifications()` | **2018-2025** | #191 |
| HIBInvestigations | `fetch_hib_investigations()` | **2018-2025** | #191 |
| PoliceNotificationsGroupGrade (alias: PoliceNotificationByStuGroup in 2024) | `fetch_police_notifications_detail()` | **2024-2025** | #191 |
| ArrestsStudentGroupGrade (alias: StuArrestbyStudentGroupGradelev in 2024) | `fetch_arrests()` | **2024-2025** | #191 |
| ELAPerformanceByTest / MathPerformancebyTest (+ pre-redesign `*PerformanceByGrade`/`*ByGradeTest`) | `fetch_spr_proficiency_by_test(subject=)` | **2017-2019, 2022-2025** | Bucket A |
| NJSLASciencebyGradeTrends (+ `ScienceAssessmentByGrade`/`NJSLAScience`/`NJSLAScienceTable`) | `fetch_spr_science_grade()` | **2019, 2021-2025** | Bucket A |
| ProgressTowardELP | `fetch_spr_elp_progress()` | **2025** | Bucket A |
| GraduationCohortProfile (+ `4Yr`/`5Yr`/`6YrGraduationCohortProfile`) | `fetch_spr_grad_cohort()` | **2020-2025** | Bucket A |
| FederalGraduationRates | `fetch_spr_fed_grad()` | **2021-2025** | Bucket A |

**Bucket A note (assessment / graduation detail).** Five sheet families with no
standalone-fetcher equivalent. The 2025 sheets read each value as a
`{_school,_district,_state}` triple, collapsed by `spr_pick_entity_value()` (same
rule as `fetch_6yr_grad_rate()`). Four of the five were backfilled into the
pre-redesign databases (the assessment + grad-cohort sheets exist earlier under
different names with deterministic column-renames); the legacy layouts store the
entity value beside a parallel `state_*` column, collapsed by the sibling
`spr_legacy_entity_value()`, and `normalize_grade_test()` maps the legacy
`grade`/`grade_subject` labels (incl. `ALG01`/`ALG02`/`GEO01`) onto the 2025
`grade_test` vocabulary. Coverage gaps are honest, not guessed: **2020-2021**
have no by-grade/test ELA/Math sheet (COVID); science is **2019, 2021-2025**
(2020 COVID, 2017-2018 is the incomparable NJASK); grad cohort is **2020-2025**
(2020 = 4/5-year only). `fetch_spr_proficiency_by_test()` covers both ELA and
Math via a `subject=` argument and exposes the high-school end-of-course Math
variants (Algebra I/II, Geometry) that `fetch_parcc()` does not.
`fetch_spr_elp_progress()` stays **2025-only** - the legacy `EnglishLanguageProgress`
is a different target-framed metric, deliberately not forced into the indicator
schema. `fetch_spr_fed_grad()` spans 2021-2025, reshaping the drifting wide
layout to long-by-cohort (4/5/6-year; 6-year only from 2024). See the "Valid
Filter Values (SPR ... Bucket A)" block in the package CLAUDE.md for full schema
and anchor values.

Notes: NAEP and StatewideEducatorEquity carry no CDS codes (state/national summary tables), so they read through the internal `fetch_spr_sheet_raw()` helper (no CDS/flag machinery). `fetch_spr_staff_demo_subject()` deliberately keeps its racial/ethnic and gender composition columns as character — NJ DOE reports small-cell percentages as privacy-protected ranges (e.g. `"70-80%"`), and coercing them to a single number would fabricate precision.

### Backfill to pre-redesign databases (2026-05)

The 14 redesign fetchers were all originally gated at `end_year >= 2025`. An audit of
the 2017-2024 workbooks (`scratch/spr-backfill/`) found that several target sheets exist
in earlier databases. Each fetcher was extended to its real first year:

| Fetcher | Backfilled to | How |
|---|---|---|
| `fetch_spr_home_language()` | 2018 | Same sheet; identical columns minus the 2025-only `SchoolYear`. 2017 omits name columns. |
| `fetch_spr_staff_counts()` | 2021 | `StaffCounts` first appears SY2020-21; identical columns. |
| `fetch_spr_staff_education()` | 2018 | Sheet renamed; reads legacy `TeachersAdminsLevelOfEducation`. Legacy `Admin` label normalized to `Administrators`. 2017 is long-format. |
| `fetch_spr_staff_retention()` | 2018 (district only) | Identical columns, but the measure is district-granularity (no `SchoolCode`) before 2025; school-level rows are 2025+. |
| `fetch_spr_naep()` | 2017 | Legacy layout (`Year`/`Test`/`Grade`, no subgroup) mapped: `Year->test_year`, `Test->subject`, `"State (NJ)"->"New Jersey"`, `student_group="All Students"` (legacy is all-students only). |
| `fetch_spr_grad_pathways()` | 2018-2022, 2024 | Legacy column names harmonized (`ELA/Math->subject` uppercased; `PARCCAssessment`/`SubstituteCompetency`/`PortfolioAppealsProcess`/`AlternateReqIEP` -> redesigned names; COVID waiver column dropped). **Absent in SY2016-17 and SY2022-23** (those years error). |
| `fetch_sgp(type="trends")` | 2018, 2019, 2023, 2024 | The redesigned `StudentGrowthTrends` (subgroup × wide ELA/Math) succeeds the legacy **`StudentGrowth`** sheet (long-by-subject). Pivot ELA/Math wide; subgroup is the column before `subject` (the school file mislabels it `SchoolYear`). Legacy `MetTarget` kept in `ela_met_target`/`math_met_target`; `*_category` is `NA` (the growth labels are new in 2025). |
| `fetch_sgp(type="by_grade")` | 2018, 2019, 2023, 2024 | Legacy `StudentGrowthByGrade` (capital B); median column name churns (`mSGP`/`mSGP_School`); growth category (`Level`) only from 2023, else `NA`. |
| `fetch_sgp(type="by_performance_level")` | 2023, 2024 | Same sheet name; clean `mSGP`+`Level` map. **2017-2019 stays gated** — that sheet is a Low/Typical/High growth-band percentage distribution, a different statistic, not a median SGP. |

**COVID gap (all SGP types):** SY2019-20 through SY2021-22 (end_year 2020-2022) carry no Student Growth Percentiles (no spring 2020/2021 statewide testing; the legacy `StudentGrowthTrends` sheet in those databases only re-displays stale pre-COVID years). Those years error rather than return stale or 0-row data. SY2016-17 is excluded from `trends`/`by_grade` (no county/district name columns).

**Confirmed 2025-only (gate retained):** `fetch_spr_essa_targets` (×6), `fetch_spr_accountability_summative`, `fetch_spr_tsi`, `fetch_spr_essa_status_counts`, `fetch_spr_staff_demo_subject`, `fetch_spr_teacher_exp_subject` — their sheets are absent from every 2017-2024 workbook. `fetch_spr_admin_experience` exists earlier but across four incompatible layouts (granularity + column-name churn); `fetch_spr_educator_equity` exists earlier but on a different scale (legacy percentages vs 2025 proportions) and without the `Classes Included` dimension. Forcing either into the 2025 shape would mis-scale or fabricate, so both stay gated.

The remaining uncovered sheets below are Tier 3 (lower priority) plus a few NEW items not yet picked up (school environment, Seal of Biliteracy detail, college/career breakdowns, and the redundant-low SPR mirror views).

---

## Domain Tables

### Enrollment

| Sheet name | DB | What it holds | Status | Proposed fetcher |
|---|---|---|---|---|
| EnrollmentTrendsbyGrade | both | Multi-year enrollment counts by grade level | NEW-med | `fetch_spr_enrollment_grade()` |
| EnrollmentTrendsByStudentGroup | both | Multi-year enrollment counts by student subgroup | NEW-med | `fetch_spr_enrollment_subgroup()` |
| EnrollmentByRacialEthnicGroup | both | Single-year racial/ethnic breakdown | NEW-med | `fetch_spr_enrollment_race()` |
| PreKAndK-FullDayHalfDay | both | Pre-K and K enrollment by full-day / half-day status | NEW-med | `fetch_spr_prek_k()` |
| EnrollmentTrendsFullSharedTime | both | Full-time vs. shared-time enrollment trends | NEW-med | `fetch_spr_enrollment_shared_time()` |
| EnrollmentByHomeLanguage | both | Enrollment counts grouped by home language | NEW-high | `fetch_spr_home_language()` |

**Note:** These sheets provide an SPR-integrated view of enrollment. The package already has standalone enrollment fetchers (`fetch_enr()`), but `EnrollmentByHomeLanguage` is new data not available through any existing fetcher.

---

### Student Growth (SGP)

| Sheet name | DB | What it holds | Status | Proposed fetcher |
|---|---|---|---|---|
| StudentGrowthTrends | both | Multi-year Student Growth Percentile trends | NEW-high | `fetch_spr_sgp_trends()` |
| StudentGrowthbyGrade | both | SGP broken out by grade level | NEW-high | `fetch_spr_sgp_grade()` |
| StudentGrowthByPerformLevel | both | SGP broken out by prior performance level | NEW-high | `fetch_spr_sgp_perf_level()` |

**Note:** Implemented as `fetch_sgp(type = "trends" | "by_grade" | "by_performance_level")` (PR #247 + backfill — see "Already Implemented" above). These three sheets are the only source of SGP data in the SPR databases.

---

### Assessment / Proficiency

| Sheet name | DB | What it holds | Status | Proposed fetcher |
|---|---|---|---|---|
| ELAParticipationPerformance | both | NJSLA ELA participation rate and proficiency | redundant-low | `fetch_spr_ela()` |
| MathParticipationPerformance | both | NJSLA Math participation rate and proficiency | redundant-low | `fetch_spr_math()` |
| ELAPerformanceByTest | both | ELA proficiency sliced by assessment variant | ✅ done | `fetch_spr_proficiency_by_test(subject="ela")` (2017-2019, 2022-2025) |
| MathPerformancebyTest | both | Math proficiency sliced by assessment variant | ✅ done | `fetch_spr_proficiency_by_test(subject="math")` (2017-2019, 2022-2025) |
| DLMTrends | both | Dynamic Learning Maps alternate assessment trends | NEW-med (Bucket B) | `fetch_dlm()` — build from richer standalone source, not this SPR sheet |
| ACCESSPartPerform | both | ACCESS for ELLs participation and performance | redundant-low | `fetch_spr_access()` |
| ProgressTowardELP | both | Progress toward English Language Proficiency goals | ✅ done | `fetch_spr_elp_progress()` (2025) |
| OverallNJSLAScience | both | NJSLA Science overall proficiency | redundant-low | `fetch_spr_science()` |
| NJSLASciencebyGradeTrends | both | NJSLA Science proficiency by grade over time | ✅ done | `fetch_spr_science_grade()` (2019, 2021-2025) |
| NJGPA | both | NJ Graduation Proficiency Assessment results | redundant-low | `fetch_spr_njgpa()` |
| NAEP | district/state only | NAEP 4th/8th grade reading and math scores | NEW-high | `fetch_spr_naep()` |

**Redundant-low explanation:** ELA/Math/Science NJSLA proficiency is already available via `fetch_parcc()`. ACCESS is available via `fetch_access()`. NJGPA is available via `fetch_njgpa()`. The SPR versions are lower priority because the standalone fetchers provide the same underlying data. `ELAPerformanceByTest` and `MathPerformancebyTest` break out results by test variant (regular vs. alternate), which the standalone fetchers do not expose — those are treated as NEW-med.

---

### College / Career

| Sheet name | DB | What it holds | Status | Proposed fetcher |
|---|---|---|---|---|
| AP_IB_Dual_Participation | both | AP, IB, and dual-enrollment participation rates | break (2025) | *(fix in progress — malformed at school level)* |
| AP_IB_Dual_PartStudentGroup | both | AP/IB/dual participation by student group | NEW-med | `fetch_spr_ap_ib_subgroup()` |
| ABIBCoursesOffered | both | Count of AP/IB courses offered | NEW-med | `fetch_spr_courses_offered()` |
| CTEParticipation | both | CTE program participation (overall) | NEW-med | `fetch_spr_cte()` |
| SLE_Participation | both | Student Learning Expectations participation | NEW-med | `fetch_spr_sle()` |
| IndustryValuedCredentials | both | Industry-valued credentials earned (overall) | NEW-med | `fetch_spr_ivc()` |

**Note on AP_IB_Dual_Participation:** `fetch_ap_participation()` intentionally stops (errors) for end_year 2025 because the school-level sheet is malformed in the 2024-25 database (pre-2025 works). This remains open — the malformation is at the source. Once NJ DOE reissues a clean sheet (or a row-level workaround is written), this moves to "covered."

**Note on CTE / Industry-Valued Credentials:** Overall CTE participation and industry-valued credentials are already accessible via the standalone `fetch_cte_participation()` (reads `CTEParticipationByStudentGroup`) and `fetch_industry_credentials()` (reads `IndustryValuedCredentialsEarned` / `IndustryValuedCredClusters`). The plain `CTEParticipation` / `IndustryValuedCredentials` summary rows above are lower priority given that coverage.

---

### Seal of Biliteracy

| Sheet name | DB | What it holds | Status | Proposed fetcher |
|---|---|---|---|---|
| SealofBiliteracy_Summary | both | Overall Seal of Biliteracy award counts | NEW-med | `fetch_spr_biliteracy_summary()` |
| SealofBiliteracy_Trends | both | Multi-year Seal of Biliteracy trends | NEW-med | `fetch_spr_biliteracy_trends()` |
| SealofBiliteracy_StudentGroup | both | Seal of Biliteracy awards by student group | NEW-med | `fetch_spr_biliteracy_subgroup()` |

**Note:** The existing `fetch_spr_data("SealofBiliteracy_Language", ...)` covers the language-breakdown sheet. These three sheets are distinct views not yet wired up.

---

### Graduation

| Sheet name | DB | What it holds | Status | Proposed fetcher |
|---|---|---|---|---|
| GraduationRateTrends | both | Multi-year 4-year graduation rate trends | redundant-low | `fetch_spr_grad_trends()` |
| GraduationCohortProfile | both | Cohort 4/5/6-year outcomes by subgroup | ✅ done | `fetch_spr_grad_cohort()` (2020-2025) |
| FederalGraduationRates | both | Federally reported graduation rates (ESSA ACGR) | ✅ done | `fetch_spr_fed_grad()` (2021-2025) |
| GraduationPathways | both | Count of graduates by pathway type | NEW-high | `fetch_spr_grad_pathways()` |

**Redundant-low explanation:** Multi-year graduation rate trends are already available via `fetch_grad_rate()` and `fetch_6yr_grad_rate()`. `GraduationPathways` is genuinely new — pathway breakdown is not available through any existing fetcher.

---

### Discipline / Safety

| Sheet name | DB | What it holds | Status | Proposed fetcher |
|---|---|---|---|---|
| PoliceNotifications | both | Count of police notifications by school/district | ✅ done | `fetch_police_notifications()` (2018-2025) |
| HIBInvestigations | both | Harassment, intimidation, bullying investigation counts | ✅ done | `fetch_hib_investigations()` (2018-2025) |
| PoliceNotificationsGroupGrade (alias: PoliceNotificationByStuGroup in 2024) | both | Police notifications by student group and grade | ✅ done | `fetch_police_notifications_detail()` (2024-2025) |
| ArrestsStudentGroupGrade (alias: StuArrestbyStudentGroupGradelev in 2024) | both | Arrests by student group and grade | ✅ done | `fetch_arrests()` (2024-2025) |

**Note on `fetch_police_notifications()` / `fetch_hib_investigations()`:** Both
sheets are present in the SPR databases for end_year 2018-2025 (absent from
SY2016-17). The 2024-25 redesign rebranded the HIB column on
`PoliceNotifications` from `harassment_intimidation_bullying_hib` to `hib` and
added a single-value `school_year` column to both sheets; the fetchers
harmonize the legacy and redesigned layouts. `HIBInvestigations` is
long-format with eight HIB-nature categories per entity.

**Note on `fetch_police_notifications_detail()` / `fetch_arrests()`:** Both
detail sheets first appear in SY2023-24 (end_year 2024) under legacy aliases
(`PoliceNotificationByStuGroup`, `StuArrestbyStudentGroupGradelev`); the
2024-25 redesign renamed them to `PoliceNotificationsGroupGrade` /
`ArrestsStudentGroupGrade` and added a `school_year` column. Each row is one
entity x one label, where the label is either a subgroup (e.g. "Black or
African American") or a grade ("Grade 9", "Grade KG"). The fetchers preserve
the raw label as `student_group_grade` and additionally split it into
normalized `subgroup` + `grade_level` columns ("PK", "K", "01"-"12", or
"TOTAL" for subgroup marginals). The 2024-25 `ArrestsStudentGroupGrade`
sheet ships with column headers `Police_Count`, `Violent_Count`, etc. — a
copy-paste from the police-notifications detail sheet — but the values are
arrest counts; `fetch_arrests()` renames those columns to the canonical
`arrested_*` prefix used by the 2024 sheet so the public API is consistent
across years. Pair with `calc_discipline_rates_by_subgroup(..., by_grade =
TRUE)` for disproportionality analysis at the (entity x grade) level.

---

### School Environment (school only)

| Sheet name | DB | What it holds | Status | Proposed fetcher |
|---|---|---|---|---|
| SchoolDay | school only | Length of school day in minutes | NEW-high | `fetch_spr_school_day()` |
| DeviceRatios | school only | Student-to-device ratio by device type | NEW-high | `fetch_spr_device_ratios()` |

---

### Staff

| Sheet name | DB | What it holds | Status | Proposed fetcher |
|---|---|---|---|---|
| AdministratorsExperience | both | Administrator experience distribution | ✅ done | `fetch_spr_admin_experience()` |
| StaffCounts | both | Counts of staff by role | ✅ done | `fetch_spr_staff_counts()` |
| TeachersAdminsDemoSubjectArea | both | Teacher/admin demographics by subject area | ✅ done | `fetch_spr_staff_demo_subject()` |
| TeachersAdminsEducation | both | Teacher/admin education level distribution | ✅ done | `fetch_spr_staff_education()` |
| TeachersAdminsOneYearRetention | both | One-year retention rates for teachers and admins | ✅ done | `fetch_spr_staff_retention()` |
| TeacherExperienceSubjArea | both | Teacher experience broken out by subject area | ✅ done | `fetch_spr_teacher_exp_subject()` |
| StatewideEducatorEquity | district/state only | Statewide educator equity metrics | ✅ done | `fetch_spr_educator_equity()` |

**All Staff sheets are implemented** (PR #252 + backfill — see "Already Implemented"). The proposed fetcher names above became the actual function names. No staff sheets remain uncovered.

---

### Accountability

| Sheet name | DB | What it holds | Status | Proposed fetcher |
|---|---|---|---|---|
| AccountabilitySummative | school only | Summative ESSA accountability score/rating | NEW-high | `fetch_spr_accountability_summative()` |
| TSIIdentification | school only | Targeted Support and Improvement identification status | NEW-high | `fetch_spr_tsi()` |
| ESSAAccountabilityStatusList | district/state only | List of schools by ESSA status within district | NEW-high | `fetch_spr_essa_status_list()` |
| ESSAAccountabilityStatusCounts | district/state only | Count of schools at each ESSA status level | NEW-high | `fetch_spr_essa_status_counts()` |
| ProficiencyTargets | both | Long-term ESSA proficiency targets vs. actuals | NEW-high | `fetch_spr_proficiency_targets()` |
| GrowthTargets | both | Long-term ESSA growth targets vs. actuals | NEW-high | `fetch_spr_growth_targets()` |
| GraduationTargets | both | Long-term ESSA graduation rate targets vs. actuals | NEW-high | `fetch_spr_graduation_targets()` |
| ProgresstowardELPTargets | both | Long-term ESSA ELP progress targets vs. actuals | NEW-high | `fetch_spr_elp_targets()` |
| ChronicAbsenteeismTargets | both | Long-term ESSA chronic absenteeism targets vs. actuals | NEW-high | `fetch_spr_absenteeism_targets()` |
| HSPersistenceTargets | both | Long-term ESSA HS persistence targets vs. actuals | NEW-high | `fetch_spr_hs_persistence_targets()` |
| ChronicAbsenteeismTrends | both | Multi-year chronic absenteeism trend (SPR view) | redundant-low | `fetch_spr_absenteeism_trends()` |

**Redundant-low explanation:** `ChronicAbsenteeismTrends` duplicates what `fetch_absence()` provides via a standalone fetcher.

**Note on ESSAAccountabilityStatusList/Counts:** Covered. `fetch_essa_status(2025, level="district")` now routes to `ESSAAccountabilityStatusList` — the 2024-25 redesign replaced the prior district-level `ESSAAccountabilityStatus` sheet with this per-entity analogue (identical 12-column layout, including `CategoryOfIdentification`); pre-2025 district behavior is unchanged. `ESSAAccountabilityStatusCounts` is covered by `fetch_spr_essa_status_counts()` (see "Already Implemented").

---

## Known Breaks for end_year = 2025

| Fetcher | Sheet affected | Symptom | Fix status |
|---|---|---|---|
| `fetch_ap_participation(2025)` | `AP_IB_Dual_Participation` malformed at school level | Intentionally stops (errors) for end_year 2025 | Open — pre-2025 works; the 2024-25 school sheet is malformed at the source |

**Resolved:** `fetch_essa_status(2025, level="district")` — fixed. It now routes 2025 district requests to `ESSAAccountabilityStatusList` (the redesign's per-entity replacement for the district `ESSAAccountabilityStatus` sheet). No longer a break.

---

## Prioritized Shortlist

Candidates that are genuinely new data (no standalone fetcher equivalent) and have broad policy relevance:

### Tier 1 — Implement first ✅ DONE (see "Already Implemented" above)

1. **StudentGrowthTrends / StudentGrowthbyGrade / StudentGrowthByPerformLevel** — SGP is entirely absent from the package. Three related sheets; ship as one `fetch_spr_sgp()` family.
2. **AccountabilitySummative + TSIIdentification** (school only) — ESSA summative score and TSI flags are central accountability outputs. High demand from researchers.
3. **ESSAAccountabilityStatusList + ESSAAccountabilityStatusCounts** (district/state only) — complement to school-level ESSA status; needed once the 2025 break is fixed.
4. **ProficiencyTargets / GrowthTargets / GraduationTargets / ProgresstowardELPTargets / ChronicAbsenteeismTargets / HSPersistenceTargets** — the full ESSA long-term-goals target suite. Six sheets, same structure; one `fetch_spr_essa_targets(indicator=)` interface would cover all.
5. **HIBInvestigations** — HIB data is high-profile in NJ; currently only removal/incident data is covered.
6. **PoliceNotifications + PoliceNotificationsGroupGrade + ArrestsStudentGroupGrade** — safety data not available anywhere else in the package.

### Tier 2 — Mostly done (items 7-10 implemented; see "Already Implemented" above)

> Still open: **#11 SchoolDay + DeviceRatios** (school-only environment data) is not yet implemented.

7. **NAEP** (district/state only) — only source of NAEP data in the package; limited to district/state level.
8. **GraduationPathways** — pathway breakdown (diploma type, alternative routes) not in existing grad fetchers.
9. **EnrollmentByHomeLanguage** — home language breakdown not in `fetch_enr()`.
10. **TeachersAdminsOneYearRetention + StatewideEducatorEquity** — retention and equity metrics; higher policy salience than other staff sheets.
11. **SchoolDay + DeviceRatios** (school only) — unique infrastructure data; no existing equivalent.

### Tier 3 — Lower priority

- ~~Remaining staff sheets~~ — **done** (all 7 staff sheets implemented in PR #252 + backfill)
- Enrollment SPR views (redundant with `fetch_enr()` but useful for consistent SPR-sourced pipelines)
- Seal of Biliteracy Summary/Trends/StudentGroup (language sheet already covered via `fetch_biliteracy_seal()`; these add breadth)
- College/career additions (AP_IB_Dual_PartStudentGroup, ABIBCoursesOffered, SLE_Participation) — note: overall CTE participation and industry-valued credentials are already covered by `fetch_cte_participation()` / `fetch_industry_credentials()`
- ~~Assessment SPR views (ELAPerformanceByTest / MathPerformancebyTest test-variant breakdown; NJSLASciencebyGradeTrends; ProgressTowardELP)~~ — **done** (Bucket A: `fetch_spr_proficiency_by_test()`, `fetch_spr_science_grade()`, `fetch_spr_elp_progress()`)
- ~~GraduationCohortProfile / FederalGraduationRates~~ — **done** (Bucket A: `fetch_spr_grad_cohort()`, `fetch_spr_fed_grad()`)
- `DLMTrends` (Dynamic Learning Maps alternate assessment) — deferred to Bucket B as a standalone `fetch_dlm()` (the standalone DLM file is richer than the SPR sheet); not built here
