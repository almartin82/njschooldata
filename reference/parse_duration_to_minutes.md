# Parse an NJ DOE "X Hrs. Y Mins." duration string to minutes

The SPR `SchoolDay` sheet publishes durations as human-readable strings
(e.g. `"6 Hrs. 25 Mins."`, `"6 Hrs 20 Mins"`). This helper extracts the
hour and minute components and returns the total minutes as a numeric.
Non-duration values (`"n/a"`, `"n/a - applies only to high schools"`,
`NA`) return `NA`. This is a deterministic re-expression of the
published value, not an estimate.

## Usage

``` r
parse_duration_to_minutes(x)
```

## Arguments

- x:

  Character vector of duration strings.

## Value

Numeric vector of total minutes (`NA` where unparseable).
