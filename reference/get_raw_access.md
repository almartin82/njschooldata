# Reads the raw ACCESS for ELLs Excel file from the state website

Downloads the ACCESS file and reads a specific grade sheet.

## Usage

``` r
get_raw_access(end_year, grade = "all")
```

## Arguments

- end_year:

  A school year (2022-2024)

- grade:

  Grade level: "K" or 0 for Kindergarten, or 1-12 for other grades. Use
  "all" to get all grades combined.

## Value

ACCESS dataframe for the specified grade
