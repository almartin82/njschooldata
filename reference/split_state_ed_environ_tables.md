# Identify the next-table-divider row inside a stacked State sheet

The State by Ed Environ sheets stack five tables vertically (by age, by
disability, by race, by gender, by ML status), each separated by a
descriptive header row and a column-name row. This helper splits the
sheet into per-table chunks keyed on the first column.

## Usage

``` r
split_state_ed_environ_tables(df)
```

## Arguments

- df:

  raw tibble (after `skip = 4` read)

## Value

named list of per-table tibbles
