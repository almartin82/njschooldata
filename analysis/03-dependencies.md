# Dependencies Analysis

## Current DESCRIPTION Dependencies

```
Depends:
    dplyr,
    ensurer,
    foreign,
    gdata,
    janitor,
    magrittr,
    R(>= 3.5.0),
    readr,
    reshape2,
    rlang,
    stringr,
    tidyr
Imports:
    downloader,
    purrr,
    readxl
Suggests:
    knitr,
    placement,
    rmarkdown,
    testthat
```

## Critical Issues

### 1. Packages in Depends That Should Be in Imports

**All packages except R itself should be in Imports, not Depends.**

`Depends` attaches packages to the user's search path, which:
- Causes namespace pollution
- Creates potential conflicts with user's other packages
- Is considered poor practice for modern R packages

**Current Depends to move to Imports**:
- dplyr
- ensurer
- foreign
- gdata
- janitor
- magrittr
- readr
- reshape2
- rlang
- stringr
- tidyr

### 2. Deprecated/Archived Packages

| Package | Status | Issue | Replacement |
|---------|--------|-------|-------------|
| **ensurer** | Archived on CRAN | No longer maintained | Use base R `stopifnot()` or rlang assertions |
| **reshape2** | Superseded | Replaced by tidyr | Use `tidyr::pivot_longer()` / `pivot_wider()` |
| **gdata** | Active but heavy | Large dependency tree | Use `readxl` (already imported) |

### 3. Unnecessary Dependencies

| Package | Current Use | Alternative |
|---------|-------------|-------------|
| **foreign** | Not found in R/ code | Remove entirely |
| **gdata** | Only for Excel reading | readxl already handles this |
| **magrittr** | For `%>%` pipe | Could use base R `|>` (R >= 4.1) |

### 4. Missing Dependencies

| Package | Used In | Current Status |
|---------|---------|----------------|
| **httr** | grate.R | Used but not declared! |
| **snakecase** | util.R | Used but not declared! |

**Critical**: `httr` is used for HTTP requests in `get_raw_grad_file()` but is not declared as a dependency!

```r
# grate.R:462, 475, 491, 502, 511, 518, 564
httr::GET(url = grate_url, httr::write_disk(grate_file))
```

### 5. Version Constraints

**Too Loose**:
- `R(>= 3.5.0)` - Released 2018, very old
  - Recommend: `R(>= 4.1.0)` for native pipe support

**Missing Version Constraints**:
- No version specified for any package
- dplyr >= 1.0.0 should be required (for `across()`)
- tidyr >= 1.0.0 should be required (for `pivot_longer()`)

## Detailed Package Analysis

### dplyr
**Status**: Core dependency, heavily used
**Current Usage**:
- `filter()`, `mutate()`, `select()`, `rename()`, `group_by()`, `summarize()`
- **Problem**: Uses deprecated `summarise_each()` and `funs()`

**Required Version**: >= 1.0.0 (for `across()` replacement)

### tidyr
**Status**: Core dependency
**Current Usage**:
- `pivot_longer()` (good, modern)
- Some files may still use `gather()`/`spread()`

**Required Version**: >= 1.0.0

### reshape2
**Status**: SUPERSEDED
**Current Usage** (fetch_nj_assess.R:278):
```r
sub_long <- reshape2::melt(to_pivot, id.vars = c('program_name', 'program_code'))
```

**Replacement**:
```r
sub_long <- tidyr::pivot_longer(
  to_pivot,
  cols = -c(program_name, program_code),
  names_to = "variable",
  values_to = "value"
)
```

### ensurer
**Status**: ARCHIVED (removed from CRAN)
**Current Usage** (fetch_nj_assess.R:66-67):
```r
valid_call(end_year, grade) %>%
  ensure_that(all(.) ~ "invalid grade/end_year parameter passed")
```

**Replacement**:
```r
if (!valid_call(end_year, grade)) {
  stop("invalid grade/end_year parameter passed")
}
# Or with rlang:
rlang::abort_if(!valid_call(end_year, grade), "invalid grade/end_year parameter passed")
```

### gdata
**Status**: Heavy dependency, limited use
**Current Usage**: Likely for Excel file reading (but readxl is better)

**Action**: Remove and ensure readxl handles all Excel operations

### foreign
**Status**: Not used
**Current Usage**: No usage found in R/ directory

**Action**: Remove from DESCRIPTION

### janitor
**Status**: Useful, well-maintained
**Current Usage**: `janitor::clean_names()` in directory.R

