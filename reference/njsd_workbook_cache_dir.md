# Directory holding cached SPR workbooks

On-disk location where downloaded SPR Excel databases are cached. Lives
under
[`njsd_cache_root`](https://almartin82.github.io/njschooldata/reference/njsd_cache_root.md),
which defaults to `tools::R_user_dir("njschooldata", "cache")` and is
overridden by `options(njschooldata.cache_dir = "/path")` or by the
`NJSCHOOLDATA_CACHE_DIR` environment variable.

## Usage

``` r
njsd_workbook_cache_dir()
```

## Value

Absolute path to the workbook cache directory (it is not created by this
getter).

## Examples

``` r
njsd_workbook_cache_dir()
#> [1] "/home/runner/.cache/R/njschooldata/spr-workbooks"
```
