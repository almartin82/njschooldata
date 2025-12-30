# Fetch all PARCC results

Convenience function to download and combine all PARCC/NJSLA results
into single data frame, including ELA, Math, and Science assessments.

## Usage

``` r
fetch_all_parcc(include_science = TRUE)
```

## Arguments

- include_science:

  Include science assessments (2019+)? Default is TRUE.

## Value

A data frame with all PARCC/NJSLA results

## Examples

``` r
if (FALSE) { # \dontrun{
# Get all PARCC/NJSLA results (takes a while)
all_parcc <- fetch_all_parcc()

# Exclude science assessments
all_parcc_no_sci <- fetch_all_parcc(include_science = FALSE)
} # }
```
