# Attach NCES ids where facilities rows carry exact NJ CDS ids

Federal identifiers are join keys only; unmatched rows stay NA.

## Usage

``` r
attach_facilities_nces(long)
```

## Arguments

- long:

  Facilities long data before dropping internal id columns.

## Value

Facilities long data with `nces_dist` and `nces_sch`.
