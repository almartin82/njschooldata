# Tidy chronic absenteeism data

Normalizes subgroup names to cross-state standards and adds entity-level
flags. Applied automatically when `fetch_absence(tidy = TRUE)`.

## Usage

``` r
tidy_absence(df)
```

## Arguments

- df:

  Data frame from
  [`fetch_chronic_absenteeism()`](https://almartin82.github.io/njschooldata/reference/fetch_chronic_absenteeism.md)

## Value

Data frame with standardized subgroup names

## Examples

``` r
if (FALSE) { # \dontrun{
ca <- fetch_chronic_absenteeism(2024)
ca_tidy <- tidy_absence(ca)
} # }
```
