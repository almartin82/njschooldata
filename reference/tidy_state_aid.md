# Tidy NJ State Aid District Details

Reshapes the wide district-details workbook to long: one row per
district per aid category. The recognized aid categories are normalized
to cross-year names; year totals and difference columns pass through
(flagged `is_aid_category = FALSE`).

## Usage

``` r
tidy_state_aid(df, end_year)
```

## Arguments

- df:

  a raw state-aid data frame from
  [`get_raw_state_aid()`](https://almartin82.github.io/njschooldata/reference/get_raw_state_aid.md)

- end_year:

  school year (end of the academic year)

## Value

long, tidy data frame
