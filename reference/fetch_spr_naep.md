# Fetch NAEP Achievement Results

Downloads the `NAEP` sheet from the redesigned 2024-25 School
Performance Reports (District/State database only). This is the National
Assessment of Educational Progress: the percentage of New Jersey (and,
for comparison, national) students at each achievement level (Below
Basic, Basic, Proficient, Advanced) for 4th- and 8th-grade reading and
mathematics, across the NAEP administration years reported in the
workbook.

## Usage

``` r
fetch_spr_naep(end_year)
```

## Arguments

- end_year:

  A school year (2017-2025). Year is the end of the academic year - e.g.
  the 2024-25 school year is `end_year` 2025. Note this is the SPR
  publication year, not the NAEP administration year (see `test_year`).

## Value

Data frame with end_year (the SPR publication year), test_year (the NAEP
administration year), state_nation, subject, grade, student_group, and
the achievement-level percentages below_basic, basic, proficient,
advanced.

## Details

NAEP is a state/national summary table with no county/district/school
breakdown, so this function returns no CDS identifiers or aggregation
flags. The `state_nation` column distinguishes `"New Jersey"` from
`"Nation"`; `test_year` is the NAEP administration year (NAEP is given
periodically, so multiple years appear). The four achievement-level
columns are returned numeric on a 0-100 scale.

**Supported years:** `end_year >= 2017`. Always reads the District/State
database (the School database has no NAEP sheet). Before the 2024-25
redesign the sheet used a leaner layout (`Year`, `Test`, `Grade` and the
four achievement levels) with no student-group breakdown; this function
maps it to the redesigned shape: `Year -> test_year`, `Test -> subject`,
the legacy `"State (NJ)"` label is normalized to `"New Jersey"`, and
`student_group` is set to the constant `"All Students"` (the legacy
sheet reports the all-students summary only; the per-subgroup breakdown
was added in 2024-25).

## Examples

``` r
if (FALSE) { # \dontrun{
# NAEP results as published in the 2024-25 SPR
naep <- fetch_spr_naep(2025)

# NAEP as published in an earlier SPR (all-students summary only)
naep_2024 <- fetch_spr_naep(2024)

# New Jersey vs. the nation, Grade 4 Math, most recent administration
library(dplyr)
fetch_spr_naep(2025) %>%
  filter(subject == "Mathematics", grade == "4",
         student_group == "All Students") %>%
  filter(test_year == max(test_year)) %>%
  select(state_nation, below_basic, basic, proficient, advanced)
} # }
```
