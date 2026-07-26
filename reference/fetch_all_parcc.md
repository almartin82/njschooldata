# Fetch all PARCC results

Convenience function to download and combine all PARCC/NJSLA results
into single data frame, including ELA, Math, and Science assessments.

## Usage

``` r
fetch_all_parcc(include_science = TRUE, allow_partial = FALSE)
```

## Arguments

- include_science:

  Include science assessments (2019+)? Default is TRUE.

- allow_partial:

  If \`FALSE\` (default), any unavailable or unparseable requested
  source fails the combined request. If \`TRUE\`, successful sources are
  returned and every request is reported by \[get_source_results()\].

## Value

A data frame with all PARCC/NJSLA results and source-result records.

## Examples

``` r
if (FALSE) { # \dontrun{
# Get all PARCC/NJSLA results (takes a while)
all_parcc <- fetch_all_parcc()

# Exclude science assessments
all_parcc_no_sci <- fetch_all_parcc(include_science = FALSE)
} # }
```
