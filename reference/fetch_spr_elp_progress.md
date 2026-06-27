# Fetch Progress Toward English Language Proficiency

Downloads the `ProgressTowardELP` sheet from the redesigned 2024-25
School Performance Reports. This is the ESSA "Progress Toward English
Language Proficiency" accountability indicator: the percentage of
English learners who met their expected annual growth target toward
proficiency on the ACCESS for ELLs assessment. It is distinct from the
*target* sheet (`ProgresstowardELPTargets`), which is exposed through
[`fetch_spr_essa_targets`](https://almartin82.github.io/njschooldata/reference/fetch_spr_essa_targets.md).

## Usage

``` r
fetch_spr_elp_progress(end_year, level = "school")
```

## Arguments

- end_year:

  A school year. Only `2025` (SY2024-25) and later are supported.

- level:

  One of `"school"` or `"district"`.

## Value

Data frame with entity identifiers, school_year, progress_toward_elp,
and the aggregation flags.

## Details

This sheet has no student-group or grade breakdown - it reports a single
`progress_toward_elp` percentage per entity. The value is repeated as a
`_school` / `_district` / `_state` triple in the source; this function
returns the entity-appropriate value (the statewide value is available
from the `is_state` row of district-level output).

This sheet ships as a multi-year trend table inside the 2025 workbook
(`school_year` 2021-22..2024-25); per the package convention this
function filters to the requested academic year (SY2024-25 for
`end_year` 2025).

**Supported years:** only `end_year >= 2025`. The `ProgressTowardELP`
sheet is new in the SY2024-25 redesign; the pre-redesign
`EnglishLanguageProgress` sheet carries a different (target-bearing)
layout and is not mapped here.

## Examples

``` r
if (FALSE) { # \dontrun{
# School-level progress toward ELP
elp <- fetch_spr_elp_progress(2025)

# Statewide progress rate
library(dplyr)
fetch_spr_elp_progress(2025, level = "district") %>%
  filter(is_state) %>%
  select(progress_toward_elp)

# Schools with the lowest ELP progress
fetch_spr_elp_progress(2025) %>%
  filter(is_school, !is.na(progress_toward_elp)) %>%
  slice_min(progress_toward_elp, n = 10) %>%
  select(district_name, school_name, progress_toward_elp)
} # }
```
