# Fetch New Jersey facilities data for multiple years

Facilities sources shipped here are mostly latest-vintage snapshots.
This helper filters by requested year strings where the source vintage
supports it, otherwise returns the available source rows with a message.

## Usage

``` r
fetch_facilities_multi(category, years, tidy = TRUE, use_cache = TRUE)
```

## Arguments

- category:

  See \[fetch_facilities()\].

- years:

  Vector of years.

- tidy, use_cache:

  See \[fetch_facilities()\].

## Value

Combined facilities long-schema data frame.

## Examples

``` r
if (FALSE) { # \dontrun{
fetch_facilities_multi("finance", 2026)
fetch_facilities_multi("environmental", 2025)
fetch_facilities_multi("inventory", 2026)
} # }
```
