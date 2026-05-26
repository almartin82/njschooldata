# ESSER-cliff exposure: did recurring spending ride one-time federal money?

The most current fiscal-analyst question in the country, computed off
the VITSTAT federal-revenue share. For each district it compares a
pre-pandemic baseline federal share to the peak federal share during the
ESSER window, and flags districts whose per-pupil spending grew while
they were leaning on that one-time federal bump – the structural set-up
for a funding cliff when the federal money expires.

## Usage

``` r
tges_federal_exposure(
  tges,
  baseline_years = NULL,
  esser_years = 2021:2024,
  bump_threshold = 0.03,
  growth_threshold = 0
)
```

## Arguments

- tges:

  Output of
  [`fetch_many_tges()`](https://almartin82.github.io/njschooldata/reference/fetch_many_tges.md)
  (multi-year) or
  [`fetch_tges()`](https://almartin82.github.io/njschooldata/reference/fetch_tges.md).

- baseline_years:

  Numeric vector of pre-pandemic years. Default: the present years
  `<= 2020`.

- esser_years:

  Numeric vector of ESSER-window years. Default `2021:2024`.

- bump_threshold:

  Numeric. Minimum federal-share increase (0-1) to flag. Default 0.03 (3
  share points).

- growth_threshold:

  Numeric. Minimum per-pupil spending growth to flag. Default 0 (any
  growth).

## Value

One row per district with the baseline/peak/bump/growth columns and the
`cliff_exposure` flag.

## Details

Requires a multi-year revenue series (pass
[`fetch_many_tges()`](https://almartin82.github.io/njschooldata/reference/fetch_many_tges.md)
output spanning the baseline and ESSER years). For each district:

- `baseline_federal_share`: mean federal share over `baseline_years`.

- `peak_federal_share`: max federal share over `esser_years`.

- `federal_bump`: `peak - baseline` (in share points, 0-1).

- `baseline_pp` / `peak_pp`: mean baseline and max ESSER-window total
  spending per pupil.

- `pp_growth`: `peak_pp / baseline_pp - 1`.

- `cliff_exposure`: `TRUE` when `federal_bump >= bump_threshold` AND
  `pp_growth > growth_threshold` – a district that grew operating spend
  during a federal-revenue surge.

This is a screen, not a finding: it cannot see whether a district
reserved the federal money for one-time uses. It surfaces who to look
at.

## Examples

``` r
if (FALSE) { # \dontrun{
library(dplyr)

tg <- fetch_many_tges(2018:2025)

tges_federal_exposure(tg) %>%
  filter(cliff_exposure) %>%
  arrange(desc(federal_bump)) %>%
  select(district_name, baseline_federal_share, peak_federal_share,
         federal_bump, pp_growth)
} # }
```
