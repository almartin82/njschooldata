# Analyze Staff Retention Patterns

Analyzes staff retention patterns across multiple years and demographic
subgroups. Calculates retention rates, turnover rates, and stability
indices with trend detection.

## Usage

``` r
analyze_retention_patterns(
  df_list,
  by_subgroup = TRUE,
  rate_scale = c("percent", "fraction")
)
```

## Arguments

- df_list:

  A named list of data frames from different years. Each element should
  be named by its end_year (e.g., list("2022" = df_2022, "2024" =
  df_2024)). Data frames should contain staff retention data with
  columns for year, location, and retention/turnover metrics.

- by_subgroup:

  Logical; if TRUE (default), analyze retention patterns by demographic
  subgroups. If FALSE, aggregate across all staff.

- rate_scale:

  Units of the supplied retention and turnover columns: `"percent"`
  (default, 0-100) or `"fraction"` (0-1). Callers must establish units
  from their source; unknown units are rejected.

## Value

Data frame with:

- year - Year identifier

- location_id - Combined location identifier

- subgroup - Demographic subgroup (if by_subgroup = TRUE)

- retention_rate - Percentage of staff who returned from previous year

- turnover_rate - Percentage of new staff in current year

- stability_index - Composite score combining retention and turnover
  (0-100)

- trend - Trend classification: "improving", "stable", "declining", or
  "insufficient_data"

## Details

This analysis accepts caller-supplied data, so no publisher or vintage
can establish its units. The default is percentage points, as documented
for NJDOE SPR retention_pct columns. Fractional inputs require explicit
opt-in. Values outside the declared scale become NA; magnitude never
selects units.

The stability index is calculated as: \$\$stability = (retention_rate +
(100 - turnover_rate)) / 2\$\$

Higher values indicate greater staff stability (retained staff + low
turnover).

Trend classification uses linear regression on multi-year stability
scores:

- improving - Positive slope (stability increasing over time)

- stable - Near-zero slope or insufficient data

- declining - Negative slope (stability decreasing over time)

## Examples

``` r
# NOTE: This function requires staff retention data with appropriate columns.
# Example assumes you have retention data frames with the required structure.
if (FALSE) { # \dontrun{
# Create example data frames with required columns
retain_2022 <- data.frame(
  year = 2022,
  location_id = c("school1", "school2"),
  subgroup = c("total", "total"),
  retention_rate = c(85.5, 90.2),
  turnover_rate = c(14.5, 9.8)
)

# Combine into named list
df_list <- list(
  "2022" = retain_2022
)

# Analyze retention patterns
patterns <- analyze_retention_patterns(df_list, by_subgroup = TRUE)
} # }
```
