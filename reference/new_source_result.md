# Create an internal source result

Source request status is deliberately separate from row-level
\`value_status\`: it describes whether an artifact was retrieved and
parsed, not whether an individual observation was reported or
suppressed.

## Usage

``` r
new_source_result(
  data = NULL,
  source_status,
  source_url = NA_character_,
  retrieved_at = NULL,
  warning = NULL,
  error = NULL,
  digest = NULL
)
```

## Arguments

- data:

  Parsed data, or \`NULL\` when no usable source was produced.

- source_status:

  One of the registered source statuses.

- source_url:

  Requested source URL.

- retrieved_at:

  Retrieval timestamp, when a request was made.

- warning:

  Optional warning context.

- error:

  Optional error context.

- digest:

  Optional SHA-256 digest of the retrieved artifact.

## Value

An object of class \`njsd_source_result\`.
