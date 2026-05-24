# Download an SPR workbook, caching it on disk

Returns a local path to the SPR Excel database for `end_year` / `level`,
downloading it from NJ DOE on first use and reusing the cached copy
thereafter. The download is validated as a real `.xlsx` (see
[`is_valid_xlsx`](https://almartin82.github.io/njschooldata/reference/is_valid_xlsx.md))
before it is cached or returned, so an HTTP error or bot-protection page
is never silently treated as data.

## Usage

``` r
spr_cached_workbook(end_year, level)
```

## Arguments

- end_year:

  SPR school year end (2017-2025).

- level:

  One of `"school"` or `"district"`.

## Value

Path to a local, validated `.xlsx` file.

## Details

Disk caching is on by default. Disable it with
`options(njschooldata.workbook_cache = FALSE)` or by turning off the
session cache
([`njsd_cache_enable`](https://almartin82.github.io/njschooldata/reference/njsd_cache_enable.md)`(FALSE)`);
in either case the workbook is downloaded to a temporary file each call.
