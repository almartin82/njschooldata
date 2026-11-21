# Process Grad Rate

Custom processing for grad rate data beyond generic process_grate.

## Usage

``` r
process_grad_rate(df, end_year, methodology)
```

## Arguments

- df:

  Output of get_grad_rate (already passed through process_grate)

- end_year:

  Ending academic year

- methodology:

  One of c('4 year', '5 year')

## Value

Data frame with normalized grad rate variables

## Details

For 5-year methodology, the raw files contain both 4-year and 5-year
columns. This function ensures `grad_rate` contains the rate matching
the requested methodology, and preserves the other rate as
`four_yr_grad_rate` or `five_yr_grad_rate`. The registered 2012-2019
dual-cohort workbooks publish both rates in percentage points, including
values below one. Conversion is unconditional; unknown vintages stop and
out-of-range source rates become NA.
