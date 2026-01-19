# Analyze Course Access Equity

Analyzes equity in course access across demographic subgroups over
multiple years. Calculates access gaps, disparity indices, and trends
over time to identify schools with large inequities in course offerings.

## Usage

``` r
analyze_course_access_equity(df_list, subgroup_cols = NULL)
```

## Arguments

- df_list:

  A named list of data frames from different years. Each element should
  be named by its end_year (e.g., list("2022" = df_2022, "2024" =
  df_2024)). Data frames should be from course enrollment fetch
  functions.

- subgroup_cols:

  Character vector specifying which subgroup dimensions to analyze. If
  NULL (default), attempts to auto-detect subgroup columns. Common
  options: "subgroup" for demographic subgroups.

## Value

Data frame with:

- year - Year identifier

- location_id - Combined location identifier

- subgroup - Demographic subgroup (e.g., "black", "hispanic", "white")

- access_rate - Course participation rate for this subgroup

- total_population_rate - Rate for total population

- access_gap_percentage - Difference from total population (percentage
  points)

- disparity_index - Ratio of subgroup rate to total population rate (1.0
  = parity, \< 1.0 = under-representation, \> 1.0 = over-representation)

- trend - Trend classification: "improving", "widening", "stable", or
  "insufficient_data"

- flag_large_gap - Logical flag if gap \> 20 percentage points

## Details

Equity analysis calculates:

- Access Rate: Percentage of students in subgroup enrolled in courses

- Access Gap: Difference between subgroup rate and total population rate

- Disparity Index: Ratio of subgroup rate to total population rate (1.0
  indicates equal access)

- Trend: Direction of change over time based on linear regression

Schools with access gaps \> 20 percentage points are flagged for
attention.

## Examples

``` r
if (FALSE) { # \dontrun{
# Fetch data for multiple years
math_2022 <- fetch_math_course_enrollment(2022)
math_2023 <- fetch_math_course_enrollment(2023)
math_2024 <- fetch_math_course_enrollment(2024)

# Combine into named list
df_list <- list(
  "2022" = math_2022,
  "2023" = math_2023,
  "2024" = math_2024
)

# Analyze equity across all subgroups
equity <- analyze_course_access_equity(df_list)

# View schools with large access gaps for Hispanic students
equity %>%
  dplyr::filter(subgroup == "hispanic", flag_large_gap == TRUE) %>%
  dplyr::select(year, school_name, subgroup, access_gap_percentage, disparity_index)
} # }
```
