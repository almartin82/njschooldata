# Download (and, if zipped, extract) the certificated-staff data file

Downloads the source for `end_year`, validates the binary (ZIP magic
bytes via
[`is_valid_xlsx`](https://almartin82.github.io/njschooldata/reference/is_valid_xlsx.md)
– a zip and an .xlsx both begin `PK`, so this rejects HTML error / bot
pages for both), and, for the zip-wrapped years, extracts the single
data member. Returns a local path to the data file (a `.csv` for the
legacy era, a `.xlsx` for the modern era).

## Usage

``` r
certificated_staff_local_file(end_year, work_dir)
```

## Arguments

- end_year:

  A covered school year end.

- work_dir:

  A scratch directory the caller owns and cleans up.

## Value

A list with `path`, `era`.
