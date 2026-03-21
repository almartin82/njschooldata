# Process raw district directory data into standardized format

Cleans column names, removes Excel formula padding, and standardizes the
schema.

## Usage

``` r
process_district_directory(raw)
```

## Arguments

- raw:

  Data frame from
  [`get_raw_district_directory()`](https://almartin82.github.io/njschooldata/reference/get_raw_district_directory.md)

## Value

Processed data frame with standardized column names
