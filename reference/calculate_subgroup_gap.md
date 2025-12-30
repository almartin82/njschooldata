# Calculate achievement gap between two subgroups

Calculates the difference in a metric between two subgroups within each
entity (district/school) and year. The gap is calculated as subgroup_a -
subgroup_b, so positive values mean subgroup_a outperforms.

## Usage

``` r
calculate_subgroup_gap(
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

  Dataframe with a 'subgroup' column and the metric of interest

- metric_col:

  Character. The column containing the metric to compare.

- subgroup_a:

  Character. The reference subgroup (typically majority/advantaged).

- subgroup_b:

  Character. The comparison subgroup (typically minority/disadvantaged).

- year_col:

  Character. Year column name. Default "end_year".

- entity_cols:

  Character vector. Columns identifying the entity (e.g.,
  c("district_id") or c("county_id", "district_id", "school_id")).

## Value

Dataframe with one row per entity-year containing:

- Original entity and year columns

- `{metric}_a`: Value for subgroup_a

- `{metric}_b`: Value for subgroup_b

- `{metric}_gap`: Absolute gap (a - b)

- `{metric}_gap_pct`: Relative gap as percent of subgroup_a

## Examples

``` r
if (FALSE) { # \dontrun{
# Calculate Black-White graduation rate gap
grate %>%
  filter(subgroup %in% c("white", "black")) %>%
  calculate_subgroup_gap(
    metric_col = "grad_rate",
    subgroup_a = "white",
    subgroup_b = "black"
  )
} # }
```
