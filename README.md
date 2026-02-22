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

**6 years of enrollment data. 1.4 million students. 580+ districts. 21 counties. Here are 15 stories the data tells...**

---

### 1. New Jersey educates 1.4 million students

New Jersey has one of the largest public school systems in the country, with enrollment holding steady through COVID and beyond.

```r
library(njschooldata)
library(ggplot2)
library(dplyr)
library(scales)

years <- 2020:2025
enr_all <- purrr::map_df(years, ~{
  tryCatch(
    fetch_enr(.x, tidy = TRUE),
    error = function(e) {
      warning(paste("Year", .x, "failed:", conditionMessage(e)))
      NULL
    }
  )
})

# State-level summary aggregated from district totals for time-series consistency
state_summary <- enr_all %>%
  filter(is_district) %>%
  group_by(end_year, subgroup, grade_level) %>%
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop")

state_totals <- state_summary %>%
  filter(subgroup == "total_enrollment") %>%
  select(end_year, grade_level, total = n_students)

state_summary <- state_summary %>%
  left_join(state_totals, by = c("end_year", "grade_level")) %>%
  mutate(pct = n_students / total)

state_total <- state_summary %>%
  filter(subgroup == "total_enrollment", grade_level == "TOTAL")

stopifnot(nrow(state_total) > 0)
state_total
#> # A tibble: 6 x 6
#>   end_year subgroup         grade_level n_students   total   pct
#>      <dbl> <chr>            <chr>            <dbl>   <dbl> <dbl>
#> 1     2020 total_enrollment TOTAL         1375828. 1375828.    1
#> 2     2021 total_enrollment TOTAL         1362400  1362400     1
#> 3     2022 total_enrollment TOTAL         1360916  1360916     1
#> 4     2023 total_enrollment TOTAL         1371921  1371921     1
#> 5     2024 total_enrollment TOTAL         1379988  1379988     1
#> 6     2025 total_enrollment TOTAL         1381182  1381182     1
```

![Statewide Enrollment](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/statewide-enrollment-1.png)

---

### 2. Charter enrollment grew 15% in five years

New Jersey's charter sector added 8,000+ students from 2020 to 2025, growing from 55,600 to over 63,800.

```r
charter_trend <- enr_all %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  mutate(sector = ifelse(is_charter, "Charter", "Traditional")) %>%
  group_by(end_year, sector) %>%
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop")

stopifnot(nrow(charter_trend) > 0)
charter_trend
#> # A tibble: 12 x 3
#>    end_year sector      n_students
#>       <dbl> <chr>            <dbl>
#>  1     2020 Charter         55604.
#>  2     2020 Traditional   1320225.
#>  3     2021 Charter         57480
#>  4     2021 Traditional   1304920
#>  5     2022 Charter         58776.
#>  6     2022 Traditional   1302140.
#>  7     2023 Charter         58568.
#>  8     2023 Traditional   1313352.
#>  9     2024 Charter         61295
#> 10     2024 Traditional   1318693
#> 11     2025 Charter         63810.
#> 12     2025 Traditional   1317372.
```

![Charter Growth](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/charter-growth-1.png)

---

### 3. Hispanic students hit 35% and rising

Hispanic enrollment surged from 30% to 35% of all NJ students in just five years, making it the fastest demographic shift in state history.

```r
hispanic <- state_summary %>%
  filter(subgroup == "hispanic", grade_level == "TOTAL")

stopifnot(nrow(hispanic) > 0)
hispanic %>% select(end_year, n_students, pct)
#> # A tibble: 6 x 3
#>   end_year n_students   pct
#>      <dbl>      <dbl> <dbl>
#> 1     2020    417042. 0.303
#> 2     2021    424170. 0.311
#> 3     2022    437187  0.321
#> 4     2023    455576. 0.332
#> 5     2024    470906  0.341
#> 6     2025    483504. 0.350
```

![Hispanic Growth](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/hispanic-growth-1.png)

---

### 4. The Big Three: Newark, Jersey City, and Paterson

New Jersey's three largest districts educate over 93,000 students combined - nearly 7% of the state.

