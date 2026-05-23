# Pick an SPR sheet name by year

Convenience helper for consumers whose source sheet was renamed in the
2024-25 (end_year 2025) SPR redesign. Returns `name_2025` when
`end_year >= 2025`, otherwise `name_legacy`.

## Usage

``` r
spr_sheet_for_year(end_year, name_legacy, name_2025)
```

## Arguments

- end_year:

  School year end.

- name_legacy:

  Sheet name used for 2017-2024.

- name_2025:

  Sheet name used for 2025 onward.

## Value

The appropriate sheet name string.
