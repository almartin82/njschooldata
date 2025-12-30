# Pad CDS fields

Zero-pads county, district, and school codes to their standard lengths
(2, 4, and 3 digits respectively).

## Usage

``` r
pad_cds(df)
```

## Arguments

- df:

  containing county_code, district_code, school_code

## Value

data frame with zero padded cds columns