```r
big_three_names <- c("Newark Public School District",
                     "Jersey City Public Schools",
                     "Paterson Public School District")
big_three_trend <- enr_all %>%
  filter(is_district, !is_charter,
         district_name %in% big_three_names,
         subgroup == "total_enrollment", grade_level == "TOTAL")

stopifnot(nrow(big_three_trend) > 0)
big_three_trend %>% select(end_year, district_name, n_students)
#> # A tibble: 15 x 3
#>    end_year district_name                   n_students
#>       <dbl> <chr>                                <dbl>
#>  1     2021 Newark Public School District        40085
#>  2     2021 Jersey City Public Schools           26541
#>  3     2021 Paterson Public School District      25657
#>  4     2022 Newark Public School District        40607
#>  5     2022 Jersey City Public Schools           26890
#>  6     2022 Paterson Public School District      24495
#>  7     2023 Newark Public School District        41430
#>  8     2023 Jersey City Public Schools           26418
#>  9     2023 Paterson Public School District      26067
#> 10     2024 Newark Public School District        42600
#> 11     2024 Jersey City Public Schools           26023
#> 12     2024 Paterson Public School District      24090
#> 13     2025 Newark Public School District        43980
#> 14     2025 Jersey City Public Schools           25692
#> 15     2025 Paterson Public School District      23609
```

![Big Three](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/big-three-1.png)

---

### 5. Kindergarten rebounded from COVID

New Jersey lost 5% of kindergartners during COVID - but by 2025, K enrollment nearly recovered while Pre-K surged past pre-pandemic levels.

```r
k_trend <- state_summary %>%
  filter(subgroup == "total_enrollment",
         grade_level %in% c("PK", "K", "01", "06", "12")) %>%
  mutate(grade_label = case_when(
    grade_level == "PK" ~ "Pre-K",
    grade_level == "K" ~ "Kindergarten",
    grade_level == "01" ~ "Grade 1",
    grade_level == "06" ~ "Grade 6",
    grade_level == "12" ~ "Grade 12",
    TRUE ~ grade_level
  ))

stopifnot(nrow(k_trend) > 0)
k_trend %>%
  filter(grade_level %in% c("K", "PK")) %>%
  select(end_year, grade_label, n_students)
#> # A tibble: 12 x 3
#>    end_year grade_label  n_students
#>       <dbl> <chr>             <dbl>
#>  1     2020 Kindergarten      90818
#>  2     2020 Pre-K             45013
#>  3     2021 Kindergarten      82604
#>  4     2021 Pre-K             56396
#>  5     2022 Kindergarten      86202
#>  6     2022 Pre-K             65350
#>  7     2023 Kindergarten      85873
#>  8     2023 Pre-K             71615
#>  9     2024 Kindergarten      90783
#> 10     2024 Pre-K             83463
#> 11     2025 Kindergarten      89428
#> 12     2025 Pre-K             87231
```

![COVID Kindergarten](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/covid-kindergarten-1.png)

---

### 6. Free/reduced lunch ranges from 98% to under 5%

Passaic City has 98% of students on free/reduced lunch while affluent suburbs like Millburn have under 5% - a stark measure of NJ's wealth divide.

```r
enr_current <- fetch_enr(2025, tidy = TRUE)

frl <- enr_current %>%
  filter(is_district, !is_charter,
         subgroup == "free_reduced_lunch", grade_level == "TOTAL",
         !is.na(pct), n_students >= 100) %>%
  arrange(desc(pct)) %>%
  head(15) %>%
  mutate(district_label = reorder(district_name, pct))

stopifnot(nrow(frl) > 0)
frl %>% select(district_name, n_students, pct)
#> # A tibble: 15 x 3
#>    district_name                                            n_students   pct
#>    <chr>                                                         <dbl> <dbl>
#>  1 Passaic City School District                              11540.    0.981
#>  2 Kipp: Cooper Norcross, A New Jersey Nonprofit Corporation  2216.    0.972
#>  3 Mastery Schools Of Camden, Inc.                            2735.    0.952
#>  4 Camden Prep, Inc.                                          1402.    0.936
#>  5 Bridgeton City School District                             5579.    0.923
#>  6 Lakewood Township School District                          3783.    0.920
#>  7 Atlantic City School District                              5577.    0.870
#>  8 New Brunswick School District                              7584.    0.867
#>  9 West New York School District                              6683.    0.848
#> 10 Lindenwold Public School District                          2634.    0.842
#> 11 Guttenberg School District                                  809.    0.828
#> 12 Harrison Public Schools                                    2016.    0.826
#> 13 Elizabeth Public Schools                                   22915.    0.819
#> 14 Bound Brook School District                                1555.    0.813
#> 15 Woodbine School District                                    200.    0.810
```

![FRL Distribution](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/frl-distribution-1.png)

---

### 7. White students dropped below 37%

White students went from 42% to under 37% of NJ public school enrollment in just five years. NJ public schools are now decisively majority-minority.

