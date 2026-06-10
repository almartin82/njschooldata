# Years for which NJ finance data is available

The union of the two NJ DOE finance sources. The per-pupil spending side
(TGES actuals) is available for `2001`-`2024`; the state-aid revenue
side is available for `2019` onward. A given year emits whichever
metrics its sources publish - recent years (2025+) carry `revenue_state`
only, because that year's spending actuals are not yet published.

## Usage

``` r
get_available_finance_years()
```

## Value

integer vector of available `end_year`s
