# Clear the session cache

Removes all cached data from memory. Useful when you want to force fresh
downloads or free up memory.

## Usage

``` r
njsd_cache_clear(reset_stats = FALSE)
```

## Arguments

- reset_stats:

  Logical; also reset hit/miss statistics

## Value

Number of items cleared (invisibly)

## Examples

``` r
njsd_cache_clear()
#> Cleared 0 item(s) from njschooldata cache.
```
