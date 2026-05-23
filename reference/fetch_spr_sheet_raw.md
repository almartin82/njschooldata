# Read an SPR sheet without CDS / aggregation-flag processing

A lighter-weight sibling of
[`fetch_spr_data`](https://almartin82.github.io/njschooldata/reference/fetch_spr_data.md)
for SPR sheets that do not carry the standard county/district/school
identifier columns (e.g. `NAEP`, `StatewideEducatorEquity`), which are
state/national summary tables. Downloads the workbook, reads the
requested sheet (skipping the 2024-25 preamble rows), snake-cases the
column names, and stamps `end_year`. No CDS renaming, subgroup cleaning,
or aggregation flags are applied.

## Usage

``` r
fetch_spr_sheet_raw(sheet_name, end_year, level = "district")
```

## Arguments

- sheet_name:

  Exact sheet name (case-sensitive).

- end_year:

  A school year (2017-2025).

- level:

  One of "school" or "district". Determines which database file to
  download.

## Value

Data frame with snake_cased column names plus `end_year`.
