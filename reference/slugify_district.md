# Slugify a district name for URL use

Converts a district name to a URL-safe slug by lowercasing, stripping
common suffixes (School District, Public Schools, ISD, USD, etc.),
removing punctuation, and replacing spaces with hyphens.

## Usage

``` r
slugify_district(district_name, district_id = NULL)
```

## Arguments

- district_name:

  Character vector of district names.

- district_id:

  Optional character vector of district IDs (same length as
  district_name). When provided and slug collisions exist, appends the
  district ID to disambiguate.

## Value

Character vector of slugified names.

## Details

When called with a vector of names and optional district IDs, detects
slug collisions and appends the district ID to disambiguate.

## Examples

``` r
slugify_district("Providence Public Schools")
#> [1] "providence"
# "providence"
slugify_district("Dallas Independent School District")
#> [1] "dallas"
# "dallas"
slugify_district(c("Liberty", "Liberty"), c("1234", "5678"))
#> [1] "liberty-1234" "liberty-5678"
# c("liberty-1234", "liberty-5678")
```
