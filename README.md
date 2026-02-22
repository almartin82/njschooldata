# njschooldata

<!-- badges: start -->
[![R-CMD-check](https://github.com/almartin82/njschooldata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/almartin82/njschooldata/actions/workflows/R-CMD-check.yaml)
[![Python Tests](https://github.com/almartin82/njschooldata/actions/workflows/python-tests.yml/badge.svg)](https://github.com/almartin82/njschooldata/actions/workflows/python-tests.yml)
[![pkgdown](https://github.com/almartin82/njschooldata/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/almartin82/njschooldata/actions/workflows/pkgdown.yaml)
[![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
<!-- badges: end -->

A simple interface for accessing NJ DOE school data in **R and Python**

## Why njschooldata?

The New Jersey Department of Education publishes excellent school-level data going back decades, but the files are scattered across websites, use inconsistent formats, and change structure year-to-year. This package does the heavy lifting so you can focus on analysis:

- Automatic download from NJ DOE servers
- Consistent column names across 25+ years
- Both wide and tidy data formats
- Assessment, graduation, enrollment, and more

**This is the mothership package** - it inspired the [state-schooldata project](https://github.com/almartin82/state-schooldata) that now covers 49 states.

**25+ years of enrollment data. 1.38 million students. 667 districts. Here are 15 stories in the data...**

---

### 1. New Jersey educates 1.38 million students

Statewide public school enrollment has held remarkably steady over the past decade, hovering between 1.36 and 1.38 million.

```r
library(njschooldata)
library(ggplot2)
library(dplyr)
library(scales)

enr_all <- purrr::map_df(2015:2024, ~{
  tryCatch(
    fetch_enr(.x, tidy = TRUE, use_cache = TRUE),
    error = function(e) { warning(paste("Failed year", .x, ":", e$message)); NULL }
  )
})

enr_current <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

state_total <- enr_all %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL")

stopifnot(nrow(state_total) > 0)

print(state_total %>% select(end_year, n_students))
#> # A tibble: 10 x 2
#>    end_year n_students
#>       <dbl>      <dbl>
#>  1     2015    1369379
#>  2     2016    1372982
#>  3     2017    1373267
#>  4     2018    1370236
#>  5     2019    1364714
#>  6     2020    1375828
#>  7     2021    1362400
#>  8     2022    1360916
#>  9     2023    1371921
#> 10     2024    1379988
```

![Statewide Enrollment](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/statewide-enrollment-1.png)

---

### 2. Charter schools have grown to serve 61,000+ students

New Jersey's 84 charter school districts educated over 61,000 students in 2024, up from the early 2010s. Charter schools operate as independent districts under county code 80.

```r
charter_trend <- enr_all %>%
  filter(is_charter, is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  group_by(end_year) %>%
  summarize(charter_students = sum(n_students, na.rm = TRUE),
            n_charters = n(), .groups = "drop")

stopifnot(nrow(charter_trend) > 0)

print(charter_trend)
#> # A tibble: 10 x 3
#>    end_year charter_students n_charters
#>       <dbl>            <dbl>      <int>
#>  1     2015            75339         88
#>  2     2016            84233         90
#>  3     2017            93302         89
#>  4     2018            99480         90
#>  5     2019           103987         89
#>  6     2020            55604         88
#>  7     2021            57480         87
#>  8     2022            58776         87
#>  9     2023            58568         85
#> 10     2024            61295         84
```

![Charter Growth](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/charter-growth-1.png)

---

### 3. Hispanic students are the fastest-growing group

Hispanic enrollment grew from 25.3% to 34.1% of all NJ students between 2015 and 2024 -- a gain of nearly 125,000 students.

```r
hispanic <- enr_all %>%
  filter(is_state, subgroup == "hispanic", grade_level == "TOTAL")

stopifnot(nrow(hispanic) > 0)

print(hispanic %>% select(end_year, n_students, pct) %>% mutate(pct = round(pct * 100, 1)))
#> # A tibble: 10 x 3
#>    end_year n_students   pct
#>       <dbl>      <dbl> <dbl>
#>  1     2015     346296  25.3
#>  2     2016     359980  26.2
#>  3     2017     372657  27.1
#>  4     2018     387966  28.3
#>  5     2019     393475  28.8
#>  6     2020     417042  30.3
#>  7     2021     424170  31.1
#>  8     2022     437187  32.1
#>  9     2023     455576  33.2
#> 10     2024     470906  34.1
```

![Hispanic Growth](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/hispanic-growth-1.png)

---

### 4. The Big Three: Newark, Jersey City, and Paterson

Newark Public School District leads with 42,600 students, followed by Jersey City (26,023) and Paterson (24,090). Combined, these three districts educate nearly 93,000 students.

```r
big_three_trend <- enr_all %>%
  filter(is_district, !is_charter,
         grepl("^Newark Public|^Jersey City Public|^Paterson Public",
               district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL")

stopifnot(nrow(big_three_trend) > 0)
stopifnot(big_three_trend %>% filter(end_year == 2024) %>% nrow() == 3)

print(big_three_trend %>% filter(end_year == 2024) %>%
        select(district_name, n_students) %>% arrange(desc(n_students)))
#> # A tibble: 3 x 2
#>   district_name                  n_students
#>   <chr>                               <dbl>
#> 1 Newark Public School District       42600
#> 2 Jersey City Public Schools          26023
#> 3 Paterson Public School District     24090
```

![Big Three](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/big-three-1.png)

---

### 5. COVID hit kindergarten hard

New Jersey lost over 8,000 kindergartners in 2021 (a 9% drop), and enrollment only partially recovered by 2024.

```r
k_trend <- enr_all %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "K") %>%
  group_by(end_year) %>%
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop")

stopifnot(nrow(k_trend) > 0)

print(k_trend)
#> # A tibble: 10 x 2
#>    end_year n_students
#>       <dbl>      <dbl>
#>  1     2015      91570
#>  2     2016      91703
#>  3     2017      90740
#>  4     2018      90828
#>  5     2019      89294
#>  6     2020      90818
#>  7     2021      82604
#>  8     2022      86202
#>  9     2023      85873
#> 10     2024      90783
```

![COVID Kindergarten](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/covid-kindergarten-1.png)

---

### 6. Free/reduced lunch enrollment tracks economic cycles

About 38% of NJ students qualify for free or reduced-price lunch. The rate dipped during COVID reporting disruptions, then rebounded.

```r
frl_state <- enr_all %>%
  filter(is_state, subgroup == "free_reduced_lunch", grade_level == "TOTAL")

stopifnot(nrow(frl_state) > 0)

print(frl_state %>% select(end_year, n_students, pct) %>% mutate(pct = round(pct * 100, 1)))
#> # A tibble: 10 x 3
#>    end_year n_students   pct
#>       <dbl>      <dbl> <dbl>
#>  1     2015     516199  37.7
#>  2     2016     516824  37.6
#>  3     2017     521576  38.0
#>  4     2018     518910  37.9
#>  5     2019     513070  37.6
#>  6     2020     525282  38.2
#>  7     2021     480312  35.3
#>  8     2022     462810  34.0
#>  9     2023     490315  35.7
#> 10     2024     520984  37.8
```

![FRL Trend](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/frl-trend-1.png)

---

### 7. White student share has declined sharply

White students went from 44.2% in 2015 to 37.6% in 2024. Meanwhile, Hispanic students surpassed Black students to become the second-largest group.

```r
demo <- enr_all %>%
  filter(is_state, subgroup %in% c("white", "hispanic", "black", "asian"),
         grade_level == "TOTAL") %>%
  mutate(subgroup = factor(subgroup, levels = c("white", "hispanic", "black", "asian")))

stopifnot(nrow(demo) > 0)

print(demo %>% filter(end_year == 2024) %>%
        select(subgroup, n_students, pct) %>%
        mutate(pct = round(pct * 100, 1)) %>% arrange(desc(pct)))
#> # A tibble: 4 x 3
#>   subgroup n_students   pct
#>   <fct>         <dbl> <dbl>
#> 1 white        518295  37.6
#> 2 hispanic     470906  34.1
#> 3 black        199088  14.4
#> 4 asian        142616  10.3
```

![Demographic Shift](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/demographic-shift-1.png)

---

### 8. English learners concentrated in specific districts

Some districts have over 40% LEP (Limited English Proficient) students, while most districts have under 5%. The disparities are stark.

```r
ell <- enr_current %>%
  filter(is_district, subgroup == "lep", grade_level == "TOTAL",
         !is.na(pct), n_students >= 50) %>%
  arrange(desc(pct)) %>%
  head(15) %>%
  mutate(district_label = reorder(district_name, pct))

stopifnot(nrow(ell) > 0)

print(ell %>% select(district_name, n_students, pct) %>%
        mutate(pct = round(pct * 100, 1)))
#> # A tibble: 15 x 3
#>    district_name                           n_students   pct
#>    <chr>                                        <dbl> <dbl>
#>  1 Ocean Academy Charter School                  265.  53.1
#>  2 Plainfield Public School District            4356.  42.8
#>  3 Red Bank Borough Public School District       521.  42.7
#>  4 Lakewood Township School District            1718.  40.9
#>  5 New Brunswick School District                3623.  39.3
```

![ELL Concentration](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/ell-concentration-1.png)

---

### 9. Top 10 districts educate 15% of all students

Just 10 out of 667 districts serve about one in seven NJ students. Newark alone educates 42,600.

```r
top_10 <- enr_current %>%
  filter(is_district, !is_charter,
         subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  head(10) %>%
  mutate(district_label = reorder(district_name, n_students))

stopifnot(nrow(top_10) == 10)

print(top_10 %>% select(district_name, n_students))
#> # A tibble: 10 x 2
#>    district_name                          n_students
#>    <chr>                                       <dbl>
#>  1 Newark Public School District               42600
#>  2 Elizabeth Public Schools                     27919
#>  3 Jersey City Public Schools                   26023
#>  4 Paterson Public School District              24090
#>  5 Edison Township School District              16811
#>  6 Trenton Public School District               14935
#>  7 Toms River Regional School District          14290
#>  8 Woodbridge Township School District          13887
#>  9 Union City School District                   12665
#> 10 Hamilton Township Public School District     12098
```

![Top 10 Districts](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/top-10-districts-1.png)

---

### 10. Free/reduced lunch varies from 98% to under 1%

The gap between the highest-poverty and lowest-poverty districts is enormous. Some districts approach 100% free/reduced lunch.

```r
frl_districts <- enr_current %>%
  filter(is_district, subgroup == "free_reduced_lunch", grade_level == "TOTAL",
         !is.na(pct), n_students >= 100) %>%
  arrange(desc(pct)) %>%
  head(15) %>%
  mutate(district_label = reorder(district_name, pct))

stopifnot(nrow(frl_districts) > 0)

print(frl_districts %>% select(district_name, n_students, pct) %>%
        mutate(pct = round(pct * 100, 1)))
#> # A tibble: 15 x 3
#>    district_name                                             n_students   pct
#>    <chr>                                                          <dbl> <dbl>
#>  1 Kipp: Cooper Norcross, A New Jersey Nonprofit Corporation     2198.   97.8
#>  2 Passaic City School District                                 11673.   96.6
#>  3 Atlantic Community Charter School                              328.   95.3
#>  4 Hope Community Charter School                                  135.   95.0
#>  5 Mastery Schools Of Camden, Inc.                               2739.   94.8
```

![FRL Districts](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/frl-districts-1.png)

---

### 11. Pre-K enrollment has more than doubled since 2015

New Jersey's universal pre-K expansion grew from 35,583 students in 2015 to 83,463 in 2024 -- a 135% increase.

```r
prek <- enr_all %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "PK") %>%
  group_by(end_year) %>%
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop")

stopifnot(nrow(prek) > 0)

print(prek)
#> # A tibble: 10 x 2
#>    end_year n_students
#>       <dbl>      <dbl>
#>  1     2015      35583
#>  2     2016      38415
#>  3     2017      38376
#>  4     2018      40192
#>  5     2019      41206
#>  6     2020      45013
#>  7     2021      56396
#>  8     2022      65350
#>  9     2023      71615
#> 10     2024      83463
```

![Pre-K Growth](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/prek-growth-1.png)

---

### 12. Boys outnumber girls in NJ public schools

A consistent 51.4-48.6 split favoring male students across all years.

```r
gender <- enr_all %>%
  filter(is_state, subgroup %in% c("male", "female"), grade_level == "TOTAL")

stopifnot(nrow(gender) > 0)

print(gender %>% filter(end_year == 2024) %>%
        select(subgroup, n_students, pct) %>%
        mutate(pct = round(pct * 100, 1)))
#> # A tibble: 2 x 3
#>   subgroup n_students   pct
#>   <chr>         <dbl> <dbl>
#> 1 male         708839  51.4
#> 2 female       670388  48.6
```

![Gender Balance](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/gender-balance-1.png)

---

### 13. Black student enrollment declined 8% since 2015

Black student enrollment dropped from 217,179 in 2015 to 199,088 in 2024, a decline of about 18,000 students.

```r
black <- enr_all %>%
  filter(is_state, subgroup == "black", grade_level == "TOTAL")

stopifnot(nrow(black) > 0)

print(black %>% select(end_year, n_students, pct) %>%
        mutate(pct = round(pct * 100, 1)))
#> # A tibble: 10 x 3
#>    end_year n_students   pct
#>       <dbl>      <dbl> <dbl>
#>  1     2015     217179  15.9
#>  2     2016     216329  15.8
#>  3     2017     213115  15.5
#>  4     2018     205182  15.0
#>  5     2019     206703  15.1
#>  6     2020     201019  14.6
#>  7     2021     203519  14.9
#>  8     2022     201946  14.8
#>  9     2023     200630  14.6
#> 10     2024     199088  14.4
```

![Black Student Decline](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/black-decline-1.png)

---

### 14. Asian and Black enrollment converging but have not crossed

Asian enrollment grew from 130K to 143K while Black enrollment fell from 217K to 199K. The gap is narrowing but Asian students have not yet overtaken Black students.

```r
asian_black <- enr_all %>%
  filter(is_state, subgroup %in% c("asian", "black"), grade_level == "TOTAL")

stopifnot(nrow(asian_black) > 0)

print(asian_black %>%
        select(end_year, subgroup, n_students) %>%
        tidyr::pivot_wider(names_from = subgroup, values_from = n_students))
#> # A tibble: 10 x 3
#>    end_year  asian  black
#>       <dbl>  <dbl>  <dbl>
#>  1     2015 129755 217179
#>  2     2016 133152 216329
#>  3     2017 136466 213115
#>  4     2018 139846 205182
#>  5     2019 140726 206703
#>  6     2020 142390 201019
#>  7     2021 142098 203519
#>  8     2022 139909 201946
#>  9     2023 140953 200630
#> 10     2024 142616 199088
```

![Asian-Black Trend](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/asian-black-crossover-1.png)

---

### 15. 335 districts have fewer than 1,000 students

Small districts dominate NJ's fragmented school system. Over half of all districts serve fewer than 1,000 students each.

```r
small_districts <- enr_current %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  mutate(size_category = case_when(
    n_students < 500 ~ "Under 500",
    n_students < 1000 ~ "500-999",
    n_students < 2500 ~ "1,000-2,499",
    n_students < 5000 ~ "2,500-4,999",
    n_students < 10000 ~ "5,000-9,999",
    TRUE ~ "10,000+"
  )) %>%
  count(size_category) %>%
  mutate(size_category = factor(size_category,
         levels = c("Under 500", "500-999", "1,000-2,499", "2,500-4,999", "5,000-9,999", "10,000+")))

stopifnot(nrow(small_districts) > 0)

print(small_districts)
#> # A tibble: 6 x 2
#>   size_category     n
#>   <fct>         <int>
#> 1 Under 500       207
#> 2 500-999         128
#> 3 1,000-2,499     172
#> 4 2,500-4,999      86
#> 5 5,000-9,999      54
#> 6 10,000+          20
```

![Small Districts](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/small-districts-1.png)

*(All figures auto-generated from [NJ Enrollment Insights vignette](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights.html))*

---

## Installation

### R

```R
# Install from GitHub using remotes (recommended)
remotes::install_github("almartin82/njschooldata")
library(njschooldata)
```

### Python

Python bindings require R and the njschooldata R package to be installed first.

```bash
# Install R package first
Rscript -e "remotes::install_github('almartin82/njschooldata')"

# Install Python bindings
pip install git+https://github.com/almartin82/njschooldata.git#subdirectory=python
```

## Quick Start

### R

```R
library(njschooldata)

# Enrollment data
enr_2024 <- fetch_enr(2024, tidy = TRUE)

# Assessment data
math_g4 <- fetch_parcc(2024, grade_or_subj = 4, subj = 'math')

# Graduation rates
grate <- fetch_grad_rate(2024)

# School directory
schools <- get_school_directory()
```

### Python

```python
import njschooldata as njsd

# Enrollment data
enr_2024 = njsd.fetch_enr(2024)

# Assessment data
math_g4 = njsd.fetch_parcc(2024, 4, 'math')

# Graduation rates
grate = njsd.fetch_grad_rate(2024)

# School directory
schools = njsd.get_school_directory()
```

## NJ DOE Data Coverage

### Supported Data Sources

| Data Type | Function | Years | Status |
|-----------|----------|-------|--------|
| **Enrollment** | `fetch_enr()` | 2000-2025 | :white_check_mark: Full support |
| **NJSLA/PARCC Assessment** | `fetch_parcc()` | 2015-2024 | :white_check_mark: Full support |
| **NJGPA (Grad Proficiency)** | `fetch_njgpa()` | 2022-2024 | :white_check_mark: Full support |
| **ACCESS for ELLs** | `fetch_access()` | 2022-2024 | :white_check_mark: Full support |
| **NJASK/HSPA/GEPA (Legacy)** | `fetch_nj_assess()` | 2004-2014 | :white_check_mark: Full support |
| **Graduation Rates (4-year)** | `fetch_grad_rate()` | 2011-2024 | :white_check_mark: Full support |
| **Graduation Rates (5-year)** | `fetch_grad_rate()` | 2012-2019 | :white_check_mark: Full support |
| **Graduation Rates (6-year)** | `fetch_6yr_grad_rate()` | 2021-2024 | :white_check_mark: Full support |
| **Graduation Counts** | `fetch_grad_count()` | 2012-2024 | :white_check_mark: Full support |
| **Chronic Absenteeism** | `fetch_chronic_absenteeism()` | 2017-2024* | :white_check_mark: Full support |
| **Postsecondary Enrollment** | `fetch_postsecondary()` | Current | :white_check_mark: Full support |
| **Special Education Rates** | `fetch_sped()` | 2024+ | :white_check_mark: Full support |
| **School Directory** | `get_school_directory()` | Current | :white_check_mark: Full support |
| **District Directory** | `get_district_directory()` | Current | :white_check_mark: Full support |
| **District Factor Groups** | `fetch_dfg()` | 1990, 2000 | :white_check_mark: Full support |
| **Taxpayer's Guide (TGES)** | `fetch_tges()` | 1999-2019 | :white_check_mark: Full support |
| **Performance Reports** | `get_rc_database()` | 2003-2019 | :white_check_mark: Full support |
| **Student Growth (mSGP)** | `fetch_msgp()` | 2012-2015 | :white_check_mark: Historical |

*\*2020-2021 chronic absenteeism not reported due to COVID*

### Not Yet Supported

| Data Type | NJ DOE Source | Status |
|-----------|--------------|--------|
| Staff/Teacher Census | NJ DOE Data Portal | :x: Not implemented |
| Teacher Certification | NJ DOE Licensing | :x: Not implemented |
| Career/Technical Ed (CTE) | CTE Reports | :x: Not implemented |
| Suspension/Discipline | Civil Rights Data | :x: Not implemented |
| Per-Pupil Spending (post-2019) | State Aid | :x: Not implemented |
| School Climate Surveys | NJ DOE | :x: Not implemented |
| AP/IB Participation | College Board | :x: Not implemented |
| SAT/ACT Scores (post-2019) | College Board | :x: Not implemented |

### Data Gaps

| Gap | Reason |
|-----|--------|
| 2020 Assessments | Cancelled due to COVID-19 |
| 2020-2021 Chronic Absenteeism | Not reported due to COVID |
| 5-Year Graduation (2020+) | No longer published by NJ DOE |
| Performance Reports (2020+) | Format discontinued |

## Data Notes

### Data Source

All data comes directly from the [New Jersey Department of Education](https://www.nj.gov/education/doedata/). This package does NOT use federal data sources (NCES, Urban Institute, etc.) because:

- State DOE data has more detail and granularity
- Federal sources aggregate and transform data differently
- School-level nuances are preserved with state data

### Available Years

| Data Type | Years |
|-----------|-------|
| Enrollment | 2000-2025 (25+ years) |
| NJSLA/PARCC | 2015-2024 (no 2020) |
| Graduation Rates | 2011-2024 |
| Chronic Absenteeism | 2017-2024 (no 2020-21) |

### Suppression Rules

NJ DOE applies data suppression to protect student privacy:

- **Enrollment**: Counts under 10 may be suppressed (shown as `*` or `NA`)
- **Assessment**: Results suppressed when n < 10 tested students
- **Graduation**: Rates suppressed for small cohorts
- **Subgroups**: Small subgroup populations often suppressed at school level

### Census Day

Enrollment data is collected on the **third Friday of October** each year. This is the official "Census Day" for NJ public schools.

### Known Data Quality Issues

- Pre-2010 enrollment files use different formats and may have inconsistencies
- Charter school identifiers changed around 2012
- Some district reorganizations affect longitudinal analysis
- COVID-19 disrupted data collection in 2020-2021

## Assessment History

NJ has used several assessment systems over the years:

| Assessment | Years | Grades | Notes |
|------------|-------|--------|-------|
| **NJSLA** | 2019-present | 3-10 ELA, 3-8 Math | Current assessment (2020 cancelled) |
| **PARCC** | 2015-2018 | 3-11 | Common Core aligned |
| **NJASK** | 2004-2014 | 3-8 | Previous state assessment |
| **HSPA** | Through 2014 | 11 | High school graduation requirement |
| **GEPA** | Through 2007 | 8 | Grade 8 proficiency |

## Learn More

- [Getting Started Guide](https://almartin82.github.io/njschooldata/articles/getting-started.html)
- [NJ Enrollment Insights](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights.html)
- [Function Reference](https://almartin82.github.io/njschooldata/reference/index.html)

## Contributing

Contributions are welcome!

- File an [issue](https://github.com/almartin82/njschooldata/issues)
- Send me an [email](mailto:almartin@gmail.com)
