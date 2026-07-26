# Retrieve and parse a graduation artifact with source provenance

Retrieve and parse a graduation artifact with source provenance

## Usage

``` r
get_raw_grad_file_result(
  end_year,
  methodology = "4 year",
  request_fn = .default_source_request
)
```

## Arguments

- end_year:

  School-year end year.

- methodology:

  One of \`"4 year"\` or \`"5 year"\`.

- request_fn:

  Injectable transport request function.

## Value

An \`njsd_source_result\`.
