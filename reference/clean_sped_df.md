# Clean SPED data

Cleans and standardizes SPED data from NJ DOE.

## Usage

``` r
clean_sped_df(df, end_year, with_status = FALSE)
```

## Arguments

- df:

  raw data frame with cleaned names, output of get_raw_sped with
  clean_sped_names applied.

- end_year:

  academic year, ending year - eg 2023-2024 is 2024.

- with_status:

  logical. If `TRUE`, appends `value_status` classified from the raw
  `sped_rate` token before numeric coercion.

## Value

cleaned data frame
