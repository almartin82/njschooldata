# Remove legacy download folders left by older versions

This compatibility helper never clears the verified historical release
store.

## Usage

``` r
njsd_workbook_cache_clear(end_year = NULL)
```

## Arguments

- end_year:

  Optional school year. With a year, remove matching legacy SPR
  workbooks and sidecars only. With NULL, remove all five legacy
  folders.

## Value

Number of legacy files removed, invisibly.
