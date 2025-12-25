# Code Quality Analysis

## Overview

This report analyzes the code quality of the njschooldata R package across 29 R files totaling approximately 8,300 lines of code.

## File-by-File Analysis

### Large Files (>300 lines) - High Priority for Refactoring

| File | Lines | Primary Issues |
|------|-------|----------------|
| enr.R | 1,115 | Multiple responsibilities, long functions |
| charter.R | 1,018 | Code duplication, similar aggregation patterns |
| grate.R | 980 | Complex conditionals, hardcoded year logic |
| report_card.R | 897 | Mixed concerns, verbose processing |
| tges.R | 852 | Repetitive tidy_* functions |
| geo.R | 387 | Hardcoded ward/neighborhood data |
| fetch_nj_assess.R | 374 | Deprecated functions, complex masks |
| parcc.R | 356 | Year-specific URL hacks |

## Critical Issues

### 1. Deprecated R Functions and Patterns

**Location: R/fetch_nj_assess.R:186-209**
```r
dplyr::summarise_each(dplyr::funs(sum))  # DEPRECATED
```
- `summarise_each()` deprecated in dplyr 0.7.0
- `funs()` deprecated in dplyr 0.8.0
- **Fix**: Use `summarise(across(...))` pattern

**Location: R/grate.R:292, 374**
```r
dplyr::rbind_all(...)  # DEPRECATED
```
- `rbind_all()` deprecated since dplyr 0.4.0
- **Fix**: Use `dplyr::bind_rows()`

### 2. Functions Exceeding 50 Lines (Need Refactoring)

| Function | File | Lines | Issue |
|----------|------|-------|-------|
| `get_raw_enr()` | enr.R | ~155 | Year-specific branching, should be split |
| `tidy_nj_assess()` | fetch_nj_assess.R | ~170 | Monolithic mask-building logic |
| `process_grate()` | grate.R | ~135 | Excessive name mapping |
| `tidy_grad_rate()` | grate.R | ~240 | Complex nested functions |
| `get_raw_grad_file()` | grate.R | ~135 | Hardcoded URLs per year |
| `clean_enr_names()` | enr.R | ~200 | Massive lookup list |
| `process_enr()` | enr.R | ~150 | Multiple responsibilities |

### 3. Code Duplication Patterns

**Aggregation Functions** (charter.R, lines 1-1018):
Nearly identical patterns repeated for:
- `charter_sector_enr_aggs()`
- `charter_sector_grate_aggs()`
- `charter_sector_gcount_aggs()`
- `charter_sector_parcc_aggs()`
- `charter_sector_spec_pop_aggs()`
- `charter_sector_sped_aggs()`
- `allpublic_*_aggs()` (6 more functions)
- `ward_*_aggs()` (4 more functions)

**Recommendation**: Create a generic `sector_aggs()` factory function.

### 4. Inconsistent Naming Conventions

Mixed patterns found:
- `get_raw_enr()` vs `fetch_enr()` (get_ vs fetch_)
- `process_grate()` vs `tidy_grad_rate()` (process_ vs tidy_)
- `clean_enr_names()` vs `rc_numeric_cleaner()` (clean_ prefix location)
- `id_enr_aggs()` vs `id_grad_aggs()` (consistent, good)

**Variables**:
- `end_year` used consistently (good)
- Mix of `county_id`/`county_code` in different contexts
- `df` vs `data` vs specific names for data frames

### 5. Magic Numbers and Hardcoded Values

**Year ranges** (multiple files):
```r
# enr.R:7 - outdated
# @param end_year ... valid values are 2000-2023

# grate.R:440
if (end_year < 1998 | end_year > 2021)

# parcc.R:319
for (i in c(2015:2019)) {  # Hardcoded PARCC years
```

**School/District codes**:
```r
# Multiple locations
district_id == '9999'  # State aggregate
school_id == '999'     # District aggregate
county_id == '80'      # Charter county
```

