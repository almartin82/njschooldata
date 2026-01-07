# Fetch AP/IB Performance Data (Alias)

Alias for
[`fetch_ap_participation`](https://almartin82.github.io/njschooldata/reference/fetch_ap_participation.md).
Returns both participation and performance data for AP/IB coursework.

## Usage

``` r
fetch_ap_performance(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2017-2024)

- level:

  One of "school" or "district"

## Value

Data frame with AP/IB participation and performance metrics

## Examples

``` r
if (FALSE) { # \dontrun{
ap_perf <- fetch_ap_performance(2024)
} # }
```
