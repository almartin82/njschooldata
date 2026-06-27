# Left-pad an NJ CDS code to a fixed width, preserving leading zeros

NJ county/district/school codes are numeric but must keep leading zeros
and stay character (e.g. district `"10"` in a drift year re-pads to
`"0010"`). Blank / non-numeric codes (e.g. a statewide aggregate row
that carries no code) become `NA`.

## Usage

``` r
staff_pad_code(x, width)
```

## Arguments

- x:

  A code vector (character or numeric).

- width:

  Target width (county 2, district 4, school 3).

## Value

A zero-padded character vector, `NA` where no numeric code.
