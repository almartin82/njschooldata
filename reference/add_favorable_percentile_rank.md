# Add favorable-direction percentile rank columns for a registered metric

Calculates percentile rank using the existing
[`add_percentile_rank()`](https://almartin82.github.io/njschooldata/reference/add_percentile_rank.md)
primitive, then orients the rank calculation by registered metric
polarity. For `lower_is_better` metrics, values are inverted before
ranking so a higher favorable percentile means a better outcome. For
`higher_is_better` and `neutral` metrics, the existing rank direction is
preserved.

This is an opt-in helper and does not change the default output of
[`add_percentile_rank()`](https://almartin82.github.io/njschooldata/reference/add_percentile_rank.md).

## Usage

``` r
add_favorable_percentile_rank(
  df,
  metric_col,
  metric = metric_col,
  prefix = NULL
)
```

## Arguments

- df:

  A dataframe, optionally grouped. Grouping defines the comparison set.

- metric_col:

  Character. The column name to rank on.

- metric:

  Character. Registry metric name used to look up polarity. Defaults to
  `metric_col`.

- prefix:

  Character. Optional prefix for output column names. If `NULL`, uses
  `{metric_col}_favorable` as prefix.

## Value

df with added `{prefix}_rank`, `{prefix}_n`, and `{prefix}_percentile`
columns.

## Examples

``` r
test_df <- tibble::tibble(id = c("A", "B", "C"), dropout_rate = c(3, 8, 12))
add_favorable_percentile_rank(test_df, "dropout_rate")
#> # A tibble: 3 × 5
#>   id    dropout_rate dropout_rate_favorable_rank dropout_rate_favorable_n
#>   <chr>        <dbl>                       <int>                    <int>
#> 1 A                3                           3                        3
#> 2 B                8                           2                        3
#> 3 C               12                           1                        3
#> # ℹ 1 more variable: dropout_rate_favorable_percentile <dbl>
grad_df <- tibble::tibble(id = c("A", "B", "C"), grad_rate = c(70, 80, 90))
add_favorable_percentile_rank(grad_df, "grad_rate", prefix = "grad_fav")
#> # A tibble: 3 × 5
#>   id    grad_rate grad_fav_rank grad_fav_n grad_fav_percentile
#>   <chr>     <dbl>         <int>      <int>               <dbl>
#> 1 A            70             1          3                33.3
#> 2 B            80             2          3                66.7
#> 3 C            90             3          3               100  
```
