# Extract Report Card Enrollment

Extract Report Card Enrollment

## Usage

``` r
extract_rc_enrollment(list_of_prs, cds_identifiers = TRUE)
```

## Arguments

- list_of_prs:

  output of get_rc_databases (ie, a list where each element is a list of
  data.frames)

- cds_identifiers:

  add the county, district and school name? default is TRUE

## Value

data frame with school enrollment
