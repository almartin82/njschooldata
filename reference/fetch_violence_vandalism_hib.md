# Fetch Violence/Vandalism/HIB Data

Downloads incident data from SPR database.

## Usage

``` r
fetch_violence_vandalism_hib(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2017-2024)

- level:

  One of "school" or "district"

## Value

Data frame with incident counts

## Examples

``` r
if (FALSE) { # \dontrun{
incidents <- fetch_violence_vandalism_hib(2024)
} # }
```
