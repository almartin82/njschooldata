# Require the redesigned (2024-25+) SPR databases

Several SPR sheets were introduced in the 2024-25 redesign and have no
pre-2025 equivalent. This guard stops with an informative error rather
than fabricating a mapping for earlier years.

## Usage

``` r
spr_require_redesign(end_year, what)
```

## Arguments

- end_year:

  School year end.

- what:

  Human-readable description of the data being requested.
