# Process raw English Learner population data

Adds entity-level aggregation flags, standardizes the grade level, and
computes the EL share of enrollment. County aggregate rows are dropped
so the output carries only state / district / school entities (the
cross-state contract). The EL share is computed fresh from the published
headcount where a count exists; for the 2020-2022 district/school files
that publish only a percent, the published percent is carried through
unchanged (never used to back-derive a count).

## Usage

``` r
process_ell(df)
```

## Arguments

- df:

  raw EL data — output of \`get_raw_ell()\`

## Value

data.frame (wide, one row per entity) with entity flags,
\`grade_level\`, \`total_enrollment\`, \`el_count\`, \`el_pct\`, and
\`pct_of_enrollment\`
