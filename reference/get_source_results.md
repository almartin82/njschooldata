# Inspect source-request status and provenance

Canonical fetchers attach one record for every required or optional
source. These records describe request-level success or failure and are
distinct from row-level \`value_status\` classifications.

## Usage

``` r
get_source_results(x)
```

## Arguments

- x:

  An object returned by a canonical fetcher.

## Value

A data frame with source status, URL, retrieval time, digest, and
warning/error context.
