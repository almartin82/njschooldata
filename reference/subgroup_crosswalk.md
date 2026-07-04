# Subgroup Standardization Crosswalk

Maps the cleaned subgroup labels emitted by the three in-package
subgroup cleaners (`clean_spr_subgroups`, `tidy_parcc_subgroup`,
`clean_6yr_grad_subgroups`) onto a single shared `subgroup_std`
vocabulary. This lets code that consumes different source families
filter on one common set of tokens. It is a non-breaking add-on: the
source-specific `subgroup` values are unchanged, and `subgroup_std` is
attached alongside them by
[`add_subgroup_std`](https://almartin82.github.io/njschooldata/reference/add_subgroup_std.md)
/
[`standardize_subgroup`](https://almartin82.github.io/njschooldata/reference/standardize_subgroup.md).

## Usage

``` r
subgroup_crosswalk
```

## Format

A data frame with 4 columns:

- raw_value:

  Cleaned subgroup label emitted by a cleaner

- vocab_family:

  Source cleaner family: one of `"spr"`, `"parcc"`, `"grad6yr"`

- subgroup_std:

  Standard subgroup token, or `NA` when the label has no standard
  equivalent

- dimension:

  Conceptual dimension: one of `"total"`, `"econ"`, `"disability"`,
  `"el"`, `"race"`, `"gender"`, or `NA` for labels with no standard
  equivalent

## Source

Derived from the in-package subgroup cleaners; rebuild with
`data-raw/build_subgroup_crosswalk.R`

## Details

Every `raw_value` is traced directly from the output of the three
cleaners (not hand-invented). Labels with no standard equivalent (for
example special-education accommodation flags or PARCC grade breakdowns)
are listed with `subgroup_std = NA` so coverage is fully documented.

## See also

[`standardize_subgroup`](https://almartin82.github.io/njschooldata/reference/standardize_subgroup.md),
[`add_subgroup_std`](https://almartin82.github.io/njschooldata/reference/add_subgroup_std.md)
