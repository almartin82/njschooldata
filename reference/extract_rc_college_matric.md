# Extract Report Card Matriculation Rates

Extract Report Card Matriculation Rates

## Usage

``` r
extract_rc_college_matric(
  list_of_prs,
  type = "16 month",
  school_only = TRUE,
  cds_identifiers = TRUE
)
```

## Arguments

- list_of_prs:

  output of get_rc_databases (ie, a list where each element is) a list
  of data.frames

- type:

  character string specifying matriculation type. One of "16 month" or
  "12 month"

- school_only:

  some years have district average results, not just school-level. if
  school_only, return only school data. default is TRUE

- cds_identifiers:

  add the county, district and school name? default is TRUE

## Value

data frame with all the years of 4 year and 2 year college matriculation
data present in in the input
