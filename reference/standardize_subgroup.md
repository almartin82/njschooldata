# Standardize subgroup labels

Maps cleaned subgroup labels onto a shared subgroup vocabulary.

## Usage

``` r
standardize_subgroup(x)
```

## Arguments

- x:

  Character vector of subgroup labels.

## Value

Character vector using the standard subgroup vocabulary. Values with no
crosswalk entry, or with an explicit no-equivalent entry, return
`NA_character_`.
