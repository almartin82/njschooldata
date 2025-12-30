# Tidy grad rate

Tidies a processed grate data frame, producing a data frame with
consistent headers and values, suitable for longitudinal analysis.

## Usage

``` r
tidy_grad_rate(df, end_year, methodology = "4 year")
```

## Arguments

- df:

  The output of process_grad_rate

- end_year:

  A school year. Year is the end of the academic year - eg 2006-07
  school year is year '2007'. Valid values are 1998-2024.

- methodology:

  One of '4 year' or '5 year'

## Value

Tidied graduation rate data frame
