# Data Category Taxonomy

Canonical taxonomy of school data categories published by state Departments of Education. njschooldata is the mothership package and covers the most categories of any package in the [state-schooldata](https://github.com/almartin82/state-schooldata) project.

## Tier 1 -- Core (every state DOE publishes this)

| # | Category | Function(s) | Years | Details |
|---|----------|-------------|-------|---------|
| 1 | **Enrollment & Demographics** | `fetch_enr()` | 2000-2025 | State, county, district, school. Race, gender, FRPL, LEP, migrant. Wide and tidy formats |
| 2 | **Assessments / Test Scores** | `fetch_parcc()`, `fetch_njask()`, `fetch_njgpa()`, `fetch_gepa()`, `fetch_hspa()` | 2004-2024 | NJSLA (2019+), PARCC (2015-2018), NJASK (2004-2014), HSPA, GEPA. ELA, Math, Science |
| 3 | **Graduation Rates** | `fetch_grad_rate()`, `fetch_grad_count()`, `fetch_6yr_grad_rate()` | 2011-2024 | 4-yr and 6-yr ACGR, graduation counts. District and school level |
| 4 | **School/District Directory** | `get_school_directory()`, `get_district_directory()` | Current | Names, IDs, addresses, school type, grade span |

## Tier 2 -- ESSA-Required (federally mandated reporting)

| # | Category | Function(s) | Years | Details |
|---|----------|-------------|-------|---------|
| 5 | Per-Pupil Expenditure | -- | -- | Not yet available |
| 6 | **Accountability Ratings** | `fetch_essa_status()`, `fetch_essa_progress()` | 2018+ | CSI/TSI lists, ESSA indicators, progress tracking |
| 7 | **Chronic Absenteeism** | `fetch_chronic_absenteeism()`, `fetch_days_absent()` | 2017-2024 | By grade, by demographic. Absenteeism rates |
| 8 | **English Learner Progress** | `fetch_access()`, `fetch_all_access()` | 2022-2024 | WIDA ACCESS for ELLs assessment results |
| 9 | **Special Education** | `fetch_sped()` | 2024+ | Classification rates by disability category |

## Tier 3 -- Commonly Published (most state DOEs have this)

| # | Category | Function(s) | Years | Details |
|---|----------|-------------|-------|---------|
| 10 | **Discipline** | `fetch_disciplinary_removals()`, `fetch_violence_vandalism_hib()` | Available | Suspensions, expulsions, HIB incidents. By demographic |
| 11 | **Teacher/Staff Data** | `fetch_staff_demographics()`, `fetch_staff_ratios()`, `fetch_teacher_experience()` | Available | Demographics, experience, student-teacher ratios |
| 12 | **College-Going Rates** | `fetch_postsecondary()` | Available | Postsecondary enrollment within 16 months |
| 14 | **SAT/ACT Scores** | `fetch_sat_participation()`, `fetch_sat_performance()` | Available | Participation rates, average scores |
| 15 | **AP/IB Participation** | `fetch_ap_participation()`, `fetch_ap_performance()`, `fetch_ib_participation()` | Available | Course enrollment, exam pass rates |
| 16 | **CTE (Career/Technical Ed)** | `fetch_cte_participation()`, `fetch_industry_credentials()`, `fetch_apprenticeship_data()` | Available | Career pathways, credentials, work-based learning |

## Tier 4 -- Rich Data

| # | Category | Function(s) | Years | Details |
|---|----------|-------------|-------|---------|
| 17 | **Course Enrollment** | `fetch_math_course_enrollment()`, `fetch_science_course_enrollment()`, `fetch_cs_enrollment()`, `fetch_arts_enrollment()`, `fetch_world_language_enrollment()` | Available | Math, science, CS, arts, world languages |

---

For the full cross-state taxonomy covering all 30 categories, see [DATA-CATEGORY-TAXONOMY.md](https://github.com/almartin82/state-schooldata/blob/main/docs/DATA-CATEGORY-TAXONOMY.md) in the parent project.
