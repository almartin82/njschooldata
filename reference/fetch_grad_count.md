# Fetch Grad Counts

Downloads and processes graduation count data.

## Usage

``` r
fetch_grad_count(end_year)
```

## Arguments

- end_year:

  End of the academic year - eg 2006-07 is 2007. Valid values are
  2012-2024.

## Value

dataframe with grad counts

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 2023 graduation counts
gcount_2023 <- fetch_grad_count(2023)
} # }
```
