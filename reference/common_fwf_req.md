# common_fwf_req

common fwf logic across various assessment types. DRY.

Detects redundant composite fields (see \`find_redundant_overlaps()\`),
parses the deduplicated layout via \`readr::read_fwf()\`, then
reconstructs the dropped composites from their component parts so that
downstream code receives a data frame with the same column count and
order as the full layout.

## Usage

``` r
common_fwf_req(url, layout)
```

## Arguments

- url:

  file location

- layout:

  data frame containing fixed-width file column specifications

## Value

layout layout to use
