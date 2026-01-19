# njschooldata TODO - SPR Database Enhancement Opportunities

Generated: 2026-01-04

## Overview

The NJ DOE School Performance Reports (SPR) databases contain **63
sheets of data** per year (2017-18 to 2023-24), but njschooldata
currently extracts from only ~5 of them. This document organizes the
remaining untapped data sources into actionable tasks.

------------------------------------------------------------------------

## 🚀 High Priority - Core Functionality Gaps

### 1. Generic SPR Data Extractor

**Goal**: Create `fetch_spr_data(sheet_name, year, level)` function
**Impact**: Enables access to all 63 SPR sheets without writing custom
extractors **Sheets unlocked**: All 63 sheets

**Tasks**: - \[ \] Create `R/fetch_spr.R` with generic extractor
function - \[ \] Map sheet names across years (some names change) - \[
\] Handle varying column structures by year - \[ \] Add documentation
for each sheet type - \[ \] Write tests for multiple sheet types - \[ \]
Update `_pkgdown.yml` with new reference section

------------------------------------------------------------------------

## 📊 High Priority - Valuable Untapped Data

### 2. Chronic Absenteeism Module

**Goal**: Extract and analyze chronic absenteeism data **Sheets**:
`ChronicAbsenteeism`, `ChronicAbsenteeismByGrade`, `DaysAbsent`
**Years**: 2017-18 to 2023-24

**Value**: Major accountability indicator; high policy relevance

**Functions to create**: - \[ \]
`fetch_chronic_absenteeism(year, level = "school")` - \[ \]
`fetch_absenteeism_by_grade(year, level = "school")` - \[ \]
`fetch_days_absent(year, level = "school")` - \[ \]
`enrich_absenteeism_demographics(df)` - join with enrollment - \[ \]
`calc_attendance_rate_trends(df_list)` - multi-year trend analysis

**Aggregations**: - \[ \] District-level aggregations - \[ \]
State-level aggregations - \[ \] By subgroup (racial, economic, ELL,
SPED)

------------------------------------------------------------------------

### 3. College & Career Readiness Module

**Goal**: Comprehensive college/career readiness indicators
**Sheets**: - `PSAT-SAT-ACTParticipation`, `PSAT-SAT-ACTPerformance` -
`APIBCourseworkPartPerf`, `APIBDualEnrPartByStudentGrp`,
`APIBCoursesOffered` - `CTE_SLEParticipation`,
`CTEParticipationByStudentGroup` - `IndustryValuedCredentialsEarned`,
`WorkbasedLearningByCareerClust` - `Apprenticeship`, `SealofBiliteracy`

**Value**: College access indicators; CTE pathways; 21st century skills

**Functions to create**: - \[ \]
`fetch_sat_participation(year, level = "school")` - \[ \]
`fetch_sat_performance(year, level = "school")` - \[ \]
`fetch_psat_participation(year, level = "school")` - \[ \]
`fetch_ap_participation(year, level = "school")` - \[ \]
`fetch_ap_performance(year, level = "school")` - \[ \]
`fetch_ib_participation(year, level = "school")` - \[ \]
`fetch_cte_participation(year, level = "school")` - \[ \]
`fetch_industry_credentials(year, level = "school")` - \[ \]
`fetch_work_based_learning(year, level = "school")` - \[ \]
`fetch_apprenticeship_data(year, level = "school")` - \[ \]
`fetch_biliteracy_seal(year, level = "school")`

**Enrichment**: - \[ \] `enrich_sat_scores_with_enrollment()` - add
subgroup counts - \[ \] `calc_college_readiness_index()` - composite
index

------------------------------------------------------------------------

### 4. Discipline & Climate Module

**Goal**: School climate and discipline data **Sheets**: -
`ViolenceVandalismHIBSubstanceOf` - `PoliceNotifications` -
`HIBInvestigations` - `DisciplinaryRemovals`

**Value**: School safety; disproportionality analysis; climate
indicators

**Functions to create**: - \[ \]
`fetch_violence_vandalism(year, level = "school")` - \[ \]
`fetch_police_notifications(year, level = "school")` - \[ \]
`fetch_hib_investigations(year, level = "school")` - \[ \]
`fetch_disciplinary_removals(year, level = "school")`

