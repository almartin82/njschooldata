# Data Currency Analysis

## Executive Summary

**CRITICAL FINDING**: The package is significantly behind on data support:

| Data Type | Package Supports | NJ DOE Has Available | Gap |
|-----------|------------------|---------------------|-----|
| Enrollment | Through 2023 | Through 2025 | 2 years |
| NJSLA Assessment | Through 2019 | Through 2025 | 6 years! |
| Graduation Rate | Through 2021 | Through 2024+ | 3+ years |
| Graduation Count | Through 2019 | Through 2024+ | 5+ years |

## Enrollment Data (`fetch_enr`)

### Current Support
- **Code claims**: 2000-2023 (per `get_raw_enr()` comments)
- **Actual tested**: Through 2022 (per test files)
- **NEWS.md**: 0.8.18 added 2023 support

### NJ DOE Availability
**Confirmed Available**: 1999-2025 (per NJ DOE website check)

Most recent: **2024-2025** school year data available at:
```
https://www.nj.gov/education/doedata/enr/enr25/enrollment_2425.zip
```

### Required Updates

1. **Update valid year range** in `get_raw_enr()`:
   ```r
   # Current (enr.R line 7)
   #' @param end_year ... valid values are 2000-2023

   # Should be
   #' @param end_year ... valid values are 1999-2025
   ```

2. **Test new years**:
   - Add tests for 2023, 2024, 2025

3. **URL pattern verification**:
   ```r
   # Pattern should work for 2024, 2025
   paste0("https://www.nj.gov/education/doedata/enr/enr", yy, "/enrollment_",
          substr(end_year - 1, 3, 4), yy, ".zip")
   ```

## Assessment Data (PARCC/NJSLA)

### Assessment History Timeline

| Years | Assessment | Status in Package |
|-------|------------|-------------------|
| 2004-2014 | NJASK/GEPA/HSPA | Supported |
| 2015-2018 | PARCC | Supported |
| 2019 | NJSLA (first year) | Supported |
| 2020-2021 | NJSLA | **NOT SUPPORTED** (COVID gap) |
| 2022-2025 | NJSLA | **NOT SUPPORTED** |

### NJ DOE Assessment Data Availability

**Confirmed Available** (per NJ DOE website):
- 2024-25 (most recent)
- 2023-24
- 2022-23
- 2021-22
- 2020-21
- 2018-19

Note: 2019-20 was cancelled due to COVID-19.

### Current Code Issues

**`fetch_all_parcc()` (parcc.R:315-356)**:
```r
for (i in c(2015:2019)) {  # HARDCODED - stops at 2019!
```

**`get_raw_sla()` (parcc.R:68-101)**:
- Only tested through 2019
- URL pattern may need updates for recent years

### Required Updates

1. **Extend `fetch_all_parcc()`**:
   ```r
   # Current
   for (i in c(2015:2019)) {

   # Should be (with COVID year handling)
   valid_years <- c(2015:2019, 2021:2025)  # Skip 2020 (cancelled)
   for (i in valid_years) {
   ```

2. **Verify NJSLA URL patterns for 2021-2025**:
   Need to check if URL pattern still works:
   ```r
   # Current pattern (may need updates)
   paste0(stem, substr(end_year - 1, 3, 4), substr(end_year, 3, 4),
          '/spring/', subj, grade, '%20NJSLA%20DATA%20',
          end_year - 1, '-', substr(end_year, 3, 4), '.xlsx')
   ```

3. **Add tests for 2021-2025**

### URL Verification Needed

Test these URLs manually or via script:
```r
# 2024 example (needs verification)
https://www.nj.gov/education/assessment/results/reports/2324/spring/ELA03%20NJSLA%20DATA%202023-24.xlsx
```

## Graduation Data

### Current Support

**Graduation Rate (`fetch_grad_rate`)**:
- Code: `end_year > 2021` throws error (grate.R:440, 832)
- Last supported: 2020 (per `get_raw_grad_file()`)

**Graduation Count (`fetch_grad_count`)**:
- Code: `end_year > 2019` throws error (grate.R:606)

### NJ DOE Availability

