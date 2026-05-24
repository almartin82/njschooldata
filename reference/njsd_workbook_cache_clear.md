# Clear cached SPR workbooks from disk

Clear cached SPR workbooks from disk

## Usage

``` r
njsd_workbook_cache_clear(end_year = NULL)
```

## Arguments

- end_year:

  Optional school year; clear only that year's workbooks (both levels).
  Default `NULL` removes all cached workbooks.

## Value

Number of files removed (invisibly).

## See also

[`njsd_workbook_cache_info`](https://almartin82.github.io/njschooldata/reference/njsd_workbook_cache_info.md)

## Examples

``` r
if (FALSE) { # \dontrun{
njsd_workbook_cache_clear()      # remove all
njsd_workbook_cache_clear(2025)  # remove just SY2024-25
} # }
```
