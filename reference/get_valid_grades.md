# Get valid grades for an assessment type and year

Returns the valid grade levels for a given assessment type and year.

## Usage

``` r
get_valid_grades(assessment_type, end_year)
```

## Arguments

- assessment_type:

  The type of assessment

- end_year:

  The year of the assessment

## Value

Vector of valid grades (may include character values like "ALG1")

## Examples

``` r
get_valid_grades("njask", 2010)
#> [1] 3 4 5 6 7 8
get_valid_grades("parcc", 2023)
#>  [1] "3"    "4"    "5"    "6"    "7"    "8"    "9"    "10"   "ALG1" "GEO" 
#> [11] "ALG2"
```
