# Prioritized Task List

This task list consolidates all findings from the analysis reports into actionable items.

---

## Priority 1: Critical (Breaking/Blocking Issues)

### 1.1 Fix Undeclared Dependencies
- **Files**: `DESCRIPTION`, `R/grate.R`, `R/util.R`
- **Change**: Add `httr` and `snakecase` to Imports - these are used but not declared
- **Why**: Package will fail to install properly without these
- **Complexity**: S

### 1.2 Remove Archived Package (ensurer)
- **Files**: `DESCRIPTION`, `R/fetch_nj_assess.R`
- **Change**: Replace `ensurer::ensure_that()` with base R `stopifnot()` or `if/stop`
- **Why**: `ensurer` is archived on CRAN, package won't install
- **Complexity**: S

### 1.3 Replace Travis CI with GitHub Actions
- **Files**: Delete `.travis.yml`, create `.github/workflows/R-CMD-check.yaml`
- **Change**: Implement modern CI using r-lib/actions
- **Why**: Travis CI free tier is discontinued
- **Complexity**: M

### 1.4 Fix Deprecated dplyr Functions
- **Files**: `R/fetch_nj_assess.R` (lines 186-209)
- **Change**: Replace `summarise_each(funs(sum))` with `summarise(across(..., sum))`
- **Why**: Will cause warnings/errors with current dplyr
- **Complexity**: S

### 1.5 Fix Deprecated rbind_all
- **Files**: `R/grate.R` (lines 292, 374)
- **Change**: Replace `dplyr::rbind_all()` with `dplyr::bind_rows()`
- **Why**: Function removed from dplyr
- **Complexity**: S

---

## Priority 2: High (Functionality/Currency)

### 2.1 Add Enrollment Data Support for 2024-2025
- **Files**: `R/enr.R`
- **Change**: Verify URL patterns work for end_year 2024 and 2025
- **Why**: NJ DOE has data available, package doesn't support it
- **Complexity**: S

### 2.2 Add NJSLA Assessment Support for 2021-2025
- **Files**: `R/parcc.R`
- **Change**:
  - Update `fetch_all_parcc()` year range (currently stops at 2019)
  - Verify `get_raw_sla()` URL patterns for 2021-2025
  - Handle COVID-19 gap (2020 had no assessments)
- **Why**: 6 years of assessment data unsupported
- **Complexity**: M

### 2.3 Add Graduation Data Support for 2021-2024
- **Files**: `R/grate.R`
- **Change**:
  - Add URLs for 2021, 2022, 2023, 2024 graduation files
  - Update year validation (currently stops at 2021)
  - Update `fetch_grad_count` (currently stops at 2019)
- **Why**: 3-5 years of graduation data unsupported
- **Complexity**: M

### 2.4 Move Packages from Depends to Imports
- **Files**: `DESCRIPTION`
- **Change**: Move all packages except R from Depends to Imports
- **Why**: Best practice, prevents namespace pollution
- **Complexity**: S

### 2.5 Remove Unused Dependencies
- **Files**: `DESCRIPTION`
- **Change**: Remove `foreign` (not used), `gdata` (readxl covers Excel), `reshape2` (superseded)
- **Why**: Cleaner dependency tree, fewer install issues
- **Complexity**: S

### 2.6 Replace reshape2 with tidyr
- **Files**: `R/fetch_nj_assess.R`
- **Change**: Replace `reshape2::melt()` with `tidyr::pivot_longer()`
- **Why**: reshape2 is superseded
- **Complexity**: S

---

## Priority 3: Medium (Code Quality/Testing)

### 3.1 Add Input Validation to Exported Functions
- **Files**: `R/enr.R`, `R/parcc.R`, `R/grate.R`, and others
- **Change**: Add parameter validation for `end_year`, `grade`, etc.
- **Why**: Cryptic errors when invalid parameters passed
- **Complexity**: M

### 3.2 Create GitHub Actions Workflow for Coverage
- **Files**: `.github/workflows/test-coverage.yaml`
- **Change**: Add codecov workflow
- **Why**: Track test coverage over time
- **Complexity**: S

### 3.3 Create GitHub Actions Workflow for pkgdown
- **Files**: `.github/workflows/pkgdown.yaml`, `_pkgdown.yml`
- **Change**: Set up documentation site deployment
- **Why**: Better discoverability, professional appearance
- **Complexity**: M

### 3.4 Migrate to testthat 3e Edition
- **Files**: `tests/testthat/*.R`, `DESCRIPTION`
- **Change**:
  - Remove `context()` calls
  - Replace `expect_is()` with `expect_s3_class()`
  - Add `Config/testthat/edition: 3` to DESCRIPTION
- **Why**: Modern testing practices
- **Complexity**: M

### 3.5 Add Temp File Cleanup
- **Files**: `R/enr.R`, `R/parcc.R`, `R/grate.R`
- **Change**: Add `on.exit(unlink(tname), add = TRUE)` after tempfile creation
- **Why**: Prevent temp file accumulation
- **Complexity**: S

### 3.6 Centralize URL Configuration
- **Files**: Create `R/config.R`, update data-fetching functions
- **Change**: Move all NJ DOE URLs to central configuration
- **Why**: Easier maintenance when URLs change
- **Complexity**: M

