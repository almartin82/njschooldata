# Get the years for which NJ enrollment data is available

Wraps \[ENR_VALID_YEARS\] (\`R/config_years.R\`), the single source of
truth for enrollment year coverage, so consumers never have to hardcode
or guess the valid range. The maximum value returned here MUST always
equal the highest \`end_year\` that \[fetch_enr()\] actually serves; see
\`test-enrollment-year-coverage.R\` for the contract test that enforces
this.

## Usage

``` r
get_available_years()
```

## Value

integer vector of valid \`end_year\` values

## Examples

``` r
get_available_years()
#>  [1] 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013
#> [16] 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023 2024 2025 2026
```