**Recommendation**: Create constants file:
```r
# R/constants.R
STATE_DISTRICT_ID <- '9999'
STATE_COUNTY_ID <- '99'
DISTRICT_SCHOOL_ID <- '999'
CHARTER_COUNTY_ID <- '80'
```

### 6. Missing or Incomplete Roxygen2 Documentation

**Undocumented internal functions**:
- `clean_name()` (enr.R:198)
- `tidy_old_format()` (grate.R:173)
- `tidy_new_format()` (grate.R:316)
- `clean_grate_names()` (grate.R:298)
- `grate_col()` (grate.R:158)
- `unzipper()` (util.R:196) - not exported but potentially useful
- `clean_name_vector()` (util.R:127)

**Missing @examples**:
Most exported functions lack runnable examples:
- `fetch_enr()` - no example
- `fetch_parcc()` - no example
- `fetch_grad_rate()` - no example

### 7. Error Handling Patterns

**Good patterns found**:
```r
# grate.R:440-441
if (end_year < 1998 | end_year > 2021) {
  stop('year not yet supported')
}
```

**Missing error handling**:
```r
# enr.R - get_raw_enr() has no validation of end_year input
# No check if download fails
downloader::download(enr_url, dest = tname, mode = "wb")
```

**Recommendations**:
1. Add input validation to all exported functions
2. Wrap downloads in tryCatch with informative messages
3. Validate downloaded file contents before processing

### 8. Input Validation Issues

**Functions lacking parameter validation**:
- `fetch_enr(end_year)` - no range check
- `fetch_parcc(end_year, grade_or_subj, subj)` - partial validation
- `process_enr(df)` - no type checking

**Example fix needed**:
```r
fetch_enr <- function(end_year, tidy = FALSE) {
  # Add validation
  if (!is.numeric(end_year) || length(end_year) != 1) {
    stop("end_year must be a single numeric value")
  }
  if (end_year < 1999 || end_year > 2025) {
    stop(sprintf("end_year must be between 1999 and 2025, got %s", end_year))
  }
  # ... rest of function
}
```

### 9. Use of Dot (.) in Pipes

**Problematic patterns** (may cause issues with native pipe):
```r
# enr.R:68
typo_names <- . %>% dplyr::rename_with(...)

# util.R:127
clean_name_vector <- . %>% gsub(...) %>% ...
```

While valid for magrittr, these patterns are:
1. Not compatible with base R pipe `|>`
2. Create anonymous functions that can be hard to debug
3. Less readable than explicit function definitions

### 10. Print Statements for Debugging

**Should be replaced with proper messaging**:
```r
# fetch_nj_assess.R:191
print(names(df)[!demog_test == 1])

# grate.R:260
print('no TOTAL row for:')
paste(constant_df$district_name, constant_df$school_name) %>% print()

# enr.R:201
ifelse(is.null(z), print(df_names), '')
```

**Recommendation**: Use `message()`, `warning()`, or `cli::cli_warn()` for user-facing output.

## Summary Statistics

| Metric | Count |
|--------|-------|
| Total R files | 29 |
| Total lines of code | ~8,300 |
| Functions > 50 lines | 12 |
| Deprecated function calls | 3+ |
| Missing @examples | 150+ exports |
| Undocumented internal functions | 10+ |
| Hardcoded year ranges | 8+ |
| Print statements (debug) | 5+ |

## Priority Recommendations

1. **Critical**: Replace deprecated `summarise_each()`, `funs()`, and `rbind_all()`
2. **High**: Add input validation to all exported functions
3. **High**: Refactor `get_raw_enr()` and `get_raw_grad_file()` to use year config
4. **Medium**: Create constants file for magic numbers
5. **Medium**: Add @examples to key exported functions
6. **Low**: Consolidate duplicate aggregation functions
7. **Low**: Replace print() with message()/warning()
