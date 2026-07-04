# Assert a year span does not cross an era break

Stops when the span from `min(years)` to `max(years)` crosses a
`scale_break` or `definition_change`, or includes a `covid_gap`, for the
selected break set. Single-year inputs do not span a break. This is a
trend guard for code that should not connect lines across regime changes
or missing/disrupted COVID years.

## Usage

``` r
assert_no_break_span(years, break_set)
```

## Arguments

- years:

  Vector of whole-number ending years.

- break_set:

  Single break-set key, such as `"njsla"` or `"attendance"`.

## Value

The input `years`, invisibly, when the span is valid.

## Examples

``` r
assert_no_break_span(2016:2018, "njsla")
try(assert_no_break_span(2014:2016, "njsla"), silent = TRUE)
try(assert_no_break_span(c(2019, 2022), "njsla"), silent = TRUE)
```
