# njschooldata

<!-- badges: start -->
[![R-CMD-check](https://github.com/almartin82/njschooldata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/almartin82/njschooldata/actions/workflows/R-CMD-check.yaml)
[![Python Tests](https://github.com/almartin82/njschooldata/actions/workflows/python-test.yaml/badge.svg)](https://github.com/almartin82/njschooldata/actions/workflows/python-test.yaml)
[![pkgdown](https://github.com/almartin82/njschooldata/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/almartin82/njschooldata/actions/workflows/pkgdown.yaml)
[![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
<!-- badges: end -->

New Jersey's education data spans 25+ years, 1.4 million students, and 600+ districts -- but accessing it requires parsing dozens of inconsistent file formats across enrollment, assessments, graduation, spending, absenteeism, and more. This package does that for you in one line of R or Python.

The original package in the [njschooldata](https://github.com/almartin82/njschooldata) family -- the mothership from which all 50 state packages descend.

**[Full documentation](https://almartin82.github.io/njschooldata/)** -- getting-started guide, enrollment insights, and complete function reference.

## Highlights

```r
library(njschooldata)
library(ggplot2)
library(dplyr)
library(scales)

theme_nj <- function() {
  theme_minimal(base_size = 14) +
    theme(
      plot.title = element_text(face = "bold", size = 16),
      plot.subtitle = element_text(color = "gray40"),
      panel.grid.minor = element_blank(),
      legend.position = "bottom"
    )
}

colors <- c("total" = "#2C3E50", "white" = "#3498DB", "black" = "#E74C3C",
            "hispanic" = "#F39C12", "asian" = "#9B59B6", "charter" = "#1ABC9C")
```

```r
# Fetch recent years of enrollment data
years <- 2015:2025
enr_all <- purrr::map_df(years, ~{
  tryCatch(fetch_enr(.x, tidy = TRUE, use_cache = TRUE), error = function(e) NULL)
})

enr_current <- fetch_enr(2025, tidy = TRUE, use_cache = TRUE)
enr_2015 <- fetch_enr(2015, tidy = TRUE, use_cache = TRUE)
```

### 1. Newark leads the charter school revolution

Newark has one of the highest charter school enrollment rates in the nation - over 30% of students attend charter schools.

```r
newark <- enr_all %>%
  filter(grepl("Newark", district_name, ignore.case = TRUE),
         is_district | is_charter,
         subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  mutate(sector = ifelse(is_charter, "Charter", "Traditional"))

newark_summary <- newark %>%
  group_by(end_year, sector) %>%
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop")

ggplot(newark_summary, aes(x = end_year, y = n_students, fill = sector)) +
  geom_area(alpha = 0.8) +
  scale_y_continuous(labels = comma) +
  scale_fill_manual(values = c("Charter" = colors["charter"], "Traditional" = colors["total"])) +
  labs(title = "Newark Leads the Charter School Revolution",
       subtitle = "Over 30% of Newark students now attend charter schools",
       x = "School Year", y = "Students", fill = "") +
  theme_nj()
```

![Newark charter](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/newark-charter-1.png)

[(source)](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights.html#newark-leads-the-charter-school-revolution)

### 2. White student share has declined dramatically

White students went from majority to minority status in NJ public schools over the past two decades.

```r
demo <- enr_all %>%
  filter(is_state, subgroup %in% c("white", "hispanic", "black", "asian"),
         grade_level == "TOTAL") %>%
  mutate(subgroup = factor(subgroup, levels = c("white", "hispanic", "black", "asian")))

ggplot(demo, aes(x = end_year, y = pct * 100, color = subgroup)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  scale_color_manual(values = colors, labels = c("White", "Hispanic", "Black", "Asian")) +
  labs(title = "White Student Share Has Declined Dramatically",
       subtitle = "NJ public schools are now majority-minority",
       x = "School Year", y = "Percent of Students", color = "") +
  theme_nj()
```

![Demographic shift](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/demographic-shift-1.png)

[(source)](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights.html#white-student-share-has-declined-dramatically)

### 3. COVID hit kindergarten hard

New Jersey lost nearly 10% of kindergartners in 2021 - and enrollment hasn't fully recovered.

```r
k_trend <- enr_all %>%
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("PK", "KF", "01", "06", "12")) %>%
  mutate(grade_label = case_when(
    grade_level == "PK" ~ "Pre-K",
    grade_level == "KF" ~ "Kindergarten",
    grade_level == "01" ~ "Grade 1",
    grade_level == "06" ~ "Grade 6",
    grade_level == "12" ~ "Grade 12",
    TRUE ~ grade_level
  ))

ggplot(k_trend, aes(x = end_year, y = n_students, color = grade_label)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  geom_vline(xintercept = 2021, linetype = "dashed", color = "red", alpha = 0.5) +
  scale_y_continuous(labels = comma) +
  labs(title = "COVID Hit New Jersey Kindergarten Hard",
       subtitle = "Lost nearly 10% of kindergartners in 2021 - still recovering",
       x = "School Year", y = "Students", color = "") +
  theme_nj()
```

![COVID kindergarten](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/covid-kindergarten-1.png)

[(source)](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights.html#covid-hit-kindergarten-hard)

## Data Taxonomy

| Category | Years | Function | Details |
|----------|-------|----------|---------|
| **Enrollment** | 2000-2025 | `fetch_enr()` | State, district, school. Race, gender, FRPL, SpEd, LEP |
| **Assessments** | 2004-2024 | `fetch_parcc()` / `fetch_njgpa()` / `fetch_old_nj_assess()` | NJSLA (2019+), PARCC (2015-18), NJASK/HSPA/GEPA (2004-14). ELA, math, science |
| **Graduation** | 2011-2024 | `fetch_grad_rate()` / `fetch_grad_count()` / `fetch_6yr_grad_rate()` | 4-yr, 5-yr, 6-yr rates + counts. State, district, school |
| **Directory** | Current | `get_school_directory()` / `get_district_directory()` | Address, phone, CDS code, school type |
| **Per-Pupil Spending** | 1999-2019 | `fetch_tges()` | 20+ budget indicators, staffing ratios, salaries |
| **Accountability** | 2003-2019 | `get_one_rc_database()` / `get_essa_file()` | Performance reports, SAT, AP, college matric |
| **Chronic Absence** | 2017-2024 | `fetch_chronic_absenteeism()` | School-level, by race/gender/disability/EL/econ status |
| **EL Progress** | 2022-2024 | `fetch_access()` | ACCESS for ELLs, proficiency levels L1-L6, by grade |
| **Special Ed** | 2024-2025 | `fetch_sped()` | Classification rates, district-level |
| **Postsecondary Enrollment** | Multi-year | `fetch_postsecondary()` | Fall + 16-month rates, school + district |
| **District Factor Groups** | 1990, 2000 | `fetch_dfg()` | SES classification (A-J) for peer comparison |
| **Student Growth (mSGP)** | 2012-2015 | `fetch_msgp()` | Median student growth percentiles, ELA + math |

> See the full [data category taxonomy](DATA-CATEGORY-TAXONOMY.md) for what each category covers.

## Quick Start

### R

```R
# Install from GitHub using remotes (recommended)
remotes::install_github("almartin82/njschooldata")
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

Python bindings require R and the njschooldata R package to be installed first.

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

## Explore More

Full analysis with enrollment insights:
- [New Jersey Enrollment Insights](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights.html) -- 10 stories
- [10 Insights from NJ School Enrollment Data](https://almartin82.github.io/njschooldata/articles/enrollment_hooks.html) -- 10 stories
- [Getting Started](https://almartin82.github.io/njschooldata/articles/getting-started.html)
- [Function reference](https://almartin82.github.io/njschooldata/reference/)

## Data Notes

- **Source**: [NJ Department of Education Data Center](https://www.nj.gov/education/doedata/)
- **Enrollment years**: 2000-2025
- **Assessment years**: 2004-2024 (2020 cancelled due to COVID-19)
- **Graduation years**: 2011-2024 (4-yr); 2012-2019 (5-yr); 2021-2024 (6-yr)
- **Chronic absenteeism**: 2017-2024 (2020-2021 not reported due to COVID)
- **Suppression**: Small cell sizes suppressed with `*` or `N`
- **Assessment history**: NJSLA (2019+), PARCC (2015-18), NJASK (2004-14), HSPA (through 2014), GEPA (through 2007)
- **CDS codes**: County-District-School identifier system (e.g., 13-3570-050)
- **Caching**: Session caching enabled by default to avoid NJ DOE bot protection

## Deeper Dive

### 4. New Jersey educates 1.4 million students

New Jersey has one of the largest public school systems in the country, with enrollment holding relatively steady over the past decade.

```r
state_total <- enr_all %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL")

ggplot(state_total, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma, limits = c(0, NA)) +
  labs(title = "New Jersey Educates 1.4 Million Students",
       subtitle = "Statewide public school enrollment has held steady",
       x = "School Year", y = "Students") +
  theme_nj()
```

![Statewide enrollment](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/statewide-enrollment-1.png)

[(source)](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights.html#new-jersey-educates-1.4-million-students)

### 5. Hispanic students are the fastest-growing group

Hispanic enrollment has grown from 20% to nearly 30% of all NJ students in two decades.

```r
hispanic <- enr_all %>%
  filter(is_state, subgroup == "hispanic", grade_level == "TOTAL")

ggplot(hispanic, aes(x = end_year, y = pct * 100)) +
  geom_line(linewidth = 1.5, color = colors["hispanic"]) +
  geom_point(size = 3, color = colors["hispanic"]) +
  labs(title = "Hispanic Students are the Fastest-Growing Group",
       subtitle = "From 20% to nearly 30% of all NJ students",
       x = "School Year", y = "Percent Hispanic") +
  theme_nj()
```

![Hispanic growth](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/hispanic-growth-1.png)

[(source)](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights.html#hispanic-students-are-the-fastest-growing-group)

### 6. The Big Three: Newark, Jersey City, and Paterson

New Jersey's three largest districts educate over 100,000 students combined - nearly 8% of the state.

```r
big_three <- c("Newark", "Jersey City", "Paterson")
big_three_trend <- enr_all %>%
  filter(is_district,
         grepl(paste(big_three, collapse = "|"), district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL")

ggplot(big_three_trend, aes(x = end_year, y = n_students, color = district_name)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  scale_y_continuous(labels = comma) +
  labs(title = "The Big Three: Newark, Jersey City, and Paterson",
       subtitle = "Combined enrollment of over 100,000 students",
       x = "School Year", y = "Students", color = "") +
  theme_nj()
```

![Big three](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/big-three-1.png)

[(source)](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights.html#the-big-three-newark-jersey-city-and-paterson)

### 7. Economic disadvantage varies widely

Some districts have nearly 100% economically disadvantaged students, while affluent suburbs have under 5%.

```r
econ <- enr_current %>%
  filter(is_district, subgroup == "econ_disadv", grade_level == "TOTAL",
         !is.na(pct), n_students >= 100) %>%
  arrange(desc(pct)) %>%
  head(15) %>%
  mutate(district_label = reorder(district_name, pct))

ggplot(econ, aes(x = district_label, y = pct * 100)) +
  geom_col(fill = colors["total"]) +
  coord_flip() +
  labs(title = "Economic Disadvantage Varies Widely",
       subtitle = "Some districts approach 100% economically disadvantaged",
       x = "", y = "Percent Economically Disadvantaged") +
  theme_nj()
```

![Economic disadvantage](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/econ-disadvantage-1.png)

[(source)](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights.html#economic-disadvantage-varies-widely)

### 8. English Language Learners concentrated in urban areas

ELL students make up over 20% in some districts but under 1% in most suburban districts.

```r
ell <- enr_current %>%
  filter(is_district, subgroup == "lep_current", grade_level == "TOTAL",
         !is.na(pct), n_students >= 50) %>%
  arrange(desc(pct)) %>%
  head(15) %>%
  mutate(district_label = reorder(district_name, pct))

ggplot(ell, aes(x = district_label, y = pct * 100)) +
  geom_col(fill = colors["hispanic"]) +
  coord_flip() +
  labs(title = "English Learners Concentrated in Urban Areas",
       subtitle = "Some districts have over 20% ELL students",
       x = "", y = "Percent English Language Learners") +
  theme_nj()
```

![ELL concentration](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/ell-concentration-1.png)

[(source)](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights.html#english-language-learners-concentrated-in-urban-areas)

### 9. Top 10 districts educate 20% of all students

Concentration at the top: just 10 districts out of 600+ serve one-fifth of all NJ students.

```r
top_10 <- enr_current %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  head(10) %>%
  mutate(district_label = reorder(district_name, n_students))

ggplot(top_10, aes(x = district_label, y = n_students)) +
  geom_col(fill = colors["total"]) +
  coord_flip() +
  scale_y_continuous(labels = comma) +
  labs(title = "Top 10 Districts Educate 20% of All Students",
       subtitle = "Just 10 out of 600+ districts serve one-fifth of NJ students",
       x = "", y = "Students") +
  theme_nj()
```

![Top 10 districts](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/top-10-districts-1.png)

[(source)](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights.html#top-10-districts-educate-20-of-all-students)

### 10. Special education rates remain steady

About 17-18% of NJ students receive special education services - among the highest rates nationally.

```r
sped <- enr_all %>%
  filter(is_state, subgroup == "special_education", grade_level == "TOTAL")

ggplot(sped, aes(x = end_year, y = pct * 100)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  labs(title = "Special Education Rates Remain Steady",
       subtitle = "About 17-18% of NJ students - among highest rates nationally",
       x = "School Year", y = "Percent Special Education") +
  theme_nj()
```

![Special education](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights_files/figure-html/special-ed-1.png)

[(source)](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights.html#special-education-rates-remain-steady)
