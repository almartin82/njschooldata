# Fetch Postsecondary Enrollment Rates

Downloads postsecondary enrollment rate data from the NJ DOE website.
Data is sourced from the National Student Clearinghouse and shows the
percentage of high school graduates enrolling in postsecondary
institutions.

## Usage

``` r
fetch_postsecondary()
```

## Value

A data frame with postsecondary enrollment rates in long format,
containing columns for county, district, school identifiers,
cohort_year, measurement_type (fall or 16_month), lower_bound, and
upper_bound.

## Details

The data includes both school-level and district-level rates. Rates are
reported as ranges because a small percentage of graduates cannot be
matched to the National Student Clearinghouse database.

Two measurement types are available:

- `fall`: Enrollment in fall immediately after graduation

- `16_month`: Enrollment within 16 months of graduation

The `lower_bound` represents confirmed enrollments only (conservative).
The `upper_bound` assumes non-matched graduates also enrolled
(optimistic).

## Examples

``` r
if (FALSE) { # \dontrun{
# Get all postsecondary enrollment data
postsec <- fetch_postsecondary()

# Filter for 16-month rates only
postsec_16mo <- postsec[postsec$measurement_type == "16_month", ]

# Filter for district-level data only
district_rates <- postsec[postsec$is_district, ]
} # }
```
