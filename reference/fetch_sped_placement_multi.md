# Fetch NJ SPED placement data for multiple years

Convenience wrapper that calls
[`fetch_sped_placement`](https://almartin82.github.io/njschooldata/reference/fetch_sped_placement.md)
for each year and binds the results. Skips years that fail with a
warning.

## Usage

``` r
fetch_sped_placement_multi(
  end_years,
  age_group = "5-21",
  level = "district",
  tidy = TRUE
)
```

## Arguments

- end_years:

  integer vector of school years

- age_group:

  one of `"5-21"` or `"3-5"`

- level:

  one of `"district"` or `"state"`

- tidy:

  logical; passed through to
  [`fetch_sped_placement()`](https://almartin82.github.io/njschooldata/reference/fetch_sped_placement.md)

## Value

a single tibble with all successfully-fetched years bound together.

## Details

Currently only end_year 2025 is supported; this wrapper is provided so
downstream code can pre-write multi-year pipelines and pick up
additional years transparently as they're added.

## See also

[`fetch_sped_placement`](https://almartin82.github.io/njschooldata/reference/fetch_sped_placement.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Pull every supported year (currently just 2025)
placement_all <- fetch_sped_placement_multi(2025)

# As more years come online, just widen the range:
# placement_all <- fetch_sped_placement_multi(2020:2025)
} # }
```
