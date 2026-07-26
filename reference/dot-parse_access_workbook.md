# Parse a validated ACCESS for ELLs workbook

Reads a specific grade sheet from an adapter-validated local workbook.

## Usage

``` r
.parse_access_workbook(path, grade = "all")
```

## Arguments

- path:

  Path to a validated ACCESS workbook.

- grade:

  Grade level: "K" or 0 for Kindergarten, or 1-12 for other grades. Use
  "all" to get all grades combined.

## Value

ACCESS dataframe for the specified grade
