# Read the statewide EL headcount + percent from the State worksheet

The State worksheet lists EL by grade; the "All Grades" row is the
published statewide total. Available as a real count for every year
2020+.

## Usage

``` r
ell_read_modern_state(xlsx, end_year)
```

## Arguments

- xlsx:

  path to the enrollment workbook

- end_year:

  ending academic year

## Value

list(el_count, el_pct)
