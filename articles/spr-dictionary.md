# SPR Data Dictionary

``` r
library(njschooldata)
library(dplyr)
```

## School Performance Reports (SPR) Database

The New Jersey Department of Education’s School Performance Reports
(SPR) databases contain **63 sheets of data** per year (2017-18 to
2023-24), covering comprehensive school performance metrics.

This document provides a dictionary of available sheets and examples of
how to use them.

## Quick Start

### Using the Generic Extractor

``` r
# Get chronic absenteeism data
ca <- fetch_spr_data("ChronicAbsenteeism", 2024)

# Get teacher experience data
teachers <- fetch_spr_data("TeachersExperience", 2024)

# Get district-level data
grad_dist <- fetch_spr_data("6YrGraduationCohortProfile", 2024, level = "district")
```

### Using Convenience Functions

``` r
# Chronic absenteeism (convenience wrapper)
ca <- fetch_chronic_absenteeism(2024)

# By grade level
ca_grade <- fetch_absenteeism_by_grade(2024)

# Days absent statistics
days <- fetch_days_absent(2024)
```

## Available SPR Sheets

### Attendance & Discipline

| Sheet Name                        | Description                          | Years     |
|-----------------------------------|--------------------------------------|-----------|
| `ChronicAbsenteeism`              | Overall chronic absenteeism rates    | 2017-2024 |
| `ChronicAbsenteeismByGrade`       | Chronic absenteeism by grade level   | 2017-2024 |
| `DaysAbsent`                      | Days absent statistics (avg, median) | 2017-2024 |
| `ViolenceVandalismHIBSubstanceOf` | Incident counts                      | 2017-2024 |
| `HIBInvestigations`               | HIB investigation details            | 2017-2024 |
| `DisciplinaryRemovals`            | Suspension/expulsion data            | 2017-2024 |

### Staffing & Human Resources

| Sheet Name                       | Description                 | Years     |
|----------------------------------|-----------------------------|-----------|
| `TeachersExperience`             | Teacher experience levels   | 2017-2024 |
| `AdministratorsExperience`       | Administrator experience    | 2017-2024 |
| `StaffCounts`                    | Staff counts by category    | 2017-2024 |
| `StudentToStaffRatios`           | Student-to-staff ratios     | 2017-2024 |
| `TeachersAdminsDemographics`     | Demographics (race, gender) | 2017-2024 |
| `TeachersAdminsLevelOfEducation` | Educational attainment      | 2017-2024 |
| `TeachersAdminsOneYearRetention` | Staff retention rates       | 2017-2024 |
| `TeachersBySubjectArea`          | Teachers by subject         | 2017-2024 |

### College & Career Readiness

| Sheet Name                        | Description                       | Years     |
|-----------------------------------|-----------------------------------|-----------|
| `PSAT-SAT-ACTParticipation`       | SAT/ACT/PSAT participation rates  | 2017-2024 |
| `PSAT-SAT-ACTPerformance`         | SAT/ACT/PSAT score distributions  | 2017-2024 |
| `APIBCourseworkPartPerf`          | AP/IB performance (detailed)      | 2017-2024 |
| `APIBDualEnrPartByStudentGrp`     | AP/IB dual enrollment by subgroup | 2017-2024 |
| `APIBCoursesOffered`              | AP/IB course offerings            | 2017-2024 |
| `CTE_SLEParticipation`            | Career/Technical Ed data          | 2017-2024 |
| `CTEParticipationByStudentGroup`  | CTE by subgroup                   | 2017-2024 |
| `IndustryValuedCredentialsEarned` | Industry credentials              | 2017-2024 |
| `WorkbasedLearningByCareerClust`  | Work-based learning               | 2017-2024 |
| `Apprenticeship`                  | Apprenticeship data               | 2017-2024 |
| `SealofBiliteracy`                | Biliteracy seal earners           | 2017-2024 |

### Course Enrollment

| Sheet Name                        | Description               | Years     |
|-----------------------------------|---------------------------|-----------|
| `MathCourseParticipation`         | Math course enrollment    | 2017-2024 |
| `ScienceCourseParticipation`      | Science course enrollment | 2017-2024 |
| `SocStudiesHistoryCourseParticip` | Social studies enrollment | 2017-2024 |
| `WorldLanguagesCourseParticipati` | World language enrollment | 2017-2024 |
| `ComputerScienceCourseParticipat` | CS enrollment             | 2017-2024 |
| `VisualAndPerformingArts`         | Arts enrollment           | 2017-2024 |

### Graduation & Dropout

| Sheet Name                      | Description                   | Years     |
|---------------------------------|-------------------------------|-----------|
| `GraduatonRateTrendsProgress`   | Graduation rate trends        | 2017-2024 |
| `5YrGraduationCohortProfile`    | 5-year graduation detailed    | 2017-2024 |
| `6YrGraduationCohortProfile`    | 6-year graduation detailed    | 2021-2024 |
| `FederalGraduationRates`        | Federal graduation rates      | 2017-2024 |
| `AccountabilityGraduationRates` | ESSA graduation rates         | 2017-2024 |
| `GraduationPathways`            | Alternate graduation pathways | 2017-2024 |
| `DropoutRateTrends`             | Dropout trends                | 2017-2024 |

