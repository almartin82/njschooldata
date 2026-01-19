# Calculate Staff Diversity Metrics

Calculates diversity indices for staff demographics using Simpson's
Diversity Index. Computes racial and gender diversity scores with
percentile rankings.

## Usage

``` r
calc_staff_diversity_metrics(df, metrics = c("racial"))
```

## Arguments

- df:

  A data frame from
  [`fetch_staff_demographics`](https://almartin82.github.io/njschooldata/reference/fetch_staff_demographics.md).
  Should contain staff demographic breakdowns with counts.

- metrics:

  Character vector specifying which diversity metrics to calculate.
  Options: "racial" (default), "gender", or both c("racial", "gender").

## Value

Data frame with:

- location_id - Combined location identifier

- diversity_index - Overall Simpson's Diversity Index (0-1 scale, higher
  = more diverse)

- racial_diversity_score - Racial diversity score (0-1 scale)

- gender_diversity_score - Gender diversity score (0-1 scale)

- diversity_percentile_rank - Percentile rank vs all schools (0-100)

- diversity_quintile - Quintile rank (1-5, 5 = most diverse)

## Details

Simpson's Diversity Index is calculated as: \$\$D = 1 - \sum(p_i^2)\$\$

where \\p_i\\ is the proportion of staff in category \\i\\.

Values range from 0 (no diversity - all staff in one category) to 1
(maximum diversity - staff evenly distributed across all categories).

## Examples

``` r
if (FALSE) { # \dontrun{
# Get staff demographics data
demographics <- fetch_staff_demographics(2024)

# Calculate racial diversity
racial_div <- calc_staff_diversity_metrics(demographics, metrics = "racial")

# Calculate both racial and gender diversity
all_div <- calc_staff_diversity_metrics(demographics,
                                         metrics = c("racial", "gender"))

# View most diverse schools
all_div %>%
  dplyr::arrange(dplyr::desc(diversity_index)) %>%
  dplyr::select(school_name, diversity_index, diversity_quintile)
} # }
```
