# Validate a redesigned-biliteracy call (2025-only, school/district level)

The three redesigned Seal-of-Biliteracy sheets exist only in the
end_year 2025 SPR workbooks. This helper enforces the supported `level`
and the 2025-only year gate with clear error messages, mirroring the
gating used by the other 2024-25 redesign fetchers.

## Usage

``` r
.validate_biliteracy_redesign(end_year, level, fn)
```

## Arguments

- end_year:

  Requested school year.

- level:

  Requested level ("school" or "district").

- fn:

  Function name, for the error message.
