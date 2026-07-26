# Pad leading digits

Ensures a numeric value has exactly the specified number of digits by
adding leading zeros.

## Usage

``` r
pad_leading(vector, digits)
```

## Arguments

- vector:

  character vector

- digits:

  ensure exactly this many digits by leading zero-padding

## Value

character vector

## Details

Numeric coercion can interpret `E` or `e` as scientific notation and can
turn non-numeric source values into plausible-looking fabricated
identifiers. This implementation pads only values containing digits and
uses string concatenation instead of a numeric round trip. Real `NA`,
alphanumeric codes, and source placeholders such as `"N.A."` are left
exactly as published.
