# Read EL headcount + percent from the District / School worksheets

Read EL headcount + percent from the District / School worksheets

## Usage

``` r
ell_read_modern_entities(xlsx, end_year)
```

## Arguments

- xlsx:

  path to the enrollment workbook

- end_year:

  ending academic year

## Value

data.frame: cds_code, el_count, el_pct (one row per entity; count is NA
where the worksheet publishes only a percent)
