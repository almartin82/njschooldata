# Load the bundled metric registry

Reads the package's bundled metric metadata table from
`inst/extdata/metric_registry.csv`. The registry records metric names,
labels, units, polarity, rate metadata, and source notes for tidy
analysis. It is authored from the metric columns and long-schema metric
names emitted by package fetchers and analysis helpers; it contains
metadata only.

The table is cached for the R session after the first read.

## Usage

``` r
load_metric_registry()
```

## Value

A tibble with columns `domain`, `metric`, `label`, `unit`, `polarity`,
`is_rate`, `denominator_metric`, `era_break_set`, and `notes`.

## Examples

``` r
registry <- load_metric_registry()
head(registry)
#> # A tibble: 6 × 9
#>   domain  metric   label unit  polarity is_rate denominator_metric era_break_set
#>   <chr>   <chr>    <chr> <chr> <chr>    <lgl>   <chr>              <chr>        
#> 1 finance per_pup… Tota… doll… neutral  FALSE   NA                 NA           
#> 2 finance per_pup… Inst… doll… neutral  FALSE   NA                 NA           
#> 3 finance per_pup… Supp… doll… neutral  FALSE   NA                 NA           
#> 4 finance per_pup… Admi… doll… neutral  FALSE   NA                 NA           
#> 5 finance per_pup… Oper… doll… neutral  FALSE   NA                 NA           
#> 6 finance per_pup… Food… doll… neutral  FALSE   NA                 NA           
#> # ℹ 1 more variable: notes <chr>
unique(registry$domain)
#>  [1] "finance"            "graduation"         "assessment"        
#>  [4] "attendance"         "discipline"         "restraint"         
#>  [7] "advanced"           "college_career"     "biliteracy"        
#> [10] "special_ed"         "el"                 "enrollment"        
#> [13] "staff"              "school_environment"
```
