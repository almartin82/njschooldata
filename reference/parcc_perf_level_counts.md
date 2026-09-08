# PARCC counts by performance level

Calculates the count of students at each performance level based on
percentages and total valid scores. This is a derivation by design:
NJDOE publishes performance-level shares (\`pct_l1\`..\`pct_l5\`) but
not the underlying counts, so this function exists to compute them from
each row's own published percentage and its own published
\`number_of_valid_scale_scores\` (the same-cell denominator those
percentages are shares of).

## Usage

``` r
parcc_perf_level_counts(df)
```

## Arguments

- df:

  dataframe, output of fetch_parcc

## Value

df with counts of students by performance level (\`num_l1\`..\`num_l5\`
= \`round(pct_lN / 100 \* number_of_valid_scale_scores)\`) and a
\`value_source\` column: \`"derived_from_pct"\` where
\`number_of_valid_scale_scores\` is non-NA, \`"published_pct_only"\`
(with every \`num_lN\` NA) where it is NA. A performance level a test
does not have (eg L3-L5 for NJGPA) carries \`pct_lN\`/\`num_lN\` NA
regardless of \`value_source\`, which describes the derivation method,
not applicability.
