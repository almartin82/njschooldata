# Check if a URL is accessible

Performs a HEAD request to verify the URL exists without downloading.

## Usage

``` r
check_url_accessible(url, timeout = 10)
```

## Arguments

- url:

  URL to check

- timeout:

  Timeout in seconds (default 10)

## Value

Logical indicating if URL is accessible

## Examples

``` r
if (FALSE) { # \dontrun{
check_url_accessible("https://www.nj.gov/education/")
} # }
```
