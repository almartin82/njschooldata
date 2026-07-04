# Get era break metadata

Returns the bundled era-break metadata used to segment trends across
assessment scale breaks, COVID gap years, and documented definition
changes.

## Usage

``` r
get_era_breaks(break_set = NULL)
```

## Arguments

- break_set:

  Optional character vector of break-set keys to return. If `NULL`, all
  break sets are returned.

## Value

A data frame with columns `break_set`, `break_year`, `break_type`,
`label`, `comparable_prior`, and `notes`.

## Examples

``` r
all_breaks <- get_era_breaks()
get_era_breaks("njsla")
#> # A tibble: 5 × 6
#>   break_set break_year break_type        label            comparable_prior notes
#>   <chr>          <int> <chr>             <chr>            <lgl>            <chr>
#> 1 njsla           2015 scale_break       NJASK/HSPA to P… FALSE            NJDO…
#> 2 njsla           2019 definition_change PARCC to NJSLA   FALSE            NJDO…
#> 3 njsla           2020 covid_gap         COVID assessmen… NA               NJDO…
#> 4 njsla           2021 covid_gap         COVID assessmen… NA               NJDO…
#> 5 njsla           2022 definition_change NJSLA resumptio… FALSE            NJDO…
get_era_breaks(c("grad", "attendance"))
#> # A tibble: 5 × 6
#>   break_set  break_year break_type        label           comparable_prior notes
#>   <chr>           <int> <chr>             <chr>           <lgl>            <chr>
#> 1 grad             2020 covid_gap         Class of 2020 … NA               NJDO…
#> 2 grad             2021 definition_change Federal gradua… FALSE            NJDO…
#> 3 grad             2022 definition_change Federal gradua… FALSE            NJDO…
#> 4 attendance       2020 covid_gap         COVID attendan… NA               NJDO…
#> 5 attendance       2021 covid_gap         COVID attendan… NA               NJDO…
```
