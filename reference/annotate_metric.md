# Attach metric metadata to a data frame

Adds `polarity`, `unit`, and `is_rate` columns to a fetcher or analysis
output. For long outputs with a `metric` column, metadata is joined per
row. Otherwise provide a scalar `metric` name to apply the same metadata
to the whole frame.

Existing data columns are preserved.

## Usage

``` r
annotate_metric(df, metric = NULL)
```

## Arguments

- df:

  A data frame.

- metric:

  Optional character scalar metric name. If `NULL` and `df` has a
  `metric` column, metadata is joined by that column.

## Value

`df` with added `polarity`, `unit`, and `is_rate` columns.

## Examples

``` r
annotate_metric(tibble::tibble(entity_name = "A", value = 0.82), "grad_rate")
#> # A tibble: 1 × 5
#>   entity_name value polarity         unit    is_rate
#>   <chr>       <dbl> <chr>            <chr>   <lgl>  
#> 1 A            0.82 higher_is_better percent TRUE   
finance <- tibble::tibble(metric = c("per_pupil_total", "revenue_state"), value = c(1, 2))
annotate_metric(finance)
#> # A tibble: 2 × 5
#>   metric          value polarity unit    is_rate
#>   <chr>           <dbl> <chr>    <chr>   <lgl>  
#> 1 per_pupil_total     1 neutral  dollars TRUE   
#> 2 revenue_state       2 neutral  dollars FALSE  
annotate_metric(tibble::tibble(value = c(10, 20)), metric = "discipline_rate")
#> # A tibble: 2 × 4
#>   value polarity        unit  is_rate
#>   <dbl> <chr>           <chr> <lgl>  
#> 1    10 lower_is_better ratio TRUE   
#> 2    20 lower_is_better ratio TRUE   
```
