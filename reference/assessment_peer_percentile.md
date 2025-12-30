# Assessment Peer Percentile

calculates the percentile rank of a school, defined as the percent of
comparison schools with lesser or equal performance, for both scale
score, percent proficiency, and a composite average of the two. USE
CAUTION when invoking this function. This function accepts WHATEVER
grouping variables are present in the input data. If your data is not
grouped in an intelligible or meaningful way, you may get nonsense
percentile ranks (eg, across grade levels, years, subgroups, etc).
Please start with the convenience wrappers
\`statewide_peer_percentile()\` and \`dfg_peer_percentile()\` to examine
percentile rank using comparison groups that are sensible.

## Usage

``` r
assessment_peer_percentile(df)
```

## Arguments

- df:

  tidy PARCC df

## Value

PARCC df with percentile ranks
