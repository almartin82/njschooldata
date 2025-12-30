# Calculate equity access rate

Calculates the share of students (overall or by subgroup) attending
schools that meet or exceed a performance threshold. This replicates the
MarGrady metric: "the share of Black students in Newark attending a
school that beat the state proficiency average."

## Usage

``` r
calculate_access_rate(
  df_enrollment,
  df_performance,
  performance_metric = "proficient_above",
  threshold_type = c("state_avg", "absolute", "percentile"),
  threshold_value = NULL,
  enrollment_col = "n_students",
  subgroup = NULL,
  join_cols = c("end_year", "county_id", "district_id", "school_id")
)
```

## Arguments

- df_enrollment:

  School-level enrollment data with demographic counts

- df_performance:

  School-level performance data

- performance_metric:

  Character. Column in df_performance to use as the performance measure.
  Default "proficient_above".

- threshold_type:

  Character. How to define "high-performing":

  - "state_avg": Above the state average for that year/grade/subject

  - "absolute": Above a fixed numeric threshold

  - "percentile": Above a percentile threshold within peers

- threshold_value:

  Numeric. The threshold value. Required for "absolute" and "percentile"
  types. For "state_avg", this is ignored.

- enrollment_col:

  Character. Column in df_enrollment containing student counts. Default
  "n_students".

- subgroup:

  Character. Which subgroup to calculate access for. If NULL, calculates
  for total enrollment. Default NULL.

- join_cols:

  Character vector. Columns to join enrollment and performance data on.
  Default c("end_year", "county_id", "district_id", "school_id").

## Value

Dataframe with columns:

- Year and entity identifiers

- `n_students_total`: Total students in subgroup

- `n_students_above`: Students in above-threshold schools

- `pct_access`: Percent with access to high-performing schools
