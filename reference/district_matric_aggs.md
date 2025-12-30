# Aggregates matriculation data by district

Only school-level matriculation data reported before 2017. This function
approximates district level results. If schools within the district do
not report for certain subgroups, the approximation will be further off.

## Usage

``` r
district_matric_aggs(df)
```

## Arguments

- df:

  output of `enrich_matric_counts`

## Value

A data frame of district aggregations
