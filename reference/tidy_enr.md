# Tidy enrollment data

Transforms wide enrollment data to long format with subgroup column.

## Usage

``` r
tidy_enr(df)
```

## Arguments

- df:

  A wide data.frame of processed enrollment data - eg output of
  \`fetch_enr\`

## Value

A long data.frame of tidied enrollment data. Carries a \`value_source\`
column: \`"published"\` for race/gender/total_enrollment subgroups
(always a real published headcount) and for
free_lunch/reduced_lunch/lep/migrant in pre-2020 files;
\`"derived_from_pct"\` or \`"published_pct_only"\` for
free_lunch/reduced_lunch/lep/migrant from 2020+ files, where NJ DOE
publishes only a percentage and the count is computed as \`pct / 100 \*
row_total\` (see \`fetch_enrollment.R\`'s \`pct_cols\` loop; this value
is NOT rounded to a whole student); \`free_reduced_lunch\` inherits the
weaker of its two component labels since it sums them.
