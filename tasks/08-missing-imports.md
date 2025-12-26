# Task 08: Fix Missing Function Imports

## Problem

R CMD check shows "no visible global function definition" for many functions that are used but not properly imported.

## Missing Functions by Package

### janitor
- `tabyl` - used in `agg_enr_pct_total`
- `clean_names` - used in `enrich_school_latlong`
- `compare_df_cols` - used in `get_merged_rc_database`
- `compare_df_cols_same` - used in `get_merged_rc_database`

### magrittr (beyond %>%)
- `extract2` - used in report_card.R, tges.R
- `use_series` - used in msgp.R, special_pop.R
- `multiply_by` - used in geo.R
- `add` - used in grate.R
- `%$%` - exposition pipe, used in grate.R

### stringr (need explicit imports)
- `str_pad` - used in geo.R
- `str_replace_all` - used in geo.R, report_card.R

### base/utils (need explicit imports)
- `data` - used in geo.R
- `download.file` - used in essa.R, report_card.R, sped.R
- `object.size` - used in cache.R

### ensurer (REMOVED - need to replace)
- `ensure_that` - used in enr.R, charter.R, sped.R
  - This package was removed! Need to replace with base R validation

## Solution

### 1. Update R/njschooldata-package.R

Add missing imports:
```r
#' @importFrom janitor tabyl clean_names compare_df_cols compare_df_cols_same
#' @importFrom magrittr extract2 use_series multiply_by add %$%
#' @importFrom stringr str_pad str_replace_all
#' @importFrom utils data download.file object.size
```

### 2. Replace ensure_that calls

Replace `ensurer::ensure_that()` with base R:
```r
# Old:
df %>% ensure_that(nrow(.) > 0)

# New:
if (nrow(df) == 0) stop("Data frame is empty")
df
```

## Files to Modify

1. `R/njschooldata-package.R` - Add imports
2. `R/enr.R` - Replace ensure_that
3. `R/charter.R` - Replace ensure_that
4. `R/sped.R` - Replace ensure_that
