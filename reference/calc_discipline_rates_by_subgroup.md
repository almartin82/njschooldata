# Calculate Discipline Rates by Subgroup

Calculates discipline rates by subgroup for disproportionality analysis.
Computes rates per specified base (default 1000 students) and calculates
risk ratios compared to total population.

## Usage

``` r
calc_discipline_rates_by_subgroup(df, rate_per = 1000)
```

## Arguments

- df:

  A data frame from
  [`fetch_disciplinary_removals`](https://almartin82.github.io/njschooldata/reference/fetch_disciplinary_removals.md),
  [`fetch_violence_vandalism_hib`](https://almartin82.github.io/njschooldata/reference/fetch_violence_vandalism_hib.md),
  or similar discipline data. Must contain subgroup column and a
  count/number column.

- rate_per:

  Base for rate calculation (default: 1000). For example, rate_per =
  1000 calculates incidents per 1000 students.

## Value

Data frame with discipline rates including:

- All original columns from input data

- discipline_rate - Incidents per rate_per students

- percent_by_subgroup - Percentage of total incidents by subgroup

- risk_ratio - Ratio of subgroup rate to total population rate (values
  \> 1 indicate higher risk than total population)

## Examples

``` r
if (FALSE) { # \dontrun{
# Get disciplinary removals data
discipline <- fetch_disciplinary_removals(2024)

# Calculate rates per 1000 students
rates <- calc_discipline_rates_by_subgroup(discipline, rate_per = 1000)

# View disproportionality for racial subgroups
rates %>%
  dplyr::filter(subgroup %in% c("black", "hispanic", "white")) %>%
  dplyr::select(school_name, subgroup, discipline_rate, risk_ratio)
} # }
```
