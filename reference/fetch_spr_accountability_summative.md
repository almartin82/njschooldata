# Fetch ESSA Summative Accountability Scores

Downloads the `AccountabilitySummative` sheet from the redesigned
2024-25 School Performance Reports. This is the school-level ESSA
summative accountability record: for each indicator (ELA/Math
proficiency, ELA/Math growth, 4/5/6-year graduation, progress toward
English language proficiency, chronic absenteeism, high-school
persistence) it reports the actual performance, the weighted indicator
score, and the indicator's weight, and rolls them up into a
`summative_score` and `summative_rating`.

## Usage

``` r
fetch_spr_accountability_summative(end_year)
```

## Arguments

- end_year:

  A school year. Only `2025` (SY2024-25) and later are supported.

## Value

Data frame with entity identifiers, school_year, subgroup, title_i,
school_configuration, the per-indicator `*_actual_performance`,
`*_indicator_score`, and `*_weight` columns, `summative_score`,
`summative_rating`, and the aggregation flags.

## Details

This sheet exists only in the School database, so this function always
reads school-level data (there is no `level` argument). Performance,
score, weight, and summative columns are returned numeric (percent signs
stripped, `"n/a"`/suppressed cells set to `NA`); `title_i` and
`school_configuration` are kept as labels. `subgroup` is standardized
via the SPR subgroup cleaner.

**Supported years:** only `end_year >= 2025`.

## Examples

``` r
if (FALSE) { # \dontrun{
# School-level summative scores
summ <- fetch_spr_accountability_summative(2025)

# Lowest summative scores among schoolwide (total population) rows
library(dplyr)
fetch_spr_accountability_summative(2025) %>%
  filter(subgroup == "total population", !is.na(summative_score)) %>%
  slice_min(summative_score, n = 10) %>%
  select(district_name, school_name, summative_score, summative_rating)

# ELA vs Math proficiency contribution to the score
fetch_spr_accountability_summative(2025) %>%
  filter(subgroup == "total population") %>%
  select(school_name, ela_proficiency_indicator_score,
         math_proficiency_indicator_score)
} # }
```
