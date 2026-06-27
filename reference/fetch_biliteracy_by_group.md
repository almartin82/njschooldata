# Fetch Seal-of-Biliteracy Seal-Earning Rate by Student Group (2024-25)

Downloads the `SealofBiliteracy_StudentGroup` sheet from the redesigned
2024-25 NJ DOE School Performance Reports. Each row reports, for one
entity and one student group, the percentage of students in that group
earning a seal, alongside the district and state rates for the same
group - an equity lens on biliteracy attainment.

## Usage

``` r
fetch_biliteracy_by_group(end_year, level = "school")
```

## Arguments

- end_year:

  Must be 2025 (the only year the sheet exists).

- level:

  One of `"school"` or `"district"`.

## Value

Data frame with entity identifiers, `school_year`, `subgroup`, the
per-group seal-earning rates (`*_pct_school` for school level only, plus
`*_pct_district` and `*_pct_state`), and the standard aggregation flags.

## Details

The sheet exists **only in end_year 2025** (both school and district
workbooks); other years error. The School workbook carries the
`students_earning_seal_pct_school` column; the District workbook omits
it (there is no school context at the district level), so that column is
present only for `level = "school"`.

Percentages are published as strings (e.g. `"6.8%"`) and coerced to
numeric. Suppression strings
(`"Enrollment for the group is <10 students."`,
`"Fewer than 5 students earned a seal."`) become `NA`, never a
fabricated number. Student-group labels are normalized by
[`clean_spr_subgroups`](https://almartin82.github.io/njschooldata/reference/clean_spr_subgroups.md)
(e.g. `"total population"`, `"economically disadvantaged"`,
`"limited english proficiency"`).

Note: the StudentGroup sheet has no statewide aggregate *row*; the state
rate for each group is carried in the `students_earning_seal_pct_state`
column on every row.

## Examples

``` r
if (FALSE) { # \dontrun{
# Seal-earning rate by student group for every school (2024-25)
bg <- fetch_biliteracy_by_group(2025)

# Equity gap: economically disadvantaged vs total, statewide-by-district
library(dplyr)
fetch_biliteracy_by_group(2025, level = "district") %>%
  filter(subgroup %in% c("total population", "economically disadvantaged")) %>%
  select(district_name, subgroup, students_earning_seal_pct_district)

# English-learner seal rate at one school
fetch_biliteracy_by_group(2025) %>%
  filter(district_id == "3570", subgroup == "limited english proficiency") %>%
  select(school_name, subgroup, students_earning_seal_pct_school)
} # }
```
