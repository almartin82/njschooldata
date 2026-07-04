# List registered metrics

Returns the bundled metric registry for browsing. Optionally filters to
one or more domains.

## Usage

``` r
list_metrics(domain = NULL)
```

## Arguments

- domain:

  Optional character vector of domains to keep.

## Value

A tibble containing registry rows.

## Examples

``` r
list_metrics()
#> # A tibble: 170 × 9
#>    domain   metric label unit  polarity is_rate denominator_metric era_break_set
#>    <chr>    <chr>  <chr> <chr> <chr>    <lgl>   <chr>              <chr>        
#>  1 finance  per_p… Tota… doll… neutral  FALSE   NA                 NA           
#>  2 finance  per_p… Inst… doll… neutral  FALSE   NA                 NA           
#>  3 finance  per_p… Supp… doll… neutral  FALSE   NA                 NA           
#>  4 finance  per_p… Admi… doll… neutral  FALSE   NA                 NA           
#>  5 finance  per_p… Oper… doll… neutral  FALSE   NA                 NA           
#>  6 finance  per_p… Food… doll… neutral  FALSE   NA                 NA           
#>  7 finance  reven… Stat… doll… neutral  FALSE   NA                 NA           
#>  8 graduat… grad_… Grad… perc… higher_… TRUE    cohort_count       grad         
#>  9 graduat… four_… Four… perc… higher_… TRUE    cohort_count       grad         
#> 10 graduat… five_… Five… perc… higher_… TRUE    cohort_count       grad         
#> # ℹ 160 more rows
#> # ℹ 1 more variable: notes <chr>
list_metrics("finance")
#> # A tibble: 7 × 9
#>   domain  metric   label unit  polarity is_rate denominator_metric era_break_set
#>   <chr>   <chr>    <chr> <chr> <chr>    <lgl>   <chr>              <chr>        
#> 1 finance per_pup… Tota… doll… neutral  FALSE   NA                 NA           
#> 2 finance per_pup… Inst… doll… neutral  FALSE   NA                 NA           
#> 3 finance per_pup… Supp… doll… neutral  FALSE   NA                 NA           
#> 4 finance per_pup… Admi… doll… neutral  FALSE   NA                 NA           
#> 5 finance per_pup… Oper… doll… neutral  FALSE   NA                 NA           
#> 6 finance per_pup… Food… doll… neutral  FALSE   NA                 NA           
#> 7 finance revenue… Stat… doll… neutral  FALSE   NA                 NA           
#> # ℹ 1 more variable: notes <chr>
list_metrics(c("graduation", "assessment"))
#> # A tibble: 40 × 9
#>    domain   metric label unit  polarity is_rate denominator_metric era_break_set
#>    <chr>    <chr>  <chr> <chr> <chr>    <lgl>   <chr>              <chr>        
#>  1 graduat… grad_… Grad… perc… higher_… TRUE    cohort_count       grad         
#>  2 graduat… four_… Four… perc… higher_… TRUE    cohort_count       grad         
#>  3 graduat… five_… Five… perc… higher_… TRUE    cohort_count       grad         
#>  4 graduat… grad_… Four… perc… higher_… TRUE    cohort_count       grad         
#>  5 graduat… grad_… Five… perc… higher_… TRUE    cohort_count       grad         
#>  6 graduat… grad_… Six … perc… higher_… TRUE    cohort_count       grad         
#>  7 graduat… cohor… Grad… count neutral  FALSE   NA                 NA           
#>  8 graduat… gradu… Grad… count neutral  FALSE   NA                 NA           
#>  9 graduat… conti… Cont… perc… neutral  TRUE    cohort_count       grad         
#> 10 graduat… non_c… Non … perc… lower_i… TRUE    cohort_count       grad         
#> # ℹ 30 more rows
#> # ℹ 1 more variable: notes <chr>
```
