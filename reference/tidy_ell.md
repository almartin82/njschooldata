# Tidy English Learner population data

Transforms processed EL data into the cross-state tidy contract: one row
per entity x year x grade x EL status x subgroup. NJ publishes a single
current-EL headcount per entity, so \`el_status\` is always
\`"current"\` and \`subgroup\` is always \`"total"\`. NJ does not
suppress EL counts, so the suppression bounds equal the point value
wherever a count is published and are \`NA\` for the percent-only
district/school years (2020-2022).

## Usage

``` r
tidy_ell(df)
```

## Arguments

- df:

  processed EL data — output of \`process_ell()\`

## Value

tidy data.frame following \[ELL_TIDY_COLS\]
