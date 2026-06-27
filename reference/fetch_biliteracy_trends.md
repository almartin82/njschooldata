# Fetch Seal-of-Biliteracy Multi-Year Trend (2024-25)

Downloads the `SealofBiliteracy_Trends` sheet from the redesigned
2024-25 NJ DOE School Performance Reports. Unlike most SPR sheets this
one is **multi-year within the single 2025 workbook**: each entity has
one row per `school_year` (`"2020-21"` through `"2024-25"`) carrying the
total seals earned that year.

## Usage

``` r
fetch_biliteracy_trends(end_year, level = "school")
```

## Arguments

- end_year:

  Must be 2025 (the only year the sheet exists).

- level:

  One of `"school"` or `"district"`. `"district"` returns district and
  state rows.

## Value

Data frame with entity identifiers, `school_year`, `total_seals_earned`
(numeric), and the standard aggregation flags. One row per entity per
`school_year`.

## Details

The sheet exists **only in end_year 2025** (both school and district
workbooks); other years error. All five `school_year` rows are returned
for each entity - the function does not filter to a single year.

`total_seals_earned` is coerced to numeric. A real published `0` (no
seals that year) is preserved as `0`; the suppression string
`"Fewer than 5 seals"` becomes `NA`, never a guessed number.

## Examples

``` r
if (FALSE) { # \dontrun{
# Five-year seal trend for every school (2024-25 workbook)
bt <- fetch_biliteracy_trends(2025)

# Statewide seal trend
library(dplyr)
fetch_biliteracy_trends(2025, level = "district") %>%
  filter(is_state) %>%
  select(school_year, total_seals_earned)

# One school's five-year trajectory
fetch_biliteracy_trends(2025) %>%
  filter(district_id == "3570", school_id == "010") %>%
  select(school_name, school_year, total_seals_earned)
} # }
```