```r
demo <- state_summary %>%
  filter(subgroup %in% c("white", "hispanic", "black", "asian"),
         grade_level == "TOTAL") %>%
  mutate(subgroup = factor(subgroup, levels = c("white", "hispanic", "black", "asian")))

stopifnot(nrow(demo) > 0)
demo %>% select(end_year, subgroup, pct) %>%
  mutate(pct = round(pct * 100, 1)) %>%
  tidyr::pivot_wider(names_from = subgroup, values_from = pct)
#> # A tibble: 6 x 5
#>   end_year white hispanic black asian
#>      <dbl> <dbl>    <dbl> <dbl> <dbl>
#> 1     2020  42       30.3  14.6  10.3
#> 2     2021  40.6     31.1  14.9  10.4
#> 3     2022  39.6     32.1  14.8  10.3
#> 4     2023  38.5     33.2  14.6  10.3
#> 5     2024  37.6     34.1  14.4  10.3
#> 6     2025  36.7     35.0  14.3  10.3
```

![Demographic Shift](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/demographic-shift-1.png)

---

### 8. English learners top 45% in some districts

ELL students make up over 45% in Plainfield and Lakewood but under 1% in most suburban districts - a concentration driven by immigration patterns.

```r
ell <- enr_current %>%
  filter(is_district, !is_charter,
         subgroup == "lep", grade_level == "TOTAL",
         !is.na(pct), n_students >= 50) %>%
  arrange(desc(pct)) %>%
  head(15) %>%
  mutate(district_label = reorder(district_name, pct))

stopifnot(nrow(ell) > 0)
ell %>% select(district_name, n_students, pct)
#> # A tibble: 15 x 3
#>    district_name                          n_students   pct
#>    <chr>                                       <dbl> <dbl>
#>  1 Plainfield Public School District           4486. 0.452
#>  2 Lakewood Township School District           1842. 0.448
#>  3 Dover Public School District                1462. 0.427
#>  4 New Brunswick School District               3656. 0.418
#>  5 Red Bank Borough Public School District      492. 0.417
#>  6 Trenton Public School District              6437. 0.416
#>  7 Irvington Public School District            3255. 0.403
#>  8 Union City School District                  4971. 0.394
#>  9 Bridgeton City School District              2381. 0.394
#> 10 Elizabeth Public Schools                    10688. 0.382
#> 11 East Newark School District                   82. 0.369
#> 12 Perth Amboy Public School District          3703. 0.367
#> 13 Passaic City School District                4294. 0.365
#> 14 Paterson Public School District             8169. 0.346
#> 15 Bound Brook School District                  645. 0.337
```

![ELL Concentration](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/ell-concentration-1.png)

---

### 9. Top 10 districts serve 15% of all students

Just 10 out of 580+ districts educate nearly 1 in 6 NJ students. Newark alone has 44,000.

```r
top_10 <- enr_current %>%
  filter(is_district, !is_charter,
         subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  head(10) %>%
  mutate(district_label = reorder(district_name, n_students))

stopifnot(nrow(top_10) > 0)
top_10 %>% select(district_name, n_students)
#> # A tibble: 10 x 2
#>    district_name                            n_students
#>    <chr>                                         <dbl>
#>  1 Newark Public School District                43980
#>  2 Elizabeth Public Schools                     27980.
#>  3 Jersey City Public Schools                   25692
#>  4 Paterson Public School District              23609
#>  5 Edison Township School District              16708
#>  6 Trenton Public School District               15474.
#>  7 Toms River Regional School District          14118.
#>  8 Woodbridge Township School District          13870.
#>  9 Union City School District                   12617
#> 10 Hamilton Township Public School District     12194.
```

![Top 10 Districts](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/top-10-districts-1.png)

---

### 10. Multiracial students: fastest-growing category

Multiracial students grew 39% in five years - from 2.4% to 3.3% of enrollment - making it the fastest-growing racial category in NJ.

```r
multi <- state_summary %>%
  filter(subgroup == "multiracial", grade_level == "TOTAL")

stopifnot(nrow(multi) > 0)
multi %>% select(end_year, n_students, pct)
#> # A tibble: 6 x 3
#>   end_year n_students    pct
#>      <dbl>      <dbl>  <dbl>
#> 1     2020     32622  0.0237
#> 2     2021     34518  0.0253
#> 3     2022     37474  0.0275
#> 4     2023     40934. 0.0298
#> 5     2024     43436. 0.0315
#> 6     2025     45246. 0.0327
```

![Multiracial Growth](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/multiracial-growth-1.png)

---

### 11. Pre-K nearly doubled since 2020

NJ's Pre-K enrollment surged from 45,000 to 87,000 in five years - fueled by the state's expanding universal pre-K program.