### Accountability

| Sheet Name                   | Description              | Years     |
|------------------------------|--------------------------|-----------|
| `ESSAAccountabilityStatus`   | ESSA status ratings      | 2017-2024 |
| `ESSAAccountabilityProgress` | ESSA progress indicators | 2017-2024 |

### Enrollment & Demographics

| Sheet Name                       | Description                       | Years     |
|----------------------------------|-----------------------------------|-----------|
| `EnrollmentTrendsbyGrade`        | Grade-level enrollment trends     | 2017-2024 |
| `EnrollmentTrendsByStudentGroup` | Enrollment by subgroup trends     | 2017-2024 |
| `EnrollmentByRacialEthnicGroup`  | Detailed racial/ethnic breakdowns | 2017-2024 |
| `PreKAndK-FullDayHalfDay`        | Pre-K and K program detail        | 2017-2024 |
| `EnrollmentTrendsFullSharedTime` | Full vs shared time               | 2017-2024 |
| `EnrollmentByHomeLanguage`       | Home language data                | 2017-2024 |

### Assessment Performance

| Sheet Name                        | Description                   | Years     |
|-----------------------------------|-------------------------------|-----------|
| `StudentGrowthTrends`             | Student growth percentiles    | 2017-2024 |
| `ELAMathPerformanceTrends`        | Historical ELA/Math trends    | 2017-2024 |
| `NJSLAELAPerformanceTrends`       | NJSLA ELA detailed trends     | 2017-2024 |
| `NJSLAMathPerformanceTrends`      | NJSLA Math detailed trends    | 2017-2024 |
| `NJSLAScience`                    | Science assessment results    | 2017-2024 |
| `AlternateAssessmentParticipatio` | Alternate assessment data     | 2017-2024 |
| `EnglishLangParticipationPerform` | ELL participation/performance | 2017-2024 |

### Postsecondary

| Sheet Name                    | Description               | Years     |
|-------------------------------|---------------------------|-----------|
| `PostSecondaryEnrRateSummary` | Postsecondary summary     | 2017-2024 |
| `PostsecondaryEnrRatesFall`   | Fall enrollment rates     | 2017-2024 |
| `PostsecondaryEnrRates16mos`  | 16-month enrollment rates | 2017-2024 |

### School Resources

| Sheet Name     | Description                | Years     |
|----------------|----------------------------|-----------|
| `SchoolDay`    | School day length/schedule | 2017-2024 |
| `DeviceRatios` | Technology/device ratios   | 2017-2024 |

### Other

| Sheet Name                  | Description                       | Years     |
|-----------------------------|-----------------------------------|-----------|
| `Header and Contact`        | School contact info               | 2017-2024 |
| `Important 2020-2021 Notes` | Data quality notes (2020-21 only) | 2020-2021 |
| `Narrative`                 | School narrative information      | 2017-2024 |

## Usage Examples

### Chronic Absenteeism Analysis

``` r
# Get school-level chronic absenteeism
ca <- fetch_chronic_absenteeism(2024)

# Filter for high-absenteeism schools
high_absent <- ca %>%
  filter(
    subgroup == "total population",
    chronically_absent_rate > 20
  ) %>%
  arrange(desc(chronically_absent_rate))

# Compare across years
library(purrr)

multi_year <- map_dfr(2018:2024, ~{
  fetch_chronic_absenteeism(.x) %>%
    filter(is_state, subgroup == "total population")
})

# Plot trend
plot(multi_year$end_year, multi_year$chronically_absent_rate,
     type = "b", xlab = "Year", ylab = "Chronic Absenteeism Rate")
```

### Teacher Experience Analysis

``` r
# Get teacher experience data
teachers <- fetch_spr_data("TeachersExperience", 2024)

# Analyze new teacher rates
new_teacher_rates <- teachers %>%
  filter(subgroup == "total population") %>%
  mutate(
    new_teacher_rate = as.numeric(`0-3 Years`) /
      as.numeric(`0-3 Years`) + as.numeric(`4-10 Years`) +
      as.numeric(`11-20 Years`) + as.numeric(`20+ Years`)
  ) %>%
  arrange(desc(new_teacher_rate))
```

### Course Access Analysis

``` r
# Get math course enrollment
math <- fetch_spr_data("MathCourseParticipation", 2024)

# Check for AP Calculus access
schools_with_calc <- math %>%
  filter(grepl("AP Calculus", math_course, ignore.case = TRUE)) %>%
  pull(school_name) %>%
  unique()

# Compare AP access across districts
ap_access <- fetch_spr_data("APIBCoursesOffered", 2024) %>%
  filter(is_district) %>%
  mutate(
    has_ap_math = grepl("AP Calculus", courses_offered, ignore.case = TRUE),
    has_ap_science = grepl("AP.*Science", courses_offered, ignore.case = TRUE)
  )
```

