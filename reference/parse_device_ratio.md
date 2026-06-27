# Parse an NJ DOE student-to-device ratio to a numeric students-per-device

The SPR `DeviceRatios` sheet publishes the ratio as `"2.6:1"` / `"1:1"`
(2018-2024) or as a bare number `"1"` / `"1.1"` (2025+). This helper
returns the students-per-device count as a numeric (the left side of the
`":1"` ratio). Non-numeric values (`"No devices reported"`, `"n/a"`,
`NA`) return `NA`.

## Usage

``` r
parse_device_ratio(x)
```

## Arguments

- x:

  Character vector of ratio strings.

## Value

Numeric vector of students per device (`NA` where unparseable).
