# Identify Focus Schools

Identifies schools that need support based on ESSA accountability
status. Filters for schools identified as Comprehensive Support,
Targeted Support, or other improvement categories, and categorizes by
support level.

## Usage

``` r
identify_focus_schools(df, end_year = NULL)
```

## Arguments

- df:

  A data frame from
  [`fetch_essa_status`](https://almartin82.github.io/njschooldata/reference/fetch_essa_status.md)
  containing ESSA accountability status information

- end_year:

  Optional school year to filter results (e.g., 2024)

## Value

Data frame with focus schools including:

- All original columns from input data

- focus_level - Categorized support level:

  - "Comprehensive Support and Improvement" - Lowest performing 5

  - "Targeted Support and Improvement" - Underperforming subgroups

  - "Other Support" - Other identification categories

Schools are sorted by focus level (Comprehensive first) and then
alphabetically by district and school name. Schools without support
identification are excluded.

## Examples

``` r
if (FALSE) { # \dontrun{
# Get ESSA status data
essa <- fetch_essa_status(2024)

# Identify focus schools
focus <- identify_focus_schools(essa)

# View comprehensive support schools
focus %>%
  dplyr::filter(focus_level == "Comprehensive Support and Improvement") %>%
  dplyr::select(district_name, school_name, category_of_identification)

# Focus on specific year
focus_2023 <- identify_focus_schools(essa, end_year = 2023)
} # }
```
