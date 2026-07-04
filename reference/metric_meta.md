# Look up metadata for one metric

Returns the single metric-registry row for `metric`. If the metric is
not registered, returns a one-row tibble with `NA` metadata and warns
once for that lookup.

## Usage

``` r
metric_meta(metric)
```

## Arguments

- metric:

  Character scalar metric name.

## Value

A one-row tibble with the metric registry schema.

## Examples

``` r
metric_meta("grad_rate")
#> # A tibble: 1 × 9
#>   domain    metric label unit  polarity is_rate denominator_metric era_break_set
#>   <chr>     <chr>  <chr> <chr> <chr>    <lgl>   <chr>              <chr>        
#> 1 graduati… grad_… Grad… perc… higher_… TRUE    cohort_count       grad         
#> # ℹ 1 more variable: notes <chr>
metric_meta("per_pupil_total")
#> # A tibble: 1 × 9
#>   domain  metric   label unit  polarity is_rate denominator_metric era_break_set
#>   <chr>   <chr>    <chr> <chr> <chr>    <lgl>   <chr>              <chr>        
#> 1 finance per_pup… Tota… doll… neutral  FALSE   NA                 NA           
#> # ℹ 1 more variable: notes <chr>
metric_meta("chronically_absent_rate")
#> # A tibble: 1 × 9
#>   domain    metric label unit  polarity is_rate denominator_metric era_break_set
#>   <chr>     <chr>  <chr> <chr> <chr>    <lgl>   <chr>              <chr>        
#> 1 attendan… chron… Chro… perc… lower_i… TRUE    NA                 attendance   
#> # ℹ 1 more variable: notes <chr>
```
