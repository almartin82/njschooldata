# Flatten source provenance to a stable record

Flatten source provenance to a stable record

## Usage

``` r
source_result_record(
  result,
  domain = NA_character_,
  end_year = NA_integer_,
  component = NA_character_
)
```

## Arguments

- result:

  A source result.

- domain:

  Canonical data family.

- end_year:

  Requested school-year end year.

- component:

  Optional component within a composed response.

## Value

A one-row data frame.