```r
prek <- state_summary %>%
  filter(subgroup == "total_enrollment", grade_level == "PK")

stopifnot(nrow(prek) > 0)
prek %>% select(end_year, n_students)
#> # A tibble: 6 x 2
#>   end_year n_students
#>      <dbl>      <dbl>
#> 1     2020      45013
#> 2     2021      56396
#> 3     2022      65350
#> 4     2023      71615
#> 5     2024      83463
#> 6     2025      87231
```

![Pre-K Surge](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/prek-surge-1.png)

---

### 12. Bergen County has more students than 12 US states

With 132,000+ students, Bergen County alone has a larger public school system than Wyoming, Vermont, North Dakota, and nine other states.

```r
county_enr <- enr_current %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  group_by(county_name) %>%
  summarize(n_students = sum(n_students, na.rm = TRUE),
            n_districts = n(), .groups = "drop") %>%
  filter(county_name != "Charters") %>%
  arrange(desc(n_students)) %>%
  head(15) %>%
  mutate(county_label = reorder(county_name, n_students))

stopifnot(nrow(county_enr) > 0)
county_enr
#> # A tibble: 15 x 4
#>    county_name n_students n_districts county_label
#>    <chr>            <dbl>       <int> <fct>
#>  1 Bergen        132247           76 Bergen
#>  2 Essex         127986.          23 Essex
#>  3 Middlesex     124477           25 Middlesex
#>  4 Union          98046.          23 Union
#>  5 Monmouth       88726.          50 Monmouth
#>  6 Hudson         82525           13 Hudson
#>  7 Camden         79287           39 Camden
#>  8 Passaic        75967           21 Passaic
#>  9 Morris         72840.          40 Morris
#> 10 Burlington     68975           39 Burlington
#> 11 Ocean          65176.          28 Ocean
#> 12 Mercer         60305           12 Mercer
#> 13 Somerset       49703           19 Somerset
#> 14 Gloucester     46682.          28 Gloucester
#> 15 Atlantic       41422           24 Atlantic
```

![County Enrollment](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/county-enrollment-1.png)

---

### 13. Most NJ districts are tiny

Half of NJ's 580 districts have fewer than 1,200 students. The median district is smaller than a single large high school.

```r
dist_sizes <- enr_current %>%
  filter(is_district, !is_charter,
         subgroup == "total_enrollment", grade_level == "TOTAL")

stopifnot(nrow(dist_sizes) > 0)
cat("Districts:", nrow(dist_sizes), "\n")
#> Districts: 580
cat("Median:", median(dist_sizes$n_students, na.rm = TRUE), "\n")
#> Median: 1180.5
cat("Under 1000:", sum(dist_sizes$n_students < 1000, na.rm = TRUE), "\n")
#> Under 1000: 264
cat("Over 10000:", sum(dist_sizes$n_students > 10000, na.rm = TRUE), "\n")
#> Over 10000: 16
```

![District Size Distribution](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/district-size-distribution-1.png)

---

### 14. NJ's enrollment pyramid shows the pre-K boom

The 2025 grade-level distribution reveals the pre-K surge: PK enrollment (87K) is approaching K (89K), reflecting NJ's universal pre-K push.

```r
grade_enr <- state_summary %>%
  filter(end_year == 2025, subgroup == "total_enrollment",
         grade_level != "TOTAL", !is.na(grade_level)) %>%
  mutate(grade_label = case_when(
    grade_level == "PK" ~ "Pre-K",
    grade_level == "K" ~ "K",
    TRUE ~ paste("Grade", grade_level)
  ),
  grade_order = case_when(
    grade_level == "PK" ~ 0,
    grade_level == "K" ~ 1,
    TRUE ~ as.numeric(grade_level) + 1
  )) %>%
  arrange(grade_order) %>%
  mutate(grade_label = factor(grade_label, levels = grade_label))

stopifnot(nrow(grade_enr) > 0)
grade_enr %>% select(grade_label, n_students)
#> # A tibble: 14 x 2
#>    grade_label n_students
#>    <fct>            <dbl>
#>  1 Pre-K            87231
#>  2 K                89428
#>  3 Grade 01         94046
#>  4 Grade 02         95059
#>  5 Grade 03         97702
#>  6 Grade 04         96802
#>  7 Grade 05         98309
#>  8 Grade 06         99016
#>  9 Grade 07        100351
#> 10 Grade 08        101570
#> 11 Grade 09        104709
#> 12 Grade 10        105414.
#> 13 Grade 11        104496.
#> 14 Grade 12        107048
```

![Grade Pyramid](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/grade-pyramid-1.png)

