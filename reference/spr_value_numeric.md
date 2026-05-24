# Coerce an SPR value column to numeric

SPR value columns mix plain numbers, percent strings (e.g. `"56.2%"`),
thousands-separated counts (e.g. `"10,238"`), and suppression phrases
(e.g. `"Data was available for less than 10 students"`,
`"n/a - Below ESSA N-Size"`,
`"There is no data available for this school year."`). This strips
thousands commas and percent signs and maps every remaining non-numeric
token to `NA`, preserving real numbers (including decimals and
half-points) exactly. Already-numeric columns pass through untouched.

## Usage

``` r
spr_value_numeric(x)
```

## Arguments

- x:

  A character or numeric vector from an SPR value column.

## Value

A numeric vector.
