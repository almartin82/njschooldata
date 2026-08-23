# Directory holding cached SPED placement workbooks

Lives under
[`njsd_cache_root`](https://almartin82.github.io/njschooldata/reference/njsd_cache_root.md),
so it follows `options(njschooldata.cache_dir)` and the
`NJSCHOOLDATA_CACHE_DIR` environment variable like every other on-disk
cache in the package.

## Usage

``` r
sped_placement_cache_dir()
```

## Value

absolute path to the cache directory (created lazily on use)
