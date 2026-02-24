# njschooldata

A simple interface for accessing NJ DOE school data in **R and Python**

**25+ years of enrollment data. 1.4 million students. 600+ districts.
Here are 10 stories in the data…**

------------------------------------------------------------------------

### 1. New Jersey Educates 1.4 Million Students

Statewide public school enrollment has held relatively steady over the
past decade.

![Statewide Enrollment](reference/figures/statewide-enrollment.png)

Statewide Enrollment

------------------------------------------------------------------------

### 2. Newark Leads the Charter School Revolution

Over 30% of Newark students now attend charter schools - one of the
highest rates in the nation.

![Newark Charter](reference/figures/newark-charter.png)

Newark Charter

------------------------------------------------------------------------

### 3. Hispanic Students are the Fastest-Growing Group

Hispanic enrollment has grown from 20% to nearly 30% of all NJ students.

![Hispanic Growth](reference/figures/hispanic-growth.png)

Hispanic Growth

------------------------------------------------------------------------

### 4. The Big Three: Newark, Jersey City, and Paterson

Combined enrollment of over 100,000 students - nearly 8% of the state.

![Big Three](reference/figures/big-three.png)

Big Three

------------------------------------------------------------------------

### 5. COVID Hit Kindergarten Hard

New Jersey lost nearly 10% of kindergartners in 2021 - and enrollment
hasn’t fully recovered.

![COVID Kindergarten](reference/figures/covid-kindergarten.png)

COVID Kindergarten

------------------------------------------------------------------------

### 6. Economic Disadvantage Varies Widely

Some districts approach 100% economically disadvantaged while affluent
suburbs have under 5%.

![Economic Disadvantage](reference/figures/econ-disadvantage.png)

Economic Disadvantage

------------------------------------------------------------------------

### 7. White Student Share Has Declined Dramatically

NJ public schools are now majority-minority.

![Demographic Shift](reference/figures/demographic-shift.png)

Demographic Shift

------------------------------------------------------------------------

### 8. English Learners Concentrated in Urban Areas

Some districts have over 20% ELL students, while most suburban districts
have under 1%.

![ELL Concentration](reference/figures/ell-concentration.png)

ELL Concentration

------------------------------------------------------------------------

### 9. Top 10 Districts Educate 20% of All Students

Just 10 out of 600+ districts serve one-fifth of all NJ students.

![Top 10 Districts](reference/figures/top-10-districts.png)

Top 10 Districts

------------------------------------------------------------------------

### 10. Special Education Rates Remain Steady

About 17-18% of NJ students receive special education services - among
the highest rates nationally.

![Special Education](reference/figures/special-education.png)

Special Education

------------------------------------------------------------------------

## Installation

### R

``` r
# Install from GitHub using remotes (recommended)
remotes::install_github("almartin82/njschooldata")
library(njschooldata)
```

### Python

Python bindings require R and the njschooldata R package to be installed
first.

``` bash
# Install R package first
Rscript -e "remotes::install_github('almartin82/njschooldata')"

# Install Python bindings
pip install git+https://github.com/almartin82/njschooldata.git#subdirectory=python
```

## NJ DOE Data Coverage

### Supported Data Sources

