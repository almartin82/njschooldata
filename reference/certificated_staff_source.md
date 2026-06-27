# Resolve the NJ DOE certificated-staff download for a year

Returns the download URL, whether it is a zip archive (vs a direct
`.xlsx`), and the parser era (`"legacy"` CSV vs `"modern"` xlsx) for
`end_year`. Filenames drift across the series and are enumerated
explicitly; spaces are URL-encoded.

## Usage

``` r
certificated_staff_source(end_year)
```

## Arguments

- end_year:

  A covered school year end.

## Value

A list with `url`, `archive` (logical), and `era`.
