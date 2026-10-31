# Specification 1: all students against all students

Specification 1: all students against all students

## Usage

``` r
sped_all_vs_all(rows, focal, comparison)
```

## Arguments

- rows:

  Rows of
  [`fetch_sped_share()`](https://almartin82.github.io/njschooldata/reference/fetch_sped_share.md)
  for one year.

- focal, comparison:

  Data frames with district_id and school_id naming rows. Use NA
  school_id for a district row.

## Value

Two rows from
[`sped_pool()`](https://almartin82.github.io/njschooldata/reference/sped_pool.md),
labeled focal and comparison.
