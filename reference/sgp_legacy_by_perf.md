# Reshape a legacy (2023-24) StudentGrowthByPerformLevel sheet to 2025 shape

Legacy columns: `ela_math`, the prior-performance-level column (named
`njsla_performance_level` in the district file,
`parcc_performance_level` in the school file – both carry "Performance
Level 1".."5" values), `m_sgp`, and `level` (the growth category). Only
2023 and 2024 carry this median-by-level measure;
[`sgp_check_year`](https://almartin82.github.io/njschooldata/reference/sgp_check_year.md)
rejects earlier years.

## Usage

``` r
sgp_legacy_by_perf(df)
```

## Arguments

- df:

  Output of
  [`fetch_spr_data`](https://almartin82.github.io/njschooldata/reference/fetch_spr_data.md)
  for a legacy by-perf-level sheet.

## Value

Data frame matching the 2025 `type = "by_performance_level"` output.
