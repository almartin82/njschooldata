# Validate grade parameter

Validates that grade is valid for the specified assessment type and
year.

## Usage

``` r
validate_grade(grade, assessment_type, end_year)
```

## Arguments

- grade:

  The grade to validate (numeric or character like "ALG1")

- assessment_type:

  The type of assessment ("njask", "parcc", etc.)

- end_year:

  The year of the assessment

## Value

TRUE invisibly if valid, otherwise throws an error
