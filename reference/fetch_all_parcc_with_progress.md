# Fetch all PARCC/NJSLA results with progress

Downloads all available PARCC and NJSLA assessment results with progress
indicators showing download status and ETA.

## Usage

``` r
fetch_all_parcc_with_progress(allow_partial = FALSE)
```

## Arguments

- allow_partial:

  If \`TRUE\`, return successful requests and attach status for
  failures. The default is strict.

## Value

A data frame with all PARCC/NJSLA results and source status.

## Examples

``` r
if (FALSE) { # \dontrun{
all_results <- fetch_all_parcc_with_progress()
} # }
```
