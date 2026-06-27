# Coerce a published staff value to numeric, with masked cells -\> NA

The evaluation workbooks mask small cells with `"*"`; both staff sources
may carry stray text. This coercion strips thousands commas, maps any
masked or non-numeric token (`"*"`, `""`, a `"<N"` range, free text) to
`NA` BEFORE numeric parsing, and otherwise returns the number. A real
published `0` stays `0`; fractional FTE values (e.g. `35.8`) are
preserved. Already-numeric input is returned unchanged.

## Usage

``` r
staff_value_numeric(x)
```

## Arguments

- x:

  A character (or numeric) vector from a count / FTE column.

## Value

A numeric vector with masked / suppressed cells as `NA`.
