# Parse a TGES rank value to an integer

Through ~2015 a rank is a plain integer (eg "34"). From 2019 on NJ DOE
encodes it as "rank\|out_of" (eg "33\|57", ie 33rd of 57 in the peer
group). This keeps the rank itself; the peer-group size is not retained.
Non-numeric markers ("N.R." Not Reported, "N.A." Not Applicable, blanks)
become NA.

## Usage

``` r
parse_rank(x)
```

## Arguments

- x:

  character vector of rank values

## Value

integer vector
