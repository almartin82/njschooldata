# Validate methodology parameter for graduation data

Validates that methodology is either "4 year" or "5 year" and that
5-year rates are available for the specified year.

## Usage

``` r
validate_methodology(methodology, end_year = NULL)
```

## Arguments

- methodology:

  The methodology to validate

- end_year:

  Optional year to check availability

## Value

TRUE invisibly if valid, otherwise throws an error
