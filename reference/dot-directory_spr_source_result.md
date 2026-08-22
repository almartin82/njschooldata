# Download the NJDOE School Performance Reports contact roster

This official NJDOE JSON is a narrower fallback for environments where
the Homeroom downloads return an Imperva challenge. It publishes
district superintendents and school principals with native CDS
identifiers.

## Usage

``` r
.directory_spr_source_result(request_fn = .default_source_request)
```

## Arguments

- request_fn:

  Injectable transport request function.

## Value

An \`njsd_source_result\`.
