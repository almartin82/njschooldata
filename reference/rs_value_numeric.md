# Coerce a masked DARS value to numeric, with "\<5"/"\*" -\> NA

The DARS workbooks mask small cells two ways: `"*"` hides a value
entirely, and `"<5"` (or `"<5.00"`, more generally `"<N"`) is a
published RANGE standing in for 1-4 students. Both must become `NA` - an
honest gap, never a guessed number. In particular this coercion must
NEVER turn `"<5"` into the literal `5`: any token beginning with `"<"`
(or equal to `"*"`) maps to `NA` BEFORE numeric parsing, so no digit is
ever extracted from a range string. A real published `0` stays `0`.

## Usage

``` r
rs_value_numeric(x)
```

## Arguments

- x:

  A character (or already-numeric) vector from a DARS count/percent
  column.

## Value

A numeric vector with masked/suppressed cells as `NA`.
