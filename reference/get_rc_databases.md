# Get multiple RC databases

Get multiple RC databases

## Usage

``` r
get_rc_databases(end_year_vector = 2012:2019, allow_partial = FALSE)
```

## Arguments

- end_year_vector:

  vector of years. Current valid values are 2012 to 2019.

- allow_partial:

  If \`FALSE\` (default), any unavailable or malformed year aborts with
  the failed years and statuses. If \`TRUE\`, returns successful years
  and records every requested year in \[get_source_results()\].

## Value

a list of dataframes
