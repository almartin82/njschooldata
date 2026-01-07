# Compare Discipline Across Years

Compares discipline metrics across multiple years, calculating
year-over-year changes and identifying long-term trends.

## Usage

``` r
compare_discipline_across_years(df_list, metrics = NULL)
```

## Arguments

- df_list:

  A named list of data frames from different years. Each element should
  be named by its end_year (e.g., list("2022" = df_2022, "2024" =
  df_2024)). Data frames should be from
  [`fetch_disciplinary_removals`](https://almartin82.github.io/njschooldata/reference/fetch_disciplinary_removals.md),
  [`fetch_violence_vandalism_hib`](https://almartin82.github.io/njschooldata/reference/fetch_violence_vandalism_hib.md),
  or similar.

- metrics:

  Character vector of metrics to compare. If NULL (default), attempts to
  auto-detect numeric metric columns. Metrics should match column names
  in the data (e.g., "discipline_rate" if calculated).

## Value

Data frame with year-over-year comparisons including:

- year - Year identifier

- location_id - Combined location identifier

- metric_name - Name of the metric

- metric_value - Value of the metric in this year

- year_over_year_change - Change from previous year

- year_over_year_pct_change - Percentage change from previous year

- multi_year_trend - Trend classification: "increasing", "decreasing",
  "stable", or "insufficient_data"

## Examples

``` r
if (FALSE) { # \dontrun{
# Fetch data for multiple years
disc_2022 <- fetch_disciplinary_removals(2022)
disc_2023 <- fetch_disciplinary_removals(2023)
disc_2024 <- fetch_disciplinary_removals(2024)

# Combine into named list
df_list <- list(
  "2022" = disc_2022,
  "2023" = disc_2023,
  "2024" = disc_2024
)

# Compare trends
trends <- compare_discipline_across_years(df_list)

# View schools with increasing discipline rates
trends %>%
  dplyr::filter(metric_name == "discipline_rate", multi_year_trend == "increasing")
} # }
```
