# Parse a modern (2020-2026) certificated-staff sheet into harmonized long form

Reads one sheet (`STATE`/`COUNTY`/`DISTRICT`/`SCHOOL`; header on row 2,
`skip = 1`) and resolves columns by normalized header name – robust to
the 2020 transitional layout (a phantom merged column, plural position
labels, `"Pacific Islander"`/`"Multi"` naming, a `"Min"` minority
column, no Non-Binary count) and the uniform 2021-2026 layout. The
trailing `"end of worksheet"` sentinel row is dropped. Each source row
(one per entity x position, with race counts reported only as a gender
total) is expanded to three long rows – `gender` `"total"` (race
breakdown populated), `"male"` and `"female"` (race columns `NA`, since
the modern files do not cross race x gender; `total` carries that
gender's headcount). Non-binary is published only as a percent (no
count) and is not surfaced.

## Usage

``` r
parse_certificated_modern(path, sheet, end_year)
```

## Arguments

- path:

  Path to the modern `.xlsx`.

- sheet:

  Sheet name to read.

- end_year:

  The school year end.

## Value

A harmonized long-by-gender data frame.