| Data Type                     | Function                                                                                                          | Years       | Status          |
|-------------------------------|-------------------------------------------------------------------------------------------------------------------|-------------|-----------------|
| **Enrollment**                | [`fetch_enr()`](https://almartin82.github.io/njschooldata/reference/fetch_enr.md)                                 | 2000-2025   | ✅ Full support |
| **NJSLA/PARCC Assessment**    | [`fetch_parcc()`](https://almartin82.github.io/njschooldata/reference/fetch_parcc.md)                             | 2015-2024   | ✅ Full support |
| **NJGPA (Grad Proficiency)**  | [`fetch_njgpa()`](https://almartin82.github.io/njschooldata/reference/fetch_njgpa.md)                             | 2022-2024   | ✅ Full support |
| **ACCESS for ELLs**           | [`fetch_access()`](https://almartin82.github.io/njschooldata/reference/fetch_access.md)                           | 2022-2024   | ✅ Full support |
| **NJASK/HSPA/GEPA (Legacy)**  | `fetch_nj_assess()`                                                                                               | 2004-2014   | ✅ Full support |
| **Graduation Rates (4-year)** | [`fetch_grad_rate()`](https://almartin82.github.io/njschooldata/reference/fetch_grad_rate.md)                     | 2011-2024   | ✅ Full support |
| **Graduation Rates (5-year)** | [`fetch_grad_rate()`](https://almartin82.github.io/njschooldata/reference/fetch_grad_rate.md)                     | 2012-2019   | ✅ Full support |
| **Graduation Rates (6-year)** | [`fetch_6yr_grad_rate()`](https://almartin82.github.io/njschooldata/reference/fetch_6yr_grad_rate.md)             | 2021-2024   | ✅ Full support |
| **Graduation Counts**         | [`fetch_grad_count()`](https://almartin82.github.io/njschooldata/reference/fetch_grad_count.md)                   | 2012-2024   | ✅ Full support |
| **Chronic Absenteeism**       | [`fetch_chronic_absenteeism()`](https://almartin82.github.io/njschooldata/reference/fetch_chronic_absenteeism.md) | 2017-2024\* | ✅ Full support |
| **Postsecondary Enrollment**  | [`fetch_postsecondary()`](https://almartin82.github.io/njschooldata/reference/fetch_postsecondary.md)             | Current     | ✅ Full support |
| **Special Education Rates**   | [`fetch_sped()`](https://almartin82.github.io/njschooldata/reference/fetch_sped.md)                               | 2024+       | ✅ Full support |
| **School Directory**          | [`get_school_directory()`](https://almartin82.github.io/njschooldata/reference/get_school_directory.md)           | Current     | ✅ Full support |
| **District Directory**        | [`get_district_directory()`](https://almartin82.github.io/njschooldata/reference/get_district_directory.md)       | Current     | ✅ Full support |
| **District Factor Groups**    | [`fetch_dfg()`](https://almartin82.github.io/njschooldata/reference/fetch_dfg.md)                                 | 1990, 2000  | ✅ Full support |
| **Taxpayer’s Guide (TGES)**   | [`fetch_tges()`](https://almartin82.github.io/njschooldata/reference/fetch_tges.md)                               | 1999-2019   | ✅ Full support |
| **Performance Reports**       | `get_rc_database()`                                                                                               | 2003-2019   | ✅ Full support |
| **Student Growth (mSGP)**     | [`fetch_msgp()`](https://almartin82.github.io/njschooldata/reference/fetch_msgp.md)                               | 2012-2015   | ✅ Historical   |

*\*2020-2021 chronic absenteeism not reported due to COVID*

### Not Yet Supported

| Data Type                      | NJ DOE Source      | Status             |
|--------------------------------|--------------------|--------------------|
| Staff/Teacher Census           | NJ DOE Data Portal | ❌ Not implemented |
| Teacher Certification          | NJ DOE Licensing   | ❌ Not implemented |
| Career/Technical Ed (CTE)      | CTE Reports        | ❌ Not implemented |
| Suspension/Discipline          | Civil Rights Data  | ❌ Not implemented |
| Per-Pupil Spending (post-2019) | State Aid          | ❌ Not implemented |
| School Climate Surveys         | NJ DOE             | ❌ Not implemented |
| AP/IB Participation            | College Board      | ❌ Not implemented |
| SAT/ACT Scores (post-2019)     | College Board      | ❌ Not implemented |

### Data Gaps

| Gap                           | Reason                        |
|-------------------------------|-------------------------------|
| 2020 Assessments              | Cancelled due to COVID-19     |
| 2020-2021 Chronic Absenteeism | Not reported due to COVID     |
| 5-Year Graduation (2020+)     | No longer published by NJ DOE |
| Performance Reports (2020+)   | Format discontinued           |

## Quick Start

### R

``` r
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

``` python
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

## Assessment History

NJ has used several assessment systems over the years:

| Assessment | Years        | Grades             | Notes                               |
|------------|--------------|--------------------|-------------------------------------|
| **NJSLA**  | 2019-present | 3-10 ELA, 3-8 Math | Current assessment (2020 cancelled) |
| **PARCC**  | 2015-2018    | 3-11               | Common Core aligned                 |
| **NJASK**  | 2004-2014    | 3-8                | Previous state assessment           |
| **HSPA**   | Through 2014 | 11                 | High school graduation requirement  |
| **GEPA**   | Through 2007 | 8                  | Grade 8 proficiency                 |

## Learn More

- [Getting Started
  Guide](https://almartin82.github.io/njschooldata/articles/getting-started.html)
- [NJ Enrollment
  Insights](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights.html)
- [Function
  Reference](https://almartin82.github.io/njschooldata/reference/index.html)

## Contributing

Contributions are welcome!

- File an [issue](https://github.com/almartin82/njschooldata/issues)
- Send me an [email](mailto:almartin@gmail.com)
