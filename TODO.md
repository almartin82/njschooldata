# R CMD Check Issues - TODO

## Status Summary
- **Errors:** 1
- **Warnings:** 4
- **Notes:** 3

---

## 1. TEST_FAILURES (ERROR - Critical)

Tests are failing because dplyr/purrr/tidyr functions are not being found at runtime.

**Root Cause:** The package uses `%>%`, `select`, `filter`, `map_df`, etc. but doesn't properly import them.

**Files to fix:** `NAMESPACE`, possibly add `@importFrom` directives

**Context file:** `tasks/01-test-failures.md`

---

## 2. UNDECLARED_IMPORTS (WARNING)

Packages used but not declared in DESCRIPTION Imports:
- `DescTools`
- `foreign`
- `geojsonio`
- `gtools`
- `placement`
- `reshape2`
- `sp`
- `tibble`

**Files to fix:** `DESCRIPTION`, `NAMESPACE`

**Context file:** `tasks/02-undeclared-imports.md`

---

## 3. UNDOCUMENTED_OBJECTS (WARNING)

Undocumented code objects and data sets:
- `charter_city`
- `geocoded`
- `layout_gepa05`, `layout_gepa06`
- `layout_hspa04`, `layout_hspa05`, `layout_hspa06`
- `layout_njask07gr5`, `layout_njask10`
- `nwk_address_addendum`
- `sped_lookup_map`

**Files to fix:** Add `.R` documentation files in `R/` or `man/`

**Context file:** `tasks/03-undocumented-objects.md`

---

## 4. UNDOCUMENTED_ARGUMENTS (WARNING)

Functions with undocumented parameters:
- `common_fwf_req.Rd`: missing `layout`
- `enrich_matric_counts.Rd`: missing `type`
- `extract_rc_college_matric.Rd`: missing `type`
- `fetch_grad_rate.Rd`: missing `methodology`
- `get_grad_rate.Rd`: missing `methodology`
- `process_parcc.Rd`: missing `grade`
- `ward_enr_aggs.Rd`: has `list_of_dfs` but should be `df`

**Files to fix:** Various `.R` files with roxygen comments

**Context file:** `tasks/04-undocumented-arguments.md`

---

## 5. NON_ASCII_DATA (WARNING)

Non-ASCII characters found in data objects (ellipsis character `…` encoded as `<85>`).

Affected objects:
- `layout_gepa`, `layout_gepa05`
- `layout_hspa`, `layout_hspa04`, `layout_hspa05`, `layout_hspa06`, `layout_hspa10`
- `layout_njask04`, `layout_njask05`, `layout_njask06gr3`, `layout_njask06gr5`
- `layout_njask07gr3`, `layout_njask07gr5`

**Files to fix:** Data files in `data/` directory

**Context file:** `tasks/05-non-ascii-data.md`

---

## 6. GLOBAL_VARIABLES (NOTE)

Many "no visible binding for global variable" notes due to tidyverse NSE.

**Status:** Partially addressed with `R/globals.R` but needs expansion.

**Files to fix:** `R/globals.R`

**Context file:** `tasks/06-global-variables.md`

---

## 7. NEWS_FORMAT (NOTE)

NEWS.md section titles don't include version numbers.

**Files to fix:** `NEWS.md`

**Context file:** `tasks/07-news-format.md`

---

## Priority Order

1. **TEST_FAILURES** - Must fix first (blocking)
2. **UNDECLARED_IMPORTS** - Must fix (causes runtime errors)
3. **GLOBAL_VARIABLES** - Fix to reduce notes
4. **UNDOCUMENTED_ARGUMENTS** - Fix warnings
5. **UNDOCUMENTED_OBJECTS** - Fix warnings
6. **NON_ASCII_DATA** - Fix warning
7. **NEWS_FORMAT** - Minor cosmetic fix
