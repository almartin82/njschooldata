# Enable or disable the session cache

Controls whether downloaded data is cached in memory for the current
session. Caching is enabled by default.

## Usage

``` r
njsd_cache_enable(enable = TRUE)
```

## Arguments

- enable:

  Logical; TRUE to enable caching, FALSE to disable

## Value

Previous cache state (invisibly)

## Examples

``` r
njsd_cache_enable(FALSE)  # Disable caching
#> njschooldata cache disabled. Data will be downloaded fresh each time.
njsd_cache_enable(TRUE)   # Re-enable caching
#> njschooldata cache enabled.
```
