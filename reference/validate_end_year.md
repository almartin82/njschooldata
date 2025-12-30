# Validate end_year parameter

Validates that end_year is a valid integer within the allowed range for
the specified data type.

## Usage

``` r
validate_end_year(end_year, data_type)
```

## Arguments

- end_year:

  The year to validate

- data_type:

  The type of data being requested (e.g., "enrollment", "parcc")

## Value

TRUE invisibly if valid, otherwise throws an error

## Examples

``` r
if (FALSE) { # \dontrun{
validate_end_year(2024, "enrollment")  # Valid
validate_end_year(1990, "enrollment")  # Error: year out of range
validate_end_year(2020, "parcc")       # Error: COVID year
} # }
```