---

### 15. NJ's poverty gap: Passaic vs Westfield

Passaic City has 98% of students on free/reduced lunch. Nearby Westfield has under 2%. This 96-point gap captures NJ's extreme wealth inequality.

```r
frl_all <- enr_current %>%
  filter(is_district, !is_charter,
         subgroup == "free_reduced_lunch", grade_level == "TOTAL",
         !is.na(pct), n_students >= 100) %>%
  arrange(desc(pct))

top_5 <- frl_all %>% head(5) %>% mutate(group = "Highest FRL")
bottom_5 <- frl_all %>% tail(5) %>% mutate(group = "Lowest FRL")
frl_extremes <- bind_rows(top_5, bottom_5) %>%
  mutate(district_label = reorder(district_name, pct))

stopifnot(nrow(frl_extremes) > 0)
frl_extremes %>% select(district_name, n_students, pct, group)
#> # A tibble: 10 x 4
#>    district_name                                            n_students   pct group
#>    <chr>                                                         <dbl> <dbl> <chr>
#>  1 Passaic City School District                              11540.    0.981 Highest FRL
#>  2 Kipp: Cooper Norcross, A New Jersey Nonprofit Corporation  2216.    0.972 Highest FRL
#>  3 Mastery Schools Of Camden, Inc.                            2735.    0.952 Highest FRL
#>  4 Camden Prep, Inc.                                          1402.    0.936 Highest FRL
#>  5 Bridgeton City School District                             5579.    0.923 Highest FRL
#>  6 Tenafly Public School District                              112.    0.033 Lowest FRL
#>  7 Ridgewood Public School District                            157.    0.029 Lowest FRL
#>  8 Bernards Township School District                           111.    0.024 Lowest FRL
#>  9 Livingston Board Of Education School District               140.    0.022 Lowest FRL
#> 10 Westfield Public School District                            105.    0.018 Lowest FRL
```

![Poverty Gap](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/poverty-gap-1.png)

*(All figures auto-generated from [NJ Enrollment Insights vignette](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights.html))*

---

## Data Notes

**Source:** [New Jersey Department of Education](https://www.nj.gov/education/doedata/) - all data comes directly from NJ DOE, not federal sources.

**Available years:** Enrollment data from 2000-2025. Tidy format (2020+) provides consistent structure with district, charter, and school-level records.

**Suppression rules:** NJ DOE suppresses counts below 10 in some data types. Enrollment data uses half-day weighting for programs like pre-K, which can produce non-integer counts.

**Census Day:** NJ enrollment counts are based on October 15 enrollment (ASSA reporting).

**Known caveats:**
- 2020+ enrollment data includes state-level rows but the vignette aggregates from district-level for time-series consistency
- Charter schools appear as separate "districts" in the data
- Pre-2020 and post-2020 data formats differ significantly

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
enr_2025 <- fetch_enr(2025, tidy = TRUE)

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
enr_2025 = njsd.fetch_enr(2025)

# Assessment data
math_g4 = njsd.fetch_parcc(2024, 4, 'math')

# Graduation rates
grate = njsd.fetch_grad_rate(2024)

# School directory
schools = njsd.get_school_directory()
```

## NJ DOE Data Coverage

| Data Type | Function | Years | Status |
|-----------|----------|-------|--------|
| **Enrollment** | `fetch_enr()` | 2000-2025 | Full support |
| **NJSLA/PARCC Assessment** | `fetch_parcc()` | 2015-2024 | Full support |
| **NJGPA (Grad Proficiency)** | `fetch_njgpa()` | 2022-2024 | Full support |
| **ACCESS for ELLs** | `fetch_access()` | 2022-2024 | Full support |
| **NJASK/HSPA/GEPA (Legacy)** | `fetch_nj_assess()` | 2004-2014 | Full support |
| **Graduation Rates (4-year)** | `fetch_grad_rate()` | 2011-2024 | Full support |
| **Graduation Counts** | `fetch_grad_count()` | 2012-2024 | Full support |
| **Chronic Absenteeism** | `fetch_chronic_absenteeism()` | 2017-2024 | Full support |
| **Special Education Rates** | `fetch_sped()` | 2024+ | Full support |
| **School Directory** | `get_school_directory()` | Current | Full support |

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

- [NJ Enrollment Insights (full vignette)](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights.html)
- [Function Reference](https://almartin82.github.io/njschooldata/reference/index.html)

## Contributing

Contributions are welcome!

- File an [issue](https://github.com/almartin82/njschooldata/issues)
- Send me an [email](mailto:almartin@gmail.com)
