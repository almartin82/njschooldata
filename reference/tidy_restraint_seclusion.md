# Tidy a raw DARS Restraint & Seclusion data frame

Renames the seven identifier columns and the 20 count/percent columns to
a stable snake_case schema, cleans the CDS codes (leading zeros
preserved), drops the trailing sentinel row and the single blank
`Student Group` row, coerces every value column to numeric with masked
cells (`"*"`, `"<5"`) mapped to `NA`, splits the student-group label
into `subgroup` + `grade_level`, and stamps the school-only entity
flags.

## Usage

``` r
tidy_restraint_seclusion(df, end_year)
```

## Arguments

- df:

  A raw data frame from
  [`get_raw_restraint_seclusion`](https://almartin82.github.io/njschooldata/reference/get_raw_restraint_seclusion.md).

- end_year:

  The school year end (added as a column).

## Value

The tidy data frame in the documented output schema.
