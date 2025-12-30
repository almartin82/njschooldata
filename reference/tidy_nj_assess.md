# tidies NJ assessment data

`tidy_nj_assess` is a utility/internal function that takes the somewhat
messy/inconsistent assessment headers and returns a tidy data frame.

## Usage

``` r
tidy_nj_assess(assess_name, df)
```

## Arguments

- assess_name:

  NJASK, GEPA, HSPA

- df:

  a processed data frame (eg, output of process_njask)
