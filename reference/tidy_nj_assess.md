# tidies NJ assessment data

`tidy_nj_assess` is a utility/internal function that takes the somewhat
messy/inconsistent assessment headers and returns a tidy data frame. The
output also carries the same seven entity-selector flag columns emitted
by tidy PARCC output - `is_state`, `is_dfg`, `is_district`, `is_school`,
`is_charter`, `is_charter_sector`, `is_allpublic` - so downstream code
can filter cross-format (PARCC + NJASK/HSPA/GEPA) results on the same
predicates.

## Usage

``` r
tidy_nj_assess(assess_name, df)
```

## Arguments

- assess_name:

  NJASK, GEPA, HSPA

- df:

  a processed data frame (eg, output of process_njask)
