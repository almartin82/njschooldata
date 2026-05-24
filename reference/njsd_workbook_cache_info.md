# Inspect the on-disk SPR workbook cache

Inspect the on-disk SPR workbook cache

## Usage

``` r
njsd_workbook_cache_info()
```

## Value

A data frame (one row per cached workbook) with `file`, `size_mb`, and
`modified`; returned invisibly after printing a one-line summary. Empty
if nothing is cached.

## See also

[`njsd_workbook_cache_clear`](https://almartin82.github.io/njschooldata/reference/njsd_workbook_cache_clear.md),
[`njsd_workbook_cache_dir`](https://almartin82.github.io/njschooldata/reference/njsd_workbook_cache_dir.md)

## Examples

``` r
njsd_workbook_cache_info()
#> No cached SPR workbooks in /home/runner/.cache/R/njschooldata/spr-workbooks
```
