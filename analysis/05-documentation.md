# Documentation Analysis

## README.md Assessment

### Current State

**Strengths**:
- Clear package description
- Explains the problem being solved
- Installation instructions present
- Basic usage examples

**Issues**:

1. **Outdated Examples**:
   ```r
   # README claims PARCC data 2015-2017
   fetch_parcc(end_year = 2017, grade_or_subj = 'ALG1', subj = 'math')
   ```
   - PARCC was replaced by NJSLA in 2019
   - Package supports through 2019 but README doesn't mention NJSLA

2. **Missing Coverage Information**:
   - No mention of NJSLA (2019+)
   - No mention of enrollment data through 2023
   - Graduation data coverage not specified

3. **Missing Modern Installation**:
   ```r
   # Current - uses deprecated devtools syntax
   library("devtools")
   devtools::install_github("almartin82/njschooldata")

   # Should also show remotes (preferred)
   remotes::install_github("almartin82/njschooldata")
   ```

4. **No Badges**: Missing:
   - R-CMD-check status
   - Code coverage
   - CRAN status (if applicable)
   - Lifecycle stage

5. **No Function Reference**: Should link to pkgdown site

### Recommended README Structure

```markdown
# njschooldata

<!-- badges: start -->
[![R-CMD-check](https://github.com/almartin82/njschooldata/actions/workflows/R-CMD-check.yaml/badge.svg)](...)
[![Codecov](https://codecov.io/gh/almartin82/njschooldata/branch/master/graph/badge.svg)](...)
[![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](...)
<!-- badges: end -->

## Overview
[Package description]

## Installation
[Installation instructions]

## Quick Start
[Basic usage examples]

## Data Coverage
| Data Type | Years Available | Function |
|-----------|-----------------|----------|
| Enrollment | 1999-2024 | `fetch_enr()` |
| NJSLA Assessment | 2019-2024 | `fetch_parcc()` |
| PARCC Assessment | 2015-2018 | `fetch_parcc()` |
| NJASK Assessment | 2004-2014 | `fetch_nj_assess()` |
| Graduation Rates | 2011-2024 | `fetch_grad_rate()` |

## Getting Help
[Links to documentation, issues]

## Contributing
[Contribution guidelines]
```

## Roxygen2 Documentation

### Coverage Statistics

| Category | Total Functions | Documented | With @examples |
|----------|----------------|------------|----------------|
| Exported | 155 | ~150 | ~5 |
| Internal | ~20 | ~5 | 0 |

### Documentation Quality Issues

1. **Missing @examples** (Almost Universal)

   Most exported functions lack runnable examples:
   ```r
   #' @title gets and processes a NJ enrollment file
   #' @param end_year a school year...
   #' @param tidy if TRUE...
   #' @export
   fetch_enr <- function(end_year, tidy=FALSE) {
   ```

   Should have:
   ```r
   #' @examples
   #' \dontrun{
   #'   # Get 2023 enrollment data
   #'   enr_2023 <- fetch_enr(2023)
   #'
   #'   # Get tidy format
   #'   enr_2023_tidy <- fetch_enr(2023, tidy = TRUE)
   #' }
   ```

2. **Incomplete @param Descriptions**
   ```r
   # enr.R - missing valid year range
   #' @param end_year a school year.  year is the end of the academic year - eg 2006-07
   #' school year is year '2007'.  valid values are 1999-2019.
   ```
   - Says 2019 but supports through 2023+

3. **Missing @return for Many Functions**
   ```r
   # Many functions lack return documentation
   #' @title clean enrollment names
   #' @param df a enr data frame
   #' @export
   clean_enr_names <- function(df) {
   ```

   Should have:
   ```r
   #' @return A data frame with standardized column names
   ```

4. **Inconsistent @title Usage**
   - Some use `#' @title` explicitly
   - Some rely on first line as title
   - Should standardize

5. **Missing @seealso Cross-References**
   Related functions should link to each other:
   ```r
   #' @seealso \code{\link{fetch_enr}} for the main entry point,
   #'   \code{\link{tidy_enr}} for tidying results
   ```

### Priority Functions Needing @examples

1. `fetch_enr()` - Primary enrollment function
2. `fetch_parcc()` - Assessment data (NJSLA)
3. `fetch_grad_rate()` - Graduation rates
4. `fetch_grad_count()` - Graduate counts
5. `fetch_nj_assess()` - Legacy assessment data
6. `get_school_directory()` - School metadata
7. `get_district_directory()` - District metadata
8. `fetch_sped()` - Special education data
9. `fetch_msgp()` - Student growth percentile
10. `fetch_tges()` - Taxpayer guide data

## Vignettes

### Current State
**No vignettes exist.**

