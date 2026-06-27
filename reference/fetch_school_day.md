# Fetch School-Day Length & Instructional Time

Downloads the `SchoolDay` sheet from the NJ DOE School Performance
Reports. Each row reports, for one school, the typical start and end
times, the total length of the school day, and the instructional time
available to full-time and shared-time students. This is school-level
operational data (time-on-learning) with no district or state aggregate,
so the function is school-level only.

## Usage

``` r
fetch_school_day(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2017-2025). Year is the end of the academic year - e.g.
  the 2023-24 school year is `end_year` 2024.

- level:

  Only `"school"` is supported (the sheet has no district/state
  analogue). Other values error.

## Value

Data frame with entity identifiers, `typical_start_time`,
`typical_end_time`, the three published duration strings and their three
derived `*_minutes` numeric columns, the 2025-only `school_year` column
when present, and the standard aggregation flags (`is_state`,
`is_county`, `is_district`, `is_school`, `is_charter`,
`is_charter_sector`, `is_allpublic`).

## Details

The sheet is present in the School workbook for **end_year 2017-2025**.
Durations are published as human-readable strings (e.g.
`"6 Hrs. 25 Mins."`); this function preserves the published strings
(`length_of_day`, `instruction_full_time`, `instruction_shared_time`)
and additionally derives numeric-minutes columns
(`length_of_day_minutes`, `instruction_full_time_minutes`,
`instruction_shared_time_minutes`) via a deterministic parse. The
2024-25 redesign:

- adds a single-value `school_year` column (e.g. `"2024-25"`), preserved
  in the output;

- reports `instruction_shared_time` as
  `"n/a - applies only to high schools"` for non-high schools, which
  parses to `NA` minutes.

The SY2016-17 (2017) sheet ships only the CDS-code ids and omits the
county/district/school name columns; those are returned as `NA` for that
year (the ids remain the real join keys). The minute columns are a
re-expression of the published string, never an estimate; unparseable
strings yield `NA` minutes.

## Examples

``` r
if (FALSE) { # \dontrun{
# Length of the school day for every school (latest year)
sd <- fetch_school_day(2024)

# Longest instructional days statewide
library(dplyr)
fetch_school_day(2024) %>%
  filter(is_school) %>%
  slice_max(instruction_full_time_minutes, n = 10) %>%
  select(district_name, school_name, instruction_full_time_minutes)

# Newark schools, sorted by length of day
fetch_school_day(2024) %>%
  filter(district_id == "3570") %>%
  arrange(desc(length_of_day_minutes)) %>%
  select(school_name, length_of_day, length_of_day_minutes)
} # }
```
