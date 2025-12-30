# Clean up CDS field names

Standardizes county, district, and school column names to consistent
naming conventions (county_code, district_code, school_code, etc.).

## Usage

``` r
clean_cds_fields(df, tges = FALSE)
```

## Arguments

- df:

  data frame with county, district and school variables

- tges:

  if run in the taxpayers guide to ed spending (tges) mode, 'district'
  resolves to district code. defaults to FALSE.

## Value

df, with consistent county_code, district_code, school_code fields
