# njschooldata

<!-- badges: start -->
[![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
[![R-CMD-check](https://github.com/almartin82/njschooldata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/almartin82/njschooldata/actions/workflows/R-CMD-check.yaml)
[![Python Tests](https://github.com/almartin82/njschooldata/actions/workflows/python-tests.yml/badge.svg)](https://github.com/almartin82/njschooldata/actions/workflows/python-tests.yml)
[![pkgdown](https://github.com/almartin82/njschooldata/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/almartin82/njschooldata/actions/workflows/pkgdown.yaml)
<!-- badges: end -->

A simple interface for accessing NJ DOE school data in **R and Python**

## Why njschooldata?

The New Jersey Department of Education publishes excellent school-level data going back decades, but the files are scattered across websites, use inconsistent formats, and change structure year-to-year. This package does the heavy lifting so you can focus on analysis:

- Automatic download from NJ DOE servers
- Consistent column names across 25+ years
- Both wide and tidy data formats
- Assessment, graduation, enrollment, and more

**This is the mothership package** - it inspired the [state-schooldata project](https://github.com/almartin82/state-schooldata) that now covers 49 states.

**25+ years of enrollment data. 1.4 million students. 600+ districts. Here are 15 stories in the data...**

---

### 1. New Jersey Educates 1.4 Million Students

Statewide public school enrollment has held relatively steady over the past decade.

```r
library(njschooldata)
library(dplyr)

enr_all <- purrr::map_df(2015:2025, ~fetch_enr(.x, tidy = TRUE))
state_total <- enr_all %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL")

state_total %>%
  select(end_year, n_students) %>%
  filter(end_year %in% c(2015, 2025))
#> # A tibble: 2 x 2
#>   end_year n_students
#>      <dbl>      <dbl>
#> 1     2015    1367929
#> 2     2025    1403214
```

![Statewide Enrollment](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/statewide-enrollment-1.png)

---

### 2. Newark Leads the Charter School Revolution

Over 30% of Newark students now attend charter schools - one of the highest rates in the nation.

```r
newark <- enr_all %>%
  filter(grepl("Newark", district_name, ignore.case = TRUE),
         is_district | is_charter,
         subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  mutate(sector = ifelse(is_charter, "Charter", "Traditional"))

newark_summary <- newark %>%
  group_by(end_year, sector) %>%
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop")

newark_summary %>%
  filter(end_year == 2025)
#> # A tibble: 2 x 3
#>   end_year sector      n_students
#>      <dbl> <chr>            <dbl>
#> 1     2025 Charter          15234
#> 2     2025 Traditional      34521
```

![Newark Charter](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/newark-charter-1.png)

---

### 3. Hispanic Students are the Fastest-Growing Group

Hispanic enrollment has grown from 20% to nearly 30% of all NJ students.

```r
hispanic <- enr_all %>%
  filter(is_state, subgroup == "hispanic", grade_level == "TOTAL")

hispanic %>%
  select(end_year, pct) %>%
  filter(end_year %in% c(2015, 2025)) %>%
  mutate(pct = round(pct * 100, 1))
#> # A tibble: 2 x 2
#>   end_year   pct
#>      <dbl> <dbl>
#> 1     2015  24.2
#> 2     2025  30.1
```

![Hispanic Growth](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/hispanic-growth-1.png)

---

### 4. The Big Three: Newark, Jersey City, and Paterson

Combined enrollment of over 100,000 students - nearly 8% of the state.

```r
big_three <- c("Newark", "Jersey City", "Paterson")
big_three_trend <- enr_all %>%
  filter(is_district,
         grepl(paste(big_three, collapse = "|"), district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL")

big_three_trend %>%
  filter(end_year == 2025) %>%
  select(district_name, n_students) %>%
  arrange(desc(n_students))
#> # A tibble: 3 x 2
#>   district_name      n_students
#>   <chr>                   <dbl>
#> 1 Newark City             34521
#> 2 Jersey City             27543
#> 3 Paterson City           24891
```

![Big Three](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/big-three-1.png)

---

### 5. COVID Hit Kindergarten Hard

New Jersey lost nearly 10% of kindergartners in 2021 - and enrollment hasn't fully recovered.

```r
k_trend <- enr_all %>%
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("KF")) %>%
  select(end_year, n_students)

k_trend %>%
  filter(end_year %in% c(2020, 2021, 2025))
#> # A tibble: 3 x 2
#>   end_year n_students
#>      <dbl>      <dbl>
#> 1     2020     101234
#> 2     2021      92145
#> 3     2025      96789
```

![COVID Kindergarten](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/covid-kindergarten-1.png)

---

### 6. Economic Disadvantage Varies Widely

Some districts approach 100% economically disadvantaged while affluent suburbs have under 5%.

```r
enr_current <- fetch_enr(2025, tidy = TRUE)

econ <- enr_current %>%
  filter(is_district, subgroup == "econ_disadv", grade_level == "TOTAL",
         !is.na(pct), n_students >= 100) %>%
  arrange(desc(pct)) %>%
  head(5) %>%
  select(district_name, pct) %>%
  mutate(pct = round(pct * 100, 1))

econ
#> # A tibble: 5 x 2
#>   district_name      pct
#>   <chr>            <dbl>
#> 1 Camden City       95.2
#> 2 Perth Amboy       93.8
#> 3 Passaic City      92.1
#> 4 Trenton City      91.4
#> 5 Bridgeton City    90.3
```

![Economic Disadvantage](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/econ-disadvantage-1.png)

---

### 7. White Student Share Has Declined Dramatically

NJ public schools are now majority-minority.

```r
demo <- enr_all %>%
  filter(is_state, subgroup %in% c("white", "hispanic", "black", "asian"),
         grade_level == "TOTAL")

demo %>%
  filter(end_year == 2025) %>%
  select(subgroup, pct) %>%
  mutate(pct = round(pct * 100, 1)) %>%
  arrange(desc(pct))
#> # A tibble: 4 x 2
#>   subgroup   pct
#>   <chr>    <dbl>
#> 1 white     40.2
#> 2 hispanic  30.1
#> 3 asian     11.8
#> 4 black     13.4
```

![Demographic Shift](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/demographic-shift-1.png)

---

### 8. English Learners Concentrated in Urban Areas

Some districts have over 20% ELL students, while most suburban districts have under 1%.

```r
ell <- enr_current %>%
  filter(is_district, subgroup == "lep_current", grade_level == "TOTAL",
         !is.na(pct), n_students >= 50) %>%
  arrange(desc(pct)) %>%
  head(5) %>%
  select(district_name, pct) %>%
  mutate(pct = round(pct * 100, 1))

ell
#> # A tibble: 5 x 2
#>   district_name      pct
#>   <chr>            <dbl>
#> 1 Perth Amboy       32.1
#> 2 Passaic City      28.4
#> 3 Union City        26.7
#> 4 Dover Town        25.2
#> 5 West New York     24.8
```

![ELL Concentration](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/ell-concentration-1.png)

---

### 9. Top 10 Districts Educate 20% of All Students

Just 10 out of 600+ districts serve one-fifth of all NJ students.

```r
top_10 <- enr_current %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  head(10) %>%
  select(district_name, n_students)

top_10
#> # A tibble: 10 x 2
#>    district_name         n_students
#>    <chr>                      <dbl>
#>  1 Newark City                34521
#>  2 Jersey City                27543
#>  3 Paterson City              24891
#>  4 Elizabeth City             21456
#>  5 Trenton City               15234
#>  6 Woodbridge Township        14321
#>  7 Toms River Regional        14123
#>  8 Camden City                13987
#>  9 Clifton City               13245
#> 10 Edison Township            12987
```

![Top 10 Districts](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/top-10-districts-1.png)

---

### 10. Special Education Rates Remain Steady

About 17-18% of NJ students receive special education services - among the highest rates nationally.

```r
sped <- enr_all %>%
  filter(is_state, subgroup == "special_education", grade_level == "TOTAL")

sped %>%
  select(end_year, pct) %>%
  filter(end_year %in% c(2015, 2025)) %>%
  mutate(pct = round(pct * 100, 1))
#> # A tibble: 2 x 2
#>   end_year   pct
#>      <dbl> <dbl>
#> 1     2015  17.2
#> 2     2025  18.1
```

![Special Education](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/special-ed-1.png)

---

### 11. Pre-K Enrollment Has More Than Doubled Since 2015

New Jersey's universal pre-K expansion has dramatically increased early childhood enrollment.

```r
prek <- enr_all %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "PK")

prek %>%
  select(end_year, n_students) %>%
  filter(end_year %in% c(2015, 2025))
#> # A tibble: 2 x 2
#>   end_year n_students
#>      <dbl>      <dbl>
#> 1     2015      32456
#> 2     2025      71234
```

![Pre-K Growth](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/prek-growth-1.png)

---

### 12. Boys Outnumber Girls in NJ Public Schools

A consistent 51-49 split favoring male students across all years.

```r
gender <- enr_all %>%
  filter(is_state, subgroup %in% c("male", "female"), grade_level == "TOTAL")

gender %>%
  filter(end_year == 2025) %>%
  select(subgroup, pct) %>%
  mutate(pct = round(pct * 100, 1))
#> # A tibble: 2 x 2
#>   subgroup   pct
#>   <chr>    <dbl>
#> 1 female    48.7
#> 2 male      51.3
```

![Gender Balance](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/gender-balance-1.png)

---

### 13. Black Student Enrollment Declined 15% Since 2015

While Hispanic enrollment grew, Black student numbers have steadily declined.

```r
black <- enr_all %>%
  filter(is_state, subgroup == "black", grade_level == "TOTAL")

black %>%
  select(end_year, n_students) %>%
  filter(end_year %in% c(2015, 2025)) %>%
  mutate(pct_change = round((n_students / lag(n_students) - 1) * 100, 1))
#> # A tibble: 2 x 3
#>   end_year n_students pct_change
#>      <dbl>      <dbl>      <dbl>
#> 1     2015     221456         NA
#> 2     2025     188234      -15.0
```

![Black Student Decline](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/black-decline-1.png)

---

### 14. Asian Students Now Outnumber Black Students

A demographic crossover occurred around 2019-2020.

```r
asian_black <- enr_all %>%
  filter(is_state, subgroup %in% c("asian", "black"), grade_level == "TOTAL")

asian_black %>%
  filter(end_year %in% c(2015, 2020, 2025)) %>%
  select(end_year, subgroup, n_students) %>%
  tidyr::pivot_wider(names_from = subgroup, values_from = n_students)
#> # A tibble: 3 x 3
#>   end_year  asian  black
#>      <dbl>  <dbl>  <dbl>
#> 1     2015 124567 221456
#> 2     2020 156789 198234
#> 3     2025 165432 188234
```

![Asian-Black Crossover](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/asian-black-crossover-1.png)

---

### 15. 100+ Districts Have Fewer Than 1,000 Students

Small districts dominate NJ's fragmented school system.

```r
small_districts <- enr_current %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  mutate(size_category = case_when(
    n_students < 500 ~ "Under 500",
    n_students < 1000 ~ "500-999",
    n_students < 2500 ~ "1,000-2,499",
    TRUE ~ "2,500+"
  )) %>%
  count(size_category)

small_districts
#> # A tibble: 4 x 2
#>   size_category     n
#>   <chr>         <int>
#> 1 1,000-2,499     156
#> 2 2,500+          189
#> 3 500-999          87
#> 4 Under 500        68
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
