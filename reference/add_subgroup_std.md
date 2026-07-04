# Add standardized subgroup labels

Adds `subgroup_std` immediately after an existing `subgroup` column.

## Usage

``` r
add_subgroup_std(df)
```

## Arguments

- df:

  Data frame that may contain a `subgroup` column.

## Value

`df` with `subgroup_std` added after `subgroup`. If `subgroup` is
absent, returns `df` unchanged with a message.
