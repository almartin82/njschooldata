# Parse a percent value from the workbook

The workbook mixes two percent formats across sheets: - State sheets
store percents as decimals (eg 0.4514 = 45.14 - District sheets store
percents as whole percents (eg 67.3 = 67.3 Both are kept on the same
0-100 scale in tidy output. Suppression flags ("\*") become NA.

## Usage

``` r
parse_placement_pct(x, scale_to_pct = 1)
```

## Arguments

- x:

  character vector

- scale_to_pct:

  numeric multiplier applied after parsing (100 for decimal sheets, 1
  for already-pct sheets)

## Value

numeric vector on the 0-100 scale (NA for suppressed)
