# Pick an entity value from a pre-redesign SPR sheet with a parallel state column

The pre-2025 SPR assessment / graduation sheets store the entity's own
value in one column (e.g. `graduates`, `mean_score`) and repeat the
statewide value in a parallel `state_*` column on every row. On the
statewide aggregate row the entity column is blank and only the
`state_*` column is populated. This returns the entity column for
ordinary rows and the `state_*` column only for the `is_state` row –
never filling a suppressed entity from the statewide column (which would
fabricate data), mirroring
[`fetch_6yr_grad_rate`](https://almartin82.github.io/njschooldata/reference/fetch_6yr_grad_rate.md).
At `level = "school"` (no statewide row) it returns the entity column
directly.

## Usage

``` r
spr_legacy_entity_value(df, entity_col, state_col, level, with_status = FALSE)
```

## Arguments

- df:

  A data frame from
  [`fetch_spr_data`](https://almartin82.github.io/njschooldata/reference/fetch_spr_data.md).

- entity_col:

  Name of the entity (school/district) value column.

- state_col:

  Name of the parallel statewide value column (may be absent).

- level:

  One of `"school"` or `"district"`.

- with_status:

  Logical. If `TRUE`, return a list with the cleaned numeric `value` and
  the `status` classified from the picked raw cell. The default `FALSE`
  returns the legacy numeric vector.

## Value

A numeric vector; suppressed / non-numeric cells become `NA`.
