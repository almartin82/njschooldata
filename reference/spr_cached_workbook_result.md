# Materialize an SPR workbook for this call

Held URLs use verified release assets. Other URLs download to a
temporary file. The caller releases the returned source result after
reading.

## Usage

``` r
spr_cached_workbook_result(
  end_year,
  level,
  request_fn = .default_source_request
)
```

## Arguments

- end_year:

  SPR school year end (2017-2025).

- level:

  One of \`"school"\` or \`"district"\`.

- request_fn:

  Injectable transport for offline tests.

## Value

An \`njsd_source_result\` with a temporary workbook path.
