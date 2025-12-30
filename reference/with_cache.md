# Create a cached version of a fetch function

Wraps a data fetching function to use the session cache.

## Usage

``` r
with_cache(fn, fn_name)
```

## Arguments

- fn:

  The fetch function to wrap

- fn_name:

  Name of the function (for cache keys)

## Value

A cached version of the function
