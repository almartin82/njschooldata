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

  A school year. Supported years depend on `type`; see **Supported
  years** above.

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
  district value. Pre-2025 years additionally carry
  `ela_met_target`/`math_met_target` and have `NA` in the `*_category`
  columns. The 2025 sheet is a multi-year trend filtered to the
  requested year and adds a `school_year` column; legacy sheets are
  single-year.

- `type = "by_grade"`: `subject`, `grade`, `median_sgp`,
  `median_sgp_category`.

- `type = "by_performance_level"`: `subject`, `njsla_performance_level`,
  `median_sgp`, `median_sgp_category`.

## Details

The `type` argument selects one of three SPR sheets:

- `"trends"` (default) – `StudentGrowthTrends` (legacy `StudentGrowth`):
  median SGP broken out by student group, for ELA and Math. One row per
  entity per student group. Pre-2025 years carry the legacy `MetTarget`
  flag in `ela_met_target`/`math_met_target` and `NA` `*_category` (the
  growth-category labels are new in 2025).

- `"by_grade"` – `StudentGrowthbyGrade` (legacy `StudentGrowthByGrade`):
  median SGP by subject (ELA/Math) and grade (Grades 4-8). The growth
  category is reported only from 2023; earlier years return `NA` for
  `median_sgp_category`.

- `"by_performance_level"` – `StudentGrowthByPerformLevel`: median SGP
  by subject and prior-year NJSLA performance level (Levels 1-5). The
  2017-2019 sheet reports a different statistic (a growth-band
  percentage distribution) and is not supported.

Median SGP value columns are returned numeric; suppressed cells (“Fewer
than 10 testers”) become `NA`, with the suppression reason preserved in
the companion `*_category` column.

**Supported years (vary by type):** `trends`: 2018, 2019, 2023, 2024,
2025. `by_grade`: 2018, 2019, 2023, 2024, 2025. `by_performance_level`:
2023, 2024, 2025. SY2019-20 through SY2021-22 (end_year 2020-2022) are
unavailable for every type – NJ produced no Student Growth Percentiles
during the COVID statewide-assessment pause.

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