**Keep**: Yes, lightweight and useful

### stringr
**Status**: Core tidyverse, heavily used
**Current Usage**: `str_split_fixed()`, `str_pad()`, `str_detect()`, `str_sub()`

**Keep**: Yes

### rlang
**Status**: Core tidyverse, required
**Current Usage**: `parse_expr()` for dynamic column creation

**Keep**: Yes

### readr
**Status**: Core tidyverse
**Current Usage**: `read_fwf()`, `read_csv()`, `fwf_positions()`

**Keep**: Yes

### readxl
**Status**: Essential for this package
**Current Usage**: Reading Excel files from NJ DOE

**Keep**: Yes, should be in Imports

### downloader
**Status**: Active, useful
**Current Usage**: `downloader::download()` for file downloads

**Keep**: Yes, handles HTTPS properly

### purrr
**Status**: Core tidyverse
**Current Usage**: `map_df()`, `map_chr()`, `map_lgl()`

**Keep**: Yes

### httr
**Status**: Used but not declared!
**Current Usage**: `httr::GET()`, `httr::write_disk()`

**Action**: Add to Imports immediately

### snakecase
**Status**: Used but not declared!
**Current Usage** (util.R:135):
```r
snakecase::to_any_case(...)
```

**Action**: Add to Imports

## Recommended DESCRIPTION

```
Package: njschooldata
Type: Package
Title: A Simple Interface for Accessing NJ DOE School Data in R
Description: R functions to import NJ school data, including assessment,
    enrollment, and accountability data from the New Jersey Department of
    Education.
Version: 0.9.0
Authors@R: person("Andrew", "Martin", role = c("aut","cre"),
    email = "almartin@gmail.com")
License: GPL-3 | file LICENSE
URL: https://github.com/almartin82/njschooldata
BugReports: https://github.com/almartin82/njschooldata/issues
Depends:
    R (>= 4.1.0)
Imports:
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
Suggests:
    httptest,
    knitr,
    rmarkdown,
    testthat (>= 3.0.0)
LazyData: true
VignetteBuilder: knitr
RoxygenNote: 7.3.1
Encoding: UTF-8
Config/testthat/edition: 3
```

## Packages to Remove
1. **ensurer** - Archived, replace with base R/rlang assertions
2. **foreign** - Not used
3. **gdata** - Unnecessary, readxl covers Excel reading
4. **reshape2** - Superseded by tidyr

## Packages to Add
1. **httr** - Already used, needs to be declared
2. **snakecase** - Already used, needs to be declared
3. **httptest** (Suggests) - For mocking web requests in tests

## Tidyverse Function Updates Required

### Deprecated Functions to Replace

| Old | New | Files |
|-----|-----|-------|
| `summarise_each(funs(sum))` | `summarise(across(..., sum))` | fetch_nj_assess.R |
| `rbind_all()` | `bind_rows()` | grate.R |
| `gather()` | `pivot_longer()` | Check all files |
| `spread()` | `pivot_wider()` | Check all files |
| `funs()` | `list()` or direct function | fetch_nj_assess.R |

### Example Migrations

**Before (deprecated)**:
```r
demog_test <- demog_masks %>%
  dplyr::summarise_each(dplyr::funs(sum)) %>%
  unname() %>% unlist()
```

**After (modern)**:
```r
demog_test <- demog_masks %>%
  dplyr::summarise(dplyr::across(everything(), sum)) %>%
  unname() %>% unlist()
```

## R Version Considerations

**Current**: R >= 3.5.0 (April 2018)

**Recommended**: R >= 4.1.0 (May 2021)

Benefits of R 4.1.0+:
- Native pipe `|>` support
- `\(x)` lambda syntax
- Better memory management
- More current user base

If targeting R 4.1.0, could optionally:
- Replace `%>%` with `|>` (but magrittr is fine)
- Use `\(x)` instead of `function(x)` in simple cases

## Dependency Tree Concerns

Current install pulls in many transitive dependencies. Key heavy dependencies:
- **tidyverse packages**: Required, acceptable
- **gdata**: Pulls in many dependencies, should remove

After cleanup, the dependency tree will be cleaner and more maintainable.

## Summary

| Category | Current | Recommended |
|----------|---------|-------------|
| Depends packages | 12 | 1 (R only) |
| Imports packages | 3 | 12 |
| Suggests packages | 4 | 4 |
| Deprecated packages | 2 | 0 |
| Undeclared dependencies | 2 | 0 |
| Unused dependencies | 2 | 0 |
