# Aggregate PARCC results across multiple grade levels

a wrapper around fetch_parcc and parcc_aggregate_calcs that simplifies
the calculation of multi-grade PARCC aggregations

## Usage

``` r
calculate_agg_parcc_prof(end_year, subj, gradespan = "3-11")
```

## Arguments

- end_year:

  school year / testing year

- subj:

  one of 'ela' or 'math'

- gradespan:

  one of c('3-11', '3-8', '9-11'). default is '3-11'

## Value

dataframe
