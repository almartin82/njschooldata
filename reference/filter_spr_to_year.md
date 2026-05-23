# Filter an SPR sheet to a single academic year

Several 2024-25 SPR sheets ship as multi-year trend tables (a
`school_year` column spanning, e.g., 2020-21..2024-25) where the
pre-redesign sheet held a single year. When a `school_year` column is
present, this keeps only the rows for the requested academic year so the
output preserves the historical one-row-per-entity shape. Sheets without
a `school_year` column are returned unchanged.

## Usage

``` r
filter_spr_to_year(df, end_year)
```

## Arguments

- df:

  Data frame from
  [`fetch_spr_data`](https://almartin82.github.io/njschooldata/reference/fetch_spr_data.md)
  (column names already snake_cased).

- end_year:

  School year end (e.g., 2025 for SY2024-25).

## Value

The data frame filtered to the requested academic year, or unchanged if
no `school_year` column exists.
