# Kill Excel Formula Padding For Numeric Strings

Removes Excel formula padding (="01") from strings, leaving just the
numeric value.

## Usage

``` r
kill_padformulas(x)
```

## Arguments

- x:

  a vector with strings entered as formulas - eg ="01"

## Value

a vector with normalized strings
