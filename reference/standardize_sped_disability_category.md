# Standardize NJ disability-category labels to cross-state snake_case

Thin wrapper around
[`standardize_sped_placement_subgroups`](https://almartin82.github.io/njschooldata/reference/standardize_sped_placement_subgroups.md)
that additionally maps the "Statewide Total" rollup row to
`"all_disabilities"` (the cross-state convention for the all-students
disability rollup).

## Usage

``` r
standardize_sped_disability_category(x)
```

## Arguments

- x:

  character vector of NJ disability-category labels

## Value

character vector of standardized `disability_category` values
