# Calculate STEM Participation Rate

Calculates the percentage of students enrolled in STEM courses (Science,
Technology, Engineering, and Mathematics). Optionally includes or
excludes Computer Science from the calculation.

## Usage

``` r
calc_stem_participation_rate(
  math_df,
  science_df,
  cs_df = NULL,
  include_cs = TRUE
)
```

## Arguments

- math_df:

  A data frame from
  [`fetch_math_course_enrollment`](https://almartin82.github.io/njschooldata/reference/fetch_math_course_enrollment.md)
  with math course enrollment data.

- science_df:

  A data frame from
  [`fetch_science_course_enrollment`](https://almartin82.github.io/njschooldata/reference/fetch_science_course_enrollment.md)
  with science course enrollment data.

- cs_df:

  Optional data frame from
  [`fetch_cs_enrollment`](https://almartin82.github.io/njschooldata/reference/fetch_cs_enrollment.md)
  with computer science enrollment data. Only used if include_cs = TRUE.

- include_cs:

  Logical; if TRUE (default), includes computer science courses in STEM
  calculation. If FALSE, only includes math and science.

## Value

Data frame with:

- school_id - School identifier

- stem_participation_rate - Percentage of students enrolled in STEM
  courses

- category - Participation category: "low" (\<30 or "high" (\>60

- vs_state_avg - Difference from state average (if state data available)

- n_stem_students - Total number of students in STEM courses

- n_total_students - Total student enrollment

## Details

STEM participation rate is calculated as the percentage of students
enrolled in at least one STEM course. Students may be counted in
multiple subject areas (e.g., a student taking both math and science),
so this represents unique students if the data allows, otherwise
represents enrollment counts.

Category thresholds:

- Low: \< 30

- Medium: 30-60

- High: \> 60

## Examples

``` r
if (FALSE) { # \dontrun{
# Get math and science enrollment
math <- fetch_math_course_enrollment(2024)
science <- fetch_science_course_enrollment(2024)
cs <- fetch_cs_enrollment(2024)

# Calculate STEM participation including CS
stem_with_cs <- calc_stem_participation_rate(math, science, cs, include_cs = TRUE)

# Calculate STEM participation excluding CS
stem_no_cs <- calc_stem_participation_rate(math, science, include_cs = FALSE)

# View schools with highest STEM participation
stem_with_cs %>%
  dplyr::arrange(dplyr::desc(stem_participation_rate)) %>%
  dplyr::select(school_name, stem_participation_rate, category, vs_state_avg)
} # }
```
