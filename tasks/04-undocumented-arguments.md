# Task 04: Fix Undocumented Arguments (WARNING)

## Problem Summary

Several exported functions have parameters that are not documented in their roxygen blocks, causing R CMD check warnings.

## Functions with Missing Documentation

### 1. `common_fwf_req()` - Missing: `layout`

**File:** Likely `R/fetch_nj_assess.R` or similar

**Current Issue:** The function has a `layout` parameter that isn't documented.

**Fix:** Add `@param layout` to roxygen block.

---

### 2. `enrich_matric_counts()` - Missing: `type`

**File:** Likely `R/matric_calcs.R` or `R/grate.R`

**Current Issue:** The function has a `type` parameter that isn't documented.

**Fix:** Add `@param type` to roxygen block.

---

### 3. `extract_rc_college_matric()` - Missing: `type`

**File:** Likely `R/report_card.R`

**Current Issue:** The function has a `type` parameter that isn't documented.

**Fix:** Add `@param type` to roxygen block.

---

### 4. `fetch_grad_rate()` - Missing: `methodology`

**File:** `R/grate.R`

**Current Issue:** The function has a `methodology` parameter that isn't documented.

**Fix:** Add `@param methodology` to roxygen block. Should describe options like "4year", "5year", etc.

---

### 5. `get_grad_rate()` - Missing: `methodology`

**File:** `R/grate.R`

**Current Issue:** Same as fetch_grad_rate.

**Fix:** Add `@param methodology` to roxygen block.

---

### 6. `process_parcc()` - Missing: `grade`

**File:** `R/parcc.R`

**Current Issue:** The function has a `grade` parameter that isn't documented.

**Fix:** Add `@param grade` to roxygen block.

---

### 7. `ward_enr_aggs()` - Parameter mismatch

**File:** `R/charter.R` or similar

**Current Issue:** Documentation says `list_of_dfs` but actual parameter is `df`.

**Fix:** Update roxygen to use `@param df` instead of `@param list_of_dfs`.

---

## Solution Template

For each function, find the roxygen block and add/fix the parameter:

```r
#' Function Title
#'
#' @param existing_param Description
#' @param layout A data frame containing fixed-width file column specifications
#' @param type Character string specifying the type. One of "16mo" or "immediate".
#' @param methodology Character string specifying calculation methodology.
#'   One of "4year" (default), "5year", or "adjusted".
#' @param grade Integer or character specifying grade level (3-11).
#' @param df A data frame containing enrollment data.
#'
#' @return ...
#' @export
function_name <- function(param1, layout, type, methodology, grade, df) {
  ...
}
```

## Files to Modify

1. **R/fetch_nj_assess.R** - `common_fwf_req` layout param
2. **R/matric_calcs.R** - `enrich_matric_counts` type param
3. **R/report_card.R** - `extract_rc_college_matric` type param
4. **R/grate.R** - `fetch_grad_rate` and `get_grad_rate` methodology params
5. **R/parcc.R** - `process_parcc` grade param
6. **R/charter.R** - `ward_enr_aggs` fix param name mismatch

## Implementation Steps

1. Search for each function definition:
   ```bash
   grep -n "common_fwf_req" R/*.R
   grep -n "enrich_matric_counts" R/*.R
   # etc.
   ```

2. Find the roxygen block above each function

3. Add/fix the `@param` line with appropriate description

4. Run `devtools::document()` to regenerate `.Rd` files

## Verification

```r
devtools::document()
devtools::check()
# Should not show "Undocumented arguments in documentation object"
```

## Notes

- Parameter descriptions should explain:
  - What type of value is expected
  - Valid options (if limited set)
  - Default value (if any)
  - What the parameter controls
