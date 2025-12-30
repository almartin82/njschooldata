# Validate PARCC/NJSLA parameters

Validates all parameters for fetch_parcc() in one call.

## Usage

``` r
validate_parcc_call(end_year, grade_or_subj, subj)
```

## Arguments

- end_year:

  The year

- grade_or_subj:

  The grade or subject code

- subj:

  The subject ("ela" or "math")

## Value

TRUE invisibly if valid, otherwise throws an error