### Discipline Analysis

``` r
# Get disciplinary removals data
discipline <- fetch_spr_data("DisciplinaryRemovals", 2024)

# Analyze suspension rates by subgroup
discipline %>%
  filter(subgroup %in% c("black", "white", "hispanic", "total population")) %>%
  group_by(subgroup) %>%
  summarize(
    total_suspended = sum(suspended_count, na.rm = TRUE),
    total_enrolled = sum(enrollment_count, na.rm = TRUE),
    suspension_rate = total_suspended / total_enrolled,
    .groups = "drop"
  )
```

## Data Structure

All SPR data returned by
[`fetch_spr_data()`](https://almartin82.github.io/njschooldata/reference/fetch_spr_data.md)
includes:

### Standard Identifier Columns

- `end_year` - School year end (e.g., 2024 for 2023-24 school year)
- `county_id`, `county_name` - County code and name
- `district_id`, `district_name` - District code and name
- `school_id`, `school_name` - School code and name (school-level only)

### Aggregation Flags

- `is_state` - State-level aggregation
- `is_county` - County-level aggregation
- `is_district` - District-level aggregation
- `is_school` - School-level aggregation
- `is_charter` - Charter school flag
- `is_charter_sector` - Charter sector aggregation
- `is_allpublic` - All public aggregation

### Sheet-Specific Columns

Each sheet contains additional columns relevant to that data type.
Column names are automatically cleaned to snake_case.

## Data Quality Notes

- **2020-2021 Data**: Some data not available due to COVID-19 pandemic
  disruptions
- **Small Cell Suppression**: Values may be suppressed (NA) for small
  subgroups to protect privacy
- **Data Validation**: Always check for NA values and data completeness
  before analysis

## See Also

- [Package documentation](https://almartin82.github.io/njschooldata/)
- [Function
  reference](https://almartin82.github.io/njschooldata/reference/index.html)
- [Getting started
  guide](https://almartin82.github.io/njschooldata/articles/getting-started.html)

``` r
sessionInfo()
#> R version 4.5.2 (2025-10-31)
#> Platform: x86_64-pc-linux-gnu
#> Running under: Ubuntu 24.04.3 LTS
#> 
#> Matrix products: default
#> BLAS:   /usr/lib/x86_64-linux-gnu/openblas-pthread/libblas.so.3 
#> LAPACK: /usr/lib/x86_64-linux-gnu/openblas-pthread/libopenblasp-r0.3.26.so;  LAPACK version 3.12.0
#> 
#> locale:
#>  [1] LC_CTYPE=C.UTF-8       LC_NUMERIC=C           LC_TIME=C.UTF-8       
#>  [4] LC_COLLATE=C.UTF-8     LC_MONETARY=C.UTF-8    LC_MESSAGES=C.UTF-8   
#>  [7] LC_PAPER=C.UTF-8       LC_NAME=C              LC_ADDRESS=C          
#> [10] LC_TELEPHONE=C         LC_MEASUREMENT=C.UTF-8 LC_IDENTIFICATION=C   
#> 
#> time zone: UTC
#> tzcode source: system (glibc)
#> 
#> attached base packages:
#> [1] stats     graphics  grDevices utils     datasets  methods   base     
#> 
#> other attached packages:
#> [1] dplyr_1.2.0        njschooldata_0.9.0
#> 
#> loaded via a namespace (and not attached):
#>  [1] jsonlite_2.0.0    compiler_4.5.2    tidyselect_1.2.1  stringr_1.6.0    
#>  [5] snakecase_0.11.1  tidyr_1.3.2       jquerylib_0.1.4   systemfonts_1.3.1
#>  [9] textshaping_1.0.4 yaml_2.3.12       fastmap_1.2.0     readr_2.2.0      
#> [13] R6_2.6.1          generics_0.1.4    knitr_1.51        tibble_3.3.1     
#> [17] janitor_2.2.1     desc_1.4.3        lubridate_1.9.5   tzdb_0.5.0       
#> [21] bslib_0.10.0      pillar_1.11.1     rlang_1.1.7       cachem_1.1.0     
#> [25] stringi_1.8.7     xfun_0.56         fs_1.6.6          sass_0.4.10      
#> [29] timechange_0.4.0  cli_3.6.5         pkgdown_2.2.0     magrittr_2.0.4   
#> [33] digest_0.6.39     hms_1.1.4         lifecycle_1.0.5   vctrs_0.7.1      
#> [37] evaluate_1.0.5    glue_1.8.0        ragg_1.5.0        rmarkdown_2.30   
#> [41] purrr_1.2.1       tools_4.5.2       pkgconfig_2.0.3   htmltools_0.5.9
```
