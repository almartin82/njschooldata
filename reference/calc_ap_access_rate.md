# Calculate AP/IB Access Rate

Calculates the percentage of students with access to Advanced Placement
(AP) or International Baccalaureate (IB) courses. Access is defined as
offering at least one AP or IB course at the school.

## Usage

``` r
calc_ap_access_rate(df, subgroup = "total population")
```

## Arguments

- df:

  A data frame from
  [`fetch_math_course_enrollment`](https://almartin82.github.io/njschooldata/reference/fetch_math_course_enrollment.md),
  [`fetch_science_course_enrollment`](https://almartin82.github.io/njschooldata/reference/fetch_science_course_enrollment.md),
  or other course enrollment functions. Should contain course type and
  student enrollment columns.

- subgroup:

  Subgroup to analyze (default: "total population"). Specify a subgroup
  name (e.g., "black", "hispanic", "economically disadvantaged") to
  calculate access rates for that demographic group.

## Value

Data frame with:

- All original columns from input data (aggregated to one row per
  school)

- ap_access_rate - Percentage of students with AP course access

- has_ap - Logical indicating school offers AP courses

- has_ib - Logical indicating school offers IB courses

- has_both - Logical indicating school offers both AP and IB

- vs_state_avg - Difference from state average (if state data available)

## Details

AP/IB access is calculated at the school level (all students in the
school have access if the school offers any AP/IB courses). The access
rate represents the proportion of students in schools that offer AP/IB
courses.

## Examples

``` r
if (FALSE) { # \dontrun{
# Get science course enrollment (includes AP sciences)
science <- fetch_science_course_enrollment(2024)

# Calculate AP access rate for total population
ap_access <- calc_ap_access_rate(science, subgroup = "total population")

# Calculate AP access rate for economically disadvantaged students
ap_access_ed <- calc_ap_access_rate(science,
                                    subgroup = "economically disadvantaged")

# View schools with highest AP access
ap_access %>%
  dplyr::filter(is_school == TRUE) %>%
  dplyr::arrange(dplyr::desc(ap_access_rate)) %>%
  dplyr::select(school_name, has_ap, has_ib, ap_access_rate)
} # }
```
