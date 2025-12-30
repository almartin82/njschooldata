# Process a NJ assessment file

Does cleanup of the raw assessment file, primarily ensuring that columns
tagged as 'one implied' are displayed correctly.

## Usage

``` r
process_nj_assess(df, layout)
```

## Arguments

- df:

  A raw NJASK, HSPA, or GEPA data frame (eg output of \`get_raw_njask\`)

- layout:

  Which layout file to use to determine which columns are one implied
  decimal.

## Value

Processed assessment data frame
