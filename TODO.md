# njschooldata Build Issues

## pkgdown Build Failure

**Date:** 2026-01-01

**Error:**
```
Error in `as_pkgdown()`:
! Can't find 'DESCRIPTION'
```

**Cause:**
The package is missing the `DESCRIPTION` file required for R packages. pkgdown cannot build a site without this core R package metadata file.

**Required to fix:**
1. Create a `DESCRIPTION` file with package metadata (Package, Title, Version, Authors@R, Description, License, etc.)
2. May also need:
   - `NAMESPACE` file (or roxygen2-generated)
   - R/ directory with package functions
   - Proper package structure per R package standards

**Current package state:**
- Has vignettes/ directory with `enrollment_hooks.Rmd`
- Has _pkgdown.yml configuration
- Has man/ directory
- Has tests/ directory
- Missing DESCRIPTION file
- Missing R/ directory with functions
- Missing NAMESPACE file
