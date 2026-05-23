# Standardize an SGP median column to numeric

SGP value columns hold either a numeric median (possibly with a
half-point, e.g. `"70.5"`) or a suppression phrase
(`"Fewer than 10 testers"`). This converts the column to numeric,
mapping the suppression phrase to `NA` (the suppression reason is
preserved in the companion `*_category` column). Real numbers, including
half-points, are kept exactly.

## Usage

``` r
sgp_value_to_numeric(x)
```

## Arguments

- x:

  Character vector from an SGP value column.

## Value

Numeric vector.
