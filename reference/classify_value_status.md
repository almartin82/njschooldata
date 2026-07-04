# Classify why a raw value token is absent or present

Reads a raw pre-coercion value token and classifies the reason its
cleaned numeric value is present or missing. Blank values and truly
unknown non-numeric tokens default to `not_published`; callers that know
a more specific structural reason should set status directly.

## Usage

``` r
classify_value_status(raw)
```

## Arguments

- raw:

  A raw character vector before numeric coercion.

## Value

A factor with levels `actual`, `suppressed`, `not_published`,
`not_yet_observed`, and `not_applicable`.
