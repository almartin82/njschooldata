# Get available end years under default selectors

Reports years served by a type's fetcher with \`source = "live"\` or
\`source = "package"\`, and all other selectors at their defaults.
Coverage is computed offline from the declarations the fetchers enforce.
Years requiring non-default selectors or private stores are excluded.

## Usage

``` r
get_available_years(type = NULL)
```

## Arguments

- type:

  A single fetch family name, such as \`"enrollment"\`, or \`NULL\` for
  all declared types.

## Value

With \`type\`, a sorted, unique integer vector of school year ends. With
\`NULL\`, a data frame with columns \`type\`, \`end_year\`, and
\`fetcher\`, ordered by type and year. Gaps in coverage remain visible.

## Details

Only enrollment coverage is declared so far. Other known fetch families
raise an error containing "coverage not yet declared".

## Examples

``` r
get_available_years("enrollment")
#>  [1] 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013
#> [16] 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023 2024 2025 2026
get_available_years()
#>          type end_year   fetcher
#> 1  enrollment     1999 fetch_enr
#> 2  enrollment     2000 fetch_enr
#> 3  enrollment     2001 fetch_enr
#> 4  enrollment     2002 fetch_enr
#> 5  enrollment     2003 fetch_enr
#> 6  enrollment     2004 fetch_enr
#> 7  enrollment     2005 fetch_enr
#> 8  enrollment     2006 fetch_enr
#> 9  enrollment     2007 fetch_enr
#> 10 enrollment     2008 fetch_enr
#> 11 enrollment     2009 fetch_enr
#> 12 enrollment     2010 fetch_enr
#> 13 enrollment     2011 fetch_enr
#> 14 enrollment     2012 fetch_enr
#> 15 enrollment     2013 fetch_enr
#> 16 enrollment     2014 fetch_enr
#> 17 enrollment     2015 fetch_enr
#> 18 enrollment     2016 fetch_enr
#> 19 enrollment     2017 fetch_enr
#> 20 enrollment     2018 fetch_enr
#> 21 enrollment     2019 fetch_enr
#> 22 enrollment     2020 fetch_enr
#> 23 enrollment     2021 fetch_enr
#> 24 enrollment     2022 fetch_enr
#> 25 enrollment     2023 fetch_enr
#> 26 enrollment     2024 fetch_enr
#> 27 enrollment     2025 fetch_enr
#> 28 enrollment     2026 fetch_enr
coverage <- get_available_years()
subset(coverage, end_year == max(end_year))
#>          type end_year   fetcher
#> 28 enrollment     2026 fetch_enr
```