**Analysis**: - \[ \]
[`calc_discipline_rates_by_subgroup()`](https://almartin82.github.io/njschooldata/reference/calc_discipline_rates_by_subgroup.md) -
disproportionality analysis - \[ \]
[`compare_discipline_across_years()`](https://almartin82.github.io/njschooldata/reference/compare_discipline_across_years.md) -
trend analysis

------------------------------------------------------------------------

### 5. Staff Demographics & Experience Module

**Goal**: Teacher and administrator quality indicators **Sheets**: -
`TeachersExperience`, `AdministratorsExperience` - `StaffCounts`,
`StudentToStaffRatios` - `TeachersAdminsDemographics` -
`TeachersAdminsLevelOfEducation` - `TeachersAdminsOneYearRetention` -
`TeachersBySubjectArea`

**Value**: Teacher quality; staff diversity; retention; resource
allocation

**Functions to create**: - \[ \]
`fetch_teacher_experience(year, level = "school")` - \[ \]
`fetch_admin_experience(year, level = "school")` - \[ \]
`fetch_staff_counts(year, level = "school")` - \[ \]
`fetch_staff_demographics(year, level = "school")` - \[ \]
`fetch_staff_education(year, level = "school")` - \[ \]
`fetch_staff_retention(year, level = "school")` - \[ \]
`fetch_teachers_by_subject(year, level = "school")`

**Analysis**: - \[ \]
[`calc_student_staff_ratio()`](https://almartin82.github.io/njschooldata/reference/calc_student_staff_ratio.md) -
aggregate ratios - \[ \]
[`calc_staff_diversity_metrics()`](https://almartin82.github.io/njschooldata/reference/calc_staff_diversity_metrics.md) -
diversity indices - \[ \]
[`analyze_retention_patterns()`](https://almartin82.github.io/njschooldata/reference/analyze_retention_patterns.md) -
retention by subgroup

------------------------------------------------------------------------

### 6. Course Enrollment Patterns Module

**Goal**: Access to rigorous coursework indicators **Sheets**: -
`MathCourseParticipation` - `ScienceCourseParticipation` -
`SocStudiesHistoryCourseParticip` - `WorldLanguagesCourseParticipati` -
`ComputerScienceCourseParticipat` - `VisualAndPerformingArts`

**Value**: Course access; equity; STEM pathways

**Functions to create**: - \[ \]
`fetch_math_course_enrollment(year, level = "school")` - \[ \]
`fetch_science_course_enrollment(year, level = "school")` - \[ \]
`fetch_social_studies_enrollment(year, level = "school")` - \[ \]
`fetch_world_language_enrollment(year, level = "school")` - \[ \]
`fetch_cs_enrollment(year, level = "school")` - \[ \]
`fetch_arts_enrollment(year, level = "school")`

**Analysis**: - \[ \]
[`calc_ap_access_rate()`](https://almartin82.github.io/njschooldata/reference/calc_ap_access_rate.md) -
% students with AP access - \[ \]
[`calc_stem_participation_rate()`](https://almartin82.github.io/njschooldata/reference/calc_stem_participation_rate.md) -
STEM course-taking - \[ \]
[`analyze_course_access_equity()`](https://almartin82.github.io/njschooldata/reference/analyze_course_access_equity.md) -
by subgroup

------------------------------------------------------------------------

## 📈 Medium Priority - Complementary Data

### 7. Accountability Status Module

**Goal**: ESSA accountability indicators **Sheets**:
`ESSAAccountabilityStatus`, `ESSAAccountabilityProgress`

**Functions to create**: - \[ \]
`fetch_essa_status(year, level = "school")` - \[ \]
`fetch_essa_progress(year, level = "school")` - \[ \]
[`identify_focus_schools()`](https://almartin82.github.io/njschooldata/reference/identify_focus_schools.md) -
flag schools needing support - \[ \]
[`track_essa_progress_over_time()`](https://almartin82.github.io/njschooldata/reference/track_essa_progress_over_time.md) -
improvement trajectories

------------------------------------------------------------------------

### 8. Dropout Rate Module

**Goal**: Complement graduation rate data with dropout rates **Sheets**:
`DropoutRateTrends`

**Functions to create**: - \[ \]
`fetch_dropout_rates(year, level = "school")` - \[ \]
`calc_dropout_to_graduation_ratio()` - \[ \]
`analyze_dropout_risk_factors()` - by subgroup

------------------------------------------------------------------------

### 9. Enhanced Assessment Data

**Goal**: Fill assessment data gaps **Sheets**: `NJSLAScience`,
`AlternateAssessmentParticipatio`, `EnglishLangParticipationPerform`

**Functions to create**: - \[ \]
`fetch_njsla_science(year, level = "school")` - from SPR - \[ \]
`fetch_alternate_assessment(year, level = "school")` - \[ \]
`fetch_ell_assessment_performance(year, level = "school")` - \[ \]
`enrich_assessment_with_growth()` - add growth percentiles

**Note**: Check if separate files exist for NJSLA Science outside SPR

------------------------------------------------------------------------

### 10. Enhanced Enrollment Data

**Goal**: Add enrollment dimensions not in main enrollment files
**Sheets**: - `EnrollmentTrendsbyGrade`,
`EnrollmentTrendsByStudentGroup` - `EnrollmentByRacialEthnicGroup` -
`PreKAndK-FullDayHalfDay` - `EnrollmentTrendsFullSharedTime` -
`EnrollmentByHomeLanguage`

**Functions to create**: - \[ \]
`fetch_enrollment_trends(year, level = "school")` - \[ \]
`fetch_racial_ethnic_enrollment(year, level = "school")` - \[ \]
`fetch_prek_detail(year, level = "school")` - \[ \]
`fetch_full_shared_time_enrollment(year, level = "school")` - \[ \]
`fetch_home_language_data(year, level = "school")`

------------------------------------------------------------------------

## 🔧 Lower Priority - Niche Data

### 11. School Resources & Schedule

**Sheets**: `SchoolDay`, `DeviceRatios`

**Functions**: - \[ \]
`fetch_school_day_length(year, level = "school")` - \[ \]
`fetch_device_ratios(year, level = "school")`

------------------------------------------------------------------------

### 12. Graduation Pathways

**Sheet**: `GraduationPathways`

**Functions**: - \[ \]
`fetch_graduation_pathways(year, level = "school")` - \[ \]
`analyze_alternate_pathway_usage()`

------------------------------------------------------------------------

### 13. Federal Graduation Rates

**Sheet**: `FederalGraduationRates`

**Functions**: - \[ \]
`fetch_federal_graduation_rates(year, level = "school")` - \[ \]
`compare_state_vs_federal_rates()`

------------------------------------------------------------------------

### 14. Narrative Data Extraction

**Sheet**: `Narrative`

**Functions**: - \[ \]
`fetch_school_narratives(year, level = "school")` - \[ \] Text analysis
of school self-descriptions

------------------------------------------------------------------------

## 🛠️ Infrastructure & Documentation Tasks

### 15. Update Documentation

Add SPR database section to main vignette

Create “SPR Data Dictionary” vignette

Update README with new capabilities

Add pkgdown reference section for SPR data

### 16. Improve Testing

Add integration tests for SPR extractors

Test cross-year compatibility (sheet name changes)

Add caching tests for large SPR files

Performance benchmarks for large data pulls

### 17. Data Quality Utilities

`validate_spr_data()` - check for missing values, inconsistencies

`compare_spr_years()` - identify structural changes

`document_spr_suppression_rules()` - track data suppression

### 18. Caching Improvements

Optimize caching for 23-80 MB SPR files

Add sheet-level caching option

Cache validation for SPR data

------------------------------------------------------------------------

## 🎯 Quick Wins (Easy, High Impact)

1.  Generic SPR extractor function - unlocks everything
2.  Chronic absenteeism - single sheet, high value
3.  SAT/ACT performance - already partially done (RC), just need SPR
    version
4.  Staff demographics - single sheet per metric
5.  AP/IB course offerings - complements existing AP/IB performance

------------------------------------------------------------------------

## 📋 Implementation Priority Order

### Phase 1 - Foundation (Weeks 1-2)

1.  Generic SPR extractor (#1)
2.  Chronic absenteeism (#2)
3.  SAT/ACT data (#3)

### Phase 2 - High Value Modules (Weeks 3-6)

4.  Discipline & climate (#4)
5.  Staff demographics (#5)
6.  Course enrollment (#6)

### Phase 3 - Completeness (Weeks 7-10)

7.  Accountability (#7)
8.  Dropout rates (#8)
9.  Enhanced assessment (#9)
10. Enhanced enrollment (#10)

### Phase 4 - Polish (Weeks 11-12)

11. Lower priority items
12. Documentation
13. Testing improvements

------------------------------------------------------------------------

## 🔍 Data Discovery Tasks

### 20. Investigate Additional Data Sources

Explore NJ DOE special education assessment data

Check for separate NJSLA Science files (not in SPR)

Investigate alternate assessment data sources

Look for CTE-specific data beyond SPR

Search for historical data archives (pre-2017)

------------------------------------------------------------------------

## 📝 Notes

- All SPR data: 2017-18 to 2023-24 (7 years)
- Files are 23-80 MB each (school-level) and 6-30 MB (district-level)
- Sheet names change slightly across years - need mapping
- Some sheets have inconsistent column structures - need robust cleaning
- Cache frequently - these are large files

------------------------------------------------------------------------

## 🤝 Contributing

Pick a task from this list and submit a PR! High priority tasks are
marked.

For questions, open an issue referencing the task number.
