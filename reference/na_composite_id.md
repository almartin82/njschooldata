# Blank a composite identifier whose parts were not all published

[`paste0()`](https://rdrr.io/r/base/paste.html) renders `NA` as the two
literal characters `"NA"`, so `paste0(NA, "3570")` is the string
`"NA3570"` – a plausible-looking identifier that joins to nothing and
reads as data. That is fabrication by concatenation, and it is the same
defect as `sprintf("%03d", NA)` producing `"0NA"`.

## Usage

``` r
na_composite_id(composite, ...)
```

## Arguments

- composite:

  Character vector: the concatenated identifier.

- ...:

  The parts the composite was built from. Length-1 constants (for
  example a published `"999"` district-total sentinel) recycle.

## Value

`composite`, with `NA_character_` wherever any part was missing or
blank.

## Details

Compose the identifier normally (so the construction stays readable at
the call site), then pass the composite and each of its parts through
this helper on the following line. Any row where a part is missing or
blank gets `NA_character_` back, which is what a consumer can actually
filter on.
