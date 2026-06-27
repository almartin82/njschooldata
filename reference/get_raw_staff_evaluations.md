# Download and read the raw staff-evaluation workbook

Downloads the standalone NJ DOE summative educator-evaluation workbook
for `end_year`, validates it is a real `.xlsx` (ZIP magic bytes; see
[`is_valid_xlsx`](https://almartin82.github.io/njschooldata/reference/is_valid_xlsx.md))
so an HTTP error page is never parsed as data, reads the rating sheet(s)
for that year (one combined sheet in 2014; the district-totals +
school-totals sheets stacked in 2015 / 2016), and returns the raw
12-column rows with their published `"*"` masks intact.

## Usage

``` r
get_raw_staff_evaluations(end_year)
```

## Arguments

- end_year:

  2014, 2015, or 2016. Other years error.

## Value

A raw data frame of the published evaluation rows.
