# Download and read the raw DARS Restraint & Seclusion workbook

Downloads the standalone NJ DOE DARS school-level Restraint & Seclusion
Excel workbook for `end_year`, validates it is a real `.xlsx` (ZIP magic
bytes; see
[`is_valid_xlsx`](https://almartin82.github.io/njschooldata/reference/is_valid_xlsx.md))
so an HTTP error or bot page is never parsed as data, and reads the
`Restraints and Seclusions` sheet. That is the second sheet (the first
is `Introduction`); its real header is row 12 (`skip = 11` - row 11 is a
masking-rule note that bleeds into the first column).

## Usage

``` r
get_raw_restraint_seclusion(end_year)
```

## Arguments

- end_year:

  2023 (SY2022-23) or 2024 (SY2023-24). Other years error.

## Value

The raw 27-column data frame, exactly as published (count/percent
columns still carry the `"*"` / `"<5"` masking tokens).
