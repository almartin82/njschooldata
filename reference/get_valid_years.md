# Get valid year range for a data type

Get valid year range for a data type

Get valid years for a data type

## Usage

``` r
get_valid_years(data_type)

get_valid_years(data_type)
```

## Arguments

- data_type:

  Character string identifying the data type

## Value

Integer vector of valid years

Integer vector of valid years

## Examples

``` r
get_valid_years("enrollment")
#>  [1] 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014
#> [16] 2015 2016 2017 2018 2019 2020 2021 2022 2023 2024 2025
get_valid_years("parcc")
#> [1] 2015 2016 2017 2018 2019 2021 2022 2023 2024
```
