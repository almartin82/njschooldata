# Fetch Student Growth Percentile (SGP) Data

Downloads NJ Student Growth Percentile (median SGP / mSGP) data from the
redesigned 2024-25 School Performance Reports databases. SGP measures
how much students grew academically relative to peers with similar score
histories; the median SGP (mSGP) summarizes a school's or district's
growth.

## Usage

``` r
fetch_sgp(end_year, level = "school", type = "trends")
```

## Arguments

- end_year:

  A school year. Currently only `2025` (SY2024-25) is supported.

- level:

  One of `"school"` or `"district"`. `"school"` returns school-level
  data; `"district"` returns district and state-level data.

- type:

  One of `"trends"` (default), `"by_grade"`, or
  `"by_performance_level"`. Selects which SGP sheet to fetch.

## Value

Data frame with median SGP data. Columns vary by `type`:

- **All types**: end_year, county_id, county_name, district_id,
  district_name, school_id, school_name, school_year, plus aggregation
  flags (is_state, is_county, is_district, is_school, is_charter, ...).

- `type = "trends"`: `subgroup`, and for ELA and Math the entity median
  (`ela_median_sgp`, `math_median_sgp`) with its `*_category` growth
  label, plus the statewide comparison (`ela_median_sgp_state`,
  `math_median_sgp_state`) and its category. At `level = "school"` the
  entity median is the school value; at `level = "district"` it is the
  district value.

- `type = "by_grade"`: `subject`, `grade`, `median_sgp`,
  `median_sgp_category`.

- `type = "by_performance_level"`: `subject`, `njsla_performance_level`,
  `median_sgp`, `median_sgp_category`.

## Details

The `type` argument selects one of three SPR sheets:

- `"trends"` (default) – `StudentGrowthTrends`: median SGP broken out by
  student group, for ELA and Math, as a multi-year trend (SY2022-23
  through the requested year). One row per entity per student group,
  filtered to the requested academic year.

- `"by_grade"` – `StudentGrowthbyGrade`: median SGP by subject
  (ELA/Math) and grade (Grades 4-8). 2024-25 only.

- `"by_performance_level"` – `StudentGrowthByPerformLevel`: median SGP
  by subject and prior-year NJSLA performance level (Levels 1-5).
  2024-25 only.

Median SGP value columns are returned numeric; suppressed cells (“Fewer
than 10 testers”) become `NA`, with the suppression reason preserved in
the companion `*_category` column.

**Supported years:** only `end_year = 2025` (SY2024-25) is available.
Pre-2025 SPR databases store SGP in differently-shaped,
differently-named sheets; supporting them is a documented follow-up.

## Examples

``` r
if (FALSE) { # \dontrun{
# School-level median SGP by student group (default type = "trends")
sgp <- fetch_sgp(2025)

# District/state-level growth trends
sgp_dist <- fetch_sgp(2025, level = "district")

# Median SGP by grade
sgp_grade <- fetch_sgp(2025, type = "by_grade")

# Median SGP by NJSLA performance level
sgp_perf <- fetch_sgp(2025, type = "by_performance_level")

# Compare a district's ELA growth to the statewide median
library(dplyr)
fetch_sgp(2025, level = "district") %>%
  filter(is_district, subgroup == "total population") %>%
  select(district_name, ela_median_sgp, ela_median_sgp_state)
} # }
```
