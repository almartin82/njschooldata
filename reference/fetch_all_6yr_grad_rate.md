# Fetch all 6-Year Graduation Rate data

Convenience function to download and combine all available 6-year
graduation rate data into a single data frame.

## Usage

``` r
fetch_all_6yr_grad_rate(level = "school")
```

## Arguments

- level:

  One of "school", "district", or "both". "both" combines school and
  district data. Default is "school".

## Value

A data frame with all 6-year graduation rate results (2021-2024)

## Examples

``` r
if (FALSE) { # \dontrun{
# Get all school-level 6-year graduation data
all_grad6 <- fetch_all_6yr_grad_rate()

# Get both school and district data
all_grad6_both <- fetch_all_6yr_grad_rate(level = "both")
} # }
```
