# Fetch Federally Reported Graduation Rates (ESSA ACGR)

Downloads the `FederalGraduationRates` sheet from the School Performance
Reports. This is the federally reported Adjusted Cohort Graduation Rate
(ACGR) used for ESSA accountability, reported for the 4-, 5-, and 6-year
cohorts by student group. The federal ACGR uses a different (federally
specified) cohort denominator than the state graduation rate in
[`fetch_grad_rate`](https://almartin82.github.io/njschooldata/reference/fetch_grad_rate.md),
so the two can differ for the same entity and year.

## Usage

``` r
fetch_spr_fed_grad(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2021-2025). Year is the end of the academic year - e.g.
  the 2020-21 school year is `end_year` 2021.

- level:

  One of `"school"` or `"district"`.

## Value

Data frame with entity identifiers, school_year (2025 only), subgroup,
cohort_years, cohort_label, graduation_rate_federal, and the aggregation
flags.

## Details

The source publishes one wide row per entity and student group with a
separate rate column per cohort length. This function reshapes that to a
tidy frame of one row per entity, student group, and cohort length:
`cohort_years` is 4, 5, or 6, `cohort_label` is the graduating cohort it
refers to (e.g. `"Cohort 2025"`), and `graduation_rate_federal` is the
entity-appropriate ACGR (percent on a 0-100 scale; suppressed cells are
`NA`). At `level = "district"` the statewide ACGR is carried on the
`is_state` row.

The sheet's column layout drifts across years and this function
harmonizes both forms: the SY2024-25 redesign names columns by cohort
length (`x_4_yr_graduation_rate_federal_school`, ...) and adds a
`school_year` and per-cohort label column; the pre-redesign layout
embeds the graduating year in the column name
(`x_2024_4_year_federal_graduation_rate`, `state_2024_4_year_...`), from
which the cohort label is recovered.

**Supported years:** `end_year` 2021-2025. The `FederalGraduationRates`
sheet is absent from the SY2016-17 through SY2019-20 databases
(`end_year` 2017-2020 error). The 6-year cohort is reported only from
SY2023-24 (`end_year` 2024) onward; for 2021-2023 only the 4- and 5-year
cohorts are present. `end_year` 2021 is SY2020-21.

## Examples

``` r
if (FALSE) { # \dontrun{
# School-level federal graduation rates (4/5/6-year, long)
fg <- fetch_spr_fed_grad(2025)

# Statewide 4-year federal ACGR
library(dplyr)
fetch_spr_fed_grad(2025, level = "district") %>%
  filter(is_state, subgroup == "total population", cohort_years == 4) %>%
  select(cohort_label, graduation_rate_federal)

# Federal vs state 4-year rate gap by district
fetch_spr_fed_grad(2024, level = "district") %>%
  filter(is_district, subgroup == "total population", cohort_years == 4) %>%
  select(district_name, graduation_rate_federal)
} # }
```
