# Clear directory data from session cache

Removes cached directory data so the next call to
[`fetch_directory()`](https://almartin82.github.io/njschooldata/reference/fetch_directory.md)
will download fresh data from NJ DOE.

## Usage

``` r
clear_directory_cache()
```

## Value

Number of items removed (invisibly)

## Examples

``` r
if (FALSE) { # \dontrun{
clear_directory_cache()
} # }
```
