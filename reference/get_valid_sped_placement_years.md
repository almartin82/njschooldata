# Valid years for SPED placement / educational-environment data

Returns the integer end_year values currently wired up for
[`fetch_sped_placement`](https://almartin82.github.io/njschooldata/reference/fetch_sped_placement.md).
Every (end_year, age_group, level) combination across 2020-2025 returns
data. State-level slices that NJ DOE published only as PDFs (state 5-21
for 2020-2022, state 3-5 for 2020-2022) are served from bundled CSVs
transcribed from those PDFs; see the audit trail under
inst/extdata/sped-placement-pdf-transcribed/.

## Usage

``` r
get_valid_sped_placement_years()
```

## Value

integer vector of supported end years
