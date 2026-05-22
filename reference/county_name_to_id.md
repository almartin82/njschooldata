# Map NJ county names to 2-digit county ID codes

Maps New Jersey county names to their standard 2-digit numeric codes
(01-21). NJ counties are numbered alphabetically.

## Usage

``` r
county_name_to_id(county_name)
```

## Arguments

- county_name:

  Character vector of county names (case-insensitive).

## Value

Character vector of 2-digit zero-padded county codes. Returns
`NA_character_` for unrecognized names.

## Examples

``` r
county_name_to_id("ESSEX")
#> [1] "07"
county_name_to_id(c("essex", "Hudson", "BERGEN"))
#> [1] "07" "09" "02"
```
