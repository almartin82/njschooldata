# Enrich report card subgroup percentages with counts derived from the same entity/year's published total enrollment

Enrich report card subgroup percentages with counts derived from the
same entity/year's published total enrollment

## Usage

``` r
enrich_rc_enrollment(df)
```

## Arguments

- df:

  data frame of including subgroup percentages

## Value

data_frame with \`n_students\` computed as \`round(percent / 100 \*
n_enrolled)\` – this subgroup's own published percent times this
entity/year's own published total enrollment – and a \`value_source\`
column marking each row \`"derived_from_pct"\` or, where either input
was NA, \`"published_pct_only"\` (with \`n_students\` NA).
