# Get valid years for a data type

Coverage comes from the package's authoritative source registry. Raw and
tidy support can differ; this compatibility front door reports tidy
support.

## Usage

``` r
get_valid_years(data_type)
```

## Arguments

- data_type:

  Registered family name or alias.

## Value

Integer vector of valid school-year end years.

## Examples

``` r
get_valid_years("enrollment")
#>  [1] 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013
#> [16] 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023 2024 2025 2026
get_valid_years("parcc")
#> [1] 2015 2016 2017 2018 2019 2022 2023 2024 2025
```
