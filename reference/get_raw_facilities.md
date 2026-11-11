# Fetch raw New Jersey facilities source data

Low-level fetcher for source transparency. Most users should call
[`fetch_facilities`](https://almartin82.github.io/njschooldata/reference/fetch_facilities.md)
or
[`fetch_facility_gis`](https://almartin82.github.io/njschooldata/reference/fetch_facility_gis.md).

## Usage

``` r
get_raw_facilities(source, use_cache = TRUE)
```

## Arguments

- source:

  One of the names in
  [`facilities_sources()`](https://almartin82.github.io/njschooldata/reference/facilities_sources.md).

- use_cache:

  Retained for compatibility; has no effect. Registers are fetched live
  on every call; dated snapshots use verified held bytes.

## Value

A source-shaped data frame or list of data frames.

## Examples

``` r
if (FALSE) { # \dontrun{
cds <- get_raw_facilities("njdoe_cds")
points <- get_raw_facilities("njgin_school_points")
grants <- get_raw_facilities("njdoe_sda_allocation")
} # }
```
