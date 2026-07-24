# Download raw school directory data from NJ DOE

Downloads the CSV file from NJ DOE Homeroom and reads it into a data
frame. The CSV includes 3 header rows that need to be skipped.

## Usage

``` r
.directory_source_result(level, request_fn = .default_source_request)
```

## Value

Data frame with raw school directory data
