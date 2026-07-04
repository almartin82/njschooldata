# Attach schema-conformance columns to tidy SPED placement output

Adds the standardized `subgroup_std` column (immediately after
`subgroup`) and, when `with_status = TRUE`, an honesty `value_status`
column.

## Usage

``` r
finalize_sped_placement(df, with_status = FALSE)
```

## Arguments

- df:

  tidy placement tibble (must contain `subgroup`; `count` used for
  status).

- with_status:

  logical; attach `value_status` when `TRUE`.

## Value

`df` with `subgroup_std` (and optionally `value_status`) added
additively.

## Details

The placement `subgroup` column is a MIXED dimension governed by the
`dimension` column: standard demographic subgroups (`black`, `white`,
`asian`, `hispanic`, `male`, `female`, `multiracial`,
`pacific_islander`) map onto the shared subgroup vocabulary;
placement-specific / non-demographic tokens (`total`, the disability
categories, the `age_*` rows, `lep`, `native_american`) have no standard
demographic equivalent and carry `subgroup_std = NA` by design.
Unmatched-subgroup warnings from `add_subgroup_std` are therefore
expected here and are suppressed.

`value_status` classifies the primary published value, the `count`
column. In these child-count sheets a cell is either a published count
or a `"*"` small-cell suppression, so a missing `count` is classified
`"suppressed"` and a present one `"actual"` (never fabricated).
