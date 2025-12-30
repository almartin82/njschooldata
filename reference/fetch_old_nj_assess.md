# a simplified interface into NJ assessment data

this is the workhorse function. given a end_year and a grade (valid
years are 2004-present), `fetch_old_nj_assess` will call the appropriate
function, process the raw text file, and return a data frame.
`fetch_old_nj_assess` is a wrapper around all the individual subject
functions (NJASK, HSPA, etc.), abstracting away the complexity of
finding the right location/file layout.

## Usage

``` r
fetch_old_nj_assess(end_year, grade, tidy = FALSE)
```

## Arguments

- end_year:

  a school year. end_year is the end of the academic year - eg 2013-14
  school year is end_year '2014'. valid values are 2004-2014.

- grade:

  a grade level. valid values are 3,4,5,6,7,8,11

- tidy:

  if TRUE, takes the unwieldy, inconsistent wide data and normalizes
  into a long, tidy data frame with ~20 headers -
  constants(school/district name and code), subgroup (all the NCLB
  subgroups) and test_name (LAL, math, etc).
