# Process raw school directory data into standardized format

Cleans column names, removes Excel formula padding, and standardizes the
schema.

## Usage

``` r
process_school_directory(raw)
```

## Arguments

- raw:

  Data frame from
  [`get_raw_school_directory()`](https://almartin82.github.io/njschooldata/reference/get_raw_school_directory.md)

## Value

Processed data frame with standardized column names
