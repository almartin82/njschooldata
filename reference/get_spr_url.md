# Get SPR Database URL

Builds the URL for the School Performance Reports database containing
multiple sheets of school performance data.

## Usage

``` r
get_spr_url(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2017-2024). Year is the end of the academic year - eg
  2020-21 school year is end_year '2021'.

- level:

  One of "school" or "district". Determines which database file to
  download.

## Value

URL string
