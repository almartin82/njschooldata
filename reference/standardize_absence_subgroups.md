# Map SPR subgroup names to cross-state standard names

Normalizes NJ-specific subgroup labels to match the naming conventions
used across all 50 state packages, enabling cross-state comparisons with
code like `filter(subgroup == "econ_disadv")`.

## Usage

``` r
standardize_absence_subgroups(subgroup)
```

## Arguments

- subgroup:

  Character vector of SPR subgroup names

## Value

Character vector with standardized names
