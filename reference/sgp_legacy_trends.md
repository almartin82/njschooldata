# Reshape a legacy (pre-2025) StudentGrowth subgroup sheet to 2025 trends shape

The redesigned 2025 `StudentGrowthTrends` sheet is the successor to the
legacy `StudentGrowth` sheet, which is long-by-subject with one row per
entity per student group. This pivots ELA/Math wide to match the 2025
output.

## Usage

``` r
sgp_legacy_trends(df, level)
```

## Arguments

- df:

  Output of
  [`fetch_spr_data`](https://almartin82.github.io/njschooldata/reference/fetch_spr_data.md)
  for a legacy StudentGrowth sheet.

- level:

  "school" or "district" (selects the entity median column).

## Value

Data frame matching the 2025 `type = "trends"` output, plus
`ela_met_target`/`math_met_target`.

## Details

Two legacy quirks are handled: (1) the subgroup column header varies
(`SubGroup`/`StudentGroup` in the district file, mislabeled `SchoolYear`
in the school file), so it is identified structurally as the column
immediately before `subject`; (2) legacy sheets carry a `MetTarget` flag
("Met Standard"/"Not Met"/...) rather than the 2025 growth/suppression
`*_category`. The `*_category` columns are therefore `NA` and the real
MetTarget value is preserved verbatim in
`ela_met_target`/`math_met_target`.
