# Extract Report Card SAT School Averages

Extract Report Card SAT School Averages

## Usage

``` r
extract_rc_SAT(list_of_prs, school_only = TRUE, cds_identifiers = TRUE)
```

## Arguments

- list_of_prs:

  output of get_rc_databases (ie, a list where each element is) a list
  of data.frames

- school_only:

  some years have district average results, not just school-level. if
  school_only, return only school data. default is TRUE

- cds_identifiers:

  add the county, district and school name? default is TRUE

## Value

data frame with all years of SAT School Averages present in the input