### Recommended Vignettes

1. **Getting Started with njschooldata** (`vignettes/getting-started.Rmd`)
   - Installation
   - Basic data retrieval
   - Understanding NJ DOE data structure

2. **Working with Enrollment Data** (`vignettes/enrollment.Rmd`)
   - `fetch_enr()` usage
   - Tidy format explained
   - Aggregation functions
   - Historical analysis

3. **Assessment Data Guide** (`vignettes/assessments.Rmd`)
   - NJSLA (2019+)
   - PARCC (2015-2018)
   - NJASK/HSPA/GEPA (historical)
   - Transition between assessment systems

4. **Graduation and Accountability** (`vignettes/graduation.Rmd`)
   - Graduation rates
   - Graduate counts
   - Report card data

## NEWS.md Assessment

### Current State
- Well-maintained history
- Documents changes back to v0.1
- Good feature documentation

### Issues
1. **Inconsistent Formatting**: Some versions use `##`, others use `#`
2. **Missing Dates**: No release dates on versions
3. **No Links**: Could link to GitHub issues/PRs

### Recommended Format
```markdown
# njschooldata 0.9.0

## New Features
* `fetch_enr()` now supports data through 2024 (#123)
* Added GitHub Actions CI workflow

## Bug Fixes
* Fixed URL for 2023 graduation data (#125)

## Breaking Changes
* Removed deprecated `ensurer` dependency

## Deprecated
* `get_raw_enr()` is now internal; use `fetch_enr()` instead
```

## DESCRIPTION File Documentation

### Current Issues

```
Title: a simple interface for accessing NJ DOE school data in R
```
- Should be Title Case: "A Simple Interface for Accessing NJ DOE School Data in R"

```
Date: 2015-04-21
```
- Extremely outdated (10 years old!)
- Should remove or update regularly

**Missing Fields**:
```
URL: https://github.com/almartin82/njschooldata
BugReports: https://github.com/almartin82/njschooldata/issues
```

## pkgdown Configuration

### Current State
No pkgdown configuration exists.

### Recommended Setup

Create `_pkgdown.yml`:
```yaml
url: https://almartin82.github.io/njschooldata/

template:
  bootstrap: 5
  bootswatch: flatly

navbar:
  structure:
    left: [intro, reference, articles, news]
    right: [search, github]

reference:
  - title: "Enrollment Data"
    desc: "Functions for NJ school enrollment data"
    contents:
      - fetch_enr
      - tidy_enr
      - enr_aggs
      - enr_grade_aggs

  - title: "Assessment Data"
    desc: "NJSLA, PARCC, and legacy assessment functions"
    contents:
      - fetch_parcc
      - fetch_nj_assess
      - fetch_njask
      - starts_with("fetch_")

  - title: "Graduation Data"
    contents:
      - fetch_grad_rate
      - fetch_grad_count

  - title: "Aggregations"
    contents:
      - ends_with("_aggs")

  - title: "Utilities"
    contents:
      - starts_with("pad_")
      - starts_with("clean_")

articles:
  - title: "Getting Started"
    contents:
      - getting-started
  - title: "Data Guides"
    contents:
      - enrollment
      - assessments
      - graduation
```

## man/ Directory

### Statistics
- 176 .Rd files (generated by roxygen2)
- Generally well-structured
- Some have incomplete sections

### Common Issues in Generated Docs

1. **Empty or Minimal Details Section**
   Most functions could benefit from longer descriptions explaining:
   - What the data represents
   - How NJ DOE organizes the data
   - Common use cases

2. **Missing Value Documentation**
   Return values often not fully documented:
   ```
   \value{
     A data frame
   }
   ```
   Should be:
   ```
   \value{
     A data frame with the following columns:
     \describe{
       \item{end_year}{Academic year (end year, e.g., 2023 for 2022-23)}
       \item{county_id}{2-digit county code}
       ...
     }
   }
   ```

## Summary of Documentation Gaps

| Component | Status | Priority |
|-----------|--------|----------|
| README.md | Outdated | High |
| Function @examples | Missing | High |
| Vignettes | None exist | High |
| pkgdown site | Not configured | Medium |
| NEWS.md | Good, minor issues | Low |
| DESCRIPTION | Missing fields | Medium |
| @return documentation | Incomplete | Medium |
| @seealso cross-refs | Missing | Low |

## Priority Actions

1. **Immediate**: Update README with current year coverage
2. **High**: Add @examples to top 10 user-facing functions
3. **High**: Create "Getting Started" vignette
4. **Medium**: Configure pkgdown site
5. **Medium**: Update DESCRIPTION metadata
6. **Low**: Add @seealso cross-references
7. **Low**: Improve @return documentation
