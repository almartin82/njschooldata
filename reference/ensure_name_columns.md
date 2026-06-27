# Ensure entity-name columns exist on an SPR data frame

A few of the earliest SPR sheets (notably the SY2016-17 `SchoolDay`
sheet) ship only the CDS-code id columns and omit the
county/district/school name columns. This helper adds any missing name
column as `NA_character_` so downstream column selection is stable. The
CDS-code ids remain the real join keys; a missing name is left `NA`,
never fabricated.

## Usage

``` r
ensure_name_columns(df)
```

## Arguments

- df:

  A data frame from
  [`fetch_spr_data`](https://almartin82.github.io/njschooldata/reference/fetch_spr_data.md).

## Value

`df` with `county_name`, `district_name`, and `school_name` guaranteed
present.
