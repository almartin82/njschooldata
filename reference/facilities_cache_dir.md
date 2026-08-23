# Internal facilities cache directory

Lives under
[`njsd_cache_root`](https://almartin82.github.io/njschooldata/reference/njsd_cache_root.md).
Before 2026-08-23 this resolver called
[`tools::R_user_dir()`](https://rdrr.io/r/tools/userdir.html) directly
and so ignored every cache override the rest of the package honours –
including the one the test suite uses to keep itself out of the caller's
real cache.

## Usage

``` r
facilities_cache_dir()
```
