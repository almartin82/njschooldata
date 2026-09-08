# Gets and processes a NJ enrollment file

\`fetch_enr\` is a wrapper around \`get_raw_enr\` and \`process_enr\`
that downloads and cleans enrollment data for a given year.

## Usage

``` r
fetch_enr(end_year, tidy = FALSE, use_cache = FALSE)
```

## Arguments

- end_year:

  A school year. Year is the end of the academic year - eg 2006-07
  school year is year '2007'. Valid values are 1999-2026.

- tidy:

  If TRUE, takes the unwieldy wide data and normalizes into a long, tidy
  data frame with limited headers - constants (school/district name and
  code), subgroup (all the enrollment file subgroups), program/grade and
  measure (row_total, free lunch, etc).

- use_cache:

  If TRUE, uses the session cache to avoid re-downloading data. See
  [`njsd_cache_info`](https://almartin82.github.io/njschooldata/reference/njsd_cache_info.md)
  for cache details.

## Value

Data frame with processed enrollment data. From 2020+ files,
\`free_lunch\`/\`reduced_lunch\`/\`lep\`/\`migrant\`/\`homeless\` are
computed as \`pct / 100 \* row_total\` from NJ DOE's published
percentage and this entity/year's own published total enrollment (never
rounded to a whole student); \`tidy = TRUE\` output carries a
\`value_source\` column (\`"published"\`, \`"derived_from_pct"\`, or
\`"published_pct_only"\`; see
[`tidy_enr`](https://almartin82.github.io/njschooldata/reference/tidy_enr.md))
and \`tidy = FALSE\` wide output carries the same provenance per field
as \`\<field\>\_value_source\` (eg \`lep_value_source\`). Pre-2020 files
publish these fields as real counts directly (\`"published"\`).

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 2023 enrollment data
enr_2023 <- fetch_enr(2023)

# Get tidy (long format) enrollment data
enr_tidy <- fetch_enr(2023, tidy = TRUE)

# Use caching for faster repeat calls
enr_cached <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
} # }
```
