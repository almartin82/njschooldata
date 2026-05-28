# Fund-balance health: budgeted vs actual and excess surplus

Joins the two TGES governance tables – CSG20 (budgeted general fund
balance vs. actual) and CSG21 (excess unreserved general fund balance) –
into one row per district-year, and adds the two flags a board member
needs before a budget vote: a structural-deficit signal and a
surplus-over-cap signal.

## Usage

``` r
tges_fund_balance_health(tges, years = NULL)
```

## Arguments

- tges:

  Output of
  [`fetch_tges()`](https://almartin82.github.io/njschooldata/reference/fetch_tges.md)
  or
  [`fetch_many_tges()`](https://almartin82.github.io/njschooldata/reference/fetch_many_tges.md).

- years:

  Optional numeric vector. Keep only these `end_year` values.

## Value

A tibble with entity columns, `end_year`, `budgeted_fund_balance`,
`actual_fund_balance`, `fund_balance_variance`, `excess_unreserved`,
`balance_yoy_change`, and the two logical flags.

## Details

Two failure modes, two flags:

- `excess_surplus_flag`: `TRUE` when NJ DOE reports a positive excess
  unreserved balance (`excess_unreserved > 0`). NJ districts may hold
  undesignated general fund surplus only up to a statutory cap (2 the
  general fund budget, or \$250k if greater); CSG21 reports the amount
  above that allowance, so a positive value is the surplus-hoarding
  signal.

- `declining_balance_flag`: `TRUE` when the actual general fund balance
  fell year over year (`balance_yoy_change < 0`). Computed only when
  more than one year is present for a district; reserves drawn down to
  paper over operating gaps are the structural-deficit signal.

`fund_balance_variance` (`actual - budgeted`) is reported for context: a
large negative variance means the district held far less surplus than it
budgeted. These flags are descriptive summaries of NJ DOE's reported
figures, not audit determinations.

CSG20/CSG21 report `end_year - 2` and `end_year - 1` for a guide; pass
[`fetch_many_tges()`](https://almartin82.github.io/njschooldata/reference/fetch_many_tges.md)
output for a longer series.

## Examples

``` r
if (FALSE) { # \dontrun{
library(dplyr)

# Newark fund-balance health over the available window
tges_fund_balance_health(fetch_many_tges(2022:2024)) %>%
  filter(district_id == "3570") %>%
  select(end_year, budgeted_fund_balance, actual_fund_balance,
         excess_unreserved, excess_surplus_flag)

# Districts drawing down reserves in the latest year
tges_fund_balance_health(fetch_tges(2024)) %>%
  filter(declining_balance_flag)
} # }
```
