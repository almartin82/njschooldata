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

**Note:** Student Growth Percentiles are entirely absent from the package. These three sheets are the only source of SGP data in the SPR databases.

---

### Assessment / Proficiency

| Sheet name | DB | What it holds | Status | Proposed fetcher |
|---|---|---|---|---|
| ELAParticipationPerformance | both | NJSLA ELA participation rate and proficiency | redundant-low | `fetch_spr_ela()` |
| MathParticipationPerformance | both | NJSLA Math participation rate and proficiency | redundant-low | `fetch_spr_math()` |
| ELAPerformanceByTest | both | ELA proficiency sliced by assessment variant | NEW-med | `fetch_spr_ela_by_test()` |
| MathPerformancebyTest | both | Math proficiency sliced by assessment variant | NEW-med | `fetch_spr_math_by_test()` |
| DLMTrends | both | Dynamic Learning Maps alternate assessment trends | NEW-med | `fetch_spr_dlm()` |
| ACCESSPartPerform | both | ACCESS for ELLs participation and performance | redundant-low | `fetch_spr_access()` |
| ProgressTowardELP | both | Progress toward English Language Proficiency goals | NEW-med | `fetch_spr_elp_progress()` |
| OverallNJSLAScience | both | NJSLA Science overall proficiency | redundant-low | `fetch_spr_science()` |
| NJSLASciencebyGradeTrends | both | NJSLA Science proficiency by grade over time | NEW-med | `fetch_spr_science_grade()` |
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

**Note on AP_IB_Dual_Participation:** `fetch_ap_participation()` intentionally stops for 2025 because the school-level sheet is malformed in the 2024-25 database. A fix is tracked in PR fix/spr-redesign-followups-2025. Once fixed, this sheet moves to "covered."

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
| GraduationCohortProfile | both | Cohort demographics and outcomes | NEW-med | `fetch_spr_grad_cohort()` |
| FederalGraduationRates | both | Federally reported graduation rates (ESSA) | NEW-med | `fetch_spr_fed_grad()` |
| GraduationPathways | both | Count of graduates by pathway type | NEW-high | `fetch_spr_grad_pathways()` |

**Redundant-low explanation:** Multi-year graduation rate trends are already available via `fetch_grad_rate()` and `fetch_6yr_grad_rate()`. `GraduationPathways` is genuinely new — pathway breakdown is not available through any existing fetcher.

---

### Discipline / Safety

| Sheet name | DB | What it holds | Status | Proposed fetcher |
|---|---|---|---|---|
| PoliceNotifications | both | Count of police notifications by school/district | NEW-high | `fetch_spr_police_notifications()` |
| HIBInvestigations | both | Harassment, intimidation, bullying investigation counts | NEW-high | `fetch_spr_hib()` |
| PoliceNotificationsGroupGrade | both | Police notifications by student group and grade | NEW-high | `fetch_spr_police_notifications_detail()` |
| ArrestsStudentGroupGrade | both | Arrests by student group and grade | NEW-high | `fetch_spr_arrests()` |

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
| AdministratorsExperience | both | Administrator experience distribution | NEW-med | `fetch_spr_admin_experience()` |
| StaffCounts | both | Counts of staff by role | NEW-med | `fetch_spr_staff_counts()` |
| TeachersAdminsDemoSubjectArea | both | Teacher/admin demographics by subject area | NEW-med | `fetch_spr_staff_demo_subject()` |
| TeachersAdminsEducation | both | Teacher/admin education level distribution | NEW-med | `fetch_spr_staff_education()` |
| TeachersAdminsOneYearRetention | both | One-year retention rates for teachers and admins | NEW-high | `fetch_spr_staff_retention()` |
| TeacherExperienceSubjArea | both | Teacher experience broken out by subject area | NEW-med | `fetch_spr_teacher_exp_subject()` |
| StatewideEducatorEquity | district/state only | Statewide educator equity metrics | NEW-high | `fetch_spr_educator_equity()` |

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

**Note on ESSAAccountabilityStatusList/Counts:** `fetch_essa_status(2025, level="district")` is currently broken because these sheets replaced the prior district-level sheet. A fix is tracked in PR fix/spr-redesign-followups-2025. Once fixed, these two sheets will be covered.

---

## Known Breaks for end_year = 2025

| Fetcher | Sheet affected | Symptom | Fix status |
|---|---|---|---|
| `fetch_essa_status(2025, level="district")` | `ESSAAccountabilityStatusList` / `ESSAAccountabilityStatusCounts` replaced prior sheet | Error / wrong data | In progress — PR fix/spr-redesign-followups-2025 |
| `fetch_ap_participation(2025)` | `AP_IB_Dual_Participation` malformed at school level | Intentionally returns NA / stops | In progress — PR fix/spr-redesign-followups-2025 |

---

## Prioritized Shortlist

Candidates that are genuinely new data (no standalone fetcher equivalent) and have broad policy relevance:

### Tier 1 — Implement first

1. **StudentGrowthTrends / StudentGrowthbyGrade / StudentGrowthByPerformLevel** — SGP is entirely absent from the package. Three related sheets; ship as one `fetch_spr_sgp()` family.
2. **AccountabilitySummative + TSIIdentification** (school only) — ESSA summative score and TSI flags are central accountability outputs. High demand from researchers.
3. **ESSAAccountabilityStatusList + ESSAAccountabilityStatusCounts** (district/state only) — complement to school-level ESSA status; needed once the 2025 break is fixed.
4. **ProficiencyTargets / GrowthTargets / GraduationTargets / ProgresstowardELPTargets / ChronicAbsenteeismTargets / HSPersistenceTargets** — the full ESSA long-term-goals target suite. Six sheets, same structure; one `fetch_spr_essa_targets(indicator=)` interface would cover all.
5. **HIBInvestigations** — HIB data is high-profile in NJ; currently only removal/incident data is covered.
6. **PoliceNotifications + PoliceNotificationsGroupGrade + ArrestsStudentGroupGrade** — safety data not available anywhere else in the package.

### Tier 2 — Implement next

7. **NAEP** (district/state only) — only source of NAEP data in the package; limited to district/state level.
8. **GraduationPathways** — pathway breakdown (diploma type, alternative routes) not in existing grad fetchers.
9. **EnrollmentByHomeLanguage** — home language breakdown not in `fetch_enr()`.
10. **TeachersAdminsOneYearRetention + StatewideEducatorEquity** — retention and equity metrics; higher policy salience than other staff sheets.
11. **SchoolDay + DeviceRatios** (school only) — unique infrastructure data; no existing equivalent.

### Tier 3 — Lower priority

- Remaining staff sheets (AdministratorsExperience, StaffCounts, TeachersAdminsDemoSubjectArea, TeachersAdminsEducation, TeacherExperienceSubjArea)
- Enrollment SPR views (redundant with `fetch_enr()` but useful for consistent SPR-sourced pipelines)
- Seal of Biliteracy Summary/Trends/StudentGroup (language sheet already covered; these add breadth)
- College/career additions (AP_IB_Dual_PartStudentGroup, ABIBCoursesOffered, CTEParticipation, SLE_Participation, IndustryValuedCredentials)
- Assessment SPR views marked redundant-low (ELAPerformanceByTest / MathPerformancebyTest have some new value via test-variant breakdown)
