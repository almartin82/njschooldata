# Tidy a pre-2025 state placement workbook (5-21 or 3-5)

For end_years where state placement is published as a standalone xlsx
(2023 3-5, 2024 5-21, 2024 3-5), parses the single-sheet workbook into
the canonical state-level tidy schema. The sheet structure has stacked
tables separated by section-header rows whose first cell labels the
dimension ("Race", "Gender", "Special Education Classification" /
"Disablity Category" / "Disability Category", "LEP Status" / "LEP").

## Usage

``` r
tidy_pre2025_state(df, end_year, age_group)
```

## Arguments

- df:

  raw tibble (sheet read with skip = 0, col_types = "text")

- end_year:

  for tagging

- age_group:

  "5-21" or "3-5"

## Value

tidy tibble matching the 2025 state output schema
