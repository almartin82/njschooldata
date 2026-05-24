# Supported SGP years by type

SGP coverage differs per `type` because the pre-redesign databases store
each measure in a differently-shaped sheet with a different history. See
[`fetch_sgp`](https://almartin82.github.io/njschooldata/reference/fetch_sgp.md)
for the empirical basis.

## Usage

``` r
sgp_supported_years(type)
```

## Arguments

- type:

  One of "trends", "by_grade", "by_performance_level".

## Value

Integer vector of supported `end_year`s.
