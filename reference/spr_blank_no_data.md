# Blank out the "no data available" sentinel in a character column

Several 2024-25 staff sheets use the literal phrase “There is no data
available for this school year.” in place of a value. For character
columns (where it cannot be caught by numeric coercion) this maps that
sentinel to `NA` while leaving every other value untouched.

## Usage

``` r
spr_blank_no_data(x)
```

## Arguments

- x:

  A character vector.

## Value

The vector with the no-data sentinel set to `NA`.
