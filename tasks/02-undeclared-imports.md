# Task 02: Fix Undeclared Imports (WARNING)

## Problem Summary

R CMD check found packages being used in the code that are not declared in the `DESCRIPTION` file's `Imports` field. This causes runtime errors when users install the package.

## Packages to Investigate

The following packages were flagged as potentially undeclared:

1. **DescTools** - Statistical tools
2. **foreign** - Read SPSS/SAS/Stata files
3. **geojsonio** - GeoJSON conversion
4. **gtools** - Various programming tools
5. **placement** - Geographic placement
6. **reshape2** - Data reshaping (predecessor to tidyr)
7. **sp** - Spatial data classes
8. **tibble** - Modern data frames

## Investigation Required

For each package, we need to determine:
1. Is it actually used in the package code?
2. If yes, should it be added to Imports or Suggests?
3. If no, remove any unnecessary `library()` or `require()` calls

### Search Commands

```bash
grep -r "DescTools" R/
grep -r "foreign" R/
grep -r "geojsonio" R/
grep -r "gtools" R/
grep -r "placement" R/
grep -r "reshape2" R/
grep -r "\\bsp::" R/
grep -r "tibble" R/
```

## Likely Resolution

Based on package history:

| Package | Likely Status | Action |
|---------|---------------|--------|
| DescTools | Unused | Remove any references |
| foreign | Unused (was removed in modernization) | Verify removed |
| geojsonio | Used in geo.R | Add to Imports |
| gtools | Possibly unused | Check and remove if unused |
| placement | Used in geo.R | Add to Imports |
| reshape2 | Superseded by tidyr | Remove references, use tidyr |
| sp | Used in geo.R | Add to Imports |
| tibble | Used indirectly via dplyr | No action needed (dependency of dplyr) |

## Current DESCRIPTION Imports

```
Imports:
    digest,
    dplyr (>= 1.0.0),
    downloader,
    httr,
    janitor,
    magrittr,
    purrr,
    readr,
    readxl,
    rlang (>= 0.4.0),
    snakecase,
    stringr,
    tidyr (>= 1.0.0)
```

## Solution

### Step 1: Search for actual usage
Find all places where these packages are referenced.

### Step 2: For packages actually used, add to DESCRIPTION

```
Imports:
    ... (existing),
    geojsonio,
    placement,
    sp
```

### Step 3: For packages not needed, remove references
- Remove any `library()`, `require()`, or `::` calls to unused packages
- Replace `reshape2` functions with `tidyr` equivalents

### Step 4: Add proper namespace imports
If a package is used, add proper `@importFrom` directives or use `::` notation.

## Files to Modify

1. **DESCRIPTION** - Add missing packages to Imports
2. **R/*.R** - Remove references to unused packages
3. **R/geo.R** - Likely contains geojsonio, placement, sp usage

## Verification

```r
devtools::check()
# Should not show "Packages used in package code but not declared"
```

## Notes

- Some packages may be in Suggests if only used in tests/vignettes
- The `tibble` warning might be a false positive (re-exported from dplyr)
- Consider whether geo functions are core or optional functionality
