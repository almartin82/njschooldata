# Enrich report card matriculation percentages with grad counts

Joins graduation count data to a data frame containing subgroup
percentages.

## Usage

``` r
enrich_grad_count(df, end_year)
```

## Arguments

- df:

  Data frame including subgroup percentages

- end_year:

  Numeric end year of grad counts to join

## Value

data_frame with graduated_count and cohort_count columns added
