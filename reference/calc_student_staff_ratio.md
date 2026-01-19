# Calculate and Analyze Student-Staff Ratios

Calculates student-to-staff ratios with categorization and state
comparisons. Analyzes ratios for overall staff, teachers,
administrators, and support staff.

## Usage

``` r
calc_student_staff_ratio(df, ratio_type = "overall")
```

## Arguments

- df:

  A data frame from
  [`fetch_staff_ratios`](https://almartin82.github.io/njschooldata/reference/fetch_staff_ratios.md)
  or similar. Should contain staff count and student enrollment columns.

- ratio_type:

  One of "overall" (default), "teachers", "administrators", or
  "support". Specifies which staff category to analyze.

## Value

Data frame with original columns plus:

- ratio_type - The type of ratio calculated

- student_staff_ratio - Students per staff member (higher = more
  students per staff)

- ratio_category - "low" (\< 10), "medium" (10-20), or "high" (\> 20)
  based on benchmarks

- percent_change_vs_state - Percent difference from state average (if
  state data available)

## Examples

``` r
if (FALSE) { # \dontrun{
# Get staff ratio data
ratios <- fetch_staff_ratios(2024)

# Calculate overall student-staff ratios
overall_ratios <- calc_student_staff_ratio(ratios, ratio_type = "overall")

# Calculate teacher-specific ratios
teacher_ratios <- calc_student_staff_ratio(ratios, ratio_type = "teachers")

# View schools with highest student-teacher ratios
teacher_ratios %>%
  dplyr::arrange(dplyr::desc(student_staff_ratio)) %>%
  dplyr::select(school_name, student_staff_ratio, ratio_category)
} # }
```
