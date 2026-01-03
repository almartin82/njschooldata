# njschooldata

A simple interface for accessing NJ DOE school data in **R and Python**

> It is often said that 80% of data analysis is spent on the process of
> cleaning and preparing the data (Dasu and Johnson 2003). Data
> preparation is not just a first step, but must be repeated many over
> the course of analysis as new problems come to light or new data is
> collected. -[@hadley](http://vita.had.co.nz/papers/tidy-data.pdf)

The State of NJ has been posting raw, fixed width text files with all
the assessment results for NJ schools/districts for well over a decade
now. **That’s great!**

Unfortunately, those files are a bit of a pain to work with, especially
if you’re trying to work with multiple grades, or multiple years of
data. Layouts change; file paths aren’t consistent, etc.

`njschooldata` attempts to simplify the task of working with NJ
education data by providing a concise and consistent interface for
reading state files into R. We make heavy use of the
[tidyverse](https://www.tidyverse.org/) and aim to create a consistent,
pipeable interface into NJ state education data.

## Installation

### R

``` r
# Install from GitHub using remotes (recommended)
remotes::install_github("almartin82/njschooldata")

# Or using devtools
devtools::install_github("almartin82/njschooldata")

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

## Data Coverage

| Data Type         | Years Available | Function                                                                                        |
|-------------------|-----------------|-------------------------------------------------------------------------------------------------|
| Enrollment        | 1999-2025       | [`fetch_enr()`](https://almartin82.github.io/njschooldata/reference/fetch_enr.md)               |
| NJSLA Assessment  | 2019-2024       | [`fetch_parcc()`](https://almartin82.github.io/njschooldata/reference/fetch_parcc.md)           |
| PARCC Assessment  | 2015-2018       | [`fetch_parcc()`](https://almartin82.github.io/njschooldata/reference/fetch_parcc.md)           |
| NJASK Assessment  | 2004-2014       | `fetch_nj_assess()`                                                                             |
| Graduation Rates  | 2011-2024       | [`fetch_grad_rate()`](https://almartin82.github.io/njschooldata/reference/fetch_grad_rate.md)   |
| Graduation Counts | 2012-2024       | [`fetch_grad_count()`](https://almartin82.github.io/njschooldata/reference/fetch_grad_count.md) |

**Note**: The 2019-20 school year assessments were cancelled due to
COVID-19.

## Usage

### R

``` r
# Get 2024 enrollment data
enr_2024 <- fetch_enr(2024)

# Get assessment data
math_2023 <- fetch_parcc(end_year = 2023, grade_or_subj = 4, subj = 'math')

# Get school directory
schools <- get_school_directory()
```

### Python

``` python
import njschooldata as njsd

# Get 2024 enrollment data
enr_2024 = njsd.fetch_enr(2024)

# Get assessment data
math_2023 = njsd.fetch_parcc(2023, 4, 'math')

# Get school directory
schools = njsd.get_school_directory()
```

### More R Examples

#### Enrollment Data

``` r
# Get 2024 enrollment data
enr_2024 <- fetch_enr(2024)

# Get enrollment data in tidy format
enr_2024_tidy <- fetch_enr(2024, tidy = TRUE)
```

### Assessment Data (NJSLA/PARCC)

``` r
# Get 2023 Grade 4 Math NJSLA data
math_2023 <- fetch_parcc(end_year = 2023, grade_or_subj = 4, subj = 'math')

# Get 2023 Grade 8 ELA data
ela_2023 <- fetch_parcc(end_year = 2023, grade_or_subj = 8, subj = 'ela')

# Get Algebra 1 results
alg1_2023 <- fetch_parcc(end_year = 2023, grade_or_subj = 'ALG1', subj = 'math')
```

### Legacy Assessment Data (NJASK, 2004-2014)

``` r
# Get 2010 grade 5 NJASK data
njask_2010 <- fetch_nj_assess(end_year = 2010, grade = 5)

# Get tidy format for longitudinal analysis
njask_2010_tidy <- fetch_nj_assess(end_year = 2010, grade = 5, tidy = TRUE)
```

### Graduation Data

``` r
# Get 2023 graduation rates
grate_2023 <- fetch_grad_rate(end_year = 2023)

# Get 5-year graduation rates
grate_2023_5yr <- fetch_grad_rate(end_year = 2023, methodology = '5 year')

# Get graduation counts
gcount_2023 <- fetch_grad_count(end_year = 2023)
```

### School and District Directories

``` r
# Get current school directory with metadata
schools <- get_school_directory()

# Get current district directory
districts <- get_district_directory()
```

## Assessment History

NJ has used several assessment systems over the years:

- **NJASK** (NJ Assessment of Skills and Knowledge): 2004-2014, Grades
  3-8
- **HSPA** (High School Proficiency Assessment): Through 2014, Grade 11
- **GEPA** (Grade Eight Proficiency Assessment): Through 2007, Grade 8
- **PARCC**: 2015-2018, aligned to Common Core
- **NJSLA** (NJ Student Learning Assessment): 2019-present (2020
  cancelled due to COVID)

## Longitudinal Analysis

The flat files provided by the state are a bit painful to work with. The
layout isn’t consistent across years or assessments, making longitudinal
analysis challenging.

`fetch_nj_assess` and `fetch_enr` have a `tidy` parameter that returns a
processed version of the data designed to facilitate longitudinal
analysis with consistent data frame structure.

## Contributing

Contributions are welcome!

Comments? Questions? Problems? Want to contribute to development? - File
an [issue](https://github.com/almartin82/njschooldata/issues) - Send me
an [email](mailto:almartin@gmail.com)
