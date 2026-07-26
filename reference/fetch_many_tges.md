# Fetch Multiple Cleaned Taxpayer's Guides to Educational Spending

Fetch Multiple Cleaned Taxpayer's Guides to Educational Spending

## Usage

``` r
fetch_many_tges(end_year_vector, allow_partial = FALSE)
```

## Arguments

- end_year_vector:

  vector of years. Current valid values are 2001 to 2025.

- allow_partial:

  If \`FALSE\` (default), any failed or unsupported year aborts the
  request. If \`TRUE\`, successful years are returned and all request
  statuses are available through \[get_source_results()\].

## Value

Named list of per-year TGES tables with source-result provenance.
