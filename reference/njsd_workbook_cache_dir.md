# Directory holding cached SPR workbooks

On-disk location where downloaded SPR Excel databases are cached.
Defaults to a per-user cache directory
(`tools::R_user_dir("njschooldata", "cache")`); override with
`options(njschooldata.cache_dir = "/path")`.

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
