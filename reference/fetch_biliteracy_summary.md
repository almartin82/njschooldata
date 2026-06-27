# Fetch Seal-of-Biliteracy Summary (2024-25)

Downloads the `SealofBiliteracy_Summary` sheet from the redesigned
2024-25 NJ DOE School Performance Reports. Each row reports, for one
entity, the total seals earned, the number of distinct languages, the
count and percentage of unique students earning a seal, and the count
and percentage of multilingual learners earning a seal.

## Usage

``` r
fetch_biliteracy_summary(end_year, level = "school")
```

## Arguments

- end_year:

  Must be 2025 (the only year the sheet exists).

- level:

  One of `"school"` or `"district"`. `"district"` returns district and
  state rows.

## Value

Data frame with entity identifiers, `school_year`, the summary metrics
above (numeric), and the standard aggregation flags (`is_state`,
`is_county`, `is_district`, `is_school`, `is_charter`,
`is_charter_sector`, `is_allpublic`).

## Details

This sheet exists **only in end_year 2025** (both school and district
workbooks); 2017-2024 had a single combined `SealofBiliteracy` sheet, so
other years error. For the per-language detail across 2018-2025 use
[`fetch_biliteracy_seal`](https://almartin82.github.io/njschooldata/reference/fetch_biliteracy_seal.md).

Percentages are published as strings (e.g. `"6.8%"`) and counts may
carry thousands separators (e.g. `"12,644"`); both are coerced to
numeric. Some multilingual-learner cells bleed a suppression note into
the value column (e.g.
`"Total Current and Former ML enrollment was less than 10 students."` or
`"Fewer than 5 students."`); these non-numeric strings become `NA`,
never a fabricated number. A genuine published `0` is preserved as `0`.

The District workbook additionally carries `schools_earning_seals(_pct)`
and `districts_earning_seals(_pct)` columns (absent from the School
workbook); they are passed through when present.

## Examples

``` r
if (FALSE) { # \dontrun{
# Summary for every school (2024-25)
bs <- fetch_biliteracy_summary(2025)

# Statewide totals (district workbook carries the is_state row)
library(dplyr)
fetch_biliteracy_summary(2025, level = "district") %>%
  filter(is_state) %>%
  select(total_seals_earned, numberof_languages, unique_students_earning_seals)

# Schools earning the most seals
fetch_biliteracy_summary(2025) %>%
  filter(is_school) %>%
  slice_max(total_seals_earned, n = 10) %>%
  select(district_name, school_name, total_seals_earned, numberof_languages)
} # }
```
