# Fetch Student-to-Device Ratios

Downloads the `DeviceRatios` sheet from the NJ DOE School Performance
Reports. Each row reports, for one school, the
student-to-computing-device ratio - a measure of digital-access equity
that became a board-level concern during and after the COVID-19
remote-learning period. This is school-level data with no district or
state aggregate, so the function is school-level only.

## Usage

``` r
fetch_device_ratios(end_year, level = "school")
```

## Arguments

- end_year:

  A school year. Supported: 2018, 2019, 2021, 2022, 2023, 2024, 2025.
  SY2016-17 (2017) and SY2019-20 (2020) error (sheet absent).

- level:

  Only `"school"` is supported (the sheet has no district/state
  analogue). Other values error.

## Value

Data frame with entity identifiers, `student_device_ratio` (the
published string), `students_per_device` (derived numeric), the
2025-only `school_year` column when present, and the standard
aggregation flags.

## Details

The sheet is present in the School workbook for **end_year 2018-2025
except SY2019-20 (2020)**; it is also absent from SY2016-17 (2017).
Those two years error. The published value is a ratio string `"2.6:1"` /
`"1:1"` (2018-2024) or a bare number `"1"` / `"1.1"` (2025+, column
renamed `students_per_device`). This function preserves the published
string as `student_device_ratio` and derives a numeric
`students_per_device` (students per one device) via a deterministic
parse. Non-numeric values (`"No devices reported"`, `"n/a"`) yield `NA`.
A value of 1 means one device per student (1:1); values above 1 mean
devices are shared.

## Examples

``` r
if (FALSE) { # \dontrun{
# Student-to-device ratios for every school (latest year)
dr <- fetch_device_ratios(2024)

# Schools furthest from 1:1
library(dplyr)
fetch_device_ratios(2024) %>%
  filter(is_school) %>%
  slice_max(students_per_device, n = 10) %>%
  select(district_name, school_name, student_device_ratio)

# Share of schools at 1:1 over time
purrr::map_dfr(c(2019, 2021, 2023, 2024), function(yr) {
  fetch_device_ratios(yr) %>%
    filter(is_school, !is.na(students_per_device)) %>%
    summarise(end_year = yr, pct_1to1 = mean(students_per_device <= 1))
})
} # }
```