### 3.7 Add Timeout Handling for Downloads
- **Files**: `R/grate.R` (httr calls), consider for downloader calls
- **Change**: Add explicit timeout to HTTP requests
- **Why**: Prevent hanging on slow connections
- **Complexity**: S

### 3.8 Add Retry Logic for Downloads
- **Files**: Create utility function, use in fetch functions
- **Change**: Implement retry with exponential backoff
- **Why**: Handle transient network failures gracefully
- **Complexity**: M

---

## Priority 4: Low (Documentation/Polish)

### 4.1 Update README.md
- **Files**: `README.md`
- **Change**:
  - Update data coverage years
  - Add NJSLA mention
  - Add badges (R-CMD-check, codecov)
  - Update installation instructions
- **Why**: First thing users see should be accurate
- **Complexity**: S

### 4.2 Add @examples to Key Functions
- **Files**: `R/enr.R`, `R/parcc.R`, `R/grate.R`, `R/directory.R`
- **Change**: Add runnable examples to top 10 user-facing functions
- **Why**: Help users understand how to use functions
- **Complexity**: M

### 4.3 Update DESCRIPTION Metadata
- **Files**: `DESCRIPTION`
- **Change**:
  - Remove or update Date field (currently 2015)
  - Add URL and BugReports fields
  - Fix Title capitalization
- **Why**: Package metadata should be current
- **Complexity**: S

### 4.4 Create .Rbuildignore
- **Files**: `.Rbuildignore`
- **Change**: Exclude non-package files from build
- **Why**: Cleaner package build
- **Complexity**: S

### 4.5 Update NEWS.md Format
- **Files**: `NEWS.md`
- **Change**: Standardize section headings, add dates
- **Why**: Clearer changelog
- **Complexity**: S

### 4.6 Add Vignette: Getting Started
- **Files**: `vignettes/getting-started.Rmd`
- **Change**: Create introductory vignette
- **Why**: Long-form documentation for new users
- **Complexity**: M

### 4.7 Create Issue/PR Templates
- **Files**: `.github/ISSUE_TEMPLATE/`, `.github/PULL_REQUEST_TEMPLATE.md`
- **Change**: Add structured templates
- **Why**: Better issue reporting, consistent PRs
- **Complexity**: S

### 4.8 Add Linting Workflow
- **Files**: `.github/workflows/lint.yaml`
- **Change**: Add lintr checks to CI
- **Why**: Consistent code style
- **Complexity**: S

### 4.9 Replace Debug Print Statements
- **Files**: `R/fetch_nj_assess.R`, `R/grate.R`, `R/enr.R`
- **Change**: Replace `print()` with `message()` or `cli::cli_inform()`
- **Why**: Proper user messaging
- **Complexity**: S

### 4.10 Add Progress Indicators for Batch Operations
- **Files**: `R/parcc.R` (`fetch_all_parcc`)
- **Change**: Add progress bar for multi-file downloads
- **Why**: Better user experience
- **Complexity**: S

---

## Implementation Order

### Phase 1: Fix Breaking Issues (Tasks 1.1-1.5)
Estimated: 1-2 hours
Must be completed first - package won't build without these.

### Phase 2: Add Data Currency (Tasks 2.1-2.6)
Estimated: 2-4 hours
High value - brings package up to date with available data.

### Phase 3: Infrastructure (Tasks 3.1-3.8)
Estimated: 2-3 hours
Modern CI/CD, better error handling.

### Phase 4: Documentation & Polish (Tasks 4.1-4.10)
Estimated: 2-3 hours
User-facing improvements.

---

## Task Tracking

| Task | Status | Notes |
|------|--------|-------|
| 1.1 | [ ] | |
| 1.2 | [ ] | |
| 1.3 | [ ] | |
| 1.4 | [ ] | |
| 1.5 | [ ] | |
| 2.1 | [ ] | |
| 2.2 | [ ] | Need to verify URL patterns |
| 2.3 | [ ] | Need to find current URLs |
| 2.4 | [ ] | |
| 2.5 | [ ] | |
| 2.6 | [ ] | |
| 3.1 | [ ] | |
| 3.2 | [ ] | |
| 3.3 | [ ] | |
| 3.4 | [ ] | |
| 3.5 | [ ] | |
| 3.6 | [ ] | |
| 3.7 | [ ] | |
| 3.8 | [ ] | |
| 4.1 | [ ] | |
| 4.2 | [ ] | |
| 4.3 | [ ] | |
| 4.4 | [ ] | |
| 4.5 | [ ] | |
| 4.6 | [ ] | Optional |
| 4.7 | [ ] | |
| 4.8 | [ ] | |
| 4.9 | [ ] | |
| 4.10 | [ ] | Optional |

---

## Success Criteria

After completing all Priority 1 and 2 tasks:
- [ ] `devtools::check()` passes with no errors or warnings
- [ ] `devtools::test()` passes all tests
- [ ] Package installs cleanly via `devtools::install()`
- [ ] `fetch_enr(2024)` returns valid data
- [ ] `fetch_parcc(2023, 4, 'ela')` returns valid data (if URL exists)
- [ ] `fetch_grad_rate(2023)` returns valid data
- [ ] GitHub Actions CI is green
