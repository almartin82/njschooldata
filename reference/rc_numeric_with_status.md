# Pair report-card numeric coercion with value-status classification

Pair report-card numeric coercion with value-status classification

## Usage

``` r
rc_numeric_with_status(x)
```

## Arguments

- x:

  A raw report-card value vector.

## Value

A list with `value` from
[`rc_numeric_cleaner`](https://almartin82.github.io/njschooldata/reference/rc_numeric_cleaner.md)
and `status` from
[`classify_value_status`](https://almartin82.github.io/njschooldata/reference/classify_value_status.md).
