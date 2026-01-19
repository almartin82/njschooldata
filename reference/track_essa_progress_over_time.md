# Track ESSA Progress Over Time

Tracks ESSA accountability status changes across multiple years,
identifying improvement trajectories, calculating transition
probabilities, and summarizing patterns in school accountability status.

## Usage

``` r
track_essa_progress_over_time(df_list, school_id = NULL)
```

## Arguments

- df_list:

  A named list of data frames from different years. Each element should
  be named by its end_year (e.g., list("2020" = df_2020, "2024" =
  df_2024)). Data frames should be from
  [`fetch_essa_status`](https://almartin82.github.io/njschooldata/reference/fetch_essa_status.md).

- school_id:

  Optional school code to track a specific school (e.g., "010")

## Value

List with two elements:

- `longitudinal` - Data frame with one row per school-year combination:

  - end_year - School year

  - county_id, district_id, school_id - Location identifiers

  - school_name - School name

  - category_of_identification - ESSA status category

  - focus_level - Categorized support level
    (Comprehensive/Targeted/Other/None)

  - status_change - Change from previous year: "Improvement", "Decline",
    "Stable", "First Year", or "Insufficient Data"

- `transitions` - Data frame with transition summary statistics:

  - from_status - Status in previous year

  - to_status - Status in current year

  - n_schools - Number of schools with this transition

  - pct_schools - Percentage of all transitions

- `summary` - List with summary statistics:

  - n_schools_tracked - Total unique schools tracked

  - n_years - Number of years in data

  - n_improvements - Number of schools showing improvement

  - n_declines - Number of schools showing decline

## Examples

``` r
if (FALSE) { # \dontrun{
# Fetch data for multiple years
essa_2020 <- fetch_essa_status(2020)
essa_2022 <- fetch_essa_status(2022)
essa_2024 <- fetch_essa_status(2024)

# Combine into named list
df_list <- list(
  "2020" = essa_2020,
  "2022" = essa_2022,
  "2024" = essa_2024
)

# Track progress over time
progress <- track_essa_progress_over_time(df_list)

# View longitudinal data
head(progress$longitudinal)

# View transition patterns
progress$transitions

# View summary
progress$summary

# Track specific school
single_school <- track_essa_progress_over_time(df_list, school_id = "010")
} # }
```
