# Track achievement gap trends over time

Combines gap calculation with trend tracking to show how achievement
gaps have changed over time for specific entities. Answers questions
like "How has Newark's Black-White gap changed from 2015 to 2023?"

## Usage

``` r
gap_trajectory(
  df,
  metric_col,
  subgroup_a,
  subgroup_b,
  year_col = "end_year",
  entity_cols = "district_id"
)
```

## Arguments

- df:

  Dataframe with subgroups and metrics over multiple years

- metric_col:

  Character. The metric to track.

- subgroup_a:

  Character. Reference subgroup.

- subgroup_b:

  Character. Comparison subgroup.

- year_col:

  Character. Year column. Default "end_year".

- entity_cols:

  Character vector. Columns identifying entity to track.

## Value

df with gap values and trend columns:

- `{metric}_gap_yoy_change`: Year-over-year change in gap

- `{metric}_gap_cumulative_change`: Change from baseline year

- `{metric}_gap_baseline`: Gap value in first year

## Examples

``` r
if (FALSE) { # \dontrun{
# Track Newark's Black-White grad rate gap over time
grate %>%
  filter(district_id == "3570") %>%
  gap_trajectory(
    metric_col = "grad_rate",
    subgroup_a = "white",
    subgroup_b = "black"
  )
} # }
```
