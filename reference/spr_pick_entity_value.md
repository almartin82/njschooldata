# Collapse an SPR school/district/state value triple to one column

Collapse an SPR school/district/state value triple to one column

## Usage

``` r
spr_pick_entity_value(df, base, level, with_status = FALSE)
```

## Arguments

- df:

  A data frame from
  [`fetch_spr_data`](https://almartin82.github.io/njschooldata/reference/fetch_spr_data.md)
  (so the `is_state` flag is present).

- base:

  The shared column stem, e.g. `"proficiency_rate"` for the triple
  `proficiency_rate_school` / `_district` / `_state`.

- level:

  One of `"school"` or `"district"`.

- with_status:

  Logical. If `TRUE`, return a list with the cleaned numeric `value` and
  the `status` classified from the picked raw cell. The default `FALSE`
  returns the legacy numeric vector.

## Value

A numeric vector: the `_school` value at school level; the `_district`
value (or `_state` on the statewide row) at district level. Suppressed /
non-numeric cells become `NA`.
