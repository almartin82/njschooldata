# Tidy a raw staff-evaluation data frame

Cleans the CDS codes (re-padded to fixed width, leading zeros
preserved), drops the trailing data-certification note rows and any
blank rows, maps the raw `CATEGORY` to a stable `staff_category`,
coerces the five rating columns to numeric with masked (`"*"`) cells -\>
`NA`, and stamps the entity flags. The statewide aggregate (county
`"99"` / district `"9999"`, present 2014-2015) is flagged `is_state`.

## Usage

``` r
tidy_staff_evaluations(df, end_year)
```

## Arguments

- df:

  A raw frame from
  [`get_raw_staff_evaluations`](https://almartin82.github.io/njschooldata/reference/get_raw_staff_evaluations.md).

- end_year:

  The school year end (added as a column).

## Value

The tidy evaluation data frame.
