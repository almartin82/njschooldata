# read Special ed excel files from the NJ state website

read Special ed excel files from the NJ state website

## Usage

``` r
get_raw_sped(end_year, level = "district")
```

## Arguments

- end_year:

  A school-year end year. Valid values are 1999-2026.

- level:

  one of `"district"` (default; district-level total classification
  rate, all supported years) or `"state"` (state-level counts +
  classification rate by IDEA disability category, 2025+ only – this
  interface reads the consolidated 2025 workbook).

## Value

a dataframe with special ed counts, etc.
