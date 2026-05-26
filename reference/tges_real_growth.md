# Decompose per-pupil spending growth into real cost vs the enrollment effect

Per-pupil spend mechanically rises when enrollment falls, because fixed
costs spread over fewer students. This function separates that
denominator artifact from real cost growth, so "costs are exploding" can
be checked against "or do we simply have fewer kids." It is the most
important TGES data caution turned into a tool.

## Usage

``` r
tges_real_growth(tges, years = NULL, deflator = NULL)
```

## Arguments

- tges:

  Output of
  [`fetch_tges()`](https://almartin82.github.io/njschooldata/reference/fetch_tges.md)
  or
  [`fetch_many_tges()`](https://almartin82.github.io/njschooldata/reference/fetch_many_tges.md).

- years:

  Optional numeric vector. Keep only these `end_year` values (applied
  after differencing, so lags still use adjacent years).

- deflator:

  Optional data frame with columns `end_year` and `price_index` (a real
  index supplied by the caller). When present, adds `real_total_exp`,
  `real_per_pupil`, and `real_pp_growth`.

## Value

A tibble with entity columns, `end_year`, `total_exp`, `ade`,
`per_pupil`, the growth and decomposition columns, and (if `deflator` is
supplied) the real-terms columns.

## Details

Built from CSG1AA (total expenditures + average daily enrollment +
per-pupil total). Because adjacent guides report overlapping actual
years, the rows are de-duplicated on district-year before differencing.
For each district-year (after the first), using the identity \\\ln(pp) =
\ln(exp) - \ln(ade)\\:

- `total_exp_growth`, `ade_growth`, `per_pupil_growth`: simple
  year-over-year percent changes.

- `real_cost_component`: \\\ln(exp_t / exp\_{t-1})\\, the
  spending-driven part of per-pupil log growth.

- `enrollment_component`: \\-\ln(ade_t / ade\_{t-1})\\, the part driven
  purely by the changing denominator (positive when enrollment falls).

- `enrollment_effect_share`: `enrollment_component` divided by total
  per-pupil log change – the fraction of per-pupil growth that is the
  enrollment artifact rather than real spending.

If a real price index is supplied via `deflator`, the function also
returns inflation-adjusted total expenditure and a `real_pp_growth`.
**No deflator is fabricated**: you must pass a real index (e.g. BLS
CPI); without one, only nominal decomposition is returned.

## Examples

``` r
if (FALSE) { # \dontrun{
library(dplyr)

rg <- tges_real_growth(fetch_many_tges(2018:2024))

# Newark: how much of per-pupil growth is just falling enrollment?
rg %>%
  filter(district_code == "3570") %>%
  select(end_year, per_pupil_growth, real_cost_component,
         enrollment_component, enrollment_effect_share)

# With a real deflator (caller-supplied CPI), get real per-pupil growth
cpi <- data.frame(end_year = 2018:2024,
                  price_index = c(251.1, 255.7, 258.8, 271.0, 292.7, 304.7, 313.7))
tges_real_growth(fetch_many_tges(2018:2024), deflator = cpi) %>%
  filter(district_code == "3570") %>%
  select(end_year, per_pupil_growth, real_pp_growth)
} # }
```
