# Graduation data URL configuration table

This table maps years and methodologies to their corresponding URLs.
When NJ DOE changes URL patterns, update this table.

## Usage

``` r
grad_url_config
```

## Format

A data frame with columns:

- end_year:

  The graduation cohort year

- methodology:

  Either "4 year" or "5 year"

- file_type:

  File format ("xlsx", "xls", "csv")

- skip_rows:

  Number of header rows to skip when reading
