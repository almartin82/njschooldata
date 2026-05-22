# Clean report card subgroup names to canonical lowercase form

Standardizes subgroup names from NJ DOE report card data to the
canonical lowercase names used across the package. Matches the output
conventions of
[`clean_spr_subgroups`](https://almartin82.github.io/njschooldata/reference/clean_spr_subgroups.md)
and
[`grad_file_group_cleanup`](https://almartin82.github.io/njschooldata/reference/grad_file_group_cleanup.md).

## Usage

``` r
clean_rc_subgroups(group)
```

## Arguments

- group:

  Character vector of subgroup names.

## Value

Character vector of cleaned, lowercase canonical subgroup names.
