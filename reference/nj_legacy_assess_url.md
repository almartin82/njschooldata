# nj_legacy_assess_url

Build the download URL for a legacy NJ assessment (NJASK / HSPA / GEPA)
state-summary flat file.

In 2024 the NJ DOE retired the old
`state.nj.us/education/schools/achievement` file tree (those URLs now
301 to nj.gov and 404) and rehosted the legacy NJASK/HSPA/GEPA summary
files under nj.gov at
`education/assessment/results/njask/njask{YY}/{subdir}/`. This helper
returns the live nj.gov URL for end_years 2005-2014.

The 2004 files were NOT rehosted on nj.gov, so for end_year 2004 we
recover the original NJ DOE file from the Internet Archive's capture of
the removed state.nj.us tree (the only remaining source). The archived
bytes are the original NJ DOE file verbatim - all VALUES still originate
from NJ DOE; only the transport differs.

## Usage

``` r
nj_legacy_assess_url(end_year, subdir, filename)
```

## Arguments

- end_year:

  assessment end_year (2004-2014)

- subdir:

  per-test/grade subdirectory, e.g. "njask5", "hspa", "gepa"

- filename:

  flat-file name within the subdirectory

## Value

a character URL
