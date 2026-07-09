# Fetch Postsecondary Enrollment Rates from SPR Databases

Downloads postsecondary enrollment rates from the NJ DOE School
Performance Reports (SPR) database workbooks.

## Usage

``` r
fetch_postsecondary_enrollment(end_year, level = "district")
```

## Arguments

- end_year:

  A school year end year. Supported years are 2017 through 2023. Year is
  the end of the academic year; for example, use 2023 for the 2022-23
  school year.

- level:

  One of `"district"` or `"school"`. `"district"` returns district and
  state rows. `"school"` returns school, district, and state rows where
  present in the school workbook.

## Value

A data frame with database year, class year, measurement window, entity
identifiers and names, subgroup, lower/upper measure columns,
`value_format`, and entity aggregation flags.

## Details

This fetcher reads two SPR database sheets and stacks them into one data
frame: `PostsecondaryEnrRatesFall` and `PostsecondaryEnrRates16mos`. The
fall sheet in database year `Y` reports graduating class `Y`; the
16-month sheet in database year `Y` reports graduating class `Y - 1`.
This mapping was checked against the `PostSecondaryEnrRateSummary`
class-year trend rows in the 2018-19, 2019-20, and 2020-21 SPR
databases, and against the class-of-2020 fall enrollment drop in the
2019-20 database.

`enrolled_any` is the share of the graduating class enrolled in
postsecondary education. The `enrolled_2yr`, `enrolled_4yr`,
`enrolled_public`, `enrolled_private`, `enrolled_in_state`, and
`enrolled_out_of_state` measures are shares of enrolled graduates, not
shares of all graduates.

Values are returned as numeric lower/upper pairs for every measure.
Plain values such as `"57.1"` are returned with equal lower and upper
bounds and `value_format == "point"`. Range strings such as
`"69.8-72.0%"` are returned without midpointing as lower and upper
bounds and `value_format == "range"`. Suppressed or missing values stay
missing; they are never converted to zero.

The source sheets carry "Statewide" as a student-group row under every
entity, repeating the state value. Those rows are promoted to one
state-reference row per measurement window (`is_state == TRUE`, entity
identifiers `NA`), so an entity's own total row is the only
`"total population"` row bearing its identifiers.

The 2023-24 SPR database (end_year 2024) shipped these postsecondary
sheets with zero data rows because National Student Clearinghouse data
had not been published. The redesigned 2024-25 SPR database (end_year
2025) removed these sheets. Both years stop with an explanatory error
instead of returning an empty or fabricated data set.

## Examples

``` r
if (FALSE) { # \dontrun{
postsec <- fetch_postsecondary_enrollment(2023, level = "district")
school_postsec <- fetch_postsecondary_enrollment(2019, level = "school")
} # }
```