Graduation data available through 2024 at:
```
https://www.nj.gov/education/schoolperformance/grad/data/
```

### Hardcoded URL Issues

The graduation file has many hardcoded URLs that need updating:

```r
# grate.R:497-520
} else if (end_year == 2018) {
  grate_url <- "https://www.nj.gov/education/schoolperformance/grad/data/ACGR2018_4YearGraduation.xlsx"
} else if (end_year == 2019) {
  grate_url <- "https://www.nj.gov/education/schoolperformance/grad/data/ACGR2019_..."
} else if (end_year == 2020) {
  grate_url <- "https://www.nj.gov/education/schoolperformance/grad/data/Cohort%202020..."
# NO 2021, 2022, 2023, 2024!
```

### Required Updates

1. **Add URLs for 2021-2024**
2. **Update year validation**:
   ```r
   # Current
   if (end_year < 1998 | end_year > 2021)

   # Should be
   if (end_year < 1998 | end_year > 2024)
   ```

3. **Add graduation count support through 2024**

## School/District Directory

### Current State
```r
# directory.R
get_district_directory <- function() {
  dir_url = "https://homeroom4.doe.state.nj.us/public/districtpublicschools/download/"
```

### Status
- URL appears to be current and working
- No year parameter needed (always returns current data)
- **No updates required** for this function

## Report Card Data

### Current State
Report card functions access NJ DOE performance reports.

### Verification Needed
- Check if 2022-2024 report card databases are available
- Update `get_rc_databases()` if needed

## Other Data Sources

### mSGP (Student Growth Percentiles)
- `fetch_msgp()` - Last supported year unclear
- Needs verification against NJ DOE

### TGES (Taxpayer Guide to Ed Spending)
- `fetch_tges()` - Year support unclear
- Needs verification

### ESSA Accountability
- `get_essa_file()` - Needs year verification

## NJ DOE Data Portal Structure Changes

Based on web research, NJ DOE has:
1. Maintained consistent URL patterns for enrollment
2. Kept assessment data in similar locations
3. Reorganized some graduation data locations

No major structural changes detected that would require significant refactoring.

## COVID-19 Data Gaps

Important context for 2020-2021 data:
- **2019-20 NJSLA**: Cancelled (no data exists)
- **2020-21 Enrollment**: Available (schools were open in some form)
- **2020-21 NJSLA**: Available (testing resumed)
- **2020-21 Graduation**: Available

Code should handle the 2020 assessment gap gracefully:
```r
# Example handling
if (end_year == 2020 && data_type == "assessment") {
  stop("NJSLA assessments were cancelled in 2019-20 due to COVID-19")
}
```

## Summary of Required Updates

### Critical (Blocking)
1. Add NJSLA support for 2021-2025
2. Add graduation data support for 2021-2024
3. Verify and update enrollment for 2024-2025

### High Priority
1. Update `fetch_all_parcc()` year range
2. Add/update graduation URLs for recent years
3. Handle COVID year appropriately

### Medium Priority
1. Update all documentation with current year ranges
2. Add tests for recent years
3. Verify other data sources (mSGP, TGES, ESSA)

### Verification Checklist

| Data Type | URL Verified | Data Downloaded | Tests Pass |
|-----------|-------------|-----------------|------------|
| Enrollment 2024 | [ ] | [ ] | [ ] |
| Enrollment 2025 | [ ] | [ ] | [ ] |
| NJSLA 2021 | [ ] | [ ] | [ ] |
| NJSLA 2022 | [ ] | [ ] | [ ] |
| NJSLA 2023 | [ ] | [ ] | [ ] |
| NJSLA 2024 | [ ] | [ ] | [ ] |
| Grad Rate 2021 | [ ] | [ ] | [ ] |
| Grad Rate 2022 | [ ] | [ ] | [ ] |
| Grad Rate 2023 | [ ] | [ ] | [ ] |
| Grad Rate 2024 | [ ] | [ ] | [ ] |

## Implementation Priority

1. **First**: Verify all URLs programmatically
2. **Second**: Update code to support new years
3. **Third**: Add tests for new years
4. **Fourth**: Update documentation
