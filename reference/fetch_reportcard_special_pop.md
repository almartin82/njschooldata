# Fetch Special Population data

Fetch Special Population data

## Usage

``` r
fetch_reportcard_special_pop(end_year)
```

## Arguments

- end_year:

  ending academic year. valid values are 2017, 2018, 2019

## Value

data.frame with special population enrollment data. \`n_students\` is
computed as \`round(percent / 100 \* n_enrolled)\` from this subgroup's
own published percent and this entity/year's own published total
enrollment; \`value_source\` marks each row \`"derived_from_pct"\` or,
where either input was NA, \`"published_pct_only"\` (with \`n_students\`
NA).
