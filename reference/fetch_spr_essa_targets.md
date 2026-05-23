# Fetch ESSA Long-Term-Goal Targets

Downloads the ESSA accountability long-term-goal target sheets from the
redesigned 2024-25 School Performance Reports. Each sheet reports, per
entity and student group, an indicator's actual performance against its
annual target (or state standard) and, where applicable, the federal
long-term goal.

## Usage

``` r
fetch_spr_essa_targets(end_year, indicator = "proficiency", level = "school")
```

## Arguments

- end_year:

  A school year. Only `2025` (SY2024-25) and later are supported.

- indicator:

  One of `"proficiency"` (default), `"growth"`, `"graduation"`, `"elp"`,
  `"absenteeism"`, or `"persistence"`.

- level:

  One of `"school"` or `"district"`. `"school"` returns school-level
  data; `"district"` returns district and state-level data.

## Value

Data frame with columns: end_year, county_id, county_name, district_id,
district_name, school_id, school_name, school_year, subgroup, indicator,
measure, indicator_performance, the indicator-specific target columns
described above, target_status (except for `"persistence"`), and the
aggregation flags (is_state, is_county, is_district, is_school,
is_charter, is_charter_sector, is_allpublic).

## Details

The `indicator` argument selects one of six target sheets, which share a
common backbone (entity identifiers, `school_year`, `subgroup`,
`measure`, `indicator_performance`) but differ in their target columns:

- `"proficiency"` – `ProficiencyTargets`: ELA and Math NJSLA
  proficiency. Columns: `annual_target`, `long_term_goal`,
  `target_status`.

- `"growth"` – `GrowthTargets`: ELA and Math median student growth.
  Columns: `state_standard_growth`, `target_status`.

- `"graduation"` – `GraduationTargets`: 4-, 5-, and 6-year graduation
  rates. Columns: `annual_target`, `long_term_goal`, `target_status`.

- `"elp"` – `ProgresstowardELPTargets`: progress toward English language
  proficiency. Columns: `annual_target`, `long_term_goal`,
  `target_status`.

- `"absenteeism"` – `ChronicAbsenteeismTargets`: chronic absenteeism.
  Columns: `target_state_average`, `target_status`.

- `"persistence"` – `HSPersistenceTargets`: high-school persistence. No
  target/status columns (performance only).

`measure` holds the sheet's own breakdown (e.g. `"ELA Proficiency"` vs.
`"Math Proficiency"`, or `"4-Year Graduation"` vs.
`"5-Year Graduation"`). `indicator` is added as a constant column equal
to the requested value so results from several indicators can be
row-bound and told apart.

Value columns (`indicator_performance`, `annual_target`,
`long_term_goal`, `state_standard_growth`, `target_state_average`) are
returned numeric; suppressed or below-N-size cells become `NA`.
`target_status` is kept as the raw status label (e.g. `"Met Target"`,
`"Met with CI"`, `"Below N-Size"`).

**Supported years:** only `end_year >= 2025` (the redesigned SY2024-25
SPR). Earlier databases do not include these sheets.

## Examples

``` r
if (FALSE) { # \dontrun{
# School-level proficiency targets (default indicator)
prof <- fetch_spr_essa_targets(2025)

# District/state-level graduation targets
grad <- fetch_spr_essa_targets(2025, indicator = "graduation", level = "district")

# Which schools missed their ELA proficiency long-term goal?
library(dplyr)
fetch_spr_essa_targets(2025, indicator = "proficiency") %>%
  filter(is_school, subgroup == "total population", measure == "ELA Proficiency") %>%
  filter(target_status == "Did Not Meet Target") %>%
  select(district_name, school_name, indicator_performance, long_term_goal)
} # }
```
