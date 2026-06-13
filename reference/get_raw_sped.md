# read Special ed excel files from the NJ state website

read Special ed excel files from the NJ state website

## Usage

``` r
get_raw_sped(end_year, level = "district")
```

## Arguments

- end_year:

  A school year. Year is the end of the academic year - eg 2006-07
  school year is year '2007'. Valid values are 2000-2026.

- level:

  one of `"district"` (default; district-level total classification
  rate, all supported years) or `"state"` (state-level counts +
  classification rate by IDEA disability category, 2025+ only – NJ DOE
  did not publish the by-disability state table in the older
  single-sheet workbooks).

## Value

a dataframe with special ed counts, etc.
