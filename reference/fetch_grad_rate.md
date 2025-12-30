# Fetch Grad Rate

Downloads and processes graduation rate data.

## Usage

``` r
fetch_grad_rate(end_year, methodology = "4 year")
```

## Arguments

- end_year:

  End of the academic year - eg 2006-07 is 2007. Valid values are
  2011-2024.

- methodology:

  Character string specifying calculation methodology. One of "4 year"
  or "5 year".

## Value

dataframe with grad rate

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 2023 graduation rates
grate_2023 <- fetch_grad_rate(2023)

# Get 5-year graduation rates
grate_5yr <- fetch_grad_rate(2019, methodology = "5 year")
} # }
```
