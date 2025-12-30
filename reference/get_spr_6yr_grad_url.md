# Get SPR database URL for 6-year graduation rates

Builds the URL for the School Performance Reports database containing
6-year graduation cohort profile data.

## Usage

``` r
get_spr_6yr_grad_url(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2021-2024). Year is the end of the academic year - eg
  2020-21 school year is end_year '2021'.

- level:

  One of "school" or "district". Determines which database file to
  download.

## Value

URL string
