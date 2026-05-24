# Reshape a legacy (pre-2025) StudentGrowthByGrade sheet to the 2025 shape

Legacy columns: `ela_math`, `grade`, a single median column whose name
churns by year (`m_sgp` for 2023-24, `m_sgp_school` for 2018-19), and
`level` (the growth category, present only 2023-24).

## Usage

``` r
sgp_legacy_by_grade(df)
```

## Arguments

- df:

  Output of
  [`fetch_spr_data`](https://almartin82.github.io/njschooldata/reference/fetch_spr_data.md)
  for a legacy by-grade sheet.

## Value

Data frame matching the 2025 `type = "by_grade"` output.
