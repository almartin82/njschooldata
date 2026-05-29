# Download (and disk-cache) the IDEA 618 placement workbook

Validates the download as a real .xlsx before caching, so an HTTP error
or bot-protection page is never written to the cache or parsed as data.

## Usage

``` r
sped_placement_cached_workbook(end_year)
```

## Arguments

- end_year:

  ending school year

## Value

path to a local, validated .xlsx file
