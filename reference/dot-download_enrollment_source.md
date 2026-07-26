# Retrieve and parse one enrollment source

Retrieve and parse one enrollment source

## Usage

``` r
.download_enrollment_source(end_year, request_fn = .default_source_request)
```

## Arguments

- end_year:

  School-year end year.

- request_fn:

  Injectable transport request function used by offline tests.

## Value

An \`njsd_source_result\` containing raw enrollment data.
