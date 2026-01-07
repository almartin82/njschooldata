# Deploy

Run the full deployment pipeline for the njschooldata R package.

## Steps to execute (in order):

### 1. Security Review
Run /security-review and report any Critical or High severity issues. Stop deployment if Critical issues are found.

### 2. Run Tests
```bash
Rscript -e "devtools::test()"
```
Report test results. Note: Some tests may fail due to NJ DOE network issues - this is expected. Check for code-related failures.

### 3. Run Linter
```bash
Rscript -e "lintr::lint_package()"
```
Report any linting errors or warnings.

### 4. Build Package
```bash
Rscript -e "devtools::check(args = c('--no-tests', '--no-manual', '--no-vignettes'))"
```
Ensure the package builds without errors.

### 5. Deploy
If all checks pass:
- Commit any pending changes
- Push to the repository
- The pkgdown GitHub Action will automatically build and deploy documentation

Report the status of each step and provide a summary at the end.
