# Legacy SPR workbook cache directory

Returns the former workbook cache path under \[njsd_cache_root()\],
without creating it. New reads use verified package-held release assets
instead.

## Usage

``` r
njsd_workbook_cache_dir()
```

## Value

Path to the legacy directory.
