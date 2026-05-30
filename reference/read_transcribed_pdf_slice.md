# Read one bundled, PDF-transcribed state-level placement slice

Reads a single CSV from `inst/extdata/sped-placement-pdf-transcribed/`
for a `(end_year, age_group)` pair where NJ DOE published the
state-level rollup only as a PDF. The CSV is in the canonical tidy
schema; the reader adds the entity-flag and entity-identifier columns
that other state-level tidy paths emit, so output is interchangeable.

## Usage

``` r
read_transcribed_pdf_slice(end_year, age_group)
```

## Arguments

- end_year:

  integer ending school year (one of 2020, 2021, 2022)

- age_group:

  "5-21" or "3-5"

## Value

tibble matching the state-level tidy schema

## Details

Validates the row schema against the audit-trail JSON sibling. See the
source documents in the same directory for provenance.
