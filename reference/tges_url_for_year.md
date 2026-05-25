# Build the download URL for a TGES/CSG year

NJ DOE relocated the guide files under `/education/guide/docs/` (and
moved the domain from state.nj.us to nj.gov). 2001-2010 ship as
`{year}_CSG.zip`, 2011-2023 as `{year}_TGES.zip`, and 2024 onward as a
per-year subfolder containing an irregularly named bundle zip.

## Usage

``` r
tges_url_for_year(end_year)
```

## Arguments

- end_year:

  reporting year

## Value

character URL
