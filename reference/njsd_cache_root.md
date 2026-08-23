# Root directory for njschooldata's on-disk caches

Resolution order, most specific first:

1.  `getOption("njschooldata.cache_dir")` – an explicit, in-session
    choice, so a caller that has deliberately redirected the cache still
    wins.

2.  `Sys.getenv("NJSCHOOLDATA_CACHE_DIR")` – an ambient override. The
    test suite sets this (see `tests/testthat/setup-cache-isolation.R`)
    so that running the tests never reads or writes the caller's own
    cache; CI can set it for the same reason.

3.  `tools::R_user_dir("njschooldata", which = "cache")` – the default,
    unchanged from before either override existed.

## Usage

``` r
njsd_cache_root()
```

## Value

Absolute path to the cache root.

## Details

The directory is not created by this getter; each cache creates its own
subdirectory on first write.
